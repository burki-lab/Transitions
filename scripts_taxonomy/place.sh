#!/bin/bash

# ussage: bash place.sh 

# Requires that the following softwares are installed and in your path:
## Python version 3.8.5 or newer
## Ete-toolkit version 3.1.2 or newer
## seqkit version 0.15.0 or newer
## epa-ng version 0.3.5 or newer
## genesis version 0.24 or newer
## gappa version 0.6.0 or newer

# You also need the following custom scripts and databases
## prune.py 
## pr2.transitions.tax (taxonomy file)
## taxonomy_merge.pl


DIR="env_seq/taxonomy"
PTT="programs/genesis-0.24.0/bin/apps/partial-tree-taxassign"
RAXML="/opt/raxml-ng"
EPA="/opt/epa-ng-0.3.5/bin/epa-ng"
TAX="PR2/pr2_transitions/pr2.transitions.tax"
GAPPA="programs/gappa/bin/gappa"

cd $DIR

### activate ete environment
conda activate ete

### log
exec > place.log 2>&1


## Strategy 2 taxonomy - prune away the OTUs and phylogenetically place them back on the reference-only tree. Get taxonomy and confidence scores for each taxonomic rank.

## split alignment into OTUs and references - this is important for running EPA-ng later!
for i in *trimal.fasta; do base=$(echo $i | awk -F '.' '{print $1}'); cat $i | seqkit grep -r -p _Otu > "$base".otus.fasta; done
for i in *trimal.fasta; do base=$(echo $i | awk -F '.' '{print $1}'); cat $i | seqkit grep -r -p _Otu -v > "$base".ref.fasta; cat "$base".ref.fasta | grep ">" | tr -d '>' > "$base".ref.list; done 

## prune tree - use a python script for this (uses the ete toolkit)
for i in *raxml.bestTree; do base=$(echo $i | awk -F '.' '{print $1}'); python prune.py $i "$base".ref.list "$base".pruned.tre; done

## get model details for use in EPA and optimise branch lengths
for i in *.pruned.tre; do base=$(echo $i | awk -F '.' '{print $1}'); ${RAXML} --evaluate --tree $i --msa "$base".ref.fasta --model GTR+G --threads 4 --prefix "$base".pruned; done

## run EPA-ng
for i in *pruned.raxml.bestTree; do base=$(echo $i | awk -F '.' '{print $1}'); ${EPA} --tree $i --ref-msa "$base".ref.fasta --query "$base".otus.fasta --model "$base".pruned.raxml.bestModel --threads 10 --no-heur --no-pre-mask --verbose; mv epa_info.log "$base".epa_info.log; mv epa_result.jplace "$base".epa_result.jplace; done


## set up taxonomy file

### fasta headers
for i in *ref.fasta; do base=$(echo $i | awk -F '.' '{print $1}'); cat $i | grep ">" | tr -d '>' | sed -E 's/(.*@)(.*)/\2\t\1\2/' | sort -k1,1 > "$base".ref.headers; done

### list of accessions
for i in *ref.fasta; do base=$(echo $i | awk -F '.' '{print $1}'); cat $i | grep ">" | sed -E 's/(.*@)(.*)/\2/' > "$base".accessions; done

### grep for taxonomy
for i in *accessions; do base=$(echo $i | awk -F '.' '{print $1}'); grep -w -f $i ${TAX} | sed -E 's/(.*)\.[0-9]+\..*(\tEukaryota.*)/\1\2/' | sed -E 's/;$//' | sort -u | sort -k1,1 > "$base".ref.tax; done

## join the files based on the common accession number
for i in *ref.headers; do base=$(echo $i | awk -F '.' '{print $1}'); join $i "$base".ref.tax | tr ' ' '\t' | cut -f 2,3 > "$base".taxonomy.txt; done

## assign taxonomy with gappa
for i in *ref.fasta; do base=$(echo $i | awk -F '.' '{print $1}'); grep "Opisthokonta" $i | tr -d '>' > "$base".outgroup; done

for i in *epa_result.jplace; do base=$(echo $i | awk -F '.' '{print $1}'); ${GAPPA} examine assign --threads 10 --jplace-path $i --sativa --taxon-file "$base".taxonomy.txt --root-outgroup "$base".outgroup --per-query-results --sativa --file-prefix "$base".assign_; done


## Strategy 1 taxonomy - get taxonomy of OTUs based on their position on the tree. See "Long-read metabarcoding of the eukaryotic rDNA operon to phylogenetically and taxonomically resolve environmental diversity" for details.
## Uses the genesis app "partial-tree-taxassign"

for i in *taxonomy.txt; do base=$(echo $i | awk -F '.' '{print $1}'); ${PTT} "$base".raxml.bestTree $i "$base".outgroup > "$base".assignment.tsv; done


## Combine taxonomy from both strategies.

for i in *assignment.tsv; do base=$(echo $i | awk -F '.' '{print $1}'); perl /media/Data_1/Mahwash/env_seq/scripts/taxonomy_merge.pl $i "$base".assign_sativa.tsv 0.5 "$base".taxonomy_merged.tsv; done

### I recommend scanning through the table manually. If the two taxonomy strategies give highly conflicting results, you can discard the sequence after checking it manually, or re-label it manually if you are confident that the sequence is not a chimera. 

