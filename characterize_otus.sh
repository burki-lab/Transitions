#!/bin/bash

# usage: characterize_otus.sh <path to directory containing otu file labelled: 18S.otus.nonchimeras.fasta>

DIR=$1
SUBJECTS="PR2/v4.12.0/pr2-plus-extra-seqs_3ndf_1510R.fasta"
THREADS=12

### change to right directory
cd $DIR

## make another folder called otus and enter it
mkdir otus
cd otus
ln -s ../18S.otus.nonchimeras.fasta .

### log
exec > characterize_otus.log 2>&1

### trim the 18S sequences with the primer 1510R. This is os that you can use a global alignment strategy against the PR2 database (trimmed with 3ndf and 1510R database)
cutadapt --minimum-length 32 -a GTAGGTGAACCTGCRGAAGG -O 12 -e 0.25 18S.otus.nonchimeras.fasta > 18S.otus_1510R.fasta

### run vsearch
vsearch --usearch_global 18S.otus_1510R.fasta --threads "${THREADS}" --dbmask none --qmask none --rowlen 0 --notrunclabels --userfields query+id1+target --maxaccepts 0 --maxrejects 32 --top_hits_only --output_no_hits --db "${SUBJECTS}" --id 0.5 --iddef 1 --userout 18S.otus.vsearch.out

### Summarize output
cat 18S.otus.vsearch.out | cut -f1,2 | uniq | cut -f2 > vsearch_per_id.txt

echo VSEARCH DONE!


## Get information about OTU abundance
cat 18S.otus.fasta | grep ">" | sed -E 's/>(.*)_(.*)/\1\t\2/' > abundances.txt


## Get information about sequence lengths
### 18S first!
seqkit fx2tab --length --name --header-line 18S.otus.nonchimeras.fasta | cut -f1,4 > 18S.lengths.txt

### 28S seqs
ln -s ../28S.otus.nonchimeras.fasta .
seqkit fx2tab --length --name --header-line 28S.otus.nonchimeras.fasta | cut -f1,4 > 28S.lengths.txt

### Full length seq
cd ..
grep ">" 18S.otus.nonchimeras.fasta | sed -E 's/>(.*)_Otu.*/\1/' > 18S.otus.list
cat *.preclusters.ng.fasta; do seqkit grep -f 18S.otus.list $i > otus/rrna.otus.fasta

cd otus
seqkit fx2tab --length --name --header-line rrna.otus.fasta | cut -f1,4 > rrna.lengths.txt

