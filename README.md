# Scripts for "Global patterns and rates of habitat transitions across the eukaryotic tree of life" (Jamy et al. 2021)

This repository contains all scripts used for processing PacBio Sequel II data (18S-28S) and for ancestral state reconstruction analyses. Check first lines of scripts for usage instructions, required software, and other comments.

## 1. Processing Sequel II data

### 1.1 Filtering CCS 
The input files are demultiplexed fastq files, with each fastq file (corresponding to a particular sample) in its own folder. Scripts for this step are available in the folder `scripts_PacBio_process`.  

First, use DADA2 to remove primers, orient reads to be in the same direction, and filter sequences. Here, we removed sequences shorter than 3000 bp, longer than 6000 bp, and with more than 4 expected errors. Export as a fasta file.  
`Rscript DADA2.r`

Or process multiple samples in parallel using:  
`parallel --jobs 3 'bash scripts_PacBio_process/filter.sh {}' ::: [list of paths to folders containing the input files]`

### 1.2 Further filtering and OTU clustering 
Further denoise seqs by generating consensus seqs of highly similar seqs (>99% identical), remove any prokaryotic seqs and chimeras, extract 18S and 28S sequences and cluster into OTUs at 97% similarity, and do another round of chimera detection. (Run this step in parallel using `parallel`).   
`bash scripts_PacBio_process/filter_to_otus.sh [path to fasta file]`

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

The last number (i.e. after the Otu term) is the OTU abundance. For instance the fasta headers above show the following abundances:  
```
64589    
2897  
2  
2  
```


### 1.3 Characterize OTUs 
Get stats about similarity to reference sequences in PR2, abundances, and sequence lengths (run on multiple samples parallel using parallel). Output files can be plotted in R for visualisation.  
`bash scripts_PacBio_process/characterize_otus.sh [path to directory containing OTU fasta files]`


