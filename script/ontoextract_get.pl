#!/usr/bin/perl
# script/get.pl

use strict;
use warnings;
use POSIX;
use String::Approx 'adistr';
use utf8;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN, ':encoding(UTF-8)';
use open ':encoding(UTF-8)';

# allow for running from root directory or from script directory
use lib qw / lib ..\/lib /;

use OntoExtract::Model::ontoextract;
use OntoExtract::Schema;

our $schema;
our $url_store_number = 30;
our %DBpedia_abstracts;
our %DBpedia_links;
our %DBpedia_images;
our %name_pattern;
our %ergo_pattern;
our %org_pattern;
our %pattern_matches;
our %org_types;

sub parse_dbpedia {
open (ABSTRACTS, './lists/dbpedia/short_abstracts_pt_utf8.nt');
while (<ABSTRACTS>) {
	chomp;
	my $line = $_;
	## Let's extract the title
	$line =~/^(.*) <=!=> (.*)/;
	my $title = $1;
	my $abstract = $2;   
	
	## Output
	#print "$title ===> $abstract\n";
	$DBpedia_abstracts{$title} = $abstract;
}
close (ABSTRACTS);

open (LINKS, './lists/dbpedia/wikipedia_links_pt_utf8.nt');
while (<LINKS>) {
	chomp;
	my $line = $_;
	## Let's extract the title
	$line =~/^(.*) <=!=> (.*)/;
	my $title = $1;
	my $url = $2;   
	
	## Output
	#print "$title ===> $abstract\n";
	$DBpedia_links{$title} = $url;
}
close (LINKS);


open (IMGS, './lists/dbpedia/images_utf8.nt');
while (<IMGS>) {
	chomp;
	my $line = $_;
	## Let's extract the title
	$line =~/^(.*) <=!=> (.*)/;
	my $title = $1;
	my $url = $2;   
	
	## Output
	#print "$title ===> $abstract\n";
	if($title && $url){
		$DBpedia_images{$title} = $url;
	}
}
close (IMGS);



}

sub create_pattern_matches {
	my ($against) = @_;
	%pattern_matches = (
	qr/[\s]([oa])[\s]($against([\s][^,.\[\(\)\]]{0,50}){0,1}),[\s]([^,.]+),/i => 88 #,
	#qr/$against,[\s]*([^,.]+)/i => 67
	);
}

sub print_names_nicknames {
	my (@processed_names) = @_;
	print "\n===================================================================================\n";
	print "===================================================================================\n";
	for my $nomes_nicks ( @processed_names ) {
		for my $elem (sort {$$nomes_nicks{$b} <=> $$nomes_nicks{$a}} keys %$nomes_nicks ) {
			print "     $elem => $nomes_nicks->{$elem} \n";
		}
		print "===================================================================================\n";
	}
	print "===================================================================================\n\n";
}

sub name_distance {
	my ($name1, $name2) = @_;
	
	my @nome_separado = split(/ |-/, $name1);
	@nome_separado = grep /\S/, @nome_separado;
	my $distanc = 1;
	my @nr_names = split(/ |-/, $name2);
	@nr_names = grep /\S/, @nr_names;
	my $dist_last = adistr($nome_separado[-1], $nr_names[-1]);
	my $dist_first = adistr($nome_separado[0], $name2);

	if(scalar(@nome_separado) > 2){
		if(scalar(@nr_names) >= 2){
			$distanc = 0.65 * abs($dist_last) + 0.35 * abs($dist_first);
			if($distanc > 0.25) {
				my $dist_middle = adistr($nome_separado[-2], $name2);
				$distanc = 0.65 * abs($dist_last) + 0.35 * abs($dist_middle);
			}
		}
		if(scalar(@nr_names) == 1){ 
			$distanc = abs($dist_last); 
			if($distanc > 0.25) {
				$distanc = abs($dist_first);
			}
		}
	} 
	if((scalar(@nome_separado) == 2)){
		
		if(scalar(@nr_names) >= 2){
			$distanc = 0.55 * abs($dist_last) + 0.45 * abs($dist_first);
		} 
		if(scalar(@nr_names) == 1){ 
			$distanc = abs($dist_last); 
			if($distanc > 0.25) {
				$distanc = abs($dist_first);
			}
		}			
	}
	if(scalar(@nome_separado) == 1) { $distanc = abs($dist_last); }
	return $distanc;	
}

