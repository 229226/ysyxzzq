#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""多核并行扫 cachesim 的参数组合，并把结果汇总成一张对比表。

cachesim 自带的 -S/--sweep 是串行的：54 个组合依次跑，每个组合都要重新
解压一遍 trace，实测要 14~15 分钟。本脚本用多个进程同时跑这些组合，
把它压到 2 分钟量级。

用法（在 npc/tools/cachesim/ 下）：
    make                                  # 先构建 build/cachesim
    python3 sweep.py                      # 等价于内置 -S 的那组网格
    python3 sweep.py --size 512:16384 --assoc 1:4
    python3 sweep.py --dry-run            # 只看网格和命令行，不跑
    python3 sweep.py -K 0,64,256 -s 2K -b 32 -a 2    # 单独扫前瞻窗口
结果写到 ../../result/cachesim/<时间戳>/：
    summary.csv   汇总表，utf-8-sig 编码，可直接用 Excel 打开
    raw/*.txt     每个组合的完整输出，排错时看这个

关于耗时：cachesim 每次运行都要 fork 一个 bzcat 把 trace 整份解压一遍，
这部分开销（341MB，约 10 秒）与 cache 配置无关。54 个组合里约 9 分钟是
同一份 trace 的重复解压，这是并行扫参数绕不掉的主要成本。
"""

import argparse
import csv
import os
import re
import shutil
import signal
import subprocess
import sys
import threading
import time
import unicodedata
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

# 脚本在 npc/tools/cachesim/ 下
SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_CACHESIM = SCRIPT_DIR / "build" / "cachesim"
DEFAULT_TRACE = SCRIPT_DIR.parent.parent / "pctrace.bin.bz2"
DEFAULT_OUTBASE = SCRIPT_DIR.parent.parent / "result" / "cachesim"

# 与内置 run_sweep() 的网格一致（main.cpp:88-90），脚本可以直接当作它的并行替代
DEFAULT_SIZES = "32:128"
DEFAULT_BLOCKS = "4:16"
DEFAULT_ASSOCS = "1:4"
DEFAULT_WINDOWS = "256"


# ========== 取值解析 ==========

def parse_size(text):
    """把 "512" / "4K" / "1M" 解析成字节数，规则与 cachesim 的 parse_size() 一致。"""
    s = text.strip()
    if not s:
        raise ValueError("空值")
    mul = 1
    if s[-1] in "kK":
        mul, s = 1024, s[:-1]
    elif s[-1] in "mM":
        mul, s = 1024 * 1024, s[:-1]
    v = int(s, 0) * mul
    if v <= 0:
        raise ValueError("必须是正整数")
    return v


def parse_plain_int(text, name):
    """相联度和前瞻窗口走裸十进制，和 cachesim 的 -a/-K 一样不支持 K/M 后缀。

    这一点必须显式拒绝：cachesim 里 -a 用裸 strtoull，写 -a 4K 会被静默
    当成 4，用户以为自己要了 4096 路。
    """
    s = text.strip()
    if s and s[-1] in "kKmM":
        raise ValueError("%s 不支持 K/M 后缀，请写十进制（如 4）" % name)
    return int(s, 0)


def parse_dimension(text, item_parser, name):
    """解析逗号分隔的取值列表。每个元素可以是三种之一：

        512            单值
        512:16384      等比闭区间，公比 2（起止都必须是 2 的幂）
        512:16384:6    等比闭区间，指定个数

    缓存容量、块大小、相联度、前瞻窗口这几个维度的工程取值几乎总是 2 的幂，
    等比写法比手打一长串省事。
    """
    out = []
    for token in text.split(","):
        token = token.strip()
        if not token:
            continue

        if ":" not in token:
            out.append(item_parser(token))
            continue

        parts = token.split(":")
        if len(parts) == 2:
            # 公比固定为 2，起止都必须是 2 的幂，否则区间里的数不是整数
            lo, hi = item_parser(parts[0]), item_parser(parts[1])
            if lo < 1 or hi < lo or not (is_pow2(lo) and is_pow2(hi)):
                raise ValueError("%s 的区间 %s 起止必须都是 2 的幂且递增，"
                                 "请用 起:止:个数 或逗号列出具体值" % (name, token))
            r = 2
            n = hi.bit_length() - lo.bit_length() + 1
        elif len(parts) == 3:
            lo, hi, n = item_parser(parts[0]), item_parser(parts[1]), int(parts[2])
            if n < 2:
                raise ValueError("%s 的等比区间至少要有 2 个数" % name)
            span = hi // lo
            r = round(span ** (1.0 / (n - 1)))
            if r < 2 or lo * r ** (n - 1) != hi:
                raise ValueError("%s 的区间 %s 求不出整数公比" % (name, token))
        else:
            raise ValueError("%s 的取值 %s 写错了，应为 值 / 起:止 / 起:止:个数"
                             % (name, token))

        out.extend(lo * r ** i for i in range(n))

    # 去重并保持顺序，允许用户把区间和单值混着写
    seen, uniq = set(), []
    for v in out:
        if v not in seen:
            seen.add(v)
            uniq.append(v)
    return uniq


# ========== 参数合法性 ==========
# 逐条镜像 CacheConfig::valid()（cachesim.cpp:15-33）。注意它判的是
# 「都是 2 的幂」+「block * assoc <= size」，没有单独的整除检查——
# 三者都是 2 的幂时，block*assoc <= size 已经蕴含了 assoc | num_blocks。
# 这里不要"顺手补上"一个恒真的整除检查。

def is_pow2(v):
    return v > 0 and (v & (v - 1)) == 0


def config_invalid_reason(size, block, assoc):
    """合法返回 None，非法返回中文原因。"""
    if size == 0 or block == 0 or assoc == 0:
        return "容量、块大小、相联度都不能为 0"
    if not (is_pow2(size) and is_pow2(block) and is_pow2(assoc)):
        return "容量、块大小、相联度都必须是 2 的幂"
    if block * assoc > size:
        return "块大小 × 相联度不能超过总容量"
    return None


def combo_tag(size, block, assoc, window):
    return "s%db%da%dK%d" % (size, block, assoc, window)


# ========== 输出解析 ==========
# 行首锚定是必须的：报告里 "占缺失" 这类文案也含 "缺失"，无锚点会把两行拼起来
# （main.cpp:73-75 的注释专门警告过，test/run_tests.sh:36-40 是既有先例）。
RE_ACCESSES = re.compile(r"取指次数\s*:\s*(\d+)")
RE_HITS = re.compile(r"^  命中\s*:\s*(\d+)", re.M)
RE_MISSES = re.compile(r"^  缺失\s*:\s*(\d+)", re.M)
RE_COMPULSORY = re.compile(r"^    Compulsory\s*:\s*(\d+)", re.M)
RE_CAPACITY = re.compile(r"^    Capacity\s*:\s*(\d+)", re.M)
RE_CONFLICT = re.compile(r"^    Conflict\s*:\s*(\d+)", re.M)
RE_ELAPSED = re.compile(r"^  耗时\s*:\s*(\d+)\s*ms", re.M)
RE_UNRELIABLE = re.compile(r"^  注意:\s*全相联基准缺失", re.M)
# "  cache 占用 : 944 bit (118 B) = 数据 512 bit + 有效位 16 bit + tag 416 bit"
RE_CACHE_SPACE = re.compile(r"^  cache 占用\s*:\s*(\d+)\s*bit\s*\((\d+)\s*B\)", re.M)


def parse_report(text):
    """从单配置模式的报告里取数。字段不全就返回 None，表示这份输出不可信。

    「cache 占用」行也要求存在：它是 cachesim 报告里固定会打的一行，缺了
    说明用的是没重新编译的旧二进制，与其静默按 0 记，不如在这里拦住。
    """
    def grab(rx):
        m = rx.search(text)
        return int(m.group(1)) if m else None

    accesses, misses, hits = grab(RE_ACCESSES), grab(RE_MISSES), grab(RE_HITS)
    space = RE_CACHE_SPACE.search(text)
    if accesses is None or misses is None or hits is None or space is None:
        return None

    return {
        "accesses": accesses,
        "hits": hits,
        "misses": misses,
        "hit_rate": 100.0 * hits / accesses if accesses else 0.0,
        "compulsory": grab(RE_COMPULSORY) or 0,
        "capacity": grab(RE_CAPACITY) or 0,
        "conflict": grab(RE_CONFLICT) or 0,
        "total_bits": int(space.group(1)),
        "total_bytes": int(space.group(2)),
        "elapsed_ms": grab(RE_ELAPSED),
        "unreliable": bool(RE_UNRELIABLE.search(text)),
    }


# ========== 并行执行 ==========

class Runner:
    """按并发度跑一批组合。中断时连子进程组一起收掉，不留孤儿 bzcat。"""

    def __init__(self, jobs, timeout):
        self.jobs = jobs
        self.timeout = timeout
        self.lock = threading.Lock()
        self.procs = {}          # tag -> Popen，中断时拿来 kill
        self.cancelled = False

    def cancel(self):
        with self.lock:
            self.cancelled = True
            procs = list(self.procs.values())
        for proc in procs:
            _kill_group(proc)

    def run_one(self, combo, cachesim, trace, raw_dir, reference):
        size, block, assoc, window = combo
        tag = combo_tag(size, block, assoc, window)

        cmd = [str(cachesim), "-i", str(trace),
               "-s", str(size), "-b", str(block), "-a", str(assoc), "-K", str(window)]
        if reference:
            cmd.append("-R")

        # encoding 必须显式给：text=True 只按 locale 解码，LC_ALL=C 时
        # Python 会按 ASCII 解，读到报告里的中文直接 UnicodeDecodeError。
        # start_new_session 让每个任务自成进程组：cachesim 内部还会 popen 一个
        # bzcat，只杀 cachesim 会把 bzcat 留成孤儿，杀进程组才收得干净。
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True, encoding="utf-8", errors="replace",
                                start_new_session=True)
        with self.lock:
            if self.cancelled:
                _kill_group(proc)
                return combo, None, "已取消"
            self.procs[tag] = proc

        try:
            # 必须用 communicate：先 wait 再读管道，输出一超过管道缓冲就会死锁
            out, err = proc.communicate(timeout=self.timeout)
        except subprocess.TimeoutExpired:
            _kill_group(proc)
            out, err = proc.communicate()
            err = "超过 %d 秒仍未结束，已终止" % self.timeout
        finally:
            with self.lock:
                self.procs.pop(tag, None)

        (raw_dir / (tag + ".txt")).write_text(
            out + ("\n--- stderr ---\n" + err if err.strip() else ""), encoding="utf-8")

        if proc.returncode != 0:
            first = [ln for ln in err.strip().splitlines() if ln.strip()]
            return combo, None, first[0] if first else ("退出码 %d" % proc.returncode)

        parsed = parse_report(out)
        if parsed is None:
            return combo, None, "输出里找不到预期字段（见 raw/%s.txt）" % tag
        return combo, parsed, None


def _kill_group(proc):
    try:
        os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
        pass


# ========== 结果表格 ==========

def display_width(s):
    """按终端显示宽度算：CJK 字符占两列。C 的 %-9s 数的是字节，中文表头
    在终端里本来就是对不齐的，这里按显示宽度补，表格才是齐的。"""
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in s)


def pad(s, width, align="<"):
    s = str(s)
    fill = " " * max(0, width - display_width(s))
    return fill + s if align == ">" else s + fill


# 「占用B」放在配置列之后、命中率之前：它是这个配置的硬件代价，紧挨着收益看最直观。
COLUMNS = [
    ("容量", 9, "<"), ("块大小", 8, "<"), ("相联度", 7, "<"), ("窗口", 7, "<"),
    ("占用B", 9, ">"), ("命中率", 9, ">"), ("缺失数", 9, ">"), ("Compulsory", 11, ">"),
    ("Capacity", 10, ">"), ("Conflict", 10, ">"), ("耗时ms", 8, ">"),
]


def render_table(rows):
    lines = []
    header = " ".join(pad(name, w, a) for name, w, a in COLUMNS)
    lines.append(header)
    lines.append("-" * display_width(header))
    for r in rows:
        values = ["%d" % r["size"], "%d" % r["block"], "%d" % r["assoc"], "%d" % r["window"],
                  "%d" % r["total_bytes"],
                  "%.2f%%" % r["hit_rate"], "%d" % r["misses"],
                  "%d" % r["compulsory"], "%d" % r["capacity"], "%d" % r["conflict"],
                  "%d" % (r["elapsed_ms"] or 0)]
        lines.append(" ".join(pad(v, w, a) for v, (_, w, a) in zip(values, COLUMNS)))
    return "\n".join(lines)


CSV_HEADER = ["容量", "块大小", "相联度", "窗口", "占用bit", "占用B", "取指次数", "命中数",
              "命中率(%)", "缺失数", "Compulsory", "Capacity", "Conflict", "耗时ms", "基准可信"]


def write_csv(path, rows):
    # utf-8-sig：带 BOM，Excel 直接双击打开才不乱码
    with open(path, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(CSV_HEADER)
        for r in rows:
            w.writerow([r["size"], r["block"], r["assoc"], r["window"],
                        r["total_bits"], r["total_bytes"],
                        r["accesses"], r["hits"], "%.4f" % r["hit_rate"], r["misses"],
                        r["compulsory"], r["capacity"], r["conflict"],
                        r["elapsed_ms"] if r["elapsed_ms"] is not None else "",
                        "否" if r["unreliable"] else "是"])


# ========== 前置检查 ==========

def check_preconditions(cachesim, trace):
    """开跑前把必然失败的情况拦掉。cachesim 自己对坏 trace 的诊断要等
    bzcat 流水线跑完才报（cachesim.cpp:315-318），也就是白烧 10 秒。"""
    if not cachesim.is_file() or not os.access(cachesim, os.X_OK):
        print("找不到可执行的 cachesim: %s\n先在 %s 下执行 make" % (cachesim, SCRIPT_DIR),
              file=sys.stderr)
        return False

    if not trace.is_file():
        print("找不到 trace 文件: %s" % trace, file=sys.stderr)
        return False

    if "'" in str(trace):
        # cachesim 用 popen("bzcat '" + path + "'") 拼命令，单引号会破坏配对
        print("trace 路径里有单引号，cachesim 的 bzcat 命令行拼不出来: %s" % trace,
              file=sys.stderr)
        return False

    with open(trace, "rb") as f:
        if f.read(3) != b"BZh":
            print("%s 不是 bzip2 文件（cachesim 只接受 bz2 压缩的 pctrace）" % trace,
                  file=sys.stderr)
            return False

    if shutil.which("bzcat") is None:
        print("找不到 bzcat，请先安装 bzip2", file=sys.stderr)
        return False

    return True


# ========== 主流程 ==========

def build_parser():
    p = argparse.ArgumentParser(
        description="多核并行扫 cachesim 的参数组合",
        formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("-i", "--trace", default=str(DEFAULT_TRACE),
                   help="bz2 压缩的 pctrace 文件（默认 %(default)s）")
    p.add_argument("-s", "--size", default=DEFAULT_SIZES, metavar="LIST",
                   help="容量列表，见下（默认 %(default)s）")
    p.add_argument("-b", "--block", default=DEFAULT_BLOCKS, metavar="LIST",
                   help="块大小列表（默认 %(default)s）")
    p.add_argument("-a", "--assoc", default=DEFAULT_ASSOCS, metavar="LIST",
                   help="相联度列表（默认 %(default)s）")
    p.add_argument("-K", "--window", default=DEFAULT_WINDOWS, metavar="LIST",
                   help="近似 OPT 前瞻窗口列表，0 表示退回纯 LRU（默认 %(default)s）")
    p.add_argument("-j", "--jobs", type=int, default=os.cpu_count() or 1,
                   help="并发进程数（默认 CPU 核数 %(default)s）")
    p.add_argument("-o", "--outdir", default=None,
                   help="结果输出目录（默认 %s/<时间戳>）" % DEFAULT_OUTBASE)
    p.add_argument("--cachesim", default=os.environ.get("CACHESIM", str(DEFAULT_CACHESIM)),
                   help="cachesim 可执行文件（默认 %(default)s，也可用 CACHESIM 环境变量）")
    p.add_argument("-R", "--reference", action="store_true",
                   help="给每个组合带上两倍窗口的参照基准（每个组合慢近一倍）")
    p.add_argument("--timeout", type=int, default=1800,
                   help="单个组合的超时秒数（默认 %(default)s）")
    p.add_argument("-n", "--dry-run", action="store_true",
                   help="只打印网格和每个组合的命令行，不真跑")
    p.add_argument("-t", "--table-only", action="store_true",
                   help="stdout 只打那张表，不打结论和汇总（便于和串行 -S 对拍）")
    p.add_argument("-q", "--quiet", action="store_true", help="不打印逐个组合的进度")

    p.epilog = __doc__ + """
取值列表语法（--size/--block/--assoc/--window 通用，逗号分隔，可混写）：
    512            单个值
    512:16384      等比闭区间，公比 2（起止都必须是 2 的幂）
    512:16384:6    等比闭区间，指定个数
    512,2K,4K      直接列出
--size/--block 支持 4K/1M 后缀；--assoc/--window 只接受十进制。
"""
    return p


def main():
    args = build_parser().parse_args()

    cachesim = Path(args.cachesim).resolve()
    trace = Path(args.trace).resolve()
    if not check_preconditions(cachesim, trace):
        return 2

    try:
        sizes = parse_dimension(args.size, parse_size, "容量")
        blocks = parse_dimension(args.block, parse_size, "块大小")
        assocs = parse_dimension(args.assoc, lambda s: parse_plain_int(s, "相联度"), "相联度")
        windows = parse_dimension(args.window, lambda s: parse_plain_int(s, "前瞻窗口"), "前瞻窗口")
    except ValueError as e:
        print("取值列表解析失败: %s" % e, file=sys.stderr)
        return 2

    # 先剔掉非法组合，免得白起一堆必然失败的子进程
    combos, skipped = [], []
    for size in sizes:
        for block in blocks:
            for assoc in assocs:
                reason = config_invalid_reason(size, block, assoc)
                if reason:
                    skipped.append((size, block, assoc, reason))
                    continue
                for window in windows:
                    combos.append((size, block, assoc, window))

    if not combos:
        print("没有任何合法组合，检查 --size/--block/--assoc 的取值范围", file=sys.stderr)
        return 2

    print("trace : %s" % trace)
    print("网格  : %d 容量 × %d 块大小 × %d 相联度 × %d 窗口 = %d 个组合"
          % (len(sizes), len(blocks), len(assocs), len(windows), len(combos)))
    if skipped:
        # 按原因归并，别逐条刷屏
        by_reason = {}
        for s, b, a, reason in skipped:
            by_reason.setdefault(reason, []).append((s, b, a))
        print("        已剔除 %d 个非法组合:" % len(skipped))
        for reason, items in by_reason.items():
            s, b, a = items[0]
            print("          %s: %d 个（如 容量%d 块%d %d路）"
                  % (reason, len(items), s, b, a))

    # -K 只喂给全相联基准（cachesim.cpp:222-224 里 sim.access(pc) 从不传前瞻），
    # 命中率和缺失数跟它无关，所以拿它去乘一个大网格是纯浪费。
    if len(windows) > 1 and len(sizes) * len(blocks) * len(assocs) > 8:
        print("提示  : 扫窗口不会改变命中率和缺失数（它只影响 3C 的划分），"
              "建议固定 cache 配置单独扫 -K", file=sys.stderr)

    if args.dry_run:
        print("\n(这是 --dry-run，不执行)\n")
        for size, block, assoc, window in combos:
            print("  %s -i %s -s %d -b %d -a %d -K %d%s"
                  % (cachesim, trace, size, block, assoc, window,
                     " -R" if args.reference else ""))
        print("\n共 %d 个组合，并发 %d" % (len(combos), args.jobs))
        return 0

    if args.outdir:
        outdir = Path(args.outdir).resolve()
    else:
        outdir = DEFAULT_OUTBASE / time.strftime("%Y%m%d-%H%M%S")
    raw_dir = outdir / "raw"
    raw_dir.mkdir(parents=True, exist_ok=True)

    print("并发  : %d 个进程" % args.jobs)
    print("输出  : %s" % outdir)
    print()

    runner = Runner(args.jobs, args.timeout)
    rows, failures = [], []
    done = 0
    started = time.time()

    def report(combo, parsed, err):
        nonlocal done
        done += 1
        size, block, assoc, window = combo
        if err:
            failures.append((combo, err))
            print("[%3d/%3d] 容量%-6d 块%-4d 相联%-2d 窗口%-5d 失败: %s"
                  % (done, len(combos), size, block, assoc, window, err), file=sys.stderr)
            return
        parsed.update(size=size, block=block, assoc=assoc, window=window)
        rows.append(parsed)
        if not args.quiet:
            print("[%3d/%3d] 容量%-6d 块%-4d 相联%-2d 窗口%-5d 命中率%7.2f%%  缺失%-12d %s ms"
                  % (done, len(combos), size, block, assoc, window,
                     parsed["hit_rate"], parsed["misses"], parsed["elapsed_ms"]))

    try:
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            futures = [pool.submit(runner.run_one, c, cachesim, trace, raw_dir,
                                   args.reference) for c in combos]
            for fut in futures:
                report(*fut.result())
    except KeyboardInterrupt:
        print("\n中断，正在收掉子进程…", file=sys.stderr)
        runner.cancel()
        if rows:
            rows.sort(key=lambda r: (r["size"], r["block"], r["assoc"], r["window"]))
            write_csv(outdir / "summary.csv", rows)
            print("已完成的 %d 个组合写入 %s" % (len(rows), outdir / "summary.csv"),
                  file=sys.stderr)
        return 130

    elapsed = time.time() - started
    rows.sort(key=lambda r: (r["size"], r["block"], r["assoc"], r["window"]))

    if rows:
        print()
        print(render_table(rows))

        if not args.table_only:
            best = min(rows, key=lambda r: (r["misses"], r["size"], r["block"]))
            print("\n缺失最少: 容量 %d 块大小 %d 相联度 %d 窗口 %d —— 缺失 %d 次，命中率 %.2f%%"
                  % (best["size"], best["block"], best["assoc"], best["window"],
                     best["misses"], best["hit_rate"]))
            if best["unreliable"]:
                print("        该组合的全相联基准缺失反而更多，基准不可信，"
                      "Conflict 已按 0 处理，建议加大 -K 复核")

            unreliable = [r for r in rows if r["unreliable"]]
            if unreliable:
                print("注意: 有 %d 个组合的全相联基准缺失数反而更大，"
                      "这些行的冲突项已按 0 处理" % len(unreliable))

            csv_path = outdir / "summary.csv"
            write_csv(csv_path, rows)
            print("汇总表: %s" % csv_path)

    if failures:
        print("\n有 %d 个组合失败：" % len(failures), file=sys.stderr)
        for combo, err in failures:
            print("  容量%d 块%d 相联%d 窗口%d: %s" % (combo + (err,)), file=sys.stderr)
        print("完整输出在 %s" % raw_dir, file=sys.stderr)

    if not args.table_only:
        print("\n总耗时 %.1f 秒（%d 个组合，并发 %d）" % (elapsed, len(combos), args.jobs))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
