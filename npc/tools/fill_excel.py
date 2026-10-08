#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
把 sim.cpp 写的 build/perf_table.csv 复制进 Excel 的 "NPC性能评估结果" 表。

表格是两行等长的 CSV：第一行是字段名，第二行是对应的值。
字段按位置搬过去，遇到模板独有的列（见 TEMPLATE_ONLY_COLS）则跳过，不做其他解析映射。

A(commit)、B(说明)、F(综合频率)、G(综合面积)、H(IPS) 仿真产不出来，sim.cpp 会占
空位，搬过来就是空的，填不填由你自己决定。

用法: python3 fill_excel.py <perf_table.csv> [excel_file]

注意：脚本不写 A(commit) / B(说明)，选行靠「A 列为『当前commit』的行」，
      没有该标记才退回第一个 A 列为空的行，所以连着跑两次会覆盖同一行。
"""

import csv
import sys
import os
from openpyxl import load_workbook

# 模板里有、CSV 里没有的字段（第一行的表头文本），写到这些列上时要跳过去
TEMPLATE_ONLY_COLS = {'IPS'}


def to_num(s):
    """能当数字就当数字写，别让整列变成文本；空串原样返回"""
    for cast in (int, float):
        try:
            return cast(s)
        except ValueError:
            pass
    return s


def main():
    if len(sys.argv) < 2:
        print("用法: python3 fill_excel.py <perf_table.csv> [excel_file]")
        sys.exit(1)

    table_file = sys.argv[1]
    excel_file = sys.argv[2] if len(sys.argv) > 2 else 'NPC性能评估结果.xlsx'

    if not os.path.isfile(table_file):
        print(f"错误: 找不到 {table_file}，先跑一次仿真（make sim）生成它", file=sys.stderr)
        sys.exit(1)

    with open(table_file, 'r', encoding='utf-8') as f:
        rows = list(csv.reader(f))

    if len(rows) < 2 or len(rows[0]) != len(rows[1]):
        print(f"错误: {table_file} 不是两行等长的性能表格", file=sys.stderr)
        sys.exit(1)

    values = rows[1]

    wb = load_workbook(excel_file)
    ws = wb['NPC性能评估结果']

    # 目标行：A 列为「当前commit」的行；没有标记才退回第一个 A 列为空的行
    row = None
    for r in range(1, ws.max_row + 1):
        if ws.cell(row=r, column=1).value == '当前commit':
            row = r
            break
    if row is None:
        row = 4
        while ws.cell(row=row, column=1).value is not None:
            row += 1

    # 模板独有的列（如 IPS）在 CSV 里没有对应字段，落点要跳过它们才能和表头对齐
    skip_cols = {c for c in range(1, ws.max_column + 1)
                 if ws.cell(row=1, column=c).value in TEMPLATE_ONLY_COLS}
    if len(values) + len(skip_cols) != ws.max_column:
        print(f"警告: CSV {len(values)} 列 + 模板独有列 {len(skip_cols)} 列 "
              f"与表格 {ws.max_column} 列对不上，检查模板或 TEMPLATE_ONLY_COLS", file=sys.stderr)

    for i, v in enumerate(values):
        if v == '':
            continue
        col = i + 1 + sum(1 for c in skip_cols if c <= i + 1)
        ws.cell(row=row, column=col, value=to_num(v))

    wb.save(excel_file)
    print(f"{len(values)} 列已写入第 {row} 行，保存至 {excel_file}")


if __name__ == '__main__':
    main()