sub log50 {
        my $n = shift;
        if(log($n)/log(50) >= 1) {
			return 1;
		}else {
			return log($n)/log(50);
		}
    }

sub connect_to_catalyst {
	print "Connecting to OntoExtract...\n";
	#my $connect_info = OntoExtract::Model::ontoextract->config->{connect_info}; # picking up database connection info
	#$schema = OntoExtract::Schema->connect( $connect_info->{'dsn'} ); # connect to the Catalyst schema
	$schema = OntoExtract::Schema->connect('dbi:mysql:dbname=ontoextract','paixao', 'paixao86123', { mysql_enable_utf8 => 1} );
	print "Connected to OntoExtract!\n";
}

sub get_pattern {
	print "Generating pattern matching list...\n";
	
	parse_dbpedia(); 
	
	open (VERBS, './lists/verbos.txt');
	while (<VERBS>) {
	 chomp;
	 $name_pattern{$_}++;
	}
	close (VERBS);
	
	open (NAC, './lists/nac.txt');
	while (<NAC>) {
	 chomp;
	 $name_pattern{$_}++;
	}
	close (NAC);
	
	open (PAISES, './lists/paises.txt');
	while (<PAISES>) {
	 chomp;
	 $name_pattern{$_}++;
	}
	close (PAISES);
	
	open (CITIES, './lists/cidades.txt');
	while (<CITIES>) {
	 chomp;
	 $name_pattern{$_}++;
	}
	close (CITIES);
	
	open (CVERBS, './lists/communication_verbs.txt');
	while (<CVERBS>) {
	 chomp;
	 $ergo_pattern{$_}++;
	 $name_pattern{$_}++;
	 $org_pattern{$_}++;
	}
	close (CVERBS);

	open (ORGS, './lists/organizacoes.txt');
	while (<ORGS>) {
	 chomp;
	 $name_pattern{$_}++;
	 $org_types{$_}++;
	}
	close (ORGS);
	
	my @extra = qw/em que sobre dr prof com também esta manhã num parlamento assembleia república líder ele para no supremo tribunal patriarca cardeal o justiça depois alteza sempre um a não qualquer senhor presidente desde já à só/;
	#push (@extra,"com o","e com","e o","e os","que o","e de");
	foreach my $elem (@extra) {
		$name_pattern{$elem}++;
	}
	print "Generation of pattern matching list terminated!\n";
}

sub get_abstract {
	my (@names_nicks_array) = @_;
	my $abstract = "";
	for(my $i = 0; $i < scalar(@names_nicks_array); $i++){
		if($DBpedia_abstracts{$names_nicks_array[$i]}){
			$abstract = $DBpedia_abstracts{$names_nicks_array[$i]} ;
			$i = scalar(@names_nicks_array);
		}
	}
	return $abstract;
}

sub get_article_link {
	my (@names_nicks_array) = @_;
	my $link = "";
	for(my $i = 0; $i < scalar(@names_nicks_array); $i++){
		if($DBpedia_links{$names_nicks_array[$i]}){
			$link = $DBpedia_links{$names_nicks_array[$i]} ;
			$i = scalar(@names_nicks_array);
		}
	}
	return $link;
}

sub get_image {
	my (@names_nicks_array) = @_;
	my $link = "";
	for(my $i = 0; $i < scalar(@names_nicks_array); $i++){
		if($DBpedia_images{$names_nicks_array[$i]}){
			$link = $DBpedia_images{$names_nicks_array[$i]} ;
			$i = scalar(@names_nicks_array);
		}
	}
	return $link;
}

