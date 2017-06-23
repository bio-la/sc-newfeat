# sc-newfeat
single cell new features identification

# requirements
- samtools (1.31)
- java (1.7)
- bedtools2 (intersectBed and fastFromBed)
- macs2
- python 2.7
- homer annotatePeaks.pl script

# Running test sample
1. you need to provide chromosome 5 of hg19 build in the config directory under reference hg19chr5.fa
2. command line is sc-newfeat.pl -bam <install dir>/sample/hg19.chr5.54to55mb.bam -outdir <install dir>/outdir/ -build hg19chr5
3. diff <install dir>/outdir/sc-newfeat.gtf <install dir>/sampledir/sc-newfeat.gtf should return nothing

# Version History

June 23, 2017: intial release v0.1
