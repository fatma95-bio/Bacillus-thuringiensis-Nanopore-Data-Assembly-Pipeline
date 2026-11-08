#!/usr/bin/env bash
set -euo pipefail

# Run from the project directory containing flye_assembly_trimmed/.
# Activate the appropriate tool environment first.
command -v samtools >/dev/null || { echo "Required tool unavailable: samtools" >&2; exit 1; }
command -v blastn >/dev/null || { echo "Required tool unavailable: blastn" >&2; exit 1; }
[[ -s flye_assembly_trimmed/assembly.fasta ]] || { echo "Missing assembly" >&2; exit 1; }
[[ ! -e contig2_verification ]] || { echo "Check existing contig2_verification outputs before repeating" >&2; exit 1; }

mkdir -p contig2_verification

samtools faidx flye_assembly_trimmed/assembly.fasta

samtools faidx flye_assembly_trimmed/assembly.fasta contig_2 \
  > contig2_verification/contig_2.fasta

samtools faidx flye_assembly_trimmed/assembly.fasta \
  contig_1 contig_3 contig_4 contig_5 contig_6 \
  > contig2_verification/other_contigs.fasta



blastn \
  -query contig2_verification/contig_2.fasta \
  -subject contig2_verification/other_contigs.fasta \
  -task blastn \
  -outfmt "7 qseqid sseqid pident length qlen qstart qend sstart send evalue bitscore" \
  -out contig2_verification/contig2_vs_other_contigs.tsv

cat contig2_verification/contig2_vs_other_contigs.tsv

