#!/bin/bash

# usage: fw-soil.sh <pairwise_distance txt file> <output>

IN=$1
OUT=$2

awk '{if($1~/freshwater/ && $2~/freshwater/) {print}}' $IN | sed -E 's/(.*)/\1\tsame/' > $OUT
awk '{if($1~/soil/ && $2~/soil/) {print}}' $IN | sed -E 's/(.*)/\1\tsame/' >> $OUT
awk '{if($1~/soil/ && $2~/freshwater/) {print}}' $IN | sed -E 's/(.*)/\1\tdifferent/' >> $OUT
awk '{if($1~/freshwater/ && $2~/soil/) {print}}' $IN | sed -E 's/(.*)/\1\tdifferent/' >> $OUT


