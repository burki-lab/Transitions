#!/bin/bash

# usage: bash taxonomy_round2.sh

# Requires that the following softwares are installed and in your path:
## raxml-ng version 0.9.0 or newer
## mafft version 7.310 or newer
## trimal version 1.2rev59 or newer
## seqkit version 0.15.0 or newer

DIR="env_seq/taxonomy"	## change me to the directory containing all examined tree files (i.e. all artefactual taxa marked).

cd $DIR

### log
exec > taxonomy_round2.log 2>&1

## remove mislabelled sequences, nucleomorphs, and weird OTUs (extremely long branches) (These are branches that are coloured blue, green and magenta respectively)
### grep for coloured sequences from round1 tree and compile them in a list
### I assume that your files are labelled as RAxML_fastTreeSH_Support.{sample}.tre
for i in RAxML_fastTreeSH_Support.*; do base=$(echo $i | awk -F '.' '{print $2}'); cat $i | grep -E "color=#0000ff|color=#00ff00|color=#ff00ff" | tr -d "'" | sed -E 's/\t(.*)\[.*\]/\1/' > "$base".remove.list; done

### How many sequences are to be removed for every dataset/sample?
echo Number of sequences to be removed: $(wc -l *remove.list)
echo

### Original number of sequences in fasta files
echo Number of sequences to be removed: $(grep -c ">" *.18S.otus.ref.fasta)
echo

### Remove mislabelled seqs, nucleomorphs etc.
for i in *18S.otus.ref.fasta; do base=$(echo $i | awk -F '.' '{print $1}'); cat $i | seqkit grep -f "$base".remove.list -v > "$base".18S.otus.ref.clean.fasta; done

### Number of sequences after removing artifacts:
echo Number of sequences to be remaining: $(grep -c ">" *.18S.otus.ref.clean.fasta)
echo

### NB: if the remove.list file is empty, you will get an error. In my case the MT.remove.list file was empty, which resulted in the MT.18S.otus.ref.clean.fasta file to be empty.
for i in *.18S.otus.ref.clean.fasta; do base=$(echo $i | awk -F '.' '{print $1}'); seqs=$(cat $i | grep -c ">"); if [ $seqs -eq 0 ]; then echo $i; cp "$base".18S.otus.ref.fasta $i; fi; done
grep -c ">" *.18S.otus.ref.clean.fasta

## align and trim!
parallel --jobs 4 'mafft --retree 2 --maxiterate 1000 --thread -10 --reorder --adjustdirection {} > {/.}.mafft.fasta' ::: *18S.otus.ref.clean.fasta

parallel --jobs 6 'trimal -in {} -out {/.}.trimal.fasta -gt 0.01 -st 0.001' ::: *18S.otus.ref.clean.mafft.fasta

for i in *trimal.fasta; do cat $i | sed -E 's/(.*) [0-9]+ bp/\1/' | tr -d ';:()[]' > fasta; mv fasta $i; done

## Run raxml-ng trees
for i in *18S.otus.ref.clean.mafft.fasta; do sample=$(echo $i | awk -F '.' '{print $1}'); raxml-ng --search --msa $i --model GTR+G --prefix "$sample" --threads 3; done

## Inspect the best trees. You may need to clean trees and repeat this step again.

