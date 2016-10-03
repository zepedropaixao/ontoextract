#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use POSIX;

sub ParseLineAbstractNTLine($) {
	my $line = shift;
	
	# ex: <http://dbpedia.org/resource/Albergaria-a-Velha> <http://www.w3.org/2000/01/rdf-schema#comment> "Albergaria-a-Velha

	## Let's extract the title
	$line =~/resource\/(.*)\> <http\:/;
	my $title = $1;
	$title =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	$title =~ s/_/ /g;
	$title =~ s/\s{0,1}\(.+?\)//i;
	
	## And now for the abstract   
	$line =~ /\> \"(.*)\"\@/;
	my $abstract = $1;
	$abstract =~ s/\\u00(..)/pack('C', hex($1))/seg;
	Encode::from_to($abstract, "iso-8859-1", "utf8");         
	
	## Output
	my %out = ();
	$out{title} = $title;
	$out{abstract} = $abstract;
	return %out;
}

sub ParseDBpedia {
open (WIKIPEDIA, './lists/dbpedia/wikipedia_links_pt.nt');
while (<WIKIPEDIA>) {
	my $line = $_;
	my %line_hash = ParseLineAbstractNTLine($line);
	print "$line_hash{title} <=!=> $line_hash{abstract}\n";	
}
close (WIKIPEDIA);
}

sub start {
open (STDOUT, '>>resultados_maluco.nt');
ParseDBpedia();
close (STDOUT);
}

start();
