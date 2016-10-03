#!/usr/bin/perl

use strict;
use warnings;

open (NAMES2, '>>./lists/organizacoes2.txt');
open (NAMES, './lists/organizacoes.txt');
while (<NAMES>) {
	chomp;
	print NAMES2 lc($_) . "\n";
}
close (NAMES);
close (NAMES2);
