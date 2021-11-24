#!/bin/bash

echo "(((((" > constraint.txt
cat Discosea.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Evosea.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Tubulinea.txt >> constraint.txt
echo ")), ((" >> constraint.txt
cat Apusomonada.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Breviatea.txt >> constraint.txt
echo "), ((((" >> constraint.txt
cat Choanoflagellata.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Metazoa.txt >> constraint.txt
echo ")), (" >> constraint.txt
cat Filasterea.txt >> constraint.txt
echo "), " >> constraint.txt
cat Pluriformea.txt >> constraint.txt
echo ", (" >> constraint.txt
cat Ichthyosporea.txt >> constraint.txt
echo ")), ((" >> constraint.txt
cat Fungi.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Rotosphaerida.txt >> constraint.txt
echo "))))), (" >> constraint.txt
cat CRuMs.txt >> constraint.txt
echo ")), (" >> constraint.txt
cat Picozoa.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Hemimastigophora.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Ancyromonad.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Malawimonad.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Metamonada.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Discoba.txt >> constraint.txt
echo "), (((" >> constraint.txt
cat Chlorophyta.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Streptophyta.txt >> constraint.txt
echo ")), " >> constraint.txt
cat Glaucophyta.txt >> constraint.txt
echo ", " >> constraint.txt
cat Rhodelphea.txt >> constraint.txt
echo "), ((" >> constraint.txt
cat Cryptophyta.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Kathablepharidacea.txt >> constraint.txt
echo ")), ((" >> constraint.txt
cat Centroplasthelida.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Haptophyta.txt >> constraint.txt
echo ")), ((" >> constraint.txt
cat Telonemia.txt >> constraint.txt
echo "), (((" >> constraint.txt
cat Bigyra.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Gyrista.txt >> constraint.txt
echo ")), ((((" >> constraint.txt
cat Apicomplexa.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Colpodellida.txt >> constraint.txt
echo ")), ((" >> constraint.txt
cat Dinoflagellata.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Perkinsea.txt >> constraint.txt
echo "))), (" >> constraint.txt
cat Ciliophora.txt >> constraint.txt
echo ")), ((" >> constraint.txt
cat Cercozoa.txt >> constraint.txt
echo "), ((" >> constraint.txt
cat Foraminifera.txt >> constraint.txt
echo "), (" >> constraint.txt
cat Radiolaria.txt >> constraint.txt
echo "))))));" >> constraint.txt

cat constraint.txt | tr -d '\n' > constraint.txt.tre
