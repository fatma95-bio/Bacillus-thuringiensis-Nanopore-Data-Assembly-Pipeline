#!/usr/bin/env bash
set -euo pipefail

# Run from the project directory containing raw_reads/.
# Activate an environment containing the required tools before running.
# Generated from the documented training commands; not an executed rerun.

command -v flye >/dev/null || { echo "Required tool unavailable: flye" >&2; exit 1; }
[[ -s "dorado_trimming/SRR41146856_adapter_trimmed.fastq" ]] || { echo "Missing or empty input: dorado_trimming/SRR41146856_adapter_trimmed.fastq" >&2; exit 1; }
[[ ! -e "flye_assembly_trimmed" ]] || { echo "Output already exists: flye_assembly_trimmed. Use a separate run folder." >&2; exit 1; }

flye \
  --nano-hq dorado_trimming/SRR41146856_adapter_trimmed.fastq \
  --threads 2 \
  --out-dir flye_assembly_trimmed

cat flye_assembly_trimmed/assembly_info.txt
