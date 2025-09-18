## 2025/05/20
## chapt GPTに作ってもらった。

from Bio import SeqIO
import os
from datetime import datetime

# 除外リストの読み込み（前方一致用）
with open("temp/HOMD_16S_dropped_header.txt") as f:
    exclude_prefixes = [line.strip() for line in f if line.strip()]

# 入力ファイル
input_file = "downloaded/HOMD_16S_rRNA_RefSeq_V16.01_full.fasta"

# 出力ファイル名の自動生成（カレントディレクトリに出力）
input_basename = os.path.basename(input_file)
name, ext = os.path.splitext(input_basename)
output_file = f"{name}_filtered{ext}"

# ログファイル名（タイムスタンプ付き）
log_file = f"{name}_filter_log_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"

# フィルタ処理
total_count = 0
excluded_count = 0
filtered_records = []
excluded_ids = []

for record in SeqIO.parse(input_file, "fasta"):
    total_count += 1
    if any(record.id.startswith(prefix) for prefix in exclude_prefixes):
        excluded_count += 1
        excluded_ids.append(record.id)
    else:
        filtered_records.append(record)

# 出力
SeqIO.write(filtered_records, output_file, "fasta")

# ログ内容
log_lines = [
    f"Input file: {input_file}",
    f"Output file: {output_file}",
    f"Date/time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
    f"Total sequences in input: {total_count}",
    f"Sequences excluded: {excluded_count}",
    f"Sequences kept: {len(filtered_records)}",
    "",
    "=== Excluded Sequence IDs ===",
] + excluded_ids

# ログ保存
with open(log_file, "w") as logf:
    logf.write("\n".join(log_lines))

# コンソール出力（件数のみ）
print("\n".join(log_lines[:6]))
print(f"Log saved to {log_file}")
