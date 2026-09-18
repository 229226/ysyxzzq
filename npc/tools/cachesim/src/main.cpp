#include "cachesim.hpp"

#include <getopt.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

static void usage(const char *prog) {
    printf("用法: %s -i <pctrace.bin> [选项]\n\n", prog);
    printf("选项:\n");
    printf("  -i, --input FILE   输入 PC 轨迹文件，bzip2 压缩的 pctrace.bin\n");
    printf("                     例如 ../../pctrace.bin.bz2\n");
    printf("  -s, --size SIZE    cache 总容量，支持 4K/16K/1M 这类写法（默认 4K）\n");
    printf("  -b, --block SIZE   块大小（默认 32）\n");
    printf("  -a, --assoc N      相联度，1 表示直接映射（默认 1）\n");
    printf("  -K, --opt-window N 前瞻窗口大小，供全相联基准做近似 OPT\n");
    printf("                     越大越接近最优，0 表示不看未来、退回纯 LRU（默认 64）\n");
    printf("  -R, --reference    额外跑一个两倍窗口的参照，用来估计基准精度\n");
    printf("                     默认关（要多花约四成时间），需要看精度时再打开\n");
    printf("  -h, --help         显示本帮助\n");
}

// 打印单个配置的分析结果
static void print_report(const CacheConfig &cfg, const AnalysisResult &r) {
    const CacheStats &st = r.stats;
    const MissBreakdown &mb = r.miss;
    const uint64_t miss_total = mb.total();

    printf("=== Cache 配置: %s ===\n", cfg.to_string().c_str());
    printf("  取指次数   : %lu\n", (unsigned long)st.accesses);
    printf("  命中       : %lu  (%.2f%%)\n", (unsigned long)st.hits, st.hit_rate());
    printf("  缺失       : %lu  (%.2f%%)\n", (unsigned long)st.misses,
           st.accesses ? 100.0 * st.misses / st.accesses : 0.0);

    printf("\n  缺失分类 (3C):\n");
    auto print_miss = [&](const char *name, uint64_t n) {
        printf("    %-12s: %lu  (占缺失 %.2f%%)\n", name, (unsigned long)n,
               miss_total ? 100.0 * n / miss_total : 0.0);
    };
    print_miss("Compulsory", mb.compulsory);
    print_miss("Capacity", mb.capacity);
    print_miss("Conflict", mb.conflict);

    // cache 的物理占用：数据阵列 + 每行的有效位 + 每行的 tag。
    // 只算这两项额外开销（仿真里的 last_used 是时间戳，不对应硬件）。
    const uint64_t total_bits = cfg.total_bits();
    printf("\n  cache 占用 : %lu bit (%lu B) = 数据 %lu bit + 有效位 %lu bit + tag %lu bit\n",
           (unsigned long)total_bits, (unsigned long)((total_bits + 7) / 8),
           (unsigned long)(cfg.size * 8), (unsigned long)cfg.num_blocks(),
           (unsigned long)(cfg.num_blocks() * cfg.tag_bits()));

    // 基准精度：同一份 trace 再用两倍窗口跑一个全相联，比较两个基准的缺失数。
    // 窗口越大越接近真正的 OPT 下界，所以两者差得越小，说明当前窗口越够用，
    // 上面的 capacity / conflict 划分就越可信。
    if (r.reference_ran) {
        printf("\n  基准精度 (前瞻窗口越大越接近 OPT 下界):\n");
        printf("    窗口 %-6lu 全相联缺失: %lu\n",
               (unsigned long)r.opt_window, (unsigned long)r.fully_miss);
        printf("    窗口 %-6lu 全相联缺失: %lu\n",
               (unsigned long)r.ref_window, (unsigned long)r.fully_miss_wide);

        // 参照恒为两倍窗口，这个差就是"窗口再翻倍还能降多少"，越小说明越够用
        const uint64_t gap = r.fully_miss - r.fully_miss_wide;
        const double pct = r.fully_miss ? 100.0 * gap / r.fully_miss : 0.0;
        printf("    相差 %lu 次 (%.2f%%)，越小说明窗口越够用；"
               "偏大就用 -K 加大窗口重跑\n",
               (unsigned long)gap, pct);
    } else if (r.opt_window > 0) {
        printf("\n  基准精度: 参照已关闭（用 -R 或 --reference 打开，"
               "可以估计当前窗口离 OPT 下界还有多远）\n");
    }

    // 边解压边仿真是交织的，没法低开销地拆开，所以只报总耗时。
    // 其中读并解压 trace 那部分是固定的，跟窗口大小和 cache 配置都无关。
    printf("\n  耗时: %lu ms（含从 bzcat 读取并解压 trace 的时间）\n",
           (unsigned long)r.elapsed_ms);

    // 注意：这段文案里不要出现 Compulsory / Capacity / Conflict，
    // 也不要让某行以两个空格 + "缺失" 开头——test/run_tests.sh 用无锚点 awk 取数，
    // 多匹配一行会把数字拼成两行，用例会静默变红。
    if (r.baseline_unreliable) {
        printf("\n  注意: 全相联基准缺失 %lu 次，反而多于本配置的 %lu 次，\n"
               "        说明这次仿真误差较大：前瞻窗口太短，或者 trace 本身太短，\n"
               "        基准已不是可信的下界，上面的分解只能当参考（冲突项按 0 处理）。\n"
               "        可以用 --opt-window N 加大前瞻窗口后重跑。\n",
               (unsigned long)r.fully_miss, (unsigned long)st.misses);
    }
}