sub get_bd_match {
	my ($against) = @_;
	print "Waiting MySQL answer to query: $against...\n";
	my $match = 'MATCH (me.content) AGAINST (\'' . $against . '\' IN BOOLEAN MODE)';
	my @queryrs = $schema->resultset('News')->search(undef, { page => 1, rows => 1000000, select => ['me.content', 'me.page_url'], distinct => 1, where => $match }); 
	create_pattern_matches($against);
	print "Received MySQL answer to query: $against!\n";
	return \@queryrs;
}

sub name_cleaner {
	my $name = shift;
	my @nome_separado = split(/ |-|:/, $name);
	@nome_separado = grep /\S/, @nome_separado; 
	foreach my $name_part (@nome_separado) {
		if(scalar(@nome_separado) < 2){
			if($name_pattern{lc($name_part)}) {
				$name = "";
			}
		} else {
			if($name_pattern{lc($name_part)}) {				
				while($name =~ s/^(.*)[\s]$name_part([\s]|[\-]|(:[\s]))(.*)//i || $name =~ s/(.*)[\s]$name_part$//i || $name =~ s/^$name_part[\s](.*)//i){
					$name = $1;
				}
			}
		}
	}
	while($name =~ s/^(.*)[\»\«\:\;\]\d\"\(\)]// || $name =~ s/^(.*)[\s][-+][\s](.*)// || $name =~ s/(.*)[\s][A-Z]+[\s](.*)//){
		$name = $1;
	}
	while($name =~ s/(.*)(([\-\s]+.)|([\-\s]+..)|([\-\s]+))$//){
		$name = $1;
	}
			
	return $name;
}

sub org_cleaner {
	my $name = shift;
	
	my @nome_separado = split(/ |-|:/, $name);
	@nome_separado = grep /\S/, @nome_separado; 
	foreach my $name_part (@nome_separado) {
		if($org_pattern{lc($name_part)}) {
			$name = "";
		}
	}
	while($name =~ s/^([^,.]+)[\»\«\:\;\]\d\'\"\(\)]// || $name =~ s/^[\»\«\:\;\]\d\'\"\(\)]([^,.]+)// || $name =~ s/^(.*)[\s][-+][\s]([^,.]+)//){
		$name = $1;
	}
	while($name =~ s/([^,.]+)(([\-\s]+.)|([\-\s]+))$//){
		$name = $1;
	}
			
	return $name;
}

sub ergo_cleaner {
	
	my $name = shift;
	
	my @nome_separado = split(/ |-|:/, $name);
	@nome_separado = grep /\S/, @nome_separado; 
	foreach my $name_part (@nome_separado) {
		if($ergo_pattern{lc($name_part)}) {
			$name = "";
		}
	}
	while($name =~ s/^([^,.]+)[\»\«\:\;\]\d\'\'"\(\)]// || $name =~ s/^(.*)[\s][-+][\s]([^,.]+)//){
		$name = $1;
	}
	while($name =~ s/([^,.]+)(([\-\s]+.)|([\-\s]+))$//){
		$name = $1;
	}
	return $name;
}

sub get_ergo_org {
	my $ergo_org = shift;
	my $ergo = "";
	my $org = "";
	my @various_roles = ("e o", "e a","com o", "seu","na abertura","deste","daquela","aos","demissão","com a", "num","sua","funções","no caso","então", "homólogo", "cessante", "eleito","da altura", "reeleito", "homóloga","e com","em exercício","designado","e os","e as","que o", "nem","indigitado", "à");
	foreach my $cond (@various_roles){
		if($ergo_org =~ /[\s]$cond[\s]/g || $ergo_org =~ /[\s]$cond$/ || $ergo_org =~ /^$cond[\s]/) {
			$ergo = "";
			$org = "";
			return $ergo, $org;
		}
	}
	$ergo = $ergo_org;
	if($ergo_org =~ /^(.*)[\s](da|das|de|dos|do)[\s]([^,.]+)/){
		$org = $3;
	}
	$ergo = ergo_cleaner($ergo);
	$org = org_cleaner($org);
	return $ergo,$org;	
}

