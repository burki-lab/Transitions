# Transitions

This repository contains all scripts used for processing PacBio Sequel II data (18S-28S) and for ancestral state reconstruction analyses. Check first lines of scripts for usage instructions and other comments.

## 1. Processing Sequel II data

### 1.1 Filtering CCS 
The input files are demultiplexed fastq files, with each fastq file (corresponding to a particular sample) in its own folder. 

First, use DADA2 to remove primers, orient reads to be in the same direction, and filter sequences. Here, we removed sequences shorter than 3000 bp, longer than 6000 bp, and with more than 4 expected errors. Export as a fasta file.  
`Rscript DADA2.r`

Or process multiple samples in parallel uisng:  
`parallel --jobs 3 'bash filter.sh {}' ::: [list of paths to folders containing the input files]`

### 1.2 Further filtering and OTU clustering 
Further denoise seqs by generating consensus seqs of highly similar seqs (>99% identical), remove any prokaryotic seqs and chimeras, extract 18S and 28S sequences and cluster into OTUs at 97% similarity, and do another round of chimera detection. (Run this step in parellel using the parallel command).   
`bash filter_to_otus.sh [path to fasta file]`

### 1.3 Characterise OTUs 
Get stats about similarity to reference sequences in PR2, abundances, and sequence lengths (run on multiple samples parallel using parallel). Output files can be plotted in R for visualisation.  
`bash characterize_otus.sh [path to directory containing OTU fasta files]`



