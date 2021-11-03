#!/usr/bin/perl
# taxonomy_merge.pl script. Custom script used in the curation pipeline for PacBio reads as descibed in Jamy et al. 2019
# By Mahwash

use strict;
use warnings;

die "\nmerges the taxonomies from the two phylogenetic strategies and generates a consensus.\n\nUsage: perl taxonomy_merge.pl <strategy1.results.tsv> <strategy2.results.tsv> <confidence_threshold> <output file>\n\n" unless @ARGV == 4;

my ($comp_tax, $epa_tax, $conf_threshold, $output) = @ARGV;


my $seq = "";
my $taxonomy = "";
my $confidence = "";
my @tax_ranks = ();
my @conf_ranks = ();


# Filter the epa_taxonomy so that it is above the confidence threshold. Output this to a temp  file.
my @conf_filtered = ();
my @tax_filtered = ();
my $size = "";
my $filename = "filtered_taxonomy.tsv";

open (my $in_epa, "<$epa_tax") or die "error opening $epa_tax for reading";
open (my $temp, ">$filename") or die "error opening $filename for writing";

while (my $line = <$in_epa>) {
	chomp $line;
	($seq, $taxonomy, $confidence) = split("\t", $line);
	@tax_ranks = split(";", $taxonomy);				# split into array
	@conf_ranks = split(";", $confidence);				# split into array
	@conf_filtered = grep { $_ > $conf_threshold } @conf_ranks;	# keep only confidence ranks above user defined threshold
	$size = @conf_filtered;						# get number of elements in confidence_filtered array
	@tax_filtered = @tax_ranks[0 .. $size-1];			# get the corresponding elements from the taxonomy file
	print $temp "$seq\t" . join(';', @tax_filtered) . "\t" . join(';', @conf_filtered) . "\n";
}

close $in_epa;
close $temp;


# Open the comprehensive taxonomy file and create a hash where the header (sequence id) points to an array (taxonomy)
my %comp_tax = ();

open (my $in_comp, "<$comp_tax") or die "error opening $comp_tax for reading";

while (my $line = <$in_comp>) {
	chomp $line;
	($seq, $taxonomy) = split("\t", $line);
	@tax_ranks = split(";", $taxonomy);
	$comp_tax{$seq} = [@tax_ranks];
}

close $in_comp;

# Do the same for the filtered taxonomy file
my %epa_tax = ();
my %epa_conf =();

open (my $in_epa_filt, "<$filename") or die "error opening $filename for reading";

while (my $line = <$in_epa_filt>) {
	chomp $line;
	($seq, $taxonomy, $confidence) = split("\t", $line);
	@tax_ranks = split(";", $taxonomy);
	@conf_ranks = split(";", $confidence);
	$epa_tax{$seq} = [@tax_ranks];
	$epa_conf{$seq} = [@conf_ranks];
}


close $in_epa_filt;


# Get the intersection of the arrays (taxonomy)
use Array::Utils qw(:all);

open (my $out, ">$output") or die "error opening $output for writing";

foreach my $seq (keys %epa_tax) {
	if (exists $comp_tax{$seq}) {
		my @intersection = intersect(@{ $epa_tax{$seq} }, @{ $comp_tax{$seq} });
		$size = @intersection;
		print $out "$seq\t" . join(';', @intersection) . "\t" . join(';', @{$epa_conf{$seq}}[0 .. $size-1]) . "\n";
	}
}

close $out;

		
