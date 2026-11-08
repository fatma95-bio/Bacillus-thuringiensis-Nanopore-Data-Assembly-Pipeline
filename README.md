# Nanopore Data Assembly and Quality Assessment Pipeline for Bacillus thuringiensis W-22

An educational workflow for quality control, adapter trimming, de novo genome assembly and assembly evaluation using public Oxford Nanopore reads.

This project documents my practical training in bacterial genome analysis. My contribution is the computational analysis, interpretation and workflow documentation. I did not isolate the strain or generate the sequencing data.

## Project overview

Long Nanopore reads can help reconstruct bacterial chromosomes and plasmid sequences, including regions that are difficult to resolve with short reads. Repeats and small contigs can nevertheless remain uncertain after assembly.

This repository presents a practical analysis of public reads from Bacillus thuringiensis strain W-22. It is a learning case study carried out on a Linux laptop, covering read quality assessment, adapter trimming, assembly and evaluation.

## Analysis question

What assembly can be reconstructed from these Nanopore reads, and how well do read mapping and genome quality estimates support the assembled contigs?

## Analysis workflow

**Public SRA data → FASTQ extraction → FastQC and NanoPlot → Dorado adapter trimming → Flye assembly → QUAST and CheckM2 → Read mapping → Contigs verification**

## Input data

