#!/usr/bin/env Rscript --vanilla

#### log output
log <- file("DADA2.log")
sink(log, append=TRUE)
sink(log, append=TRUE, type="message")

#### Setup

library(dada2);packageVersion("dada2")
library(Biostrings); packageVersion("Biostrings")
library(ggplot2); packageVersion("ggplot2")
library(reshape2); packageVersion("reshape2")
library(tictoc); packageVersion("tictoc")
library(ShortRead); packageVersion("ShortRead")

#### Specify paths and primers
path <- getwd() # CHANGE ME to location of the fastq file
fn <- list.files(path, pattern=".fastq")

F3nd <- "GGCAAGTCTGGTGCCAG"
R21 <- "GACGAGGCATTTGGCTACCTT"

rc <- dada2:::rc
theme_set(theme_bw())


#### Remove primers and orient reads
tic("primers")
nop <- file.path(path, "noprimers", basename(fn))
prim <- removePrimers(fn, nop, primer.fwd=F3nd, primer.rev=dada2:::rc(R21), orient=TRUE, verbose=TRUE)
toc()

#### Inspect length distribution
pdf("length.pdf")
hist(nchar(getSequences(nop)), 100)
dev.off()


#### Filter
tic("filter")
filt <- file.path(path, "filtered", basename(fn))
track <- filterAndTrim(nop, filt, minQ=3, minLen=3000, maxLen=6000, maxN=0, rm.phix=FALSE, maxEE=4, verbose=TRUE)
toc()


#### Export filtered seqs as fasta file
sample <- tools::file_path_sans_ext(basename(fn))
sample_filt <- paste0(sample, ".filtered.fasta")
writeFasta(readFastq(filt), sample_filt, width=20000L)

#### Remove the fastq files we generated earlier to clean up
unlink("filtered", recursive = TRUE)
unlink("noprimers", recursive = TRUE)



quit()
