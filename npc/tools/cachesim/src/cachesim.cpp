#include "cachesim.hpp"

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unordered_set>

// 判断是否为 2 的幂
static bool is_pow2(uint64_t v) { return v != 0 && (v & (v - 1)) == 0; }

// 以 2 为底的对数，要求 v 是 2 的幂
static uint32_t log2_of(uint64_t v) { return __builtin_ctzll(v); }

bool CacheConfig::valid(std::string &err) const {
    if (size == 0 || block_size == 0 || assoc == 0) {
        err = "容量、块大小、相联度都不能为 0";
        return false;
    }
    if (!is_pow2(size) || !is_pow2(block_size) || !is_pow2(assoc)) {
        err = "容量、块大小、相联度都必须是 2 的幂";
        return false;
    }
    if (assoc > num_blocks()) {
        err = "相联度不能超过总块数（" + std::to_string(num_blocks()) + "）";
        return false;
    }
    if (block_size * assoc > size) {
        err = "块大小 × 相联度不能超过总容量";
        return false;
    }
    return true;
}

std::string CacheConfig::to_string() const {
    char buf[160];
    if (assoc == 1) {
        snprintf(buf, sizeof(buf), "容量 %luB, 块 %luB, 直接映射 (%lu 组)",
                 (unsigned long)size, (unsigned long)block_size,
                 (unsigned long)num_sets());
    } else if (full_assoc()) {
        snprintf(buf, sizeof(buf), "容量 %luB, 块 %luB, 全相联 (%lu 块)",
                 (unsigned long)size, (unsigned long)block_size,
                 (unsigned long)num_blocks());
    } else {
        snprintf(buf, sizeof(buf), "容量 %luB, 块 %luB, %lu 路组相联 (%lu 组)",
                 (unsigned long)size, (unsigned long)block_size,
                 (unsigned long)assoc, (unsigned long)num_sets());
    }
    return std::string(buf);
}

// ========== CacheSim ==========

CacheSim::CacheSim(const CacheConfig &cfg) : cfg_(cfg) {
    lines_.resize(cfg_.num_blocks());
}

uint64_t CacheSim::index_of(uint64_t addr) const {
    // 地址切成 [tag | index | offset]
    if (cfg_.num_sets() == 1) return 0;
    return (addr >> log2_of(cfg_.block_size)) & (cfg_.num_sets() - 1);
}

uint64_t CacheSim::tag_of(uint64_t addr) const {
    return addr >> (log2_of(cfg_.block_size) + log2_of(cfg_.num_sets()));
}

bool CacheSim::probe(uint64_t addr, const Lookahead *la) {
    clock_++;

    const uint64_t set = index_of(addr);
    const uint64_t tag = tag_of(addr);
    Line *base = &lines_[set * cfg_.assoc];

    // 命中：更新 LRU 时间戳
    for (uint64_t i = 0; i < cfg_.assoc; i++) {
        if (base[i].valid && base[i].tag == tag) {
            base[i].last_used = clock_;
            return true;
        }
    }

    // 缺失：优先用空闲行
    uint64_t victim = 0;
    bool free_found = false;
    for (uint64_t i = 0; i < cfg_.assoc; i++) {
        if (!base[i].valid) { victim = i; free_found = true; break; }
    }

    if (!free_found) {
        if (la != nullptr && la->count > 0) {
            // 全相联基准：按前瞻窗口做近似 OPT
            victim = opt_victim(base, *la);
        } else {
            // 常规 cache（或窗口为空）：替换最久未使用的行
            uint64_t oldest = UINT64_MAX;
            for (uint64_t i = 0; i < cfg_.assoc; i++) {
                if (base[i].last_used < oldest) { oldest = base[i].last_used; victim = i; }
            }
        }
    }

    base[victim].valid = true;
    base[victim].tag = tag;
    base[victim].last_used = clock_;
    return false;
}

// ========== 近似 OPT 的替换 ==========

// 窗口里的块号分布很规整（相邻 PC 往往落进同一个块），乘个奇数把高位打散
static inline uint64_t opt_hash(uint32_t blk) {
    return (uint64_t)blk * 0x9E3779B97F4A7C15ULL;
}

