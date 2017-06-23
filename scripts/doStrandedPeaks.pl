#!/usr/bin/perl -w

#use strict;
use warnings;
use Bio::SeqIO;

my ($i, $j, $pipeline_dir, $results_dir, $reads_dir, $next_arg, $ligne, $job_dir, $cmd);
my $parameters = {};

if(scalar(@ARGV) == 0){
    print "\nUsage: $0 \n\t";
    print "-bed \t\t<.bed>\n\t";
    print "-count \t\t<count>\n\t";
    print "-bedout \t\t<bedout>\n\t";
    print "-expr_cutoff \t\t<nb reads cutoff to keep peak>\n\t";
    print "-add \t\t<nt add>\n\n";
    exit(1);
}

get_args_and_error_check($parameters, @ARGV);
process();

sub process {
	
	my %data=();
	open(my $count, "<", $parameters->{count} );
	while(<$count>){
		chomp();
		my $line = $_;
		my @tab = split("\t",$line);
		my $ind = 4;
		if($tab[3] eq "-"){ $ind = 5; }
		
		$key = $tab[0].":".$tab[1]."-".$tab[2];
		# on garde le peak si more than $parameters->{expr_cutoff} reads in good strand only
		if($tab[$ind] > $parameters->{expr_cutoff}){
			$data{$key}{"strand"} = $tab[3];
			$data{$key}{"count"} = $tab[$ind];
			$data{$key}{"summit_max"} = $tab[6];
			$data{$key}{"summit"} = $tab[7];
		}
		
	}
	close($count);
	
	print values(%data)."\n";
	
	my %already=();
	open(my $bed, "<", $parameters->{bed} );
	open(my $bedout, ">", $parameters->{bedout} );
	while(<$bed>){
		chomp();
		my $line = $_;
		my @tab = split("\t",$line);
		$key = $tab[0].":".$tab[1]."-".$tab[2];
		
		if($data{$key}{"strand"} && !$already{$key}){
			$already{$key} = 1;
			# positioning of peaks function of summits computed in CountCoveragePeak java class
			# should be set fucntion of fragment length distribution from wetlab protocol (Bionalayser)
			# extract 100 bases downstream the summit + 150 bases to identify potential "polyA-like" region on the genome
			my $start = $data{$key}{"summit"} + 150;
			my $end = $start + 100;
			
			if($data{$key}{"strand"} eq "-"){
				$start = $data{$key}{"summit"} - 250;
				$end = $start + 100;
			}
			if($start > 0 && $end > 0){
				print $bedout $tab[0]."\t".$start."\t".$end."\t".$tab[3]."\t".$data{$key}{"count"}."\t".$data{$key}{"strand"}."\n";
			}
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
	    elsif($next_arg eq "-count"){ $parameters->{count} = shift(@ARGV); }
	    elsif($next_arg eq "-bedout"){ $parameters->{bedout} = shift(@ARGV); }
	    elsif($next_arg eq "-add"){ $parameters->{add} = shift(@ARGV); }
	    elsif($next_arg eq "-expr_cutoff"){ $parameters->{expr_cutoff} = shift(@ARGV); }
	}

	# Check integrity of the parameters
    my $error_to_print;
 	my $parameters_to_print;
 	
    if (defined $error_to_print)    { print STDERR "ERROR(s):\n", $error_to_print, "\n"; }
    if (defined $parameters_to_print)    { print STDERR "Settings:\n", $parameters_to_print, "\n";}
}