sub get_names {
	my $queryrs = shift;
	print "Beggining name extraction process...\n";
	my @resultado_final = ();
	foreach my $match (keys %pattern_matches) {
		my %names = ();
		my %sexes = ();
		my %page_url = ();
		my @ergos = ();
		my %orgs = ();
		
		for my $row ( @$queryrs )
		{
			my $content = $row->content;
			my $url = $row->page_url;
			chomp($content);
			while($content =~ s/$match//i) {
				my $sex = $1;
				my $ergo_org = $2;
				my $name = $4;				
				if(length($name)<3 || $name !~ /^[A-Z].*/ || $name !~ m/[A-Z][^,.\s]+$/g || $name =~ /\\u\d{4}/g || length($ergo_org)<3){next;}#\u00C0-\u00DD
				my ($ergo, $org) = get_ergo_org($ergo_org);
				$name = name_cleaner($name);
				if(defined($name) && defined($ergo) && length($ergo) > 4 && $name =~ m/[A-Z][^,.\s]+$/g && length($name)>3){
					$names{$name}++;
					$sexes{$name}->{$sex}++;
					$page_url{$name}->{$url}++;
					if(defined($org) && length($org) > 4){
						$orgs{$org}++;
						$page_url{$org}->{$url}++;
					}
					if(defined($ergo) && length($ergo) > 1){
						
						if(defined($org) && length($org) > 1) {
							push @ergos,{person => $name, organization => $org, ergo => $ergo};
							$page_url{$ergo}->{$url}++;
						}else{
							push @ergos,{person => $name, ergo => $ergo};
							$page_url{$ergo}->{$url}++;
						}
					}
				}elsif(defined($org) && length($org) > 4 && defined($ergo) && length($ergo) > 4){
					$orgs{$org}++;
					$page_url{$org}->{$url}++;
					if(defined($ergo) && length($ergo) > 1){
						push @ergos,{organization => $org, ergo => $ergo};
						$page_url{$ergo}->{$url}++;
					}
				}
			}
		}
		###################################################### SAVE PERSONS
		print "\n ----> Persons Found:\n\n";
		my $names_nicks = nickname_identifier(15,\%names);
		my @names_nicks_complete = @$names_nicks;
		for(my $i=0;$i<scalar(@$names_nicks);$i++) {
			my %url_list = ();
			my @names_nicks_array = sort {$names_nicks->[$i]->{$b} <=> $names_nicks->[$i]->{$a}} keys %{$names_nicks->[$i]};
			my $main_name = $names_nicks_array[0];
			my $count = 0;
			foreach my $url (keys %{$page_url{$main_name}}) {
				if($count < $url_store_number){
					$count++;
					$url_list{$url} = $page_url{$main_name}->{$url};
				}else{
					last();
				}
			}
			my $main_sex = (sort {$sexes{$main_name}->{$b} <=> $sexes{$main_name}->{$a}} keys %{$sexes{$main_name}})[0];
			my $abstract = get_abstract(@names_nicks_array);
			my $link = get_article_link(@names_nicks_array);
			my $image = get_image(@names_nicks_array);
			$main_sex = "m", if($main_sex eq 'o' || $main_sex eq 'O');
			$main_sex = "f", if($main_sex eq 'a' || $main_sex eq 'A');
			my $nr_hits = $names_nicks->[$i]{$main_name};
			delete $names_nicks->[$i]{$main_name};
			my @temp_rs = ('p', $pattern_matches{$match}, $main_name, $nr_hits, $names_nicks->[$i], \%url_list, $abstract, $link, $image, $main_sex);
			push (@resultado_final, \@temp_rs);	
		}
		###################################################### SAVE ORGS
		print "\n ----> Organizations Found:\n\n";
		my $orgs_nicks =  nickname_identifier(2,\%orgs);
		my @orgs_nicks_complete = @$orgs_nicks;
		for(my $i=0;$i<scalar(@$orgs_nicks);$i++) {
			my %url_list = ();
			my $main_name = (sort {$orgs_nicks->[$i]->{$b} <=> $orgs_nicks->[$i]->{$a}} keys %{$orgs_nicks->[$i]} )[0];
			my $count = 0;
			foreach my $url (keys %{$page_url{$main_name}}) {
				if($count < $url_store_number){
					$count++;
					$url_list{$url} = $page_url{$main_name}->{$url};
				}else{
					last();
				}
			}
			my $abstract = get_abstract($main_name);
			my $link = get_article_link($main_name);
			my $image = get_image($main_name);
			my $nr_hits = $orgs_nicks->[$i]{$main_name};
			delete $orgs_nicks->[$i]->{$main_name};
			my @temp_rs = ('o', $pattern_matches{$match}, $main_name, $nr_hits, $orgs_nicks->[$i], \%url_list, $abstract, $link, $image);
			push (@resultado_final, \@temp_rs);	
		}
		###################################################### SAVE ROLES
		print "\n ----> Roles Found:\n\n";
		my %ergo_hash = ();
		for my $ergo (@ergos){
			if($ergo->{person}){
				push @{ $ergo_hash{$ergo->{person}} }, $ergo;
			}else{
				push @{ $ergo_hash{$ergo->{organization}} }, $ergo;
			}
		}
		
		foreach my $ergos_key (keys %ergo_hash ){
		my %ergos_nicks_f = ();
		for my $ergo (@{$ergo_hash{$ergos_key}}){
			$ergos_nicks_f{$ergo->{ergo}}++;
		}
		my $ergos_nicks =  nickname_identifier(0.5,\%ergos_nicks_f); #identifica parecidos
		
		for(my $i=0;$i<scalar(@$ergos_nicks);$i++) {
			my %url_list = ();
			my %pers_ergo_org = ();
			my %pers_ergo = ();
			my %orgs_ergo = ();
			my %hash_temp = %{$ergos_nicks->[$i]};
			foreach my $nome (keys %hash_temp) {
				foreach my $ergo (@ergos){
					if($ergo->{ergo} eq $nome){
						if($ergo->{person} && $ergo->{organization}){
							$pers_ergo_org{$ergo->{person}} = $ergo->{organization};
						} elsif($ergo->{person}){
							$pers_ergo{$ergo->{person}} = 0;
						} elsif($ergo->{organization}){
							$orgs_ergo{$ergo->{organization}} = 0;
						}
					}
				}					
			}
			
			my $main_name = (sort {$hash_temp{$b} <=> $hash_temp{$a}} (keys %hash_temp))[0];
			my $abstract = get_abstract($main_name);
			my $link = get_article_link($main_name);
			my $count = 0;
			foreach my $url (keys %{$page_url{$main_name}}) {
				if($count < $url_store_number){
					$count++;
					$url_list{$url} = $page_url{$main_name}->{$url};
				}else{
					last();
				}
			}
			my $nr_hits = $hash_temp{$main_name};
			delete $hash_temp{$main_name};
			my @temp_rs = ('r', $pattern_matches{$match}, $main_name, $nr_hits, \%hash_temp, \%url_list, $abstract, $link,'', \%pers_ergo_org, \%pers_ergo, \%orgs_ergo);
			push (@resultado_final, \@temp_rs);		
		}
	}
		###################################################### 
	}

	print "Name extraction process terminated!\n";
	return \@resultado_final;
}

