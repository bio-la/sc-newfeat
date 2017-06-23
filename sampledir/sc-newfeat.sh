#!/bin/bash
date '+TS[START]: %Y-%m-%d %k:%M:%S.%N'
echo StartTime is `date`
echo Directory is `pwd`
export CLASSPATH=/share/apps/local/ipmc-sc-newfeat//classes:/share/apps/local/ipmc-sc-newfeat//lib/picard-1.38.jar:/share/apps/local/ipmc-sc-newfeat//lib/sam-1.38.jar
echo Time is `date`

/share/apps/local/bedtools2/bin/intersectBed -v -abam /share/apps/local/ipmc-sc-newfeat/sample/hg19.chr5.54to55mb.bam -b ./config/hg19chr5_exons.gtf  > /share/apps/local/ipmc-sc-newfeat/outdir//nonexonic.bam
echo Time is `date`

/share/apps/local/samtools-1.3.1/samtools index /share/apps/local/ipmc-sc-newfeat/outdir//nonexonic.bam
echo Time is `date`

/usr/java/jdk1.7.0_51/jre/bin/java filter.GlobalFilter -bam_input /share/apps/local/ipmc-sc-newfeat/outdir///nonexonic.bam -bam_output /share/apps/local/ipmc-sc-newfeat/outdir///nonexonic_qv10.bam -filter_mapqv 10
echo Time is `date`

/share/apps/local/samtools-1.3.1/samtools index /share/apps/local/ipmc-sc-newfeat/outdir//nonexonic_qv10.bam
echo Time is `date`

export PYTHONPATH=/share/apps/local/MACS2/lib/python2.7/site-packages/
echo Time is `date`

cd /share/apps/local/ipmc-sc-newfeat/outdir//
echo Time is `date`

/share/apps/local/MACS2/bin/macs2 callpeak -t /share/apps/local/ipmc-sc-newfeat/outdir//nonexonic_qv10.bam -f BAM -g hs -n sc-newfeat --extsize 100 --nomodel
echo Time is `date`

cd /share/apps/local/ipmc-sc-newfeat/
echo Time is `date`

/usr/java/jdk1.7.0_51/jre/bin/java -Xmx8g singlecell.CountCoveragePeak -bam /share/apps/local/ipmc-sc-newfeat/outdir//nonexonic_qv10.bam -in /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat_peaks.narrowPeak -out /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat_peaks.count.txt
echo Time is `date`

/usr/bin/perl /share/apps/local/ipmc-sc-newfeat/scripts/doStrandedPeaks.pl -expr_cutoff 100 -bed /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat_peaks.narrowPeak -count /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat_peaks.count.txt -bedout /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat_peaks.stranded.bed
echo Time is `date`

/share/apps/local/bedtools2/bin/fastaFromBed -s -fi ./config/hg19chr5.fa -bed /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat_peaks.stranded.bed -fo /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat_peaks.stranded.fasta
echo Time is `date`

/usr/bin/perl /share/apps/local/ipmc-sc-newfeat/scripts/delPolyALikePeaks.pl -bed /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat_peaks.stranded.bed -fa /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat_peaks.stranded.fasta -peaks /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat_peaks.narrowPeak -bedout /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat.stranded.nopolyA.bed -nbA 15
echo Time is `date`

/share/apps/local/homer/bin/annotatePeaks.pl /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat.stranded.nopolyA.bed hg19 -annStats /share/apps/local/ipmc-sc-newfeat/outdir//homer_stats.txt > /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat.stranded.nopolyA.annotated.txt
echo Time is `date`

/usr/bin/perl /share/apps/local/ipmc-sc-newfeat/scripts/doGtf.pl -homer /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat.stranded.nopolyA.annotated.txt -gtf /share/apps/local/ipmc-sc-newfeat/outdir//sc-newfeat.gtf
echo Time is `date`

RETVAL=$?
set -e
date '+TS[JOB_END]: %Y-%m-%d %k:%M:%S.%N'
set +x
echo EndTime is `date`
date '+TS[END]: %Y-%m-%d %k:%M:%S.%N'
exit $RETVAL
