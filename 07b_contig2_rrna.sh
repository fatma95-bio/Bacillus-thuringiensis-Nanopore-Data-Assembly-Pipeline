#!/usr/bin/env bash
set -euo pipefail

# Run from the project directory containing raw_reads/ and read_mapping/.
# Activate the appropriate tool environment first.
command -v barrnap >/dev/null || { echo "Required tool unavailable: barrnap" >&2; exit 1; }
[[ -s contig2_verification/contig_2.fasta ]] || { echo "Run contig 2 extraction first" >&2; exit 1; }
[[ ! -e contig2_verification/rrna_predictions.gff ]] || { echo "rRNA output already exists" >&2; exit 1; }
barrnap --kingdom bac --threads 2 \
  contig2_verification/contig_2.fasta \
  > contig2_verification/rrna_predictions.gff \
  2> contig2_verification/barrnap.log

cat contig2_verification/rrna_predictions.gff