sub nickname_identifier {
	my ($diff_aceite, $nomes) = @_;
	$diff_aceite = $diff_aceite/100;
	my @processed_names = ();
	for my $key (sort {$nomes->{$b} <=> $nomes->{$a}} (keys(%$nomes))) {
		if($key && $nomes->{$key}){
		my @nome_com_nicknames = ( $key, $nomes->{$key} );
		delete $nomes->{$key};
		my @all_names = keys(%$nomes);		
		for(my $i=0; $i < scalar(@all_names);$i++){			
			if(name_distance($key,$all_names[$i]) < $diff_aceite) {			
				push(@nome_com_nicknames,$all_names[$i]);
				push(@nome_com_nicknames,$nomes->{$all_names[$i]});
				delete $nomes->{$all_names[$i]};
			}
		}
		push @processed_names, { @nome_com_nicknames };
	}
	}
	print_names_nicknames (@processed_names);
	return \@processed_names;
}

sub save_or_update_element {
	my ($type, $arguments, $certainty) = @_;
	my ($newname, $fromwho_id, $fromwho_flag) = undef;
	my $table = get_table($type);
	if($type eq 'u' || $type eq 'n'){
		$fromwho_id = $arguments->{fromwho_id};
		$fromwho_flag = $arguments->{fromwho_flag};
	}
	if($type eq 'r'){
		$fromwho_id = $arguments->{id_person};
		$fromwho_flag = $arguments->{id_organization};
	}
	my $rs = get_element_by_name($type, $arguments->{name},$fromwho_id, $fromwho_flag);
	if(!$rs){
		$newname = save_element($type, $arguments, $certainty);
	}else{
		$newname = update_element($type,$rs->id, $arguments, $certainty);
	}
	return $newname;
}

