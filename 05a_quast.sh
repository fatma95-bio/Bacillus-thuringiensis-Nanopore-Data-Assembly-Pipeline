#!/usr/bin/env bash
set -euo pipefail

# Run from the project directory containing raw_reads/.
# Activate an environment containing the required tools before running.
# Generated from the documented training commands; not an executed rerun.

command -v quast >/dev/null || { echo "Required tool unavailable: quast" >&2; exit 1; }
[[ -s "flye_assembly_trimmed/assembly.fasta" ]] || { echo "Missing or empty input: flye_assembly_trimmed/assembly.fasta" >&2; exit 1; }
[[ ! -e "quast_flye_results" ]] || { echo "Output already exists: quast_flye_results. Use a separate run folder." >&2; exit 1; }

quast flye_assembly_trimmed/assembly.fasta \
  -t 2 \
  -o quast_flye_results

cat quast_flye_results/report.txt
