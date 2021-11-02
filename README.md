# Transitions

This repository contains all scripts used for processing PacBio Sequel II data (18S-28S) and for ancestral state reconstruction analyses. Check first lines of scripts for usage instructions and other comments.

## 1. Processing Sequel II data

### 1.1 Filtering CCS 
The input files are demultiplexed fastq files, with each fastq file (corresponding to a particular sample) in its own folder. Scripts for this step are available in the folder `scripts_PacBio_process`.  

First, use DADA2 to remove primers, orient reads to be in the same direction, and filter sequences. Here, we removed sequences shorter than 3000 bp, longer than 6000 bp, and with more than 4 expected errors. Export as a fasta file.  
`Rscript DADA2.r`

Or process multiple samples in parallel using:  
`parallel --jobs 3 'bash filter.sh {}' ::: [list of paths to folders containing the input files]`

### 1.2 Further filtering and OTU clustering 
Further denoise seqs by generating consensus seqs of highly similar seqs (>99% identical), remove any prokaryotic seqs and chimeras, extract 18S and 28S sequences and cluster into OTUs at 97% similarity, and do another round of chimera detection. (Run this step in parallel using `parallel`).   
`bash filter_to_otus.sh [path to fasta file]`

The output is fasta files with OTU representative sequences for both 18S and 28S. The headers look like this:  

```
>c-741_conseq_Otu0001_64589  
>c-5261_conseq_Otu0010_2897  
>m64077_200204_130436/33555821/ccs_Otu1339_2  
>m64077_200204_130436/91750552/ccs_Otu1341_2  
```

Fasta headers containing `conseq` are consensus sequences generated from highly similar sequences. If for a sequence, there are no other highly similar sequences, no consensus is generated, giving fasta headers like the third and fourth in the list above. In the above fasta headers, the following parts are the sequence id:  

```
c-741_conseq_Otu0001
c-5261_conseq_Otu0010   
m64077_200204_130436/33555821/ccs_Otu1339   
m64077_200204_130436/91750552/ccs_Otu1341
```   

The biggest OTU (in terms of abundance) is `Otu0001` in this case, `Otu0010` is the tenth biggest OTU and so on.

The last number (i.e.e after the Otu term) is the OTU abundnace. For instance the fasta headers above show the following abundances:  
```
64589    
2897  
2  
2  
```


### 1.3 Characterize OTUs 
Get stats about similarity to reference sequences in PR2, abundances, and sequence lengths (run on multiple samples parallel using parallel). Output files can be plotted in R for visualisation.  
`bash characterize_otus.sh [path to directory containing OTU fasta files]`


## 2. Taxonomic annotation
This phylogeny-aware taxonomic annotation step requires some manual curation. For a detailed overview of the algorithm, see [Jamy et al. 2020](https://onlinelibrary.wiley.com/doi/full/10.1111/1755-0998.13117).

### 2.1 Initial tree inference


