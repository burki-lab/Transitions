#!/usr/bin/perl
# otu_affiliation.pl
# By Mahwash Jamy
use strict;
use warnings;

use List::Util qw(sum);

die "\nFind the environmental affiliation of each OTU. Hard coded to work with the specific output from my PacBio samples.\n\nUsage: otu_affiliation.pl <transposed OTU table> <output>\n\n" unless @ARGV == 2;

my ($input, $output) = @ARGV;

# Open output file and write the column headings
open(my $out, ">$output") or die "error opening $output for writing";
print $out "OTU\ttotal_abundance\tmar_abundance\tterr_abundance\taffiliation\tratio\n";

# Open input table and start parsing
open(my $table, "<$input") or die "error opening $input for reading";

my $affiliation = "";
my $ratio = "";

while (my $line = <$table>) {
	my @fields = split("\t", $line);
	my $otu = $fields[0];
	my $total_ab = sum @fields[1..21];
	my $mar_ab = sum @fields[3, 4, 5, 6, 7, 8, 9, 10, 18];
	my $terr_ab = sum @fields[1, 2, 11, 12, 13, 14, 15, 16, 17, 19, 20, 21];
	if ( $mar_ab > $terr_ab ) {
		$affiliation = "marine"; 
		$ratio = ($mar_ab / $total_ab);
	} else { 
		$affiliation = "terrestrial";
		$ratio = ($terr_ab / $total_ab);
	}

	# print it all out for the line
	print $out "$otu\t$total_ab\t$mar_ab\t$terr_ab\t$affiliation\t$ratio\n";
}

close $table;
close $out;
