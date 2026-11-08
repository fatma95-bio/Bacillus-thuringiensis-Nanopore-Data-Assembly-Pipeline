#!/usr/bin/env bash
set -euo pipefail

# Run from the project directory containing raw_reads/.
# Activate an environment containing the required tools before running.
# Generated from the documented training commands; not an executed rerun.

command -v NanoPlot >/dev/null || { echo "Required tool unavailable: NanoPlot" >&2; exit 1; }
[[ -s "raw_reads/SRR41146856.fastq" ]] || { echo "Missing or empty input: raw_reads/SRR41146856.fastq" >&2; exit 1; }
[[ ! -e "NanoPlot_raw" ]] || { echo "Output already exists: NanoPlot_raw. Use a separate run folder." >&2; exit 1; }

NanoPlot \
  --fastq raw_reads/SRR41146856.fastq \
  --threads 2 \
  --outdir NanoPlot_raw

cat NanoPlot_raw/NanoStats.txt
