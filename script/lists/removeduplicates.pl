#!/usr/bin/perl
 
 open (FILE, 'ergos.txt');
  open (CONVERTFILE, '>>ergos2.txt');
 %remamigo = ();
 while (<FILE>) {
	 chomp;
	 $remamigo{$_}++;
	 
 }
foreach $key (sort (keys(%remamigo))) {
	
	print CONVERTFILE "$key\n";
	
	
	}
 
 close (FILE);
  close (CONVERTFILE);
  exit;
