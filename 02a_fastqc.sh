#!/usr/bin/env bash
set -euo pipefail

# Run from the project directory containing raw_reads/.
# Activate an environment containing the required tools before running.
# Generated from the documented training commands; not an executed rerun.

command -v fastqc >/dev/null || { echo "Required tool unavailable: fastqc" >&2; exit 1; }
[[ -s "raw_reads/SRR41146856.fastq" ]] || { echo "Missing or empty input: raw_reads/SRR41146856.fastq" >&2; exit 1; }
[[ ! -e "FastQC_results" ]] || { echo "Output already exists: FastQC_results. Use a separate run folder." >&2; exit 1; }

mkdir -p FastQC_results

fastqc raw_reads/SRR41146856.fastq \
  --outdir FastQC_results \
  --memory 4096 \
  --threads 1
