#!/bin/bash

# usage: filter_to_otus.sh <fasta file containing filtered sequences with full path>

# Before using the script, download the SILVA SSU-Ref-NR99 fasta file (v132 or newer). Make a blastdb database, and add the path to the variable DB below. 
# This script also requires two additional perl scripts (available on https://github.com/burki-lab/Transitions): extract_18S-28S.pl and replace_fasta_header.pl

# Requires that the following softwares are installed and in your path:
## vsearch version 2.3.4 or newer
## mafft version 7.310 or newer
## mothur version 1.39.5 or newer
## ncbi-blast+ version 2.9.0-2 or newer
## barrnap version 0.9 or later
## perl v5.30.0 or later

VAR=$1
DIR=$(dirname "${VAR}")
BASE=$(basename "${VAR}") 
SAMPLE="${BASE%.*}"
THREADS=12
DB="SILVA/v132/SILVA_132_SSURef_Nr99_tax_silva_trunc.db"  ## change me to the correct path!
EXTRACT="scripts/extract_18S-28S.pl"  ## change me to the correct path!
REPLACE="scripts/replace_fasta_header.pl" ## change me to the correct path!


### log
exec > $DIR/filter_to_otus.log 2>&1

### change to right directory
cd $DIR

### Start by preclustering all filtered sequences!
echo
echo =====================================
echo "Preclustering all sequences (99% id)"
echo =====================================
echo

mkdir preclusters
vsearch --cluster_fast $BASE --id 0.99 --threads "${THREADS}" --clusters preclusters/precluster.c- --uc precluster.uc

### Separate preclusters > 2 sequences
mkdir preclusters/large_preclusters
cd preclusters
for i in precluster.c-*; do number=$(grep -c ">" $i); if (($number > 2)); then mv $i large_preclusters/; fi; done
cd large_preclusters

### construct count table for chimera detection downstream
for i in precluster.c-*; do x=$(echo $i | cut -d '.' -f2); count=$(grep -c ">" $i); echo -e ""$x"_conseq\t"$count"" >> $SAMPLE.count_table; done
mv $SAMPLE.count_table ./..

### Align large preclusters with mafft (takes too long for clusters with several hundred thousand seqs - so I use only the first 10,000 seqs in a cluster for aligning)
echo "Aligning large preclusters ..."
echo
for i in precluster.c-*; do if [ $(grep -c ">" $i) -lt 10000 ]; then mafft --quiet --thread "${THREADS}" $i > $i.aligned.fasta; else mafft --quiet --thread "${THREADS}" <(seqkit head -n 1000 $i) > $i.aligned.fasta; fi; done

### Generate majority rule consensus sequences
for i in *.aligned.fasta; do mothur -q "#consensus.seqs(fasta=$i, cutoff=51)"; done
rm mothur*

### Change header name so that it is informative
for i in *.aligned.cons.fasta; do x=$(echo $i | cut -d '.' -f2); sed -i -E "s/(>)(.*)/\1${x}_\2/" $i; done

### mv consensus sequences fasta files back to the parent folder
mv *.aligned.cons.fasta ./..
cd ..
cat precluster.c-* > $SAMPLE.preclusters.fasta

### add small-preclusters to count table
grep ">m" $SAMPLE.preclusters.fasta | while read line; do header=$(echo $line | sed -E 's/>(.*)/\1/'); echo -e "$header\t1" >> $SAMPLE.count_table; done
echo -e "Representative_Sequence\ttotal" | cat - $SAMPLE.count_table > temp && mv temp $SAMPLE.count_table
mv $SAMPLE.count_table ./..
mv $SAMPLE.preclusters.fasta ./..
cd ..


### degap sequences
mothur "#degap.seqs(fasta=$SAMPLE.preclusters.fasta)"

echo Total number of preclusters: $(cat $SAMPLE.preclusters.ng.fasta | grep -c "^>")


### Remove prokaryotic sequences by BLASTING against SILVA
echo
echo =====================================
echo Removing prokaryotes
echo =====================================
echo

blastn -query $SAMPLE.preclusters.ng.fasta -db $DB -evalue 1e-10 -num_threads "${THREADS}" -out $SAMPLE.preclusters.ng_vs_Silva.blastn -outfmt '6 std salltitles'