// 把窗口扫一遍，建出"块号 -> 它最近一次出现的位置"。
// 用轮次戳区分新旧槽位，所以不用每轮清零，也没有任何动态分配——
// 每次缺失都重建一个哈希表的话，5800 万次缺失光 malloc 就是分钟级开销。
void CacheSim::opt_index_build(const Lookahead &la) {
    if (opt_slots_ < la.count * 2) {
        opt_slots_ = 1;
        while (opt_slots_ < la.count * 2) opt_slots_ <<= 1;
        opt_key_.assign(opt_slots_ * 4, 0);
        opt_pos_.assign(opt_slots_ * 4, 0);
        opt_stamp_.assign(opt_slots_ * 4, 0);
        opt_round_ = 0;
    }

    opt_round_++;

    for (uint64_t j = 0; j < la.count; j++) {
        const uint32_t blk = la.blocks[j];
        const uint64_t s = (opt_hash(blk) & (opt_slots_ - 1)) * 4;
        for (int w = 0; w < 4; w++) {
            if (opt_stamp_[s + w] != opt_round_) {
                // 空槽位。窗口是从近到远正序扫的，第一次写入就是最近的位置
                opt_stamp_[s + w] = opt_round_;
                opt_key_[s + w] = blk;
                opt_pos_[s + w] = (uint32_t)j;
                break;
            }
            if (opt_key_[s + w] == blk) break;  // 本轮已记过，保留更近的那个
        }
    }
}

// 返回块号在窗口里最近一次出现的位置；窗口里不再出现则返回 UINT64_MAX
uint64_t CacheSim::opt_index_find(uint32_t blk) const {
    const uint64_t s = (opt_hash(blk) & (opt_slots_ - 1)) * 4;
    for (int w = 0; w < 4; w++) {
        if (opt_stamp_[s + w] == opt_round_ && opt_key_[s + w] == blk)
            return opt_pos_[s + w];
    }
    return UINT64_MAX;
}

uint64_t CacheSim::opt_victim(const Line *base, const Lookahead &la) {
    opt_index_build(la);

    // 窗口里不再出现的行最优先踢（它的下次使用距离必然 ≥ 窗口长度），
    // 其次踢窗口里位置最靠后的；距离相同时用 last_used 兜底。
    uint64_t victim = 0;
    uint64_t best = 0;
    bool has = false;
    for (uint64_t i = 0; i < cfg_.assoc; i++) {
        // 全相联下 num_sets 为 1，tag_of(addr) 恰好等于块号，可以直接比
        const uint64_t d = opt_index_find((uint32_t)base[i].tag);
        if (!has || d > best ||
            (d == best && base[i].last_used < base[victim].last_used)) {
            best = d;
            victim = i;
            has = true;
        }
    }
    return victim;
}

bool CacheSim::access(uint64_t addr, const Lookahead *la) {
    stats_.accesses++;
    const bool hit = probe(addr, la);
    if (hit) stats_.hits++;
    else     stats_.misses++;
    return hit;
}

// ========== 3C 缺失分类 ==========

