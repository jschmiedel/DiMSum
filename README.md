<p align="left">
  <img src="./Dumpling.png" width="100">
</p>

Welcome to the GitHub repository for DiMSum: An error model and pipeline for analyzing deep mutational scanning (DMS) data and diagnosing common experimental pathologies.

# Table Of Contents

* **1. [Pipeline Overview](#pipeline-overview)**
* **2. [Installation Instructions](docs/INSTALLATION.md)**
* **3. [Command-line Arguments](docs/ARGUMENTS.md)**
* **4. [Input File Formats](docs/FILEFORMATS.md)**
* **5. [Demo](docs/DEMO.md)**

# Pipeline Overview

The DiMSum pipeline processes raw sequencing reads (in FASTQ format) or variant counts from deep mutational scanning (DMS) experiments to calculate estimates of variant fitness (and assocated error). These estimates are suitable for use in downstream analyses of epistasis and [protein structure determination](https://github.com/lehner-lab/DMS2structure).

The DiMSum pipeline consists of five stages grouped into two modules that can be run independently:

* **_WRAP_** (DiMSum stages 1-3) processes raw FASTQ files generating a table of variant counts
* **_STEAM_** (DiMSum stages 4-5) analyses variant counts generating variant fitness and error estimates

A description of each DiMSum stage is given below.

## Stage 0: **DEMULTIPLEX** raw reads (_WRAP_)

Demultiplex samples and trim read barcodes using *[Cutadapt](docs/INSTALLATION.md)* (optional). This stage is run if a [Barcode Design File](docs/FILEFORMATS.md#barcode-design-file) is supplied (see [arguments](docs/ARGUMENTS.md#multiplexed-fastq-files)).

## Stage 1: **QC** raw reads (_WRAP_)

Produce raw read quality reports using *[FastQC](docs/INSTALLATION.md)* (and unzip and split FASTQ files if necessary).

## Stage 2: **TRIM** constant regions (_WRAP_)

Remove constant region sequences from read 5’ and 3’ ends using *[Cutadapt](docs/INSTALLATION.md)*. By default the sequences of 3' constant regions are assumed to be the reverse complement of 5' constant region sequences (see [stage-specific arguments](docs/ARGUMENTS.md#trim-arguments)).

## Stage 3: **ALIGN** paired-end reads (_WRAP_)

Align overlapping read pairs using *[VSEARCH](docs/INSTALLATION.md)* and filter resulting variants according to base quality, expected number of errors and constituent read length (see [stage-specific arguments](docs/ARGUMENTS.md#align-arguments)). Unique variant sequences are then tallied using *[Starcode](docs/INSTALLATION.md)*. For [Trans library designs](docs/ARGUMENTS.md#trans-library-design), read pairs are simply concatenated. For single-end libraries, reads are only filtered.

## Stage 4: **PROCESS** variants (_STEAM_)

Combine sample-wise variant counts and statistics to produce a unified results data.table. After aggregating counts across technical replicates, variants are processed and filtered according to user specifications (see [stage-specific arguments](docs/ARGUMENTS.md#process-arguments)):
* **4.1** For [Barcoded library designs](docs/ARGUMENTS.md#barcoded-library-design), read counts are aggregated at the variant level for barcode/variant mappings specified in the [Variant Identity File](docs/FILEFORMATS.md#variant-identity-file). Undefined/misread barcodes are ignored.
* **4.2** Indel variants (defined as those not matching the wild-type nucleotide sequence length) are removed.
* **4.3** If internal constant region(s) are specified, these are excised from all variants if a perfect match is found (see ['_--wildtypeSequence_' argument](docs/ARGUMENTS.md#process-arguments)).
* **4.4** Variants with mutations inconsistent with the library design are removed (see ['_--permittedSequences_' argument](docs/ARGUMENTS.md#process-arguments)).
* **4.5** Variants with more substitutions than desired are also removed (see ['_--maxSubstitutions_' argument](docs/ARGUMENTS.md#process-arguments)).
* **4.6** Finally, nonsynonymous variants with synonymous substitutions in other codons are removed if necessary (see ['_--mixedSubstitutions_' argument](docs/ARGUMENTS.md#process-arguments)).

## Stage 5: **ANALYSE** counts (_STEAM_)

Calculate fitness and error estimates for a user-specified subset of substitution variants (see [stage-specific arguments](docs/ARGUMENTS.md#analyse-arguments)):
* **5.1** Optionally remove low count variants according to user-specified soft/hard thresholds to minimise the impact of "fictional" variants from sequencing errors.
* **5.2** Calculate replicate normalisation parameters (scale and shift) to minimise inter-replicate fitness differences.
* **5.3** Fit the error model to a high confidence subset of variants to determine additive and multiplicative error terms.
* **5.4** Aggregate variant fitness and error at the amino acid level if the target molecule is a coding sequence.
* **5.5** Optionally normalise fitness and error estimates by the number of generations in the case of a growth-rate based assay (see [Experiment Design File](docs/FILEFORMATS.md#experimental-design-file)).
* **5.6** Merge fitness scores between replicates in a weighted manner that takes into account their respective errors.

## Output Files

Primary output files:

* **report.html** DiMSum pipeline summary report and diagnostic plots in html format.
* **DiMSum_Project_fitness_replicates.RData** R data object with replicate (and merged) fitness scores and associated errors.
* **DiMSum_Project_variant_data_merge.RData** R data object with variant counts and statistics.

Additional output files:

* **fitness_wildtype.txt** Wild-type fitness score and associated error.
* **fitness_singles.txt** Single amino acid or nucleotide variant fitness scores and associated errors.
* **fitness_doubles.txt** Double amino acid or nucleotide variant fitness scores and associated errors.
* **fitness_silent.txt** Silent (synonymous) variant fitness scores and associated errors (for coding sequences only).
* **fitness_singles_MaveDB.csv** [MaveDB](https://www.mavedb.org/) compatible .csv file with single amino acid or nucleotide variant fitness scores and associated errors.
* **DiMSum_Project_variant_data_merge.tsv** Tab-separated plain text file with variant counts and statistics.
* **DiMSum_Project_nobarcode_variant_data_merge.tsv** Tab-separated plain text file with sequenced barcodes that were not found in the variant identity file.
* **DiMSum_Project_indel_variant_data_merge.tsv** Tab-separated plain text file with indel variants.
* **DiMSum_Project_rejected_variant_data_merge.tsv** Tab-separated plain text file with rejected variants (internal constant region mutants, mutations inconsistent with the library design or variants with too many substitutions).

(Vector illustration credit: <a href="https://www.vecteezy.com">Vecteezy!</a>)