cat $SAMPLE.preclusters.ng_vs_Silva.blastn | sort -k1,1 -k12,12nr |	awk '!seen[$1]++' > tophit.$SAMPLE.preclusters.ng_vs_Silva.blastn

cat tophit.$SAMPLE.preclusters.ng_vs_Silva.blastn | grep -v "Eukaryota" | cut -f 1 > prok.list

echo Number of prokaryotic preclusters: $(wc -l prok.list)
echo

mothur -q "#remove.seqs(fasta=$SAMPLE.preclusters.ng.fasta, count=$SAMPLE.count_table, accnos=prok.list)"

echo Number of preclusters after filtering out prokaryotes: $(cat $SAMPLE.preclusters.ng.pick.fasta | grep -c "^>")
echo Number of sequences represented: $(cat $SAMPLE.pick.count_table | grep -v "total" | awk '{sum += $2} END {print sum}')


### Only keep sequences with one copy of 18S and 28S
echo
echo =====================================
echo Removing siameras and incomplete seqs
echo =====================================
echo

barrnap --threads "${THREADS}" --reject 0.4 --kingdom euk $SAMPLE.preclusters.ng.pick.fasta > barrnap.gff

cat barrnap.gff | grep "+" | grep "18S" | cut -f 1 | sort | uniq -u > barrnap.18S.list
cat barrnap.gff | grep "+" | grep "28S" | cut -f 1 | sort | uniq -u > barrnap.28S.list

comm -12 barrnap.18S.list barrnap.28S.list > barrnap.comm.list

echo "Extracting seqs with 18S and 28S ..."
mothur -q "#get.seqs(accnos=barrnap.comm.list, fasta=$SAMPLE.preclusters.ng.pick.fasta, count=$SAMPLE.pick.count_table)"

echo Number of preclusters after filtering out siameras and incomplete seqs: $(cat $SAMPLE.preclusters.ng.pick.pick.fasta | grep -c "^>")
echo Number of sequences represented: $(cat $SAMPLE.pick.pick.count_table | grep -v "total" | awk '{sum += $2} END {print sum}')

echo
echo =====================================
echo Removing chimeras
echo =====================================
echo

### chimera detection (increase number of chunks so it is more compatible with long seqs)
mothur -q "#chimera.uchime(fasta=$SAMPLE.preclusters.ng.pick.pick.fasta, count=$SAMPLE.pick.pick.count_table, reference=self, chunks=20, abskew=1.5, chimealns=T)"

mothur -q "#remove.seqs(fasta=$SAMPLE.preclusters.ng.pick.pick.fasta, count=$SAMPLE.pick.pick.count_table, accnos=$SAMPLE.preclusters.ng.pick.pick.denovo.uchime.accnos)"

echo Number of chimeras detected: $(wc -l $SAMPLE.preclusters.ng.pick.pick.denovo.uchime.accnos)
echo Number of preclusters left: $(cat $SAMPLE.preclusters.ng.pick.pick.pick.fasta | grep -c "^>")
echo Number of sequences represented: $(cat $SAMPLE.pick.pick.pick.count_table | grep -v "total" | awk '{sum += $2} END {print sum}')

echo
echo =====================================
echo Extract 18S and 28S
echo =====================================
echo

### Finally, extract 18S and 28S from each sequence

perl $EXTRACT barrnap.gff $SAMPLE.preclusters.ng.pick.pick.pick.fasta 18S.fasta 28S.fasta

echo Sanity check..
echo
echo Number of 18S sequences: $(cat 18S.fasta | grep -c ">")
echo Number of 28S sequences: $(cat 28S.fasta | grep -c ">")
echo

echo
echo =====================================
echo "Cluster into OTUs (97% id)"
echo =====================================
echo

mothur -q "#cluster(fasta=18S.fasta, count=$SAMPLE.pick.pick.pick.count_table, method=agc)"

echo Number of clusters: $(cat 18S.agc.unique_list.list | cut -f 1,2)
echo

mothur -q "#get.oturep(count=$SAMPLE.pick.pick.pick.count_table, list=18S.agc.unique_list.list, label=0.03, fasta=18S.fasta, method=abundance)"
echo

echo "Removing singletons.."

