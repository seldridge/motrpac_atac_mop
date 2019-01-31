#!/bin/bash 

# Get number of filtered mapped reads per chromosome and contig using samtools idxstats 
# Summarize results for all samples in one file 

CROMWELL_EX=/path/to/cromwell-executions/atac
OUTDIR=/path/to/outdir

mkdir -p ${OUTDIR}

for dir in `ls ${CROMWELL_EX}`; do 
	bam=${CROMWELL_EX}/${dir}/call-filter/shard-0/execution/*trim.merged.nodup.bam
	sample_prefix=$(basename ${bam} | sed "s/_L001.*//")
	echo "seq_name	seq_length	n_mapped_reads	n_unmapped_reads" > ${OUTDIR}/${sample_prefix}.idxstats.log 
	samtools idxstats $bam >> ${OUTDIR}/${sample_prefix}.idxstats.log
done
first=1
# summarize in one file 
for log in `ls ${OUTDIR} | grep "idxstats.log"`; do 
	if [ "$first" == 1 ]; then 
		cut -f 1,2 ${OUTDIR}/${log} > ${OUTDIR}/tmp1
		first=0
	fi
	sample_prefix=`echo ${log} | sed "s/\.idxstats\.log//"`
	cut -f 3 ${OUTDIR}/${log} | sed "1 s/^.*$/$sample_prefix/" > ${OUTDIR}/tmp2
	paste ${OUTDIR}/tmp1 ${OUTDIR}/tmp2 > ${OUTDIR}/tmp3
	rm ${OUTDIR}/tmp1 ${OUTDIR}/tmp2
	mv ${OUTDIR}/tmp3 ${OUTDIR}/tmp1
done
mv ${OUTDIR}/tmp1 ${OUTDIR}/idxstats.merged.log 
