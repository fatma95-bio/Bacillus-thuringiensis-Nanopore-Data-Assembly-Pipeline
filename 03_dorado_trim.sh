#!/usr/bin/env bash
set -euo pipefail

# Run from the project directory containing raw_reads/.
# Activate an environment containing the required tools before running.
# Generated from the documented training commands; not an executed rerun.

command -v dorado >/dev/null || { echo "Required tool unavailable: dorado" >&2; exit 1; }
[[ -s "raw_reads/SRR41146856.fastq" ]] || { echo "Missing or empty input: raw_reads/SRR41146856.fastq" >&2; exit 1; }
[[ ! -e "dorado_trimming/SRR41146856_adapter_trimmed.fastq" ]] || { echo "Output already exists: dorado_trimming/SRR41146856_adapter_trimmed.fastq. Use a separate run folder." >&2; exit 1; }
mkdir -p dorado_trimming

dorado trim \
  --sequencing-kit SQK-RBK114-96 \
  --no-trim-primers \
  --threads 2 \
  --emit-fastq \
  raw_reads/SRR41146856.fastq \
  > dorado_trimming/SRR41146856_adapter_trimmed.fastq \
  2> dorado_trimming/full_trimming.log

cat dorado_trimming/full_trimming.log