| Item | Dataset |
|---|---|
| Organism | Bacillus thuringiensis |
| Strain | W-22 |
| SRA run | [SRR41146856](https://www.ncbi.nlm.nih.gov/sra/?term=SRR41146856) |
| Experiment | [SRX35661388](https://www.ncbi.nlm.nih.gov/sra/?term=SRX35661388) |
| BioProject | [PRJNA1539979](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA1539979/) |
| BioSample | [SAMN64006424](https://www.ncbi.nlm.nih.gov/biosample/SAMN64006424/) |
| Associated GenBank assembly | [GCA_062066590.1](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_062066590.1/) |
| Submitter listed in the dataset metadata | Jeonbuk National University |
| Platform | Oxford Nanopore PromethION |
| Flow cell | R10.4.1 |
| Library preparation | Rapid Barcoding Kit 96 V14 |
| Read layout | SINGLE |
| Number of reads | 168,347 |
| Total bases | 924,650,833 bp |

## Workflow overview

1. Download reads and prepare FASTQ.
2. Assess raw reads with FastQC and NanoPlot.
3. Trim adapters with Dorado.
4. Assemble the reads with Flye.
5. Evaluate the assembly with QUAST and CheckM2.
6. Map reads back to the assembly with Minimap2 and SAMtools.
7. Verify contig 2 using read support, local BLASTn and rRNA prediction.

## Software

Software must already be available. Installation instructions are outside the scope of this README.

| Tool | Version recorded during training | Purpose |
|---|---|---|
| FastQC | v0.13.0 | Initial read quality screening |
| NanoPlot | 1.48.0 | Long-read length, quality and yield summaries |
| Dorado | 2.1.2 | Adapter trimming |
| Flye | 2.9.6-b1802 | Long-read genome assembly |
| QUAST | 5.3.0 | Assembly statistics |
| CheckM2 | 1.1.0 | Estimated completeness and contamination |
| Minimap2 | 2.31-r1302 | Read mapping |
| SAMtools | 1.25 | BAM processing and coverage summaries |
| BLASTn | 2.16.0+ | DNA sequence comparisons |
| Barrnap | 1.10.5 | rRNA prediction |

Commands below are organized for reuse from one project directory. They use relative paths instead of a personal home-directory path. Activate the environment containing each tool before running it. Output folder names are kept consistent here; individual exploratory runs during training sometimes used other folder names.

Keep the original reads and assembly. These commands can create or overwrite output files, so do not repeat completed runs in the same folders without checking existing results.

## 1. Download reads and prepare FASTQ

**Script:** [Download and extract FASTQ](01_download_extract.sh). Run this optional script from the parent of the project directory.

The original training run started with a downloaded `SRR41146856.fastq.gz` file. The archive route below is an alternative way to obtain the reads, not a claim that it was the original download method.

### Download the SRA archive with wget

```bash
mkdir -p Nanopore_BT_strain_W22_training
cd Nanopore_BT_strain_W22_training

mkdir -p raw_reads/SRR41146856

wget \
  https://sra-pub-run-odp.s3.amazonaws.com/sra/SRR41146856/SRR41146856 \
  -O raw_reads/SRR41146856/SRR41146856.sra
```

`wget` downloads the archive; `-O` sets its local filename. The archive contains SRA data and is not a gzip-compressed FASTQ.

### Extract FASTQ with SRA Toolkit

```bash
fasterq-dump raw_reads/SRR41146856 \
  --threads 2 \
  --outdir raw_reads
```

This extracts reads and quality scores into FASTQ.

For this single-read Nanopore run, the expected working file is:

```text
raw_reads/SRR41146856.fastq
```

Check the output:

```bash
ls -lh raw_reads/SRR41146856.fastq
head -n 4 raw_reads/SRR41146856.fastq
```

## 2. Assess raw read quality

Script names follow the README step numbers. Letters identify separate scripts within the same step, for example `02a` for FastQC and `02b` for NanoPlot.

### 2a. FastQC

**Script:** [FastQC](02a_fastqc.sh).

FastQC provides an initial screen of stored quality scores, sequence composition and overrepresented sequences.

```bash
mkdir -p FastQC_results

fastqc raw_reads/SRR41146856.fastq \
  --outdir FastQC_results \
  --memory 4096 \
  --threads 1
```

Main report:

```text
FastQC_results/SRR41146856_fastqc.html
```

The initial analysis encountered a Java heap-space error. The command above requests more memory for FastQC. Long-read length and composition warnings require interpretation; they do not automatically mean that a Nanopore dataset should be discarded. An adapter-content pass does not establish that every Nanopore adapter or barcode is absent.

### 2b. NanoPlot

**Script:** [NanoPlot](02b_nanoplot.sh).

NanoPlot summarizes long-read lengths, quality scores and sequence yield.

```bash
NanoPlot \
  --fastq raw_reads/SRR41146856.fastq \
  --threads 2 \
  --outdir NanoPlot_raw

cat NanoPlot_raw/NanoStats.txt
```

Main visual report: `NanoPlot_raw/NanoPlot-report.html`.

| Measure | Observed result |
|---|---:|
| Number of reads | 168,347 |
| Total bases | 924,650,833 bp |
| Mean read length | 5,492.5 bp |
| Median read length | 3,092 bp |
| Read length N50 | 10,060 bp |
| Mean reported read quality | Q19.0 |
| Median reported read quality | Q21.7 |
| Longest read | 98,240 bp |

Read N50 means that half of the sequenced bases occur in reads at least 10,060 bp long. Reported quality scores are basecaller predictions, not an independent measurement of sequencing errors. No blanket read-quality filter was applied at this stage.

## 3. Trim adapters with Dorado

**Script:** [Adapter trimming](03_dorado_trim.sh). The script processes all reads.

The supplied metadata described a Rapid Barcoding Kit 96 V14 library. Dorado used the kit identifier `SQK-RBK114-96`. This kit setting belongs to this dataset and should not be assumed for another run.

### Process all reads

```bash
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
```

- `--no-trim-primers` skips primer trimming, so this was an adapter-only step.
- `--emit-fastq` requests FASTQ rather than the default BAM output.
- `>` saves reads; `2>` saves diagnostic messages.

The log reported 168,347 reads written. A separate before/after sequence comparison found **38 changed reads** and **1,822 bases removed**. Those change counts came from the comparison, not directly from the Dorado log. They indicate a small amount of adapter-like sequence detected under these settings, not a general contamination percentage.

## 4. Assemble the trimmed reads with Flye

**Script:** [Flye assembly](04_flye_assembly.sh).

Flye reconstructs longer sequences from overlapping reads. The `--nano-hq` mode was selected for the R10.4.1 Nanopore data; it is not a per-read quality filter.

```bash
flye \
  --nano-hq dorado_trimming/SRR41146856_adapter_trimmed.fastq \
  --threads 2 \
  --out-dir flye_assembly_trimmed

cat flye_assembly_trimmed/assembly_info.txt
```

Main files:

- `assembly.fasta`: assembled DNA sequences.
- `assembly_info.txt`: lengths, coverage estimates, circularity and repeat information.
- `assembly_graph.gfa`: the assembly graph.
- `flye.log`: progress and diagnostic messages.

| Contig | Length bp | Flye coverage | Circular label | Repeat label |
|---|---:|---:|---|---|
| contig_1 | 5,592,291 | 140 | Y | N |
| contig_5 | 114,328 | 336 | Y | Y |
| contig_3 | 102,976 | 220 | Y | N |
| contig_6 | 40,439 | 734 | Y | Y |
| contig_2 | 5,586 | 42 | Y | Y |
| contig_4 | 587 | 6,491 | Y | Y |

Total assembly length: **5,856,207 bp in six contigs**. The largest contig is a chromosome candidate. Flye's circular and repeat labels are assembly inferences, not independent proof of complete chromosomes or plasmids.

## 5. Evaluate assembly quality

### 5a. QUAST

**Script:** [QUAST evaluation](05a_quast.sh).

QUAST describes assembly size, fragmentation and continuity. This command does not use a reference genome.

```bash
quast flye_assembly_trimmed/assembly.fasta \
  -t 2 \
  -o quast_flye_results

cat quast_flye_results/report.txt
```

| Measure | Result |
|---|---:|
| Number of contigs | 6 |
| Total length | 5,856,207 bp |
| Largest contig | 5,592,291 bp |
| N50 | 5,592,291 bp |
| N90 | 5,592,291 bp |
| L50 | 1 |
| L90 | 1 |
| GC | 35.39% |
| Unknown bases N | 0 |

N50 describes continuity, not correctness. L50 of 1 means that the largest contig alone contains at least half the assembled bases. No Ns means no unknown bases represented by N; it does not mean zero sequence errors.

### 5b. CheckM2

**Script:** [CheckM2 evaluation](05b_checkm2.sh).

CheckM2 predicts genome completeness and contamination from genome content.

```bash
checkm2 predict \
  --threads 2 \
  --input flye_assembly_trimmed/assembly.fasta \
  --output-directory checkm2_flye_results

cat checkm2_flye_results/quality_report.tsv
```

An existing CheckM2 database must already be configured.

| Measure | Result |
|---|---:|
| Estimated completeness | 100% |
| Estimated contamination | 0% |
| Total contigs | 6 |
| Predicted coding sequences | 5,967 |
| Coding density | 0.838 |

These are encouraging content-quality estimates. They do not establish chromosome closure, an exhaustive plasmid inventory or base-level accuracy.

## 6. Map reads back to the assembly

**Script:** [Read mapping and coverage](06_map_reads.sh).

The original reads were mapped to the trimmed-read assembly to inspect read support. This comparison uses the assembled contigs as the target; it does not align contigs to a published reference.

```bash
mkdir -p read_mapping
set -o pipefail

minimap2 -ax lr:hq -t 2 \
  flye_assembly_trimmed/assembly.fasta \
  raw_reads/SRR41146856.fastq \
  2> read_mapping/minimap2.log \
  | samtools sort -m 1G \
      -o read_mapping/reads_vs_flye.sorted.bam -
```

`lr:hq` selects accurate long-read alignment settings. The pipe streams alignments to SAMtools for coordinate sorting and BAM output. The `1G` memory setting applies to each sorting thread, not to the entire pipeline.

### Check and index the BAM

```bash
samtools quickcheck -v read_mapping/reads_vs_flye.sorted.bam
samtools index read_mapping/reads_vs_flye.sorted.bam
```

No output from `quickcheck` means the basic header/end-of-file check passed. It does not inspect every alignment. The BAM index enables fast regional access.

### Generate summaries

```bash
samtools flagstat read_mapping/reads_vs_flye.sorted.bam \
  > read_mapping/mapping_summary.txt

samtools coverage read_mapping/reads_vs_flye.sorted.bam \
  > read_mapping/coverage_per_contig.tsv

cat read_mapping/mapping_summary.txt
cat read_mapping/coverage_per_contig.tsv
```

**162,452 of 168,347 primary read records mapped: 96.50%.** Secondary and supplementary alignments are additional alignment records, not extra input reads. Zero paired-read counts are expected for this dataset.

| Contig | Covered bases percent | Mean depth | Mean MAPQ |
|---|---:|---:|---:|
| contig_1 | 100 | 137.208 | 59.7 |
| contig_2 | 82.8142 | 11.5349 | 0.289 |
| contig_3 | 100 | 213.899 | 59.1 |
| contig_4 | 100 | 6,482.38 | 59.5 |
| contig_5 | 100 | 320.489 | 59.6 |
| contig_6 | 100 | 700.445 | 59.7 |

- **Coverage breadth** is the percentage of contig positions covered by reads.
- **Mean depth** is the average aligned read coverage at a position.
- **MAPQ** describes confidence of read placement, not basecall accuracy.

Contig 2 was the only contig with incomplete coverage (82.81%) and near-zero mean MAPQ (0.289), making it the clearest mapping concern. All other contigs had 100% coverage and high mean MAPQ. Contig 4 had unusually high depth, but this alone did not demonstrate an assembly error or contamination. Read coverage and MAPQ do not independently establish correct joins or circularity.

## 7. Verify contig 2

The mapping summary identified contig 2 as the clearest concern: it was 5,586 bp long, with 82.81% coverage, mean depth 11.53 and mean MAPQ 0.289. We investigated whether its sequence was already represented in the chromosome candidate and whether it contained rRNA genes.

This section is the endpoint of the analysis presented here. It does not include a contig-removal step, annotation or later small-contig investigations.

**Scripts:** [Contig 2 extraction and BLAST](07a_verify_contig2.sh) and [rRNA prediction](07b_contig2_rrna.sh). The scripts use separate tools; activate an environment containing the required programs before each one.

### 7a. Extract and compare contig 2

```bash
mkdir -p contig2_verification

samtools faidx flye_assembly_trimmed/assembly.fasta

samtools faidx flye_assembly_trimmed/assembly.fasta contig_2 \
  > contig2_verification/contig_2.fasta

samtools faidx flye_assembly_trimmed/assembly.fasta \
  contig_1 contig_3 contig_4 contig_5 contig_6 \
  > contig2_verification/other_contigs.fasta
```

The query file contains contig 2. The comparison file contains **all five other contigs: 1, 3, 4, 5 and 6**. Contig 2 is excluded from the target file so that it cannot simply match itself.

### Compare contig 2 with the other assembled contigs

```bash
blastn \
  -query contig2_verification/contig_2.fasta \
  -subject contig2_verification/other_contigs.fasta \
  -task blastn \
  -outfmt "7 qseqid sseqid pident length qlen qstart qend sstart send evalue bitscore" \
  -out contig2_verification/contig2_vs_other_contigs.tsv

cat contig2_verification/contig2_vs_other_contigs.tsv
```

The following key results are retained from the earlier comparison against contigs 1, 3, 5 and 6. The command above now includes contig 4 as well; this revised target set has not been rerun here. The recorded matches were to **contig 1, the main chromosome candidate**:

| Query positions in contig 2 | Subject positions in contig 1 | Identity |
|---|---|---:|
| 1–4,958 | 4,051,808–4,046,852 | 99.899% |
| 4,956–5,586 | 4,052,437–4,051,809 | 99.366% |

Together, these two alignments cover all 5,586 query bases, with a small overlap. The decreasing subject coordinates indicate reverse orientation. Their order differs between the linear representations of the two sequences. This is not one uninterrupted 100%-identity alignment.

Other chromosome locations also had long, highly similar matches, supporting a repeat-related interpretation. A BLAST hit count is not a count of complete biological copies.

### 7b. Identify rRNA genes with Barrnap

```bash
barrnap --kingdom bac --threads 2 \
  contig2_verification/contig_2.fasta \
  > contig2_verification/rrna_predictions.gff \
  2> contig2_verification/barrnap.log

cat contig2_verification/rrna_predictions.gff
```

The original Barrnap run used the two-contig extraction and reported these features on contig 2. The focused command above reruns prediction on contig 2 alone.

| Predicted feature | Contig 2 positions | Strand |
|---|---|---|
| 5S rRNA | 1–108 | minus |
| 23S rRNA | 211–3,132 | minus |
| 16S rRNA | 3,279–4,830 | minus |

The minus strand describes orientation and is not an error.

### Conclusion of contig 2 verification

The combined evidence supports interpreting contig 2 as a **potentially redundant representation of a chromosomal rRNA-repeat region**: its complete sequence is represented through near-identical chromosome-candidate alignments, its read placement is ambiguous and rRNA genes were predicted.

## Overall findings

The Nanopore workflow produced a highly contiguous six-contig assembly with encouraging genome-content estimates and read support. Adapter trimming changed 38 of 168,347 reads and removed 1,822 bases. Contig 2 showed the clearest concern in the mapping summary because coverage was incomplete and placement confidence was very low.
The analysis is a training case study ending at contig 2 verification.

## Repository structure

| Path | Contents |
|---|---|
| `README.md` | Project description, commands, observed results and limitations |
| `01_download_extract.sh` | Optional archive download and FASTQ extraction |
| `02a_fastqc.sh` | Initial read QC |
| `02b_nanoplot.sh` | Long-read statistics |
| `03_dorado_trim.sh` | Full-dataset adapter trimming |
| `04_flye_assembly.sh` | Trimmed-read assembly |
| `05a_quast.sh` | Reference-free assembly statistics |
| `05b_checkm2.sh` | Genome-content quality estimates |
| `06_map_reads.sh` | Read mapping and coverage |
| `07a_verify_contig2.sh` | Contig 2 extraction and BLASTn against all other contigs |
| `07b_contig2_rrna.sh` | rRNA prediction on contig 2 |

## Reproducibility

The scripts document computational steps from a Nanopore genome analysis performed on a Linux laptop using Conda environments. Users should adapt input paths, software environments and computational resources to their own systems.

## Acknowledgements

I thank the original dataset generators and submitters, NCBI and the developers of the analysis tools. 
## Documentation and references

- [SRA Toolkit FASTQ extraction](https://github.com/ncbi/sra-tools/wiki/HowTo%3A-fasterq-dump)
- [NCBI SRA on AWS](https://registry.opendata.aws/ncbi-sra/)
- [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- [NanoPlot](https://github.com/wdecoster/NanoPlot)
- [Dorado adapter trimming](https://software-docs.nanoporetech.com/dorado/latest/barcoding/trimming/)
- [Flye](https://github.com/mikolmogorov/Flye)
- [QUAST](https://github.com/ablab/quast)
- [CheckM2](https://github.com/chklovski/CheckM2)
- [Minimap2](https://github.com/lh3/minimap2)
- [SAMtools](https://www.htslib.org/doc/samtools.html)
- [BLAST documentation](https://www.ncbi.nlm.nih.gov/books/NBK279690/)
- [Barrnap](https://github.com/tseemann/barrnap)
- [NCBI data-use policy](https://www.ncbi.nlm.nih.gov/home/about/policies/)

