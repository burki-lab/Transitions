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
This phylogeny-aware taxonomic annotation step is based on the 18S gene alone as it has more comprehensive databases. Here we use a custom PR2 database (called `PR2_transitions`) with 9 ranks of taxonomy instead of 8. The changes in taxonomy were made to reflect the most recent eukaryotic tree of life (based on [Burki et al. 2019](https://www.sciencedirect.com/science/article/pii/S0169534719302575?via%3Dihub)). This custom database is available on [Figshare](https://figshare.com/articles/dataset/Global_patterns_and_rates_of_habotat_transitions_across_the_eukaryotic_tree_of_life/15164772). Changes to taxonomy can be viewed [here](https://docs.google.com/spreadsheets/d/1XaNgaZb5QTFH-YsvGiEV8a0i37CYr580/edit?usp=sharing&ouid=115778713146153097020&rtpof=true&sd=true). This taxonomic annotation step requires some manual curation. For a detailed overview of the algorithm, see [Jamy et al. 2020](https://onlinelibrary.wiley.com/doi/full/10.1111/1755-0998.13117). Scripts for this step can be found in the folder `scripts_taxonomy`.

### 2.1 Initial tree inference
Infer one tree per sample. Here, we want to infer a global eukaryotic tree with:  
1. The OTUs from our environmental sample  
2. The two closest related reference sequences for each OTU. These are referred to in the script as `top2hits`.    
3. Representatives from all major eukaryotic groups and supergroups (here I selected 124 seqs). The fasta file `pr2.main_groups.fasta` is available in `scripts_taxonomy`. Referred to in the script as EUKREF. 

The script `taxonomy_round1.sh` will assemble this dataset, align with mafft, gently trim the alignment, and infer a quick-and-dirty tree with SH-like support. As before, use `parallel` to compute multiple files simultaneously.

`bash taxonomy_round1.sh [path to directory containing final 18S OTU file]`

### 2.2 Manual curation
Examine the tree manually in FigTree and colour taxa that should be discarded. Mark nucleomorph sequences (green - hex code: #00FF00), mislabelled reference sequences (blue - hex code: #0000FF), and any OTU sequences that look like artefacts (ridiculously long branch for example) (magenta - hex code: #FF00FF). Nucleomorph OTU sequences are easily identified because they cluster with reference nucleomorph sequences. Mislabelled reference sequences are also easily identified, for example you may find a PR2 sequence annotated as Fungi clustering with Dinoflagellates etc. Other artefact OTU sequences (chimeras) are trickier to spot. I recommend BLASTing suspicious sequences in two halves, and using the information about abundance (in the fasta header) to help you decide which sequences to keep or not. This is an important step so take your time. Save all tree files after examination in a new folder called `taxonomy`.  

