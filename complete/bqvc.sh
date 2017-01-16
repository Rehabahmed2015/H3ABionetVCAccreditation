#!/bin/bash

# This file shoule be for bqsr and vc using:
# 1. GATK
# 2. Freebayes

echo -e "################## Parsing command line arguments ##############"
set -x
if [ $# -lt 11 ]; then
   echo -e "$0: error in calling the script, revise the arguments!" |  mail -s "accreditation pipeline" azzaea@gmail.com
   exit
fi
inputbam=$1
align_res=$2
samplename=$3
reports=$4
email=$5
analysis=$6
reference=$7
targeted=$8
dbsnp138=$9
Mills=${10}
TG_1000Gindels=${11}
tool=${12}

echo -e "##################### Loading needed modules ###################"
set +x

module load gatk/3.6
module load freebayes/1.1.0 
gatkdir="/usr/src/gatk/gatk-3.6/"
###################################### Base recalibration stage: 
start=`date `
java -Xmx10g -XX:-UseGCOverheadLimit -jar $gatkdir/GenomeAnalysisTK.jar \
	-T BaseRecalibrator\
	-R $reference \
	-I $inputbam \
	-L $targeted\
	-knownSites $dbsnp138\
	-knownSites $Mills\
	-knownSites $TG_1000Gindels\
	-o $reports/${samplename}.recal.table \
	 -nct 4
end=`date `
echo -e "BaseRecalibrator\t$start\t$end" >> $reports/timings.$analysis

start=`date `
java -jar $gatkdir/GenomeAnalysisTK.jar\
	-T PrintReads\
	-R $reference\
	-I ${align_res}/$samplename.dedup.bam \
	-BQSR $reports/${samplename}.recal.table\
	-o $align_res/${samplename}.recal.bam
 end=`date `
 echo -e "PrintReads\t$start\t$end" >> $reports/timings.$analysis

./check_bam.sh $align_res/${samplename}.recal.bam bqsr_gatk $reports $samplename $email

############################################## Variant calling stage:
start=`date `
java -jar $gatkdir/GenomeAnalysisTK.jar \
	-T HaplotypeCaller\
	-R $reference\
	-I  ${align_res}/$samplename.dedup.bam \
	-BQSR $reports/${samplename}.recal.table\
	--dbsnp $dbsnp138 \
	-o $vars/$samplename.raw.calls.haplotypecaller.vcf\
	-L $targeted \
	 -nct 4
end=`date `
echo -e "HaplotypeCaller\t$start\t$end" >> $reports/timings.$analysis


################################## Freebayes
start=`date `
freebayes -f $reference ${align_res}/$samplename.dedup.bam > $vars/$samplename.raw.calls.freebayes.vcf
end=`date `
echo -e "freebayes\t$start\t$end" >> $reports/timings.$analysis


