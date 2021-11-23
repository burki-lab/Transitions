#!/usr/bin/perl
# connected_component_sd.pl
# By Mahwash Jamy
use strict;
use warnings;

die "\nFind the number of connected components containing surface only seqs, freshwater only seqs, or both, at varying identity thresholds. \n\nUsage: connected_component_sd.pl <nodes file> <id threshold> <output>\n\n" unless @ARGV == 3;

my ($input, $id, $output) = @ARGV;

my $cc = 1;
my $node = "";
my @array = ();
my $surface = 0;
my $deep = 0;
my $both = 0;

# Open input table and start parsing
open(my $table, "<$input") or die "error opening $input for reading";
my $header = <$table>; 		#skip the first line

while (my $line = <$table>) {
	my @fields = split("\t", $line);
	my $first = $fields[0];
	if ( $first == $cc ) {
		push @array, "$fields[1]";
	} else {
		if (grep(/surface/, @array) && not grep(/freshwater/ || /soil/ || /deep/, @array)) {
			$surface++;
		} elsif (grep(/deep/, @array) && not grep(/freshwater/ || /surface/ || /soil/,  @array)) {
			$deep++;
		} elsif (grep(/surface/ || /deep/, @array) && not grep(/freshwater/ || /soil/, @array)) {
			$both++;
		}
		$cc++;
		@array = ();
		my @fields = split("\t", $line);
		push @array, "$fields[1]";
	}
}

## repeat to process last connected component
if (grep(/surface/, @array) && not grep(/freshwater/ || /soil/ || /deep/, @array)) {
	$surface++;
} elsif (grep(/deep/, @array) && not grep(/freshwater/ || /surface/ || /soil/,  @array)) {
	$deep++;
} elsif (grep(/surface/ || /deep/, @array) && not grep(/soil/ || /freshwater/, @array)) {
	$both++;
}

close $table;

# Open output file and write the column headings
open(my $out, ">$output") or die "error opening $output for writing";
print $out "$id\tsurface\t$surface\n$id\tdeep\t$deep\n$id\tboth\t$both\n";

close $out;
