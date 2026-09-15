// 生成用来验证 cachesim 3C 统计的 pctrace 测试数据。
//
// 每个用例的访问序列都取得很小，期望的 3C 结果可以手工推导出来：
// 生成后用 run_tests.sh 逐个跑 cachesim，把实际输出和这里的期望值对比。
//
// pctrace 的记录格式：start_pc(u32) + count(u32)，表示从 start_pc 起
// 连续执行 count 条指令（PC 依次加 4）。用例里的 pc 都按块大小对齐，
// 这样一条记录就正好对应访问某个块。

#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <string>
#include <vector>

struct Run {
    uint32_t pc;
    uint32_t count;
};

struct TestCase {
    const char *name;
    const char *desc;
    uint64_t size;    // cache 容量（字节）
    uint64_t block;   // 块大小（字节）
    uint64_t assoc;   // 相联度
    std::vector<Run> runs;
    // 期望的统计结果
    uint64_t accesses, misses, compulsory, capacity, conflict;
};

// 把用例写成 bzip2 压缩的 pctrace，和 cachesim 的读取方式对称
static bool write_case(const TestCase &tc, const std::string &path) {
    const std::string cmd = "bzip2 -c > '" + path + "'";
    FILE *fp = popen(cmd.c_str(), "w");
    if (fp == NULL) {
        fprintf(stderr, "无法执行 bzip2\n");
        return false;
    }

    for (size_t i = 0; i < tc.runs.size(); i++) {
        uint32_t rec[2] = { tc.runs[i].pc, tc.runs[i].count };
        if (fwrite(rec, sizeof(uint32_t), 2, fp) != 2) {
            pclose(fp);
            fprintf(stderr, "写入 %s 失败\n", path.c_str());
            return false;
        }
    }
    return pclose(fp) == 0;
}

int main() {
    // 说明里各用例的推导都基于：块大小 4B（一条指令），
    // 直接映射的组号 = 块号 & (组数-1)，全相联基准按近似 OPT 替换。
    std::vector<TestCase> cases = {
        { "compulsory_only", "顺序取指 16 条，每块只碰一次，全是冷启动缺失",
          64, 4, 1, {{0, 16}}, 16, 16, 16, 0, 0 },

        { "loop_hit", "同样 4 条指令的循环跑 3 遍，只有第一遍缺失",
          64, 4, 1, {{0, 4}, {0, 4}, {0, 4}}, 12, 4, 4, 0, 0 },

        { "capacity", "只有 2 个块的位置，却要轮着用 3 个块，"
         "OPT 全相联也装不下",
          8, 4, 1, {{0, 1}, {4, 1}, {8, 1}, {0, 1}, {4, 1}, {8, 1}}, 6, 5, 3, 1, 1 },

        { "conflict_direct", "直接映射 4 组，块 0 和块 4 撞在同一组互相踢，"
         "全相联装得下这两个块",
          16, 4, 1, {{0, 1}, {16, 1}, {0, 1}}, 3, 3, 2, 0, 1 },

        { "conflict_2way", "2 路组相联：块 0/2/4 都落在组 0，两路放不下三个，"
         "全相联 4 个块能全装下",
          16, 4, 2, {{0, 1}, {8, 1}, {16, 1}, {0, 1}}, 4, 4, 3, 0, 1 },

        // 这个序列下 LRU 全相联会比直接映射多缺一次（LRU 组相联不满足
        // stack property），旧的 LRU 基准会把冲突项算成负数，换 OPT 才是 1
        { "lru_trap", "块 0/2/1 的序列：LRU 全相联缺 6 次、OPT 只缺 4 次",
          8, 4, 1, {{0, 1}, {8, 1}, {4, 1}, {0, 1}, {8, 1}, {4, 1}}, 6, 5, 3, 1, 1 },

        { "block_merge", "一段 8 条指令跨 4 个块，验证段内按块合并不会重复计数",
          32, 8, 1, {{0, 8}}, 8, 4, 4, 0, 0 },
    };

    FILE *list = fopen("cases.txt", "w");
    if (list == NULL) {
        fprintf(stderr, "无法写出 cases.txt\n");
        return 1;
    }

    printf("生成测试用的 pctrace 数据：\n\n");
    for (size_t i = 0; i < cases.size(); i++) {
        const TestCase &tc = cases[i];
        const std::string path = std::string(tc.name) + ".bin.bz2";

        if (!write_case(tc, path)) {
            fprintf(stderr, "生成 %s 失败\n", path.c_str());
            fclose(list);
            return 1;
        }

        printf("%s\n", tc.name);
        printf("  配置: 容量 %luB / 块 %luB / %lu 路      用例: %s\n",
               (unsigned long)tc.size, (unsigned long)tc.block,
               (unsigned long)tc.assoc, tc.desc);
        printf("  期望: 取指 %lu  缺失 %lu  (compulsory %lu, capacity %lu, conflict %lu)\n\n",
               (unsigned long)tc.accesses, (unsigned long)tc.misses,
               (unsigned long)tc.compulsory, (unsigned long)tc.capacity,
               (unsigned long)tc.conflict);

        fprintf(list, "%s %lu %lu %lu %lu %lu %lu %lu %lu\n",
                path.c_str(), (unsigned long)tc.size, (unsigned long)tc.block,
                (unsigned long)tc.assoc, (unsigned long)tc.accesses,
                (unsigned long)tc.misses, (unsigned long)tc.compulsory,
                (unsigned long)tc.capacity, (unsigned long)tc.conflict);
    }

    fclose(list);
    printf("期望值已写入 cases.txt，用 `make check` 逐个对比。\n");
    return 0;
}