sub save_element {
	my ($type, $arguments, $certainty) = @_;
	my $newname;
	my $table = get_table($type);
	if(defined($table)){
		$newname = eval {$schema->resultset($table)->create($arguments)}; if($@) {print $@ . "\n";return 0;}
		if($type ne 'u'){
			if($certainty->{'id_from'} && $certainty->{'from_flag'}){
				my $rs = $schema->resultset('Certainty')->find({id_to => $certainty->{'id_from'}, to_flag => $certainty->{'from_flag'} });
				my $bc = $rs->final_certainty;
				my $fc = 100 * (($bc / 100) * ($certainty->{'method_certainty'} / 100));
				$fc = 95 if($fc > 95);
				$certainty->{'final_certainty'} = $fc;
				#print "Certainty changed to $fc !\n";			
			}
			$certainty->{'id_to'} = $newname->id;
			$certainty->{'to_flag'} = $type;
			my $newcertainty = eval { $schema->resultset('Certainty')->create($certainty) }; if($@) {print $@ . "\n";return 0;}
		}
	}
	return $newname->id;
}

sub update_element {	
	my ($type, $id_element, $arguments, $certainty) = @_;
	if($type ne 'u'){
		my $newname;
		my $table = get_table($type);
		my $rs = $schema->resultset($table)->find($id_element);
		if(defined($table) && defined($rs)){
			$rs->update($arguments); if($@) {print $@ . "\n";return 0;}
			if($certainty){
				my $rs2 = $schema->resultset('Certainty')->find({id_to => $id_element, to_flag => $type});
				if($rs2->id_from && $rs2->from_flag){
					my $rs_certainty = $schema->resultset('Certainty')->find({id_to => $rs2->id_from, to_flag => $rs2->from_flag });
					my $bc = $rs_certainty->final_certainty;
					my $fc = 100 * (($bc / 100) * ($certainty->{'method_certainty'} / 100));
					if($fc > 95){ $fc = 95; }
					$certainty->{'final_certainty'} = $fc;
					#print "Certainty changed to $fc !\n";			
				}
				update_certainty($type,$id_element, $certainty->{final_certainty});
			}
		}
	}
	#print "Element updated!\n";
	return $id_element;
}

sub update_certainty {
	my ($type, $id_element, $final_certainty) = @_;
	
	my $rs = $schema->resultset('Certainty')->find({ id_to => $id_element, to_flag => $type }); 
	## UPDATE CERTAINTY
	my $stored_final_certainty = $rs->final_certainty;
	my $fc = 0;
	if($stored_final_certainty < 95){
	$fc = 100 - (100 * (((100 - $stored_final_certainty)/100) * ((100 - $final_certainty)/100)));
	if($fc > 95){ $fc = 95; }
	#print " -> actualizing certainty to $fc!\n";
	$rs->update({
			method_certainty => $fc,
			final_certainty => $fc
		});
		if($@) {print $@ . "\n";return 0;}
	
	my $rs2 = $schema->resultset('Certainty')->search({ id_from => $id_element, from_flag => $type });
	## PROPAGATE CERTAINTY
	foreach my $row ($rs2->all){	
		my $stored_method_certainty2 = $row->method_certainty;
		if($stored_method_certainty2 < 95){
		my $fc2 = 100 * (($stored_method_certainty2 / 100) * ($fc / 100));
		if($fc2 > 95){ $fc2 = 95; }
		$row->update({
				final_certainty => $fc2
			});
			if($@) {print $@ . "\n";return 0;}
			#print "Certainty has been propagated!\n";
		}
	}
	}
	return $id_element;
}