int main(int argc, char *argv[]) {
    std::string input;
    CacheConfig cfg;

    static struct option long_opts[] = {
        {"input", required_argument, NULL, 'i'},
        {"size",  required_argument, NULL, 's'},
        {"block", required_argument, NULL, 'b'},
        {"assoc", required_argument, NULL, 'a'},
        {"opt-window", required_argument, NULL, 'K'},
        {"reference",    no_argument, NULL, 'R'},
        {"no-reference", no_argument, NULL, 'r'},
        {"help",  no_argument,       NULL, 'h'},
        {0, 0, 0, 0}
    };

    AnalyzeOptions aopt;

    int opt;
    while ((opt = getopt_long(argc, argv, "i:s:b:a:K:Rrh", long_opts, NULL)) != -1) {
        switch (opt) {
        case 'i':
            input = optarg;
            break;
        case 's':
            if (!parse_size(optarg, cfg.size)) {
                fprintf(stderr, "非法的容量: %s\n", optarg);
                return 1;
            }
            break;
        case 'b':
            if (!parse_size(optarg, cfg.block_size)) {
                fprintf(stderr, "非法的块大小: %s\n", optarg);
                return 1;
            }
            break;
        case 'a':
            cfg.assoc = strtoull(optarg, NULL, 0);
            break;
        case 'K':
            // 0 是合法值，表示不看未来、退回纯 LRU 基准
            aopt.opt_window = strtoull(optarg, NULL, 0);
            break;
        case 'R':
            aopt.reference = true;
            break;
        case 'r':
            aopt.reference = false;
            break;
        case 'h':
            usage(argv[0]);
            return 0;
        default:
            usage(argv[0]);
            return 1;
        }
    }

    if (input.empty()) {
        fprintf(stderr, "必须用 -i 指定 trace 文件\n\n");
        usage(argv[0]);
        return 1;
    }

    std::string err;

    if (!cfg.valid(err)) {
        fprintf(stderr, "非法的 cache 配置: %s\n", err.c_str());
        return 1;
    }

    AnalysisResult r;
    if (!analyze(input, cfg, aopt, r, err)) {
        fprintf(stderr, "读取 trace 失败: %s\n", err.c_str());
        return 1;
    }

    printf("trace: %s，共 %lu 次取指\n\n", input.c_str(),
           (unsigned long)r.stats.accesses);
    print_report(cfg, r);
    return 0;
}
