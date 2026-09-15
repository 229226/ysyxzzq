#ifndef __CACHESIM_HPP__
#define __CACHESIM_HPP__

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

// ========== cache 配置 ==========
// 只模拟指令 cache：一次取指 = 一次访问，访问地址是 PC。
struct CacheConfig {
    uint64_t size = 4 * 1024;   // 总容量（字节）
    uint64_t block_size = 32;   // 块大小（字节）
    uint64_t assoc = 1;         // 相联度，1 表示直接映射

    uint64_t num_blocks() const { return size / block_size; }
    uint64_t num_sets()   const { return num_blocks() / assoc; }
    bool     full_assoc() const { return assoc == num_blocks(); }

    // 参数必须都是 2 的幂且能整除，否则无法用位运算切分地址
    bool valid(std::string &err) const;
    std::string to_string() const;
};

// ========== 统计 ==========
struct CacheStats {
    uint64_t accesses = 0;   // 取指次数
    uint64_t hits = 0;
    uint64_t misses = 0;

    double hit_rate() const { return accesses ? 100.0 * hits / accesses : 0.0; }
};

// 3C 缺失分类
struct MissBreakdown {
    uint64_t compulsory = 0;  // 冷启动：该块第一次被访问
    uint64_t capacity = 0;    // 容量：全相联（近似 OPT）下也会缺
    uint64_t conflict = 0;    // 冲突：相联度/映射方式导致的额外缺失

    uint64_t total() const { return compulsory + capacity + conflict; }
};

// trace 里的一段：从 start_pc 开始连续执行了 count 条指令（PC 依次加 4）
struct PcRun {
    uint32_t start_pc;
    uint32_t count;
};

// 前瞻窗口：按程序顺序排列的未来访问块号，blocks[0] 是最近的一次。
// 只喂给全相联基准，用来做近似 OPT 的替换决策。
// 前提：窗口里的块号必须和 cache 用同一个 block_size（当前 sim 与 fa_sim 共用 cfg）。
struct Lookahead {
    const uint32_t *blocks;
    uint64_t        count;
};

// 分析选项
struct AnalyzeOptions {
    // 基准的前瞻窗口大小，以 PC 条数计。0 表示不看未来，退回纯 LRU 基准。
    uint64_t opt_window = 64;

    // 是否额外跑一个两倍窗口的参照基准，用来估计当前窗口离 OPT 下界还有多远。
    // 默认关闭：它要多花约四成仿真时间（窗口缓冲和索引都翻倍），调参阶段用不上，
    // 等选定配置后再用 -R 打开看精度即可。opt_window 为 0 时参照无意义，会自动跳过。
    bool reference = false;
};

// ========== cache 仿真 ==========
class CacheSim {
public:
    explicit CacheSim(const CacheConfig &cfg);

    // 单次取指访问，返回是否命中。
    // la 非空且非空窗口时，缺失的替换决策改用近似 OPT（只对全相联基准有意义）。
    bool access(uint64_t addr, const Lookahead *la = nullptr);

    const CacheStats  &stats()  const { return stats_; }
    const CacheConfig &config() const { return cfg_; }

private:
    struct Line {
        uint64_t tag = 0;
        bool     valid = false;
        uint64_t last_used = 0;  // LRU 时间戳
    };

    CacheConfig cfg_;
    std::vector<Line> lines_;    // 所有组的所有行，第 s 组占 [s*assoc, (s+1)*assoc)
    uint64_t clock_ = 0;
    CacheStats stats_;

    // 近似 OPT 用的窗口索引：块号 -> 它在窗口里最近一次出现的位置。
    // 用带轮次戳的定长多路索引，避免每次缺失都构造/析构哈希表。
    std::vector<uint32_t> opt_key_;
    std::vector<uint32_t> opt_pos_;
    std::vector<uint32_t> opt_stamp_;
    uint64_t opt_slots_ = 0;
    uint32_t opt_round_ = 0;

    // 一次访问，更新 cache 状态和替换信息，返回是否命中（不更新统计）
    bool probe(uint64_t addr, const Lookahead *la);

    uint64_t index_of(uint64_t addr) const;
    uint64_t tag_of(uint64_t addr) const;

    // 近似 OPT：踢掉窗口中最晚才会再用到的行
    uint64_t opt_victim(const Line *base, const Lookahead &la);
    void     opt_index_build(const Lookahead &la);
    uint64_t opt_index_find(uint32_t blk) const;
};

// ========== 3C 缺失分类 ==========
// 一次分析的完整结果
struct AnalysisResult {
    CacheStats    stats;                        // 常规 cache 的统计
    MissBreakdown miss;                         // 3C 缺失分类
    uint64_t      fully_miss = 0;               // 全相联基准的缺失数，供报告核对
    bool          baseline_unreliable = false;  // 基准缺失反而更多，3C 只能当参考

    // 精度参照：同配置、但前瞻窗口开两倍的另一个全相联模拟。它的缺失数更接近
    // 真正的 OPT 下界，和 fully_miss 一对比就知道当前窗口够不够用。
    // 关掉参照、或 opt_window 为 0 时，reference_ran 为 false、fully_miss_wide 为 0。
    uint64_t      fully_miss_wide = 0;
    bool          reference_ran = false;        // 本次到底跑没跑参照
    uint64_t      opt_window = 0;               // 基准窗口大小，报告里要显示
    uint64_t      ref_window = 0;               // 参照窗口大小（= 两倍基准窗口）

    // 分析总耗时（毫秒）。边解压边仿真是交织在一起的，低开销地拆开做不到，
    // 所以这里只报总数；其中包含从 bzcat 读并解压 trace 的时间。
    uint64_t      elapsed_ms = 0;
};

// 分析指定配置。内部边解压边喂 cache，只遍历一遍 trace，不把 trace 存下来。
// 常规 cache 和同容量同块大小的全相联 cache 同时跑：后者用近似 OPT 替换
// （看 opt.opt_window 条前瞻），它的缺失减去冷启动记作 capacity，
// 与常规 cache 缺失之差就是相联度/映射方式带来的 conflict。
// 返回 false 表示读 trace 失败，原因写在 err 里。
bool analyze(const std::string &path, const CacheConfig &cfg, const AnalyzeOptions &opt,
             AnalysisResult &out, std::string &err);

// ========== trace 读取 ==========
// 流式遍历 bzip2 压缩的 pctrace.bin：用 popen 调 bzcat，读到一段就回调一次。
// 解压和仿真交替进行，内存里只留当前这一段，不会出现解压后的副本。
bool pctrace_foreach(const std::string &path,
                     const std::function<void(const PcRun &)> &fn,
                     std::string &err);

// 把 "4K" / "1M" / "512" 这类写法转成字节数
bool parse_size(const char *str, uint64_t &out);

#endif
