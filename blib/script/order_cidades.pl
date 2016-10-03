#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell
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
