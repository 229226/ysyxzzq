#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
自动解析 sim 输出并填入 Excel 的 "NPC性能评估结果" 表。
用法: python fill_excel.py <sim_output_file> [excel_file] [--debug]
环境变量: FREQ, AREA 可预设频率和面积
"""

import re
import sys
import os
from openpyxl import load_workbook

# ---------- 列映射（与您修改的一致） ----------
COLUMN_MAP = {
    'sim_cycles': 'C',
    'instr_count': 'D',
    'ipc': 'E',
    'freq': 'F',
    'area': 'G',

    'ifu_fetch_count': 'H',
    'ifu_wait_start_cyc': 'I',
    'ifu_wait_start_pct': 'J',
    'ifu_wait_mem_cyc': 'K',
    'ifu_wait_mem_pct': 'L',
    'ifu_update_output_cyc': 'M',
    'ifu_update_output_pct': 'N',
    'ifu_wait_idu_cyc': 'O',
    'ifu_wait_idu_pct': 'P',
    'ifu_total_cyc': 'Q',

    'idu_decode_count': 'R',
    'idu_wait_ifu_cyc': 'S',
    'idu_wait_ifu_pct': 'T',
    'idu_update_output_cyc': 'U',
    'idu_update_output_pct': 'V',
    'idu_wait_exu_cyc': 'W',
    'idu_wait_exu_pct': 'X',
    'idu_total_cyc': 'Y',

    'exu_calc_count': 'Z',
    'exu_wait_idu_cyc': 'AA',
    'exu_wait_idu_pct': 'AB',
    'exu_update_output_cyc': 'AC',
    'exu_update_output_pct': 'AD',
    'exu_wait_lsu_cyc': 'AE',
    'exu_wait_lsu_pct': 'AF',
    'exu_total_cyc': 'AG',

    'lsu_read_count': 'AH',
    'lsu_write_count': 'AI',
    'lsu_wait_exu_cyc': 'AJ',
    'lsu_wait_exu_pct': 'AK',
    'lsu_wait_read_cyc': 'AL',
    'lsu_wait_read_pct': 'AM',
    'lsu_update_output_r_cyc': 'AN',
    'lsu_update_output_r_pct': 'AO',
    'lsu_wait_write_cyc': 'AP',
    'lsu_wait_write_pct': 'AQ',
    'lsu_update_output_w_cyc': 'AR',
    'lsu_update_output_w_pct': 'AS',
    'lsu_wait_wbu_cyc': 'AT',
    'lsu_wait_wbu_pct': 'AU',
    'lsu_total_cyc': 'AV',

    'wbu_write_count': 'AW',
    'wbu_wait_lsu_cyc': 'AX',
    'wbu_wait_lsu_pct': 'AY',
    'wbu_write_reg_cyc': 'AZ',
    'wbu_write_reg_pct': 'BA',
    'wbu_total_cyc': 'BB',

    'idu_U': 'BC',
    'idu_J': 'BD',
    'idu_I': 'BE',
    'idu_Ical': 'BF',
    'idu_B': 'BG',
    'idu_Rcal': 'BH',
    'idu_LOAD': 'BI',
    'idu_STORE': 'BJ',
    'idu_CSR': 'BK',

    'total_ins_cyc': 'BL',
    'u_cyc': 'BM',
    'u_pct': 'BN',
    'u_avg': 'BO',
    'j_cyc': 'BP', 
    'j_pct': 'BQ',
    'j_avg': 'BR',
    'i_cyc': 'BS', 
    'i_pct': 'BT',
    'i_avg': 'BU',
    'ical_cyc': 'BV', 
    'ical_pct': 'BW',
    'ical_avg': 'BX',
    'b_cyc': 'BY', 
    'b_pct': 'BZ',
    'b_avg': 'CA',
    'rcal_cyc': 'CB', 
    'rcal_pct': 'CC',
    'rcal_avg': 'CD',
    'load_cyc': 'CE', 
    'load_pct': 'CF',
    'load_avg': 'CG',
    'store_cyc': 'CH', 
    'store_pct': 'CI',
    'store_avg': 'CJ',
    'csr_cyc': 'CK', 
    'csr_pct': 'CL',
    'csr_avg': 'CM',
    'other_cyc': 'CN', 
    'other_pct': 'CO',
    'other_avg': 'CP',

    'lsu_read_avg': 'CQ',
    'lsu_write_avg': 'CR',
}

# ---------- 辅助函数：解析带有周期/百分比/平均的行 ----------
def parse_stat_line(line):
    """
    解析形如 "U-type (lui/auipc)           : 481050  (1.19%)  平均: 51.75"
    返回 (类型标识, 周期数, 百分比, 平均值) 或 (None,None,None,None)
    """
    # 去掉首尾空白，但保留内部空格
    line = line.strip()
    if not line:
        return None, None, None, None

    # 匹配模式：类型部分 : 周期数 (百分比%) [可选 平均: 数值]
    # 类型部分可能包含括号，所以用 (.*?) 非贪婪匹配到第一个 :
    m = re.match(r'^(.*?)\s*:\s*(\d+)\s*\(([\d.]+)%\)\s*(?:平均:\s*([\d.]+))?', line)
    if m:
        type_label = m.group(1).strip()
        cyc = int(m.group(2))
        pct = float(m.group(3))
        avg = float(m.group(4)) if m.group(4) else None
        return type_label, cyc, pct, avg
    return None, None, None, None

# ---------- 解析核心函数 ----------
def parse_output(text, debug=False):
    data = {}

    # 1. 基础信息
    m = re.search(r'执行花费了(\d+)个时钟周期', text)
    if m:
        data['sim_cycles'] = int(m.group(1))
    elif debug:
        print("Warning: '仿真周期数' not found")

    m = re.search(r'执行了(\d+)条指令', text)
    if m:
        data['instr_count'] = int(m.group(1))
    elif debug:
        print("Warning: '指令数' not found")

    m = re.search(r'IPC为([\d.]+)', text)
    if m:
        data['ipc'] = float(m.group(1))
    elif debug:
        print("Warning: 'IPC' not found")

    # 2. IFU 模块
    ifu_section = re.search(r'ptrace:IFU 模块统计.*?\n(.*?)(?=\nptrace:|$)', text, re.DOTALL)
    if ifu_section:
        ifu_text = ifu_section.group(1)
        for name in ['IFU_wait_start', 'IFU_wait_mem', 'IFU_update_output', 'IFU_wait_IDU']:
            key = name.lower()
            pat = rf'{re.escape(name)}\s*:\s*(\d+)\s*\(([\d.]+)%\)'
            m = re.search(pat, ifu_text)
            if m:
                data[f'{key}_cyc'] = int(m.group(1))
                data[f'{key}_pct'] = float(m.group(2))
            elif debug:
                print(f"Warning: {name} not found in IFU section")
        # 取指次数 = IFU_update_output（用已有的）
        if 'ifu_update_output_cyc' in data:
            data['ifu_fetch_count'] = data['ifu_update_output_cyc']
        # 总工作周期
        m = re.search(r'总工作周期\s*(\d+)', ifu_text)
        if m:
            data['ifu_total_cyc'] = int(m.group(1))
        elif debug:
            print("Warning: IFU total cycles not found")
    else:
        print("Warning: IFU section not found")

    # 3. IDU 模块
    idu_section = re.search(r'ptrace:IDU 模块统计.*?\n(.*?)(?=\nptrace:|$)', text, re.DOTALL)
    if idu_section:
        idu_text = idu_section.group(1)
        for name in ['IDU_wait_IFU', 'IDU_update_output', 'IDU_wait_EXU']:
            key = name.lower()
            pat = rf'{re.escape(name)}\s*:\s*(\d+)\s*\(([\d.]+)%\)'
            m = re.search(pat, idu_text)
            if m:
                data[f'{key}_cyc'] = int(m.group(1))
                data[f'{key}_pct'] = float(m.group(2))
            elif debug:
                print(f"Warning: {name} not found in IDU section")
        if 'idu_update_output_cyc' in data:
            data['idu_decode_count'] = data['idu_update_output_cyc']
        m = re.search(r'总工作周期\s*(\d+)', idu_text)
        if m:
            data['idu_total_cyc'] = int(m.group(1))
        elif debug:
            print("Warning: IDU total cycles not found")
    else:
        print("Warning: IDU section not found")

    # 4. EXU 模块
    exu_section = re.search(r'ptrace:EXU 模块统计.*?\n(.*?)(?=\nptrace:|$)', text, re.DOTALL)
    if exu_section:
        exu_text = exu_section.group(1)
        for name in ['EXU_wait_IDU', 'EXU_update_output', 'EXU_wait_LSU']:
            key = name.lower()
            pat = rf'{re.escape(name)}\s*:\s*(\d+)\s*\(([\d.]+)%\)'
            m = re.search(pat, exu_text)
            if m:
                data[f'{key}_cyc'] = int(m.group(1))
                data[f'{key}_pct'] = float(m.group(2))
            elif debug:
                print(f"Warning: {name} not found in EXU section")
        if 'exu_update_output_cyc' in data:
            data['exu_calc_count'] = data['exu_update_output_cyc']
        m = re.search(r'总工作周期\s*(\d+)', exu_text)
        if m:
            data['exu_total_cyc'] = int(m.group(1))
        elif debug:
            print("Warning: EXU total cycles not found")
    else:
        print("Warning: EXU section not found")

    # 5. LSU 模块
    lsu_section = re.search(r'ptrace:LSU 模块统计.*?\n(.*?)(?=\nptrace:|$)', text, re.DOTALL)
    if lsu_section:
        lsu_text = lsu_section.group(1)
        for name in ['LSU_wait_EXU', 'LSU_wait_read', 'LSU_update_output_r',
                     'LSU_wait_write', 'LSU_update_output_w', 'LSU_wait_WBU']:
            key = name.lower()
            pat = rf'{re.escape(name)}\s*:\s*(\d+)\s*\(([\d.]+)%\)'
            m = re.search(pat, lsu_text)
            if m:
                data[f'{key}_cyc'] = int(m.group(1))
                data[f'{key}_pct'] = float(m.group(2))
            elif debug:
                print(f"Warning: {name} not found in LSU section")
        # 单独提取读/写次数
        m = re.search(r'LSU_update_output_r\s*:\s*(\d+)', lsu_text)
        if m:
            data['lsu_read_count'] = int(m.group(1))
        m = re.search(r'LSU_update_output_w\s*:\s*(\d+)', lsu_text)
        if m:
            data['lsu_write_count'] = int(m.group(1))
        m = re.search(r'总工作周期\s*(\d+)', lsu_text)
        if m:
            data['lsu_total_cyc'] = int(m.group(1))
        elif debug:
            print("Warning: LSU total cycles not found")
    else:
        print("Warning: LSU section not found")

    # 6. WBU 模块
    wbu_section = re.search(r'ptrace:WBU 模块统计.*?\n(.*?)(?=\nptrace:|$)', text, re.DOTALL)
    if wbu_section:
        wbu_text = wbu_section.group(1)
        for name in ['WBU_wait_LSU', 'WBU_write_reg']:
            key = name.lower()
            pat = rf'{re.escape(name)}\s*:\s*(\d+)\s*\(([\d.]+)%\)'
            m = re.search(pat, wbu_text)
            if m:
                data[f'{key}_cyc'] = int(m.group(1))
                data[f'{key}_pct'] = float(m.group(2))
            elif debug:
                print(f"Warning: {name} not found in WBU section")
        m = re.search(r'WBU_write_reg\s*:\s*(\d+)', wbu_text)
        if m:
            data['wbu_write_count'] = int(m.group(1))
        m = re.search(r'总工作周期\s*(\d+)', wbu_text)
        if m:
            data['wbu_total_cyc'] = int(m.group(1))
        elif debug:
            print("Warning: WBU total cycles not found")
    else:
        print("Warning: WBU section not found")

    # 7. IDU 指令类型统计 (数量)
    idu_type_section = re.search(r'ptrace:IDU指令类型统计.*?\n(.*?)(?=\nptrace:|$)', text, re.DOTALL)
    if idu_type_section:
        idu_type_text = idu_type_section.group(1)
        type_map = {
            'U-type': 'idu_U',
            'J-type': 'idu_J',
            'I-type': 'idu_I',
            'I-ALU': 'idu_Ical',
            'Branch': 'idu_B',
            'R-ALU': 'idu_Rcal',
            'Load': 'idu_LOAD',
            'Store': 'idu_STORE',
            'CSR': 'idu_CSR',
        }
        # 按行解析，更可靠
        for line in idu_type_text.splitlines():
            line = line.strip()
            if not line:
                continue
            for label, key in type_map.items():
                # 匹配标签开头，因为可能包含括号，但标签是固定的
                if line.startswith(label):
                    m = re.search(r':\s*(\d+)', line)
                    if m:
                        data[key] = int(m.group(1))
                    break
            # 如果已经全部找到，可以提前结束（可选）
    else:
        print("Warning: IDU type section not found")

    # 8. 指令完整周期统计（包含周期、百分比、平均）
    cycle_section = re.search(r'ptrace:指令完整周期统计.*?\n(.*?)(?=\nptrace:|$)', text, re.DOTALL)
    if cycle_section:
        cycle_text = cycle_section.group(1)
        # 定义类型映射（与列映射中的后缀对应）
        type_key_map = {
            'U-type': 'u',
            'J-type': 'j',
            'I-type': 'i',
            'I-ALU': 'ical',
            'Branch': 'b',
            'R-ALU': 'rcal',
            'Load': 'load',
            'Store': 'store',
            'CSR': 'csr',
            'Other': 'other',
        }
        # 按行解析
        for line in cycle_text.splitlines():
            line = line.strip()
            if not line:
                continue
            label, cyc, pct, avg = parse_stat_line(line)
            if label is None:
                continue
            # 尝试匹配类型
            matched_key = None
            for type_label, suffix in type_key_map.items():
                if line.startswith(type_label):
                    matched_key = suffix
                    break
            if matched_key is None:
                continue  # 未知类型跳过（如 Total）
            # 存入数据
            if cyc is not None:
                data[f'{matched_key}_cyc'] = cyc
            if pct is not None:
                data[f'{matched_key}_pct'] = pct
            if avg is not None:
                data[f'{matched_key}_avg'] = avg
        # 额外处理 Total（虽然不是列映射，但可以用于调试）
        total_line = next((l for l in cycle_text.splitlines() if l.strip().startswith('Total')), None)
        if total_line:
            _, cyc, pct, _ = parse_stat_line(total_line)
            if cyc is not None:
                data['total_ins_cyc'] = cyc
    else:
        print("Warning: cycle statistics section not found")

    # 9. LSU 平均延迟
    lsu_delay_section = re.search(r'ptrace:LSU访存延迟统计.*?\n(.*?)(?=\nptrace:|$)', text, re.DOTALL)
    if lsu_delay_section:
        delay_text = lsu_delay_section.group(1)
        m = re.search(r'Read\s*:.*?平均\s*([\d.]+)', delay_text)
        if m:
            data['lsu_read_avg'] = float(m.group(1))
        else:
            print("Warning: LSU read avg not found")
        m = re.search(r'Write\s*:.*?平均\s*([\d.]+)', delay_text)
        if m:
            data['lsu_write_avg'] = float(m.group(1))
        else:
            print("Warning: LSU write avg not found")
    else:
        print("Warning: LSU delay section not found")

    return data


# ---------- 写入 Excel ----------
def write_to_excel(excel_path, data, debug=False):
    wb = load_workbook(excel_path)
    ws = wb['NPC性能评估结果']

    # 找到第一个空行（从第4行开始）
    row = 4
    while ws.cell(row=row, column=1).value is not None:
        row += 1

    # 填入数据
    for field, col_letter in COLUMN_MAP.items():
        if field in data:
            ws[col_letter + str(row)] = data[field]
        elif debug:
            print(f"Warning: field '{field}' not in data, skipped")

    wb.save(excel_path)
    print(f"数据已追加到第 {row} 行，保存至 {excel_path}")


# ---------- 主程序 ----------
def main():
    if len(sys.argv) < 2:
        print("用法: python fill_excel.py <sim_output_file> [excel_file] [--debug]")
        sys.exit(1)

    sim_file = sys.argv[1]
    excel_file = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith('--') else 'NPC性能评估结果.xlsx'
    debug = '--debug' in sys.argv

    with open(sim_file, 'r', encoding='utf-8') as f:
        text = f.read()

    data = parse_output(text, debug)

    # 交互输入缺失的值
    if 'freq' not in data:
        freq = os.environ.get('FREQ', input("请输入综合频率 (MHz)，回车跳过: "))
        if freq.strip():
            data['freq'] = float(freq)
    if 'area' not in data:
        area = os.environ.get('AREA', input("请输入综合面积，回车跳过: "))
        if area.strip():
            data['area'] = area

    if debug:
        print("\n解析得到的数据:")
        for k, v in sorted(data.items()):
            print(f"  {k}: {v}")

    write_to_excel(excel_file, data, debug)


if __name__ == '__main__':
    main()