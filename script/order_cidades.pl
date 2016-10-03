#!/usr/bin/perl
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN, ':encoding(UTF-8)';
use open ':encoding(UTF-8)';

 open (FILE, 'paises.txt');
 open (CONVERTFILE, '>>paises2.txt');

my %pattern = ();
while (<FILE>) {
	#print "BLA\n";
	chomp;
	$pattern{$_}++;	
}
foreach my $key (sort keys %pattern) {
	print CONVERTFILE "$key\n";
}
		
close (PAISES);
 close (FILE);
 close (CONVERTFILE);
 exit;