## 2. Taxonomic annotation
This phylogeny-aware taxonomic annotation step is based on the 18S gene alone as it has more comprehensive databases. Here we use a custom PR2 database (called `PR2_transitions`) with 9 ranks of taxonomy instead of 8. The changes in taxonomy were made to reflect the most recent eukaryotic tree of life (based on [Burki et al. 2019](https://www.sciencedirect.com/science/article/pii/S0169534719302575?via%3Dihub)). This custom database is available on [Figshare](https://figshare.com/articles/dataset/Global_patterns_and_rates_of_habotat_transitions_across_the_eukaryotic_tree_of_life/15164772). Changes to taxonomy can be viewed [here](https://docs.google.com/spreadsheets/d/1XaNgaZb5QTFH-YsvGiEV8a0i37CYr580/edit?usp=sharing&ouid=115778713146153097020&rtpof=true&sd=true). This taxonomic annotation step requires some manual curation. For a detailed overview of the algorithm, see [Jamy et al. 2020](https://onlinelibrary.wiley.com/doi/full/10.1111/1755-0998.13117). Scripts for this step can be found in the folder `scripts_taxonomy`.

### 2.1 Initial tree inference
Infer one tree per sample. Here, we want to infer a global eukaryotic tree with:  
1. The OTUs from our environmental sample  
2. The two closest related reference sequences for each OTU. These are referred to in the script as `top2hits`.    
3. Representatives from all major eukaryotic groups and supergroups (here I selected 124 seqs). The fasta file `pr2.main_groups.fasta` is available in `scripts_taxonomy`. Referred to in the script as EUKREF. 

The script `taxonomy_round1.sh` will assemble this dataset, align with mafft, gently trim the alignment, and infer a quick-and-dirty tree with SH-like support. As before, use `parallel` to compute multiple files simultaneously.

`bash scripts_taxonomy/taxonomy_round1.sh [path to directory containing final 18S OTU file]`

### 2.2 Manual curation
Examine the tree manually in FigTree and colour taxa that should be discarded. Mark nucleomorph sequences (green - hex code: #00FF00), mislabelled reference sequences (blue - hex code: #0000FF), and any OTU sequences that look like artefacts (ridiculously long branch for example) (magenta - hex code: #FF00FF). Nucleomorph OTU sequences are easily identified because they cluster with reference nucleomorph sequences. Mislabelled reference sequences are also easily identified, for example you may find a PR2 sequence annotated as Fungi clustering with Dinoflagellates etc. Other artefact OTU sequences (chimeras) are trickier to spot. I recommend BLASTing suspicious sequences in two halves, and using the information about abundance (in the fasta header) to help you decide which sequences to keep or not. This is an important step so take your time. Save all tree files after examination in a new folder called `taxonomy`.  

### 2.3 Build ML trees
Remove all artefactual/misannotated sequences from your fasta files. [Here](https://docs.google.com/spreadsheets/d/1KHMcCRYNMnRqaP7yrI3UyUK0QYFG06gIjFg09PYjKbI/edit?usp=sharing) is a list of sequences from PR2 that I removed or reannotated. Re-align and trim cleaned fasta files, and re-infer trees. You may need to do another round of cleaning before proceeding. 

`bash scripts_taxonomy/taxonomy_round2.sh`


### 2.4 Assign taxonomy based on phylogeny
Here we use two approaches or "strategies" to get taxonomy of the OTUs based on the inferred tree. This step requires a reference *taxonomy* file from PR2. The taxonomy file for the custom *PR2_transitions* database can be found on [Figshare](https://figshare.com/articles/dataset/Global_patterns_and_rates_of_habotat_transitions_across_the_eukaryotic_tree_of_life/15164772).

1. **Strategy 1.** Propagate taxonomy from the closest neighbour to each OTU. 
2. **Strategy 2.** Prune away OTUs to get a tree containing reference sequences alone. Phylogenetically place the OTUs on the phylogeny and use the placement information to calculate taxonomy and confidence for each taxonomic rank.

Generate a consensus from the two strategies. I recommend manually checking the output table quickly to make sure that everything makes sense. If there are huge conflicts between the two strategies for a sequence, it may be a chimera. Manually check this before discarding though. 

`bash scripts_taxonomy/place.sh`

### 2.5 Transfer taxonomy to 28S molecule
Now that we have labelled all our 18S OTU sequences for each sample, we can transfer the taxonomy to the corresponding 28S molecules! I also incorporated the taxonomy information in the fasta headers for both the 18S and 28S genes. 

First, I used a few `sed` commands and the taxonomy output table from the previous step so my fasta headers now looked like this:

```
>c-1122_conseq_Otu0513_44_soil_PuertoRico_Eukaryota_Obazoa_Opisthokonta_Metazoa_Platyhelminthes_Turbellaria_Macrostomorpha_Macrostomum_Genus
>c-54_conseq_Otu010_10196_freshwater_Svartberget-fw_Eukaryota_TSAR_Stramenopiles_Gyrista_Dictyochophyceae_Dictyochophyceae_X_Pedinellales_Family
>c-6522_conseq_Otu0357_21_freshwater_permafrost_Eukaryota_TSAR_Alveolata_Ciliophora_Colpodea_Colpodea_X_Cyrtolophosidida_Family
>c-5162_conseq_Otu0063_727_soil_Sweden_Eukaryota_TSAR_Rhizaria_Cercozoa_Filosa-Imbricatea_Spongomonadida_Spongomonadidae_Spongomonadidae_X_Spongomonadidae_X_sp_Species
>c-1765_conseq_Otu299_22_deep_Ms2-mes_Eukaryota_TSAR_Alveolata_Dinoflagellata_Syndiniales_Dino-Group-I_Dino-Group-I-Clade-5_Dino-Group-I-Clade-5_X_Dino-Group-I-Clade-5_X_sp_Species
```

As before, the first part is the sequence ID. In this case:

```
c-1122_conseq_Otu0513
c-54_conseq_Otu010
c-6522_conseq_Otu0357
c-5162_conseq_Otu0063
c-1765_conseq_Otu299
```

Next is information about abundance (number of reads):

```
44
10196
21
727
22
```

Followed by environment and sample information:

```
soil_PuertoRico
freshwater_Svartberget-fw
freshwater_permafrost
soil_Sweden
deep_Ms2-mes  ## deep ocean - mesopelagic - from Malaspina
```

Finally, information on taxonomy and the rank to which the OTU is annotated.

```
Eukaryota_Obazoa_Opisthokonta_Metazoa_Platyhelminthes_Turbellaria_Macrostomorpha_Macrostomum_Genus
Eukaryota_TSAR_Stramenopiles_Gyrista_Dictyochophyceae_Dictyochophyceae_X_Pedinellales_Family
Eukaryota_TSAR_Alveolata_Ciliophora_Colpodea_Colpodea_X_Cyrtolophosidida_Family
Eukaryota_TSAR_Rhizaria_Cercozoa_Filosa-Imbricatea_Spongomonadida_Spongomonadidae_Spongomonadidae_X_Spongomonadidae_X_sp_Species
Eukaryota_TSAR_Alveolata_Dinoflagellata_Syndiniales_Dino-Group-I_Dino-Group-I-Clade-5_Dino-Group-I-Clade-5_X_Dino-Group-I-Clade-5_X_sp_Species
```

Using the script `scripts_taxonomy/replace_fasta_header.pl`, I changed the fasta headers of the 28S gene as well so they were identical to the 18S gene.



## 3. Global 18S-28S phylogeny

Any scripts and necessary files for this section can be found in the folder `scripts_global_phylogeny`.

### 3.1 Align, trim and concatenate

First combine the labelled 18S sequences from all samples into a single fasta file. I labelled mine `all.18S.fasta`. I did the same for the 28S gene and lablled it `all.28S.fasta`.

Align the 18S and 28S genes with mafft-auto. Since it is a large number of sequences, mafft used the FFT-NS-2 algorithm. (Here I also tried the SINA aligner, T-Coffee and Kalign - I inspected all alignments visually by eye and found that SINA and T-Coffee gave me bad alignments where even the most conserved regions of the 18S gene were not aligned. Kalign and mafft seemed to work better and in the end I chose to stick to mafft.) 

```
mafft --thread 20 --reorder all.18S.fasta > all.18S.mafft.fasta
mafft --thread 20 --reorder all.28S.fasta > all.28S.mafft.fasta
```

Next trim the alignments. Here we want to gently trim the alignments so that we reduce the number of alignment sites and make tree inference less computationally intensive. However, we do not want to trim too much as we want to combine it short read metabarcoding data (V4 region) in a later step. After several trials I opted to remove columns with more than 95% gaps. 

```
trimal -in all.18S.mafft.fasta -out all.18S.mafft.trimal.fasta -gt 0.05
trimal -in all.28S.mafft.fasta -out all.28S.mafft.trimal.fasta -gt 0.05
```

After visually inspecting the alignments, concatenate the 18S and 28S genes. I use the script `concat_fasta.pl` found at https://github.com/iirisarri/phylogm/blob/master/concat_fasta.pl

```
perl concat_fasta.pl all.18S.mafft.trimal.fasta all.28S.mafft.trimal.fasta > all.concat.mafft.trimal.fasta
```


### 3.2 Several rounds of prelimiary phylogenies

Infer Maximum Likelihood phylogenies (unconstrained) with RAxML v8 (I don't recommend using raxml-ng at this stage because it does not have the GTRCAT model implemented yet, so tree inference is much slower). 

```
for i in $(seq 20); do raxmlHPC-PTHREADS-AVX -s all.concat.mafft.trimal.fasta -m GTRCAT -n all.concat.${1} -T 7 -p $RANDOM; done
```

Visually inspect the best ML tree and remove any chimeras or artefacts. Because our sequences are taxonomically labelled, it should make looking at the tree easier. Flag and remove chimeras (e.g. any Ascomycetes sequences that cluster with Basidiomycetes), check potential artefacts such as long-branches. Remove artefactual taxa, re-align, trim and re-infer trees. Do several rounds of this. 

I also removed super-fast evolving taxa using [TreeShrink](https://github.com/uym2/TreeShrink).

```
run_treeshrink.py -t RAxML_bestTree.all.concat -k 2500
```

(I played with several values of `k` and selected 2500 as it seemed reasonable for my dataset). In my case, 118 long branches were identified, mostly consisting of *Mesodinium*, *Microsporidium*, many unlabelled taxa, several Apicomplexa, several Discoba, and Colladaria. Fast-evolving taxa were removed to avoid long-branch attraction. 

I also did two rounds of preliminary phylogenies that were constrained. See next step to see how I constrained trees.


### 3.3 Infer final ML global phylogeny (constrained)

Once satisfied, I ran a final global ML phylogeny. For this paper, I enforced monophyly for groups such as ciliates, dinoflagellates, fungi etc. These groups correspond to rank 4 in the *PR2_transitions* [dataset](https://docs.google.com/spreadsheets/d/1XaNgaZb5QTFH-YsvGiEV8a0i37CYr580/edit?usp=sharing&ouid=115778713146153097020&rtpof=true&sd=true). The constrained groups and overview of the backbone phylogeny can be seen in `scripts_global_phylogeny/constrained_groups.newick`. 

I then used the taxonomic labels of each sequence to set up a multifucating constraint file (see [this guide](https://cme.h-its.org/exelixis/web/software/raxml/hands_on.html) on constraint trees by the Exelexis lab for more information). 

```
bash set_up_constraint.sh
```

Once I had the list of taxa for each group, I put it all together using a simple bash script `scripts_global_phylogeny/combine.sh`. Please note that this script is hard-coded to work for this specific datatset. 

```
cd constrained
cp scripts_global_phylogeny/combine.sh .

## ran a script to put it together in a newick file
bash combine.sh
```

This script will generate a file called `constraint.txt.tre`. Check it in FigTree to confirm that it makes sense. 


Finally run the global phylogeny!

```
## 100 ML trees
for i in $(seq 100); do raxmlHPC-PTHREADS-AVX -s all.concat.mafft.trimal.fasta -m GTRCAT -n all.concat.${1} -T 7 -p $RANDOM -j -g constraint.txt.tre; done

## 100 bootstrap replicates
raxmlHPC-PTHREADS-AVX -s all.concat.mafft.trimal.fasta -m GTRCAT -T7 -n bootstraps -g constraint.txt.tre - p $RANDOM -b $RANDOM -#100
```

I visualised the best ML tree. First root it arbitrarily at Amorphea. I used a custom script that roots a tree at a specified node. The node is specified as the ancestor of two or more tips. In this case I made a list of sequences in Amorphea (see `scripts_global_phylogeny/Amorphea.list`). 

```
python scripts_global_phylogeny/root_at_node.py RAxML_bestTree.all.concat.53 Amorphea.list RAxML_bestTree.all.concat.53.rooted.tre
```

View the phylogeny in anvi'o. Decorate the phylogeny with taxonomy, % similarity to references in PR2, and habitat (listed in the fast header). I beautified the figure in Adobe Illustrator. 



### 3.4 Unifrac analyses

Perform Unifrac analsis on the best ML tree. Using mothur for this. 

```
### First generate groups file. This is a tab delimited file that contains two columns: the taxa name and which group they belong to.
cat all.concat.mafft.trimal.fasta | grep ">" | tr -d '>' | grep "freshwater" | sed -E 's/(.*)/\1\tfreshwater/' > habitats.unifrac.txt
cat all.concat.mafft.trimal.fasta | grep ">" | tr -d '>' | grep "soil" | sed -E 's/(.*)/\1\tsoil/' >> habitats.unifrac.txt
cat all.concat.mafft.trimal.fasta | grep ">" | tr -d '>' | grep "surface" | sed -E 's/(.*)/\1\tsurface/' >> habitats.unifrac.txt
cat all.concat.mafft.trimal.fasta | grep ">" | tr -d '>' | grep "deep" | sed -E 's/(.*)/\1\tdeep/' >> habitats.unifrac.txt

### Clustering habitats
mothur "#unifrac.unweighted(tree=RAxML_bestTree.all.concat.53.rooted.tre, group=habitats.unifrac.txt, distance=square, random=t)"
```

Do the same for the samples.


### 3.5 Patristic distances

The aim here was to generate a graph that compares pairwise patristic distances between all leaves on the concatenated 18S-28S tree and whether or not they are from the same habitat. I exptected to see a trend where closley related OTUs are from the same habitat, and this relationship breaks down as the patristic distance increases.

Calculate pairwise patristic distances of the rooted tree. For this I found a script online: https://github.com/linsalrob/EdwardsLab/blob/master/trees/tree_to_cophenetic_matrix.py

```
python scripts_global_phylogeny/tree_to_cophenetic_matrix.py -t rooted.amorphea.RAxML_bestTree.all.concat.53 > pairwise_distance.matrix

Converting square matrix to cleaned text file (i.e. without duplicates and self comparisons) 
awk 'NR==1{for(i=2; i<=NF; i++){a[i]=$i}} NR!=1{for(i=NR+1; i<=NF; i++){print $1 "\t" a[i-1] "\t" $i}}' pairwise_distance.matrix > pairwise_distance.txt
```

Only extracting pairwise comparisons that are separated by a distance of less than 1.5 to avoid comparisons between taxa that are extremely distantly related (where we dont expect to see any relationhip between habitat type and distance anyway).

```
cat pairwise_distance.txt | awk '$3 < 1.5' > pairwise_distance.1.5.txt
```

Do habitat comparisons

```
bash mar-terr.sh pairwise_distance.1.5.txt mar-terr.txt
bash fw-soil.sh pairwise_distance.1.5.txt fw-soil.txt
bash surface-deep.sh pairwise_distance.1.5.txt surface-deep.txt
```


## 4 Incorporate short read metabarcoding data

To increase covered diversity, include existing short-read metabarcoding data. See Supplmenetary Table 3 of the manuscript to see which studies were included. Any scripts used are provided 


### 4.1 Process raw data

Primers were with `cutadapt` (maximum error rate = 10%). We used the `DADA2 R package` to process reads into ASVs using the `filterAndTrim` function, adapting the paaremters for each dataset. Where appropriate, forward and reverse reads were merged with the `mergePairs` function with default parameters, and chimeras removed with the `removeBimeraDenovo` function. We assigned taxonomy to the ASVs using the `assignTaxonomy` function against the PR2 database version 4.12.

ASVs from each study were concatenated together based on habitat (freshwater, soil, marine euphotic, and marine aphotic). This resulted in four fasta files, one for each habitat.


### 4.2 Cluster ASVs

ASVs from each dataset span slightly different regions of the V4, depending on the primer set used by each study. To reduce redundancy and to make the size of the dataset more manageable for phylogenetic analyses, we clustered the ASVs into OTUs at 97% similarity. 

```
for i in *fasta; do vsearch --cluster_size $i --sizein --sizeout --centroids "$i".centroids --id 0.97 --iddef 2 --uc "$i".ucfile; done
```

We then cleaned up the datasets to be conservative in what we considered to be present in a habitat. We decided to retain OTUs that have at least 100 reads or are present in at least two distinct samples. 

```
bash scripts_short_reads/filter_OTUs.sh <path to directory containing input files>
```

### 4.3 Align short reads to long-read alignment (from step 3)

Short-reads were aligned with PaPaRa using the best ML tree from step 3 as reference (in practice, any tree will do). 

PaPaRa expects the reference alignment to be in phylip format.

```
perl scripts_short_reads/fasta2phylip.pl -f all.concat.mafft.trimal.fasta -o all.concat.mafft.trimal.phylip
```

The query (short-read) sequences should be in uppercase or PaPaRa will fail. 

```
cat soil.filtered.fasta | seqkit seq -u > soil.filtered.u.fasta 
cat fw.filtered.fasta | seqkit seq -u > fw.filtered.u.fasta 
cat surface.filtered.fasta | seqkit seq -u > surface.filtered.u.fasta 
cat deep.filtered.fasta | seqkit seq -u > deep.filtered.u.fasta 
```

Align!

```
papara -t ../RAxML_bestTree.all.concat.53 -s all.concat.mafft.trimal.phylip -q soil.filtered.u.fasta -r -j 8
papara -t ../RAxML_bestTree.all.concat.53 -s all.concat.mafft.trimal.phylip -q fw.filtered.u.fasta -r -j 8
papara -t ../RAxML_bestTree.all.concat.53 -s all.concat.mafft.trimal.phylip -q surface.filtered.u.fasta -r -j 8
papara -t ../RAxML_bestTree.all.concat.53 -s all.concat.mafft.trimal.phylip -q deep.filtered.u.fasta -r -j 8
```

Convert resulting alignments to fasta, and rename them to indicate the habitat.

```
cat papara_alignment.default | sed -e '1d' -e 's/^/>/g' -e 's/[[:blank:]]\+/\n/g' > papara_alignment.fasta
```

Visualise the alignment in ALiView for a sanity check. Do the short reads align to the V4 region? Remove any that align elsewhere. 


### 4.4 Phylogenetic placement

Extract query sequences from the PaPaRa alignments.

```
cat soil.papara_alignment.clean.fasta | seqkit grep -r -p "asv" > soil.aligned.queries.fasta
cat fw.papara_alignment.clean.fasta | seqkit grep -r -p "asv" > fw.aligned.queries.fasta
cat surface.papara_alignment.clean.fasta | seqkit grep -r -p "asv" > surface.aligned.queries.fasta
cat deep.papara_alignment.clean.fasta | seqkit grep -r -p "asv" > deep.aligned.queries.fasta
```

We'll use the best ML tree from step 3 as the reference tree. In practice it doesnt matter so much.

Get model for EPA

```
raxml-ng --evaluate --msa all.concat.mafft.trimal.fasta --tree RAxML_bestTree.all.concat.53.rooted.tre --model GTR+G --threads 8
```

Placement with EPA-ng!

```
epa-ng -s all.concat.mafft.trimal.fasta -t RAxML_bestTree.all.concat.53.rooted.tre -q soil.aligned.queries.fasta --model all.concat.mafft.trimal.fasta.raxml.bestModel -T 8
epa-ng -s all.concat.mafft.trimal.fasta -t RAxML_bestTree.all.concat.53.rooted.tre -q fw.aligned.queries.fasta --model all.concat.mafft.trimal.fasta.raxml.bestModel -T 8
epa-ng -s all.concat.mafft.trimal.fasta -t RAxML_bestTree.all.concat.53.rooted.tre -q surface.aligned.queries.fasta --model all.concat.mafft.trimal.fasta.raxml.bestModel -T 8
epa-ng -s all.concat.mafft.trimal.fasta -t RAxML_bestTree.all.concat.53.rooted.tre -q deep.aligned.queries.fasta --model all.concat.mafft.trimal.fasta.raxml.bestModel -T 8
```

Visualised the jplace files using iTOL.


We removed queries with high EDPL (which indicates sequences that were poorly placed).

Examine EDPL.

```
gappa examine edpl --jplace-path epa_result.soil.jplace --threads 2
gappa examine edpl --jplace-path epa_result.fw.jplace --threads 2
gappa examine edpl --jplace-path epa_result.surface.jplace --threads 2
gappa examine edpl --jplace-path epa_result.deep.jplace --threads 2
```

Get a list of poorly placed queries; i.e. with high EDPL (i.e. above 0.05). This list will be used later to filter out these poorly placed queries.

```
cat *edpl_list.csv | tr ',' '\t' | egrep "e-[0-9]" -v | grep -v "EDPL" | LC_ALL=C awk '$4 > 0.05' | cut -f2 > high_edpl.list
```

Calculate Earth mover's distance to see how distinct the habitats are.

```
gappa analyze krd --jplace-path deep.jplace soil.jplace surface.jplace fw.jplace

mothur "#tree.shared(phylip=matrix.csv)"
```


## 5 Inferring clade specific phylogenies with short- and long-read data

Infer trees for selected clades. These are clades with both terrestrial and marine sequences. Selected clades were:

Apicomplexa
Bigyra
Centroplasthelida
Cercozoa
Chlorophyta
Choanoflagellata
Ciliophora
Cryptophyta
Dinoflagellata
Discoba
Fungi
Gyrista
Haptophyta
Ichthyosporea
Perkinsea
Telonemia

Put this list in a file called `clades.txt`.

### 5.1 Extract queries/short-read sequences for each clade

Using the placement files, we can extract the short-read sequences for each respective clade. Here we will discard any sequences placed in the "wrong" clade e.g. sequences labelled as "Apicomplexa" placed in "Excavata".

First get reference (i.e. PacBio long-read) tips for each clade. These which will be fed to gappa to extract the sequences placed on that particular clade.

```
## Get tips for each clade
cat clades.txt | while read line; do python scripts_infer_clade_trees/get_tip_labels_from_clade.py RAxML_bestTree.all.concat.53.rooted.tre $line > "$line".tips; done

## Add clade label to each sequence so for each clade, we get a tsv with the second column corresponding to clade name.
for i in *tips; do clade=$(echo $i | cut -f1 -d '.'); cat $i | sed -E "s/(.*)/\1\t$clade/" > temp; mv temp $i; done

## Put together
cat *tips > all.clades.tips
```

Now filter all query sequences based on EDPL.

```
cat soil.aligned.queries.fasta fw.aligned.queries.fasta surface.aligned.queries.fasta deep.aligned.queries.fasta > all.aligned.queries.fasta

cat all.aligned.queries.fasta | seqkit grep -f high_edpl.list -v > all.aligned.queries.filtered.fasta 
```

Now get per clade jplace and fasta files.

```
gappa prepare extract --jplace-path epa_result.soil.jplace --clade-list-file all.clades.tips --fasta-path all.aligned.queries.filtered.fasta --point-mass --threads 4 > soil.log
gappa prepare extract --jplace-path epa_result.fw.jplace --clade-list-file all.clades.tips --fasta-path all.aligned.queries.filtered.fasta --point-mass --threads 4 > fw.log
gappa prepare extract --jplace-path epa_result.surface.jplace --clade-list-file all.clades.tips --fasta-path all.aligned.queries.filtered.fasta --point-mass --threads 4 > surface.log
gappa prepare extract --jplace-path epa_result.deep.jplace --clade-list-file all.clades.tips --fasta-path all.aligned.queries.filtered.fasta --point-mass --threads 4 > deep.log
```

Retain only those short Illumina sequences that are placed there (i.e. remove all amoebozoa from groups like Bigyra etc.).

```
cat Cercozoa.fasta | seqkit grep -r -p "Cercozoa" > Cercozoa.queries.fasta
cat Fungi.fasta | seqkit grep -r -p "Fungi" > Fungi.queries.fasta
...
```

Make a folder for each clade

```
cat clades.txt | while read line; do mkdir $line; done
```

### 5.2 Infer clade trees

First, make files with taxa from clade of interest and outgroup, in order to extract clade and outgroup from the best tree

```
bash get_clade_outgroup.sh
```

Extract subtree from global euk phylogeny to serve as the backbone constraint. 

```
for i in */; do clade=$(echo $i | tr -d '/'); python scripts_infer_clade_trees/get_tip_labels_from_subtree.py RAxML_bestTree.all.concat.53.rooted.tre "$clade".txt > "$i$clade".tips; done
```

Get ref alignment for each clade. And get queries for each clade. 

```
for i in */; do clade=$(echo $i | tr -d '/'); cat all.concat.mafft.trimal.fasta | seqkit grep -r -f "$i$clade".tips > "$i$clade".fasta; done 

## Cat together ref and query fasta file
for i in */; do clade=$(echo $i | tr -d '/'); cd $i; cat *fasta > "$clade".ref.queries.fasta; cd ..; done

## Remove illegal characters
for i in */; do clade=$(echo $i | tr -d '/'); cd $i; cat "$clade".ref.queries.fasta | tr ';' '_' > temp; mv temp "$clade".ref.queries.fasta; cd ..; done
```

Set up trees!! An example is shown below.

```
for i in $(seq 100); do raxmlHPC-PTHREADS-SSE3 -s Centroplasthelida.ref.queries.fasta -m GTRCAT -n Centroplasthelida.${i}.tree -T 7 -p ${i} -r Centroplasthelida.tre; done
```

Then root trees and remove outgroup for analyses. An example is shown for Bigyra.

```
### Bigyra
#### Root at Gyrista
for i in RAxML_bestTree*; do python scripts_infer_clade_trees/root_at_clade.py $i Gyrista rooted."$i"; done
#### Extract Bigyra
for i in rooted.RAxML_bestTree*; do python scripts_infer_clade_trees/extract_clade.py $i Bigyra Bigyra."$i"; done
```