bool analyze(const std::string &path, const CacheConfig &cfg, const AnalyzeOptions &opt,
             AnalysisResult &out, std::string &err) {
    const auto t_begin = std::chrono::steady_clock::now();

    // 指定配置和同容量同块大小的全相联 cache 同时跑，一趟遍历喂两份
    CacheSim sim(cfg);
    CacheConfig fa_cfg = cfg;
    fa_cfg.assoc = fa_cfg.num_blocks();
    CacheSim fa_sim(fa_cfg);
    CacheSim fa_sim_wide(fa_cfg);  // 同样配置，但前瞻窗口开两倍，当精度参照

    // 只记访问过的块号，用来判断冷启动缺失，量与代码规模有关，与 trace 长度无关
    std::unordered_set<uint64_t> seen_blocks;

    // 前瞻窗口。pctrace_foreach 是读一段回调一次、回调里看不到未来，
    // 所以先把 PC 攒进窗口，之后每来一条就处理窗口里最老的那条，
    // 这样处理它时，窗口里正好剩下它之后的一串，可以当近似 OPT 的"未来"。
    // 窗口每条 PC 都推进一步，不管当前访问命中还是缺失——OPT 要的是真实的未来序列，
    // 只在缺失时取样会让窗口内容稀疏错位。
    //
    // 基准看前 K 条，参照看前 KR = 2K 条，一趟遍历喂三份。
    // 关掉参照时 KW 就等于 K，窗口缓冲和索引开销都跟着降下来。
    const uint64_t K       = opt.opt_window;              // 基准窗口
    const bool     use_ref = opt.reference && K > 0;      // 窗口为 0 时参照无意义
    const uint64_t KR      = use_ref ? 2 * K : 0;         // 参照窗口（两倍）
    const uint64_t KW      = use_ref ? KR : K;            // 窗口实际要开多深
    std::vector<uint32_t> win(KW ? 2 * KW : 0);
    uint64_t tail = 0;  // 窗口末尾在 win 里的下标
    uint64_t wlen = 0;  // 窗口里现有多少条

    auto process_pc = [&](uint64_t pc, const Lookahead *la_k, const Lookahead *la_w) {
        // 该块第一次被访问，无论什么 cache 都必然缺失，记作冷启动缺失
        if (seen_blocks.insert(pc / cfg.block_size).second) out.miss.compulsory++;
        sim.access(pc);             // 常规 cache 永远不看未来，行为与改造前一致
        fa_sim.access(pc, la_k);    // 全相联基准按窗口做近似 OPT
        if (la_w != nullptr) fa_sim_wide.access(pc, la_w);
    };

    auto step = [&]() {
        const uint64_t blk = win[tail - wlen];
        wlen--;
        // 摘掉当前这条，剩下的正好是它之后的 wlen 条
        const uint32_t *fut = win.data() + (tail - wlen);
        // 各自裁到自己那个窗口深度。窗口里存的是块号，下面还原成块起始地址
        // 再喂给 cache：tag 和 index 只由块号决定，和用真实 PC 访问完全等价。
        Lookahead la_k{fut, wlen < K  ? wlen : K};
        Lookahead la_r{fut, wlen < KR ? wlen : KR};
        process_pc(blk * cfg.block_size, &la_k, use_ref ? &la_r : nullptr);
    };

    const bool ok = pctrace_foreach(path, [&](const PcRun &run) {
        for (uint32_t i = 0; i < run.count; i++) {
            const uint64_t pc = run.start_pc + (uint64_t)i * 4;

            if (K == 0) { process_pc(pc, nullptr, nullptr); continue; }

            if (tail == 2 * KW) {
                memmove(win.data(), win.data() + KW, KW * sizeof(uint32_t));
                tail = KW;
            }
            win[tail++] = (uint32_t)(pc / cfg.block_size);  // 存块号，省掉缺失时的除法
            wlen++;
            if (wlen > KW) step();
        }
    }, err);

    if (!ok) return false;

    // 收尾：窗口里剩的就是 trace 尾部那几条，按先进先出排空，一条都不能少
    // （少了 accesses 就对不上）。窗口自然变短，最后几条的前瞻为空，退化成 LRU。
    while (wlen > 0) step();

    out.stats = sim.stats();
    out.fully_miss = fa_sim.stats().misses;
    out.reference_ran = use_ref;
    out.fully_miss_wide = use_ref ? fa_sim_wide.stats().misses : 0;
    out.opt_window = K;
    out.ref_window = use_ref ? KR : 0;

    // 全相联基准的缺失 = 冷启动 + 容量；多出来的就是相联度/映射方式造成的冲突缺失。
    // compulsory ≤ fully_miss 是结构性的（每块的首次访问在任何 cache 里都必缺），
    // 这里一并截断，免得万一反超时算出回绕的巨大无符号数。
    out.miss.capacity = out.fully_miss >= out.miss.compulsory
                      ? out.fully_miss - out.miss.compulsory : 0;
    out.miss.conflict = out.stats.misses >= out.fully_miss
                      ? out.stats.misses - out.fully_miss : 0;

    // 窗口有限，基准未必真的取到容量下界。真出现反超就如实标记，让报告提示误差
    out.baseline_unreliable = out.fully_miss > out.stats.misses;

    out.elapsed_ms = (uint64_t)std::chrono::duration_cast<std::chrono::milliseconds>(
                         std::chrono::steady_clock::now() - t_begin).count();

    return true;
}

// ========== trace 读取 ==========

bool pctrace_foreach(const std::string &path,
                     const std::function<void(const PcRun &)> &fn,
                     std::string &err) {
    // trace 是 bzip2 压缩过的，用 bzcat 解压后直接从管道里读。
    // 路径两侧加引号，免得路径里有空格时被 shell 拆成多个参数。
    const std::string cmd = "bzcat '" + path + "'";

    FILE *fp = popen(cmd.c_str(), "r");
    if (fp == NULL) {
        err = "无法执行 bzcat，请确认已安装 bzip2";
        return false;
    }

    uint64_t run_cnt = 0;
    PcRun rec;
    size_t n;
    // 每读到一段就立刻喂给回调，读完就丢，内存里不留整份 trace
    while ((n = fread(&rec, sizeof(PcRun), 1, fp)) == 1) {
        fn(rec);
        run_cnt++;
    }

    if (n != 0) {
        pclose(fp);
        err = path + " 末尾有一条不完整的记录，文件可能被截断了";
        return false;
    }

    if (pclose(fp) != 0) {
        err = "bzcat 读取 " + path + " 失败，请确认文件是 bzip2 压缩的且路径正确";
        return false;
    }

    if (run_cnt == 0) {
        err = path + " 里没有任何访问记录";
        return false;
    }
    return true;
}

bool parse_size(const char *str, uint64_t &out) {
    if (str == NULL || *str == '\0') return false;

    char *end = NULL;
    unsigned long long v = strtoull(str, &end, 0);
    if (end == str || v == 0) return false;

    if (*end == 'k' || *end == 'K') {
        v *= 1024ULL;
        end++;
    } else if (*end == 'm' || *end == 'M') {
        v *= 1024ULL * 1024ULL;
        end++;
    }

    if (*end != '\0') return false;
    out = (uint64_t)v;
    return true;
}
