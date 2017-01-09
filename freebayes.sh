#!bin/bash

Module load freebayes/1.1.0 

freebayes -f /home/users_current/ryahmed/free/hg19/ucsc.hg19.fasta CBSB_Khartoum.dedup.bam > var.vcf

