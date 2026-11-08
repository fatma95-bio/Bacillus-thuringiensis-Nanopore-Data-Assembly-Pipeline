#!/usr/bin/env bash
set -euo pipefail

# Run from the project directory containing raw_reads/.
# Activate an environment containing the required tools before running.
# Generated from the documented training commands; not an executed rerun.

command -v wget >/dev/null || { echo "Required tool unavailable: wget" >&2; exit 1; }
command -v fasterq-dump >/dev/null || { echo "Required tool unavailable: fasterq-dump" >&2; exit 1; }
# Alternative archive route, not the original FASTQ.gz download.
# Run this script from the parent of the project folder.
[[ ! -e Nanopore_BT_strain_W22_training/raw_reads/SRR41146856 ]] || {
  echo "Archive folder already exists. Inspect existing data before repeating." >&2
  exit 1
}
[[ ! -e Nanopore_BT_strain_W22_training/raw_reads/SRR41146856.fastq ]] || {
  echo "FASTQ already exists. No new download is needed." >&2
  exit 1
}

mkdir -p Nanopore_BT_strain_W22_training
cd Nanopore_BT_strain_W22_training

mkdir -p raw_reads/SRR41146856

wget \
  https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR41146856/SRR41146856 \
  -O raw_reads/SRR41146856/SRR41146856.sra

fasterq-dump raw_reads/SRR41146856 \
  --threads 2 \
  --outdir raw_reads

ls -lh raw_reads/SRR41146856.fastq
head -n 4 raw_reads/SRR41146856.fastq
