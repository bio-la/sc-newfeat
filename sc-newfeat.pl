#!/usr/bin/perl

use strict;
use warnings;

my ($i,$j,$cmd,$line);

my $perlpath		= "/usr/bin/perl";
my $pythonpath		= "/share/apps/local/bin/python2.7";
my $samtoolspath	= "/share/apps/local/samtools-1.3.1/samtools",
my $javapath		= "/usr/java/jdk1.7.0_51/jre/bin/java";
my $intersectbed	= "/share/apps/local/bedtools2/bin/intersectBed";
my $macs2path		= "/share/apps/local/MACS2/bin/macs2";
my $macs2pythonpath = "/share/apps/local/MACS2/lib/python2.7/site-packages/";
my $fastaFromBed	= "/share/apps/local/bedtools2/bin/fastaFromBed";
my $homerAnnotate	= "/share/apps/local/homer/bin/annotatePeaks.pl";

if(scalar(@ARGV) == 0){
    print "\nUsage: $0 \n\t"; 
    print "-bam \t\t<give me a .bam file>\n\t";
    print "-outdir \t<give me a working directory>\n\t";
    print "-build \t\t<hg19, hg38, mm10 or hg19chr5 for sample test>\n\n";
    exit(1);
}


my $parameters = {};
$parameters->{build} = "hg19";
get_args_and_error_check($parameters, @ARGV);
my $here = `pwd`;
chomp($here);
$parameters->{here} = $here."/";

if(-e $parameters->{bam}){
	process();
}

