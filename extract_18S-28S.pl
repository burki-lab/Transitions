#!/usr/bin/perl
# extract_rrna.pl
# By Mahwash

use strict;
use warnings;

die "\nTakes in fasta file with PacBio reads and extracts the 18S and 28S genes based on barrnap predictions.\n\nUsage: extract_rrna.pl <barrnap file> <fasta file> <18S output> <28S output>\n\n" unless @ARGV == 4;

my ($barrnap, $fasta, $SSUout, $LSUout) = @ARGV;

my %fasta = ();
my $header = "";
my $concatenated_seq = "";
my %blast_coords = ();
my @columns = ();
my $start = ();
my $end = ();
my %barrnap_18S = ();
my %barrnap_28S = ();


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


# Build a hash where the keys (seq_id in barrnap file) point at an array containing the start and end coordinates
open (my $in_barrnap, "<$barrnap") or die "error opening $barrnap for reading";
while (my $line = <$in_barrnap>) {
    if ($line =~ /18S_rRNA/) {
        @columns = split("\t", $line);
        ($header, $start, $end) = ($columns[0], ($columns[3] - 1), $columns[4]);
        $barrnap_18S{$header} = [$start, $end];
    }elsif ($line =~ /28S_rRNA/) {
        @columns = split("\t", $line);
        ($header, $start, $end) = ($columns[0], ($columns[3] - 1), $columns[4]);
        $barrnap_28S{$header} = [$start, $end];
    }
}
        
close $in_barrnap;


# open output file and extract 18S sequences using the substr function
open (my $output18S, ">$SSUout") or die "error opening $SSUout for writing";

foreach my $header (keys %barrnap_18S) {
    if (exists $fasta{$header}) {
        print $output18S ">$header\n";
        my $seq = substr($fasta{$header}, 0, $barrnap_18S{$header}[1]);
        print $output18S "$seq\n";
        }                     
}


close $output18S;



# open output file and extract rrna sequences using the substr function
open (my $output28S, ">$LSUout") or die "error opening $LSUout for writing";

foreach my $header (keys %barrnap_28S) {
    if (exists $fasta{$header}) {
        print $output28S ">$header\n";
        my $seq = substr($fasta{$header}, $barrnap_28S{$header}[0]);
        print $output28S "$seq\n";
        }       
}

close $output28S;
