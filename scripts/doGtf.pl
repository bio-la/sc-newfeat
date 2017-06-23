#!/usr/bin/perl -w

#use strict;
use warnings;
use Bio::SeqIO;

my ($i, $j, $pipeline_dir, $results_dir, $reads_dir, $next_arg, $ligne, $job_dir, $cmd);
my $parameters = {};

if(scalar(@ARGV) == 0){
    print "\nUsage: $0 \n\t";
    print "-homer \t\t<homer txt file>\n\t";
    print "-gtf \t\t<output gtf file>\n\n";
    exit(1);
}

get_args_and_error_check($parameters, @ARGV);
process();

sub process {
	
	my $id = 0;
	my $nn;
	open(my $homer, "<", $parameters->{homer} );
	open(my $gtf, ">", $parameters->{gtf} );
	my $line = <$homer>;
	while(<$homer>){
		chomp();
		$line = $_;
		my @tab = split("\t",$line);
		
		$id++;
		if(length($id) == 1){ 	 $nn = "0000".$id; }
		elsif(length($id) == 2){ $nn = "000".$id; }
		elsif(length($id) == 3){ $nn = "00".$id; }
		elsif(length($id) == 4){ $nn = "0".$id; }
		elsif(length($id) == 5){ $nn = $id; }
		 
		if($tab[1] eq "chrMT"){}
		else{
			$tab[1] =~ s/^chr//;
			
			if(!$tab[15]){ $tab[15] = "NA"; }
			
			$gene_id = "ENSG".$nn;
			$gene_name = $gene_id."_".$tab[15];
			$transcript_id = "ENST".$nn;
			$transcript_name = $transcript_id."_".$tab[15]."-001";
			$exon_id = "ENSE".$nn;
			
			print $gtf $tab[1]."\tensembl\ttranscript\t".$tab[2]."\t".$tab[3]."\t.\t".$tab[4]."\t.\tgene_id \"".$gene_id."\"; gene_version \"1\"; transcript_id \"".$transcript_id."\"; transcript_version \"1\"; gene_name \"".$gene_name."\"; gene_source \"ensembl_havana\"; gene_biotype \"unknown\"; transcript_name \"".$transcript_name."\"; transcript_source \"ensembl\"; transcript_biotype \"unknown\"; tag \"basic\";\n";
			print $gtf $tab[1]."\tensembl\texon\t".$tab[2]."\t".$tab[3]."\t.\t".$tab[4]."\t.\tgene_id \"".$gene_id."\"; gene_version \"1\"; transcript_id \"".$transcript_id."\"; transcript_version \"1\"; exon_number \"1\"; gene_name \"".$gene_name."\"; gene_source \"ensembl_havana\"; gene_biotype \"unknown\"; transcript_name \"".$transcript_name."\"; transcript_source \"ensembl\"; transcript_biotype \"unknown\"; exon_id \"".$exon_id."\"; exon_version \"1\"; tag \"basic\";\n";
		}
	}
	close($homer);
	close($gtf);
}


sub get_args_and_error_check {

    my($parameters, @ARGV) = @_;
    my $next_arg;
    
	# Parse the command line
	while(scalar @ARGV > 0){
	    $next_arg = shift(@ARGV);
	    if($next_arg eq "-homer"){ $parameters->{homer} = shift(@ARGV); }
	    elsif($next_arg eq "-gtf"){ $parameters->{gtf} = shift(@ARGV); }
	}

	# Check integrity of the parameters
    my $error_to_print;
 	my $parameters_to_print;
 	
    if (defined $error_to_print)    { print STDERR "ERROR(s):\n", $error_to_print, "\n"; }
    if (defined $parameters_to_print)    { print STDERR "Settings:\n", $parameters_to_print, "\n";}
}









