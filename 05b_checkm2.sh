#!/usr/bin/env bash
set -euo pipefail

# Run from the project directory containing raw_reads/.
# Activate an environment containing the required tools before running.
# Generated from the documented training commands; not an executed rerun.

command -v checkm2 >/dev/null || { echo "Required tool unavailable: checkm2" >&2; exit 1; }
[[ -s "flye_assembly_trimmed/assembly.fasta" ]] || { echo "Missing or empty input: flye_assembly_trimmed/assembly.fasta" >&2; exit 1; }
[[ ! -e "checkm2_flye_results" ]] || { echo "Output already exists: checkm2_flye_results. Use a separate run folder." >&2; exit 1; }

checkm2 predict \
  --threads 2 \
  --input flye_assembly_trimmed/assembly.fasta \
  --output-directory checkm2_flye_results

cat checkm2_flye_results/quality_report.tsv
