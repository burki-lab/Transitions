#!/bin/bash

# usage: surface-deep.sh <pairwise_distance txt file> <output>

IN=$1
OUT=$2

awk '{if($1~/surface/ && $2~/surface/) {print}}' $IN | sed -E 's/(.*)/\1\tsame/' >> $OUT
awk '{if($1~/deep/ && $2~/deep/) {print}}' $IN | sed -E 's/(.*)/\1\tsame/' >> $OUT
awk '{if($1~/surface/ && $2~/deep/) {print}}' $IN | sed -E 's/(.*)/\1\tdifferent/' >> $OUT
awk '{if($1~/deep/ && $2~/surface/) {print}}' $IN | sed -E 's/(.*)/\1\tdifferent/' >> $OUT