sub calculate_certainty {
	my ($method_certainty, $nr_hits) = @_;
	my $certainty = $method_certainty + log50($nr_hits)*(100-$method_certainty);
	if ($certainty > 95){
		return 95;
	}
	return $certainty;
}

sub save_name {
	my ($from_element, $method_certainty, $type, $nr_hits, $name, $abstract, $link, $image, $id_from, $from_flag) = @_;
	my $name_arguments;
	my $final_certainty = calculate_certainty($method_certainty, $nr_hits);
	if($type eq 'o'){
		$name_arguments = { name => $name};
		$name_arguments->{abstract} = $abstract if($abstract && $abstract ne '');
		$name_arguments->{articlelink} = $link if($link && $link ne '');
		$name_arguments->{logo} = $image if($image && $image ne '');
	}elsif ($type eq 'p'){
		$name_arguments = { name => $name, sex => $id_from};
		$name_arguments->{abstract} = $abstract if($abstract && $abstract ne '');
		$name_arguments->{articlelink} = $link if($link && $link ne '');
		$name_arguments->{picture} = $image if($image && $image ne '');
	}elsif ($type eq 'n'){
			$name_arguments = { name => $name, fromwho_id => $abstract, fromwho_flag => $link};
	}elsif($type eq 'u') {
			$name_arguments = { name => $name, fromwho_id => $abstract, fromwho_flag => $link, type_flag => $image};
	} elsif($type eq 'r'){
		my $person = get_element_by_name('p', $image);
		my $organization = get_element_by_name('o', $id_from);
		 $name_arguments = { name => $name};
		 $name_arguments->{id_person} = $person->id_person if($person);
		 $name_arguments->{id_organization} = $organization->id_organization if($organization);
		 $name_arguments->{abstract} = $abstract if($abstract && $abstract ne '');
		 $name_arguments->{articlelink} = $link if($link && $link ne '');
	}
	
	my $name_certainty = { id_from => $from_element->id, from_flag => $from_element->type, method_certainty => $final_certainty, final_certainty => $final_certainty, nr_hits => $nr_hits};
	my $id_saved = save_or_update_element($type, $name_arguments, $name_certainty);#adiciona name principal
	
	return $id_saved;
}

sub save_names {
	my ($from_element, $method_results) = @_;
	print "Beggining name storing process...\n";
	for my $method ( @$method_results ) {
		my ($type, $method_certainty, $name, $nr_hits, $nicknames, $urls, $abstract, $link, $image, $pers_org_list, $pers_list, $orgs_list) = @$method;
		
	################ GUARDA NOME
		my @ids_saved = ();
		if($type eq 'r'){
			foreach my $pers_org (keys %$pers_org_list){
				push @ids_saved, save_name($from_element, $method_certainty, $type, $nr_hits, $name, $abstract,$link, $pers_org, $pers_org_list->{$pers_org});
			}
			foreach my $pers (keys %$pers_list){
				push @ids_saved, save_name($from_element, $method_certainty, $type, $nr_hits, $name, $abstract,$link, $pers);
			}
			foreach my $orgs (keys %$orgs_list){
				push @ids_saved, save_name($from_element, $method_certainty, $type, $nr_hits, $name,$abstract,$link,'',$orgs);
			}
		}elsif($type eq 'p') {
			push @ids_saved, save_name($from_element, $method_certainty, $type, $nr_hits, $name, $abstract, $link, $image, $pers_org_list);
		} else {
			push @ids_saved, save_name($from_element, $method_certainty, $type, $nr_hits, $name, $abstract, $link, $image);
		}
		foreach my $id_saved (@ids_saved){
		################ GUARDA NICKNAMES
			
			for my $nick (keys %$nicknames ) {
				save_name($from_element, $method_certainty, 'n', $nicknames->{$nick},$nick, $id_saved, $type);
			}
			
		################ GUARDA URLS
			
			foreach my $url (keys %$urls) {
				save_name($from_element, $method_certainty, 'u', $urls->{$url},$url, $id_saved, $type, 'r');
			}
		}
		
	}
	print "Name storing process terminated!\n";
}

