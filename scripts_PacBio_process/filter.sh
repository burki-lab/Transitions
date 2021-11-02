#!/bin/bash

# usage: filter.sh <path to folder containing fastq>

# Requires that the following softwares are installed:
## R version 3.6.3 or newer
## DADA2 version 1.14 or newer

# parameters
path=$1

# log
exec > $path/filter.log 2>&1

# Go to the right directory
cd $path
pwd

echo Running DADA2...
Rscript DADA2.r

echo Finished filtering sequences

