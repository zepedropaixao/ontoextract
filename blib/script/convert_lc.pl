#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

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