cat 18S.agc.unique_list.0.03.rep.fasta | grep -E "Otu[0-9]+\|1$" | tr -d '>' > singletons.list
echo

echo Number of singletons: $(wc -l singletons.list)
echo
mothur -q "#remove.seqs(fasta=18S.agc.unique_list.0.03.rep.fasta, count=18S.agc.unique_list.0.03.rep.count_table, accnos=singletons.list)"
echo

cat 18S.agc.unique_list.0.03.rep.pick.fasta | sed -E 's/(>.*)\t(.*)/\1_\2/' | tr '|' '_' > 18S.otus.fasta

echo Number of non-singleton OTUs: $(cat 18S.otus.fasta | grep -c ">")
echo
echo Number of representative sequences: $(cat 18S.agc.unique_list.0.03.rep.pick.count_table | grep -v "total" | awk '{sum += $2} END {print sum}')
echo

echo
echo =====================================
echo Get 28S OTUs file
echo =====================================
echo

## Basically get the 28S counterpart seqs to the 18S OTU representatives

cat 18S.otus.fasta | grep ">" | sed -E 's/>(.*)_Otu[0-9]+_[0-9]+/\1/' > 18S.otus.list
mothur -q "#get.seqs(accnos=18S.otus.list, fasta=28S.fasta)"

## Change the fasta headers to include the OTU number so the 18S and 28S seqs have the exact same header.
cat 18S.otus.fasta | grep ">" | sed -E 's/>(.*)(_Otu[0-9]+_[0-9]+)/\1\t\1\2/' > replace_headers.list
perl $REPLACE 28S.pick.fasta replace_headers.list 28S.otus.fasta

echo Sanity check..
echo
echo Number of 18S OTUs: $(cat 18S.otus.fasta | grep -c ">")
echo Number of 28S OTUs: $(cat 28S.otus.fasta | grep -c ">")
echo

### Another chimera detection
echo
echo ===================================
echo "Chimera detection at OTU level"
echo ===================================
echo

## Change fasta headers to work with vsearch
cat 18S.otus.fasta | sed -E 's/(>.*_Otu[0-9]+)_([0-9]+)/\1;size=\2/' > 18S.otus.fasta.vsearchformat
cat 28S.otus.fasta | sed -E 's/(>.*_Otu[0-9]+)_([0-9]+)/\1;size=\2/' > 28S.otus.fasta.vsearchformat

## Chimera detection
vsearch --uchime_denovo 18S.otus.fasta.vsearchformat --uchimealns 18S.otus.denovo.uchimealns --uchimeout 18S.otus.denovo.uchimeout --minh 1 --mindiv 1.5
vsearch --uchime_denovo 28S.otus.fasta.vsearchformat --uchimealns 28S.otus.denovo.uchimealns --uchimeout 28S.otus.denovo.uchimeout --minh 1 --mindiv 1.5

cat 18S.otus.denovo.uchimeout | grep -E "Y$" | cut -f2 | sort -u > 18S.otus.chimeras.list
cat 28S.otus.denovo.uchimeout | grep -E "Y$" | cut -f2 | sort -u > 28S.otus.chimeras.list

echo Number of 18S chimeras: $(wc -l 18S.otus.chimeras.list)
echo Number of 28S chimeras: $(wc -l 28S.otus.chimeras.list)

## How many of the chimeras are common? 
echo Number of chimeras common: $(grep -f 28S.otus.chimeras.list 18S.otus.chimeras.list | wc -l)

cat 18S.otus.chimeras.list 28S.otus.chimeras.list | sort -u > chimeras.list

## Clean OTUs files
cat 18S.otus.fasta.vsearchformat | seqkit grep -f chimeras.list -v | sed -E 's/(>.*);size=(.*)/\1_\2/' > 18S.otus.nonchimeras.fasta
cat 28S.otus.fasta.vsearchformat | seqkit grep -f chimeras.list -v | sed -E 's/(>.*);size=(.*)/\1_\2/' > 28S.otus.nonchimeras.fasta


echo Number of 18S OTUs: $(cat 18S.otus.nonchimeras.fasta | grep -c ">")
echo Number of 28S OTUs: $(cat 28S.otus.nonchimeras.fasta | grep -c ">")

echo DONE!


