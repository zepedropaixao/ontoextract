#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use POSIX;

sub ParseLineAbstractNTLine($) {
	my $line = shift;
	
	# ex: <http://dbpedia.org/resource/Albergaria-a-Velha> <http://www.w3.org/2000/01/rdf-schema#comment> "Albergaria-a-Velha
	
	
	if($line =~ /^<http\:\/\/pt/){next;}

	## Let's extract the title

	$line =~/\<http\:\/\/xmlns(.*)\> \<(http\:(.*)\/wiki\/(.*))\>/;
	my $url = $2;
	my $title = $4;
	$title =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	$title =~ s/_/ /g;
	$title =~ s/\s{0,1}\(.+?\)//i;
	
	## And now for the abstract 
	$url =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
	#$url =~ s/\\u00(..)/pack('C', hex($1))/seg;
	$url =~ s/\s{0,1}\(.+?\)//i;
	Encode::from_to($url, "iso-8859-1", "utf8");         
	
	## Output
	my %out = ();
	$out{title} = $title;
	$out{url} = $url;
	return %out;
}

sub ParseDBpedia {
open (WIKIPEDIA, './lists/dbpedia/wikipedia_links_pt.nt');
while (<WIKIPEDIA>) {
	my $line = $_;
	if($line =~ /^<http\:\/\/pt/){next;}
	my %line_hash = ParseLineAbstractNTLine($line);
	print "$line_hash{title} <=!=> $line_hash{url}\n";	
}
close (WIKIPEDIA);
}

sub start {
open (STDOUT, '>>resultados_maluco.nt');
ParseDBpedia();
close (STDOUT);
}

start();
