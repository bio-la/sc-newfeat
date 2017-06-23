#!/usr/bin/perl -w

#use strict;
use warnings;
use Bio::SeqIO;

my ($i, $j, $pipeline_dir, $results_dir, $reads_dir, $next_arg, $ligne, $job_dir, $cmd);
my $parameters = {};

if(scalar(@ARGV) == 0){
    print "\nUsage: $0 \n\t";
    print "-bed \t\t<bed>\n\t";
    print "-fa \t\t<fa>\n\t";
    print "-peaks \t\t<original peaks>\n\t";
    print "-nbA \t\t<nbA>\n\t";
    print "-bedout \t\t<bedout>\n\n";
    exit(1);
}

get_args_and_error_check($parameters, @ARGV);
process();

sub process {
	
	my %good_peaks=();
	my $ww = 0;
	my $keepit=0;
	open(my $fa, "<", $parameters->{fa} );
	while(my $line=<$fa>){
		chomp($line);
		$line =~ s/^>//;
		$seq=<$fa>;
		chomp($seq);
		$ww++;
		
		my $keep = 1;
		for($i=0; $i<length($seq)-20; $i++){
			$ss = substr($seq,$i,20);
			$ss =~ s/[TGC]//g;
			if(length($ss) > $parameters->{nbA}){ $keep = 0; }
		}
		
		if($keep){ $good_peaks{$line} = $seq; $keepit++; }
		else{ print $keepit."/".$ww."\n"; }
	}
	close($fa);
	
	print "good_peaks : ".values(%good_peaks)."\n";

	my %real_peaks_coordinate=();
	open(my $peaks, "<", $parameters->{peaks} );
	while(<$peaks>){
		chomp();
		my $line = $_;
		my @tab = split("\t",$line);
		$real_peaks_coordinate{$tab[3]} = $tab[0]."\t".$tab[1]."\t".$tab[2];
	}
	close($peaks);
	
	open(my $bed, "<", $parameters->{bed} );
	open(my $bedout, ">", $parameters->{bedout} );
	while(<$bed>){
		chomp();
		my $line = $_;
		my @tab = split("\t",$line);
		$key = $tab[0].":".$tab[1]."-".$tab[2]."(".$tab[5].")";
		
		if($good_peaks{$key}){
			print $bedout "chr".$real_peaks_coordinate{$tab[3]}."\t".$tab[3]."\t".$tab[4]."\t".$tab[5]."\n";
		}
	}
	close($bed);
	close($bedout);
}

sub get_args_and_error_check {

    my($parameters, @ARGV) = @_;
    my $next_arg;
    
	# Parse the command line
	while(scalar @ARGV > 0){
	    $next_arg = shift(@ARGV);
	    if($next_arg eq "-bed"){ $parameters->{bed} = shift(@ARGV); }
	    elsif($next_arg eq "-fa"){ $parameters->{fa} = shift(@ARGV); }
	    elsif($next_arg eq "-nbA"){ $parameters->{nbA} = shift(@ARGV); }
	    elsif($next_arg eq "-bedout"){ $parameters->{bedout} = shift(@ARGV); }
	    elsif($next_arg eq "-peaks"){ $parameters->{peaks} = shift(@ARGV); }
	}

	# Check integrity of the parameters
    my $error_to_print;
 	my $parameters_to_print;
 	
    if (defined $error_to_print)    { print STDERR "ERROR(s):\n", $error_to_print, "\n"; }
    if (defined $parameters_to_print)    { print STDERR "Settings:\n", $parameters_to_print, "\n";}
}









