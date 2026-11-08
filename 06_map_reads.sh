#!/usr/bin/env bash
set -euo pipefail

# Run from the project directory containing raw_reads/.
# Activate an environment containing the required tools before running.
# Generated from the documented training commands; not an executed rerun.

command -v minimap2 >/dev/null || { echo "Required tool unavailable: minimap2" >&2; exit 1; }
command -v samtools >/dev/null || { echo "Required tool unavailable: samtools" >&2; exit 1; }
[[ -s "flye_assembly_trimmed/assembly.fasta" ]] || { echo "Missing or empty input: flye_assembly_trimmed/assembly.fasta" >&2; exit 1; }
[[ -s "raw_reads/SRR41146856.fastq" ]] || { echo "Missing or empty input: raw_reads/SRR41146856.fastq" >&2; exit 1; }
[[ ! -e "read_mapping/reads_vs_flye.sorted.bam" ]] || { echo "Output already exists: read_mapping/reads_vs_flye.sorted.bam. Use a separate run folder." >&2; exit 1; }

mkdir -p read_mapping
set -o pipefail

minimap2 -ax lr:hq -t 2 \
  flye_assembly_trimmed/assembly.fasta \
  raw_reads/SRR41146856.fastq \
  2> read_mapping/minimap2.log \
  | samtools sort -m 1G \
      -o read_mapping/reads_vs_flye.sorted.bam -

samtools quickcheck -v read_mapping/reads_vs_flye.sorted.bam
samtools index read_mapping/reads_vs_flye.sorted.bam

samtools flagstat read_mapping/reads_vs_flye.sorted.bam \
  > read_mapping/mapping_summary.txt

samtools coverage read_mapping/reads_vs_flye.sorted.bam \
  > read_mapping/coverage_per_contig.tsv

cat read_mapping/mapping_summary.txt
cat read_mapping/coverage_per_contig.tsv
