#!/usr/bin/perl
# connected_component_fs.pl
# By Mahwash Jamy
use strict;
use warnings;

die "\nFind the number of connected components containing freshwater only seqs, soil only seqs, or both, at varying identity thresholds. \n\nUsage: connected_component_fs.pl <nodes file> <id threshold> <output>\n\n" unless @ARGV == 3;

my ($input, $id, $output) = @ARGV;

my $cc = 1;
my $node = "";
my @array = ();
my $freshwater = 0;
my $soil = 0;
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
		if (grep(/freshwater/, @array) && not grep(/surface/ || /soil/ || /deep/, @array)) {
			$freshwater++;
		} elsif (grep(/soil/, @array) && not grep(/freshwater/ || /surface/ || /deep/,  @array)) {
			$soil++;
		} elsif (grep(/freshwater/ || /soil/, @array) && not grep(/surface/ || /deep/, @array)) {
			$both++;
		}
		$cc++;
		@array = ();
		my @fields = split("\t", $line);
		push @array, "$fields[1]";
	}
}

## repeat to process last connected component
if (grep(/freshwater/, @array) && not grep(/surface/ || /soil/ || /deep/, @array)) {
	$freshwater++;
} elsif (grep(/soil/, @array) && not grep(/freshwater/ || /surface/ || /deep/,  @array)) {
	$soil++;
} elsif (grep(/freshwater/ || /soil/, @array) && not grep(/surface/ || /deep/, @array)) {
	$both++;
}

close $table;

# Open output file and write the column headings
open(my $out, ">$output") or die "error opening $output for writing";
print $out "$id\tfreshwater\t$freshwater\n$id\tsoil\t$soil\n$id\tboth\t$both\n";

close $out;
