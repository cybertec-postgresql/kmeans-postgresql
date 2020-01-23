#!/usr/bin/perl --

use strict;
use warnings;

use Getopt::Std;

sub check_prereq{
	if( !`which gnuplot` ){
		die "gnuplot needs installed in \$PATH$/";
	}
	if( !`which psql` ){
		die "psql needs installed in \$PATH$/";
	}
}

sub usage{
	print STDERR <<_HELP;
Usage: $0 [-h] [-d dbname] [-k number] [-t]
	-h:	print this help
	-d:	database to connect
	-k:	number of class
	-t:	output ascii
_HELP
	0;
}

sub main{
	&check_prereq();
	my %opt;

	getopts('hd:k:t', \%opt);

	if( $opt{'h'} ){
		return &usage;
	}
	my $dbname = $opt{'d'} || "db1";
	my $k = $opt{'k'} || 5;
	my $sql = <<_SQL;

SELECT kmeans(ARRAY[val1, val2], $k) OVER (), val1, val2
FROM testdata
ORDER BY 1
_SQL
	open my $fh, "-|", qq(psql -U postgres -A -F ' ' -t -c "$sql" $dbname) or die $!;
	open my $out, ">", "tmp.dat" or die $!;
	my $prev_k = 0;
	while( <$fh> ){
		chomp;
		my( $k, $v1, $v2 ) = split / /, $_;
		if( $k != $prev_k ){
			print $out "\n\n";
			$prev_k = $k;
		}
		print $out "$v1 $v2\n";
	}
	close $out;
	close $fh;

	my @buf;
	for my $i ( 0 .. $prev_k ){
		push @buf,  "\"tmp.dat\" index $i:$i using 1:2";
	}
	if( $opt{'t'} ){
		my $plotcmd = 'gnuplot -e \'set terminal dumb; set key outside;  plot ' . join( ", ", @buf ) . '; exit\'';
		system($plotcmd);
	}
	else{
		my $plotcmd2 = 'gnuplot -e \' plot ' . join( ", ", @buf ) . '; exit\'';
		system($plotcmd2);
		#print $plotcmd2 . $/;
	}
}

if( $0 eq __FILE__ ){
	&main( @ARGV );
}

