#!/usr/bin/perl
# replace_fasta_header.pl
# By Mahwash

use strict;
use warnings;

die "\nReplaces fasta headers with ones provided in a tab delimited file.\n\nUsage: replace_fasta_header.pl <fasta file> <tsv> <output>\n\n" unless @ARGV == 3;

my ($fasta, $tsv, $output) = @ARGV;

my %fasta = ();
my $header = "";
my $concatenated_seq = "";
my $header_replace = "";
my %new_header = ();

# Build a hash where the keys (headers in fasta file) point at the sequence
open(my $in_fasta, "<$fasta") or die "error opening $fasta for reading";

while (my $line = <$in_fasta>) {
        if ($line =~ /^>(\s*\S+).*/) {
        $header = $1;
        $concatenated_seq = "";
    }
    else {
                chomp($line);
        $concatenated_seq = $concatenated_seq . $line;
        $fasta{$header} = $concatenated_seq;
    }
}
close $in_fasta;


# Build a hash where the keys (old header) point to the new fasta header
open (my $in_list, "<$tsv") or die "error opening $tsv for reading";
while (my $line = <$in_list>) {
        ($header, $header_replace) = split("\t", $line);
        $new_header{$header} = $header_replace;
}

close $in_list;


# open output file and print out fasta file with new headers
open (my $out, ">$output") or die "error opening $output for writing";

foreach my $header (keys %new_header) {
    if (exists $fasta{$header}) {
        print $out ">$new_header{$header}$fasta{$header}\n";
    }
}

close $out;