sub runCmds {
	my(@cmds) = @_;
	
	open SH, "> ".$parameters->{outdir}."sc-newfeat.sh" || die $_;
	print SH "#!/bin/bash\n";
	print SH "date '+TS[START]: %Y-%m-%d %k:%M:%S.%N'\n";
	print SH "echo StartTime is `date`\n";
	print SH "echo Directory is `pwd`\n";  
		
	for(my $i=0;$i<@cmds;$i++){
		print SH $cmds[$i]."\n";
		print SH "echo Time is `date`\n\n";
	}

	print SH "RETVAL=\$?\n";
	print SH "set -e\n";
	print SH "date '+TS[JOB_END]: %Y-%m-%d %k:%M:%S.%N'\n";
	print SH "set +x\n";
	print SH "echo EndTime is `date`\n";
	print SH "date '+TS[END]: %Y-%m-%d %k:%M:%S.%N'\n";
	print SH "exit \$RETVAL\n";
	close(SH);
	
	system("/bin/chmod 775 ".$parameters->{outdir}."sc-newfeat.sh");
	print "\n\n#----------\nExecuting pipeline ".$parameters->{outdir}."sc-newfeat.sh\n#--------\n";
	system($parameters->{outdir}."sc-newfeat.sh");
}
sub process {
	my @cmds;
	my $half_peak_size 	= 100;
	my $gsize			= "3200000000"; # human genome
	my $gtf_exons		= "./config/".$parameters->{build}."_exons.gtf"; # gtf file with only exonic region
	my $fasta_build 	= "./config/".$parameters->{build}.".fa"; # genome fasta file
	my $homerbuild		= $parameters->{build};
	if($parameters->{build} eq "hg19chr5"){ $homerbuild="hg19"; }
	
	print "coucou\n";
	
	if(!-e $gtf_exons || !-e $fasta_build){
		print "\n\n#-----\nError: no gtf of fasta in directory for build specified (".$parameters->{build}.")\n#-----\n";
		exit;
	}
	
	# extract non -exonic reads
	push(@cmds, "export CLASSPATH=".$parameters->{here}."/classes:".$parameters->{here}."/lib/picard-1.38.jar:".$parameters->{here}."/lib/sam-1.38.jar");
	push(@cmds, $intersectbed." -v -abam ".$parameters->{bam}." -b ".$gtf_exons."  > ".$parameters->{outdir}."nonexonic.bam");
	push(@cmds, $samtoolspath." index ".$parameters->{outdir}."nonexonic.bam");
	# filter for low QV reads (potential secondary records also)
	push(@cmds, $javapath." filter.GlobalFilter -bam_input ".$parameters->{outdir}."/nonexonic.bam -bam_output ".$parameters->{outdir}."/nonexonic_qv10.bam -filter_mapqv 10");
	push(@cmds, $samtoolspath." index ".$parameters->{outdir}."nonexonic_qv10.bam");
	# MACS2 peak detection
	push(@cmds, "export PYTHONPATH=".$macs2pythonpath);
	push(@cmds, "cd ".$parameters->{outdir});
	push(@cmds, $macs2path." callpeak -t ".$parameters->{outdir}."nonexonic_qv10.bam -f BAM -g hs -n sc-newfeat --extsize ".$half_peak_size." --nomodel");
	push(@cmds, "cd ".$parameters->{here});
	# get count on plus and minus strand to assess strandness, compute also summit coordinate of each peak
	push(@cmds, $javapath." -Xmx8g singlecell.CountCoveragePeak -bam ".$parameters->{outdir}."nonexonic_qv10.bam -in ".$parameters->{outdir}."sc-newfeat_peaks.narrowPeak -out ".$parameters->{outdir}."sc-newfeat_peaks.count.txt");
	# identify the region of the potential "polyA-like" region
	push(@cmds, $perlpath." ".$parameters->{here}."scripts/doStrandedPeaks.pl -expr_cutoff 100 -bed ".$parameters->{outdir}."sc-newfeat_peaks.narrowPeak -count ".$parameters->{outdir}."sc-newfeat_peaks.count.txt -bedout ".$parameters->{outdir}."sc-newfeat_peaks.stranded.bed");
	# extract the fasta sequence of the potential "polyA-like" region
	push(@cmds, $fastaFromBed." -s -fi ".$fasta_build." -bed ".$parameters->{outdir}."sc-newfeat_peaks.stranded.bed -fo ".$parameters->{outdir}."sc-newfeat_peaks.stranded.fasta");
	# remove "polyA-like" peaks
	push(@cmds, $perlpath." ".$parameters->{here}."scripts/delPolyALikePeaks.pl -bed ".$parameters->{outdir}."sc-newfeat_peaks.stranded.bed -fa ".$parameters->{outdir}."sc-newfeat_peaks.stranded.fasta -peaks ".$parameters->{outdir}."sc-newfeat_peaks.narrowPeak -bedout ".$parameters->{outdir}."sc-newfeat.stranded.nopolyA.bed -nbA 15");
	push(@cmds, $homerAnnotate." ".$parameters->{outdir}."sc-newfeat.stranded.nopolyA.bed ".$homerbuild." -annStats ".$parameters->{outdir}."homer_stats.txt > ".$parameters->{outdir}."sc-newfeat.stranded.nopolyA.annotated.txt");
	push(@cmds, $perlpath." ".$parameters->{here}."scripts/doGtf.pl -homer ".$parameters->{outdir}."sc-newfeat.stranded.nopolyA.annotated.txt -gtf ".$parameters->{outdir}."sc-newfeat.gtf");
	
	runCmds(@cmds);
}
sub get_args_and_error_check {
    my($parameters, @ARGV) = @_;
    my $next_arg;
    
	# Parse the command line
	while(scalar @ARGV > 0){
	    $next_arg = shift(@ARGV);
	    if($next_arg eq "-bam"){ $parameters->{bam} = shift(@ARGV); }
	    elsif($next_arg eq "-build"){ $parameters->{build} = shift(@ARGV); }
	    elsif($next_arg eq "-outdir"){
	    	$parameters->{outdir} = shift(@ARGV);
	    	mkdir $parameters->{outdir};
	    	$parameters->{outdir} = $parameters->{outdir}."/";
	    }
	}

	# Check integrity of the parameters
    my $error_to_print;
 	my $parameters_to_print;
 	
 	unless(defined $parameters->{bam}) { $error_to_print .=  "\tNo bam file specified.\n";}
 	
    unless(defined $parameters->{outdir}) { $error_to_print .= "\tNo outdir specified.\n";}
    if(-e $parameters->{outdir} && -d $parameters->{outdir}){  $parameters_to_print .=  "\toutdir\t\t= $parameters->{outdir} \n"; } 
    else{ $parameters_to_print .= "\t$parameters->{outdir} did not exist so it was created \n";  }

    unless(defined $parameters->{build})   { $error_to_print .= "\tNo organism genome build specified.\n";}
    if($parameters->{build} eq "hg38" || $parameters->{build} eq "hg19" || $parameters->{build} eq "hg19chr5" || $parameters->{build} eq "mm10") { $parameters_to_print .=  "\tgenome build\t= $parameters->{build}\n"; }
    else{ die "ERROR: $parameters->{build} not permitted (select hg19, hg38, mm10 or hg19chr5 for sample test)\n";}

    if (defined $error_to_print)    { print STDERR "ERROR(s):\n", $error_to_print, "\n"; }
    if (defined $parameters_to_print)    { print STDERR "Settings:\n", $parameters_to_print;}

}