sub get_table {
	my $type = shift;
	my $table;
	$table = 'Person' if($type eq 'p'); 
	$table = 'Organization' if($type eq 'o');
	$table = 'Role' if($type eq 'r');
	$table = 'Nickname' if($type eq 'n');
	$table = 'Relatedurl' if($type eq 'u');	
	return $table;
}

sub get_element_by_id {
	my ($type, $id) = @_;
	my $table = get_table($type);
	return $schema->resultset($table)->find($id);
}

sub get_element_by_name {
	my ($type, $name, $fromwho_id, $fromwho_flag) = @_;
	my $table = get_table($type);
	my $elem = undef;
	if($type eq 'u' || $type eq 'n'){
		$elem = eval {$schema->resultset($table)->find({name => $name, fromwho_flag=>$fromwho_flag, fromwho_id=>$fromwho_id})};
		if($@) {print $@ . "\n";}
	}elsif($type eq 'r'){
		$elem = eval {$schema->resultset($table)->find({name => $name, id_person=>$fromwho_id, id_organization=>$fromwho_flag})};
		if($@) {print $@ . "\n";}
	}else{
		$elem = eval {$schema->resultset($table)->find({name => $name})};
		if($@) {print $@ . "\n";}
	}
	if (!$elem){
		if($type eq 'p' && $type eq 'o'){
			my $nick = eval {$schema->resultset('Nickname')->first({name => $name, fromwho_flag => $type})};
			if($@) {print $@ . "\n";}
			if ($nick) {
				$elem = eval {$schema->resultset($table)->find($nick->fromwho_id)};
				if($@) {print $@ . "\n";}
			} else {
				return undef;
			}
		}else{ ###########AQUI DEVIA VERIFICAR SE É ROLE
			return undef;
		}
	}
	
	return $elem;	
}

sub begin_extraction_process {
	my ($type, $name) = @_;
	
	my $queryrs = get_bd_match($name);
	my $nomes = get_names($queryrs);
	
	my $id = save_element($type, {name => $name, type => $type}, {method_certainty => 100, final_certainty => 100});
	my $from_element = $schema->resultset(get_table($type))->find($id); 
	
	save_names($from_element, $nomes);
}

sub start {
	#my $iter = shift;
	my %cycle_roles = ();
	open (ROLES, './lists/cargos.txt');
	while (<ROLES>) {
	 chomp;
	 $cycle_roles{$_}++;
	}
	close (ROLES);
	open (ERGOS, './lists/ergos.txt');
	while (<ERGOS>) {
	 chomp;
	 $cycle_roles{$_}++;
	}
	close (ERGOS);
	my $type = "r";
	my $array_size = keys(%cycle_roles);
	my $count = 0;
	while($array_size > 0){
	#while($count < $iter){
		
		my $rand = int(rand($array_size));
		my $name = (keys %cycle_roles)[$rand];
		my $now = strftime("[%Y-%m-%d_%R]", localtime(time));
		my $out_file = ">>./logs/extraction/".$now."_".$name.".txt";
		open (STDOUT, $out_file);
		if($count == 0){
			connect_to_catalyst();
			get_pattern();
		}
		
		begin_extraction_process($type, $name);
		close (STDOUT);
		delete $cycle_roles{$name};
		$array_size = keys(%cycle_roles);
		$count++;
	}
}

start();

#teste();

sub teste {
	my $connect_info = OntoExtract::Model::ontoextract->config->{connect_info}; # picking up database connection info
	print $connect_info->{'dsn'};
}



