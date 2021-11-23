#!/usr/bin/perl
# connected_component_mt.pl
# By Mahwash Jamy
use strict;
use warnings;

die "\nFind the number of connected components containing marine only seqs, terrestrial only seqs, or both, at varying identity thresholds. \n\nUsage: connected_component_mt.pl <nodes file> <id threshold> <output>\n\n" unless @ARGV == 3;

my ($input, $id, $output) = @ARGV;

my $temp = "temp.txt";
my $cc = 1;
my $node = "";
my @array = ();
my $terrestrial = 0;
my $marine = 0;
my $both = 0;

# Open temp file for writing
#open(my $out_temp, ">$temp") or die "error creating $temp";

# Open input table and start parsing
open(my $table, "<$input") or die "error opening $input for reading";
my $header = <$table>; #skip the first line

while (my $line = <$table>) {
	my @fields = split("\t", $line);
	my $first = $fields[0];
	if ( $first == $cc ) {
		push @array, "$fields[1]";
	} else {
		if (grep(/freshwater/ || /soil/, @array) && not grep(/surface/ || /deep/, @array)) {
			$terrestrial++;
		} elsif (grep(/surface/ || /deep/, @array) && not grep(/freshwater/ || /soil/, @array)) {
			$marine++;
		} elsif (grep(/surface/ || /deep/, @array) && grep(/freshwater/ || /soil/, @array)) {
			$both++;
		}
		$cc++;
		@array = ();
		my @fields = split("\t", $line);
		push @array, "$fields[1]";
	}
}

## repeat to process last connected component
if (grep(/freshwater/ || /soil/, @array) && not grep(/surface/ || /deep/, @array)) {
	$terrestrial++;
} elsif (grep(/surface/ || /deep/, @array) && not grep(/freshwater/ || /soil/, @array)) {
	$marine++;
} elsif (grep(/surface/ || /deep/, @array) && grep(/freshwater/ || /soil/, @array)) {
	$both++;
}

close $table;

# Open output file and write the column headings
open(my $out, ">$output") or die "error opening $output for writing";
print $out "$id\tterrestrial\t$terrestrial\n$id\tmarine\t$marine\n$id\tboth\t$both\n";

close $out;
