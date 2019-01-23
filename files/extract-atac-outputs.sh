# !/bin/bash

# Compile outputs from samples run with a single replicate

base=/path/to/cromwell-executions/atac
outdir=/path/to/outputs

mkdir -p $outdir

for dir in `ls $base`; do 

	prefix=`ls $base/$dir/call-bowtie2/shard-0/execution | grep -E "trim.merged.bam$" | sed "s/_L001.*//"`
	echo $prefix
	# filtered BAM file  
	cp $base/$dir/call-filter/shard-0/execution/${prefix}_L001_R1_001.trim.merged.nodup.bam $outdir
	# insert length histogram 
	cp $base/$dir/call-ataqc/shard-0/execution/*trim.merged.inserts.hist_graph.pdf $outdir
	# TSS enrichment
	cp $base/$dir/call-ataqc/shard-0/execution/*trim.merged_large_tss-enrich.png $outdir
	cp $base/$dir/call-ataqc/shard-0/execution/*trim.merged_tss-enrich.png $outdir
	# # signal bigwigs
	# cp $base/$dir/call-macs2/shard-0/execution/*trim.merged.nodup.tn5.fc.signal.bigwig $outdir
	# cp $base/$dir/call-macs2/shard-0/execution/*trim.merged.nodup.tn5.pval.signal.bigwig $outdir
	# qc report
	html=$base/$dir/call-qc_report/execution/qc.html
	cp $html $outdir/$prefix.qc.html
	cp $base/$dir/call-qc_report/execution/qc.json $outdir/$prefix.qc.json
	# peak files 
	cp $base/$dir/call-reproducibility_idr/execution/optimal_peak.narrowPeak.gz $outdir/${prefix}_idr_optimal_peak.gz
	cp $base/$dir/call-reproducibility_overlap/execution/optimal_peak.narrowPeak.gz $outdir/${prefix}_overlap_optimal_peak.gz

done

first=1
# condense JSON reports
for json in `ls $outdir | grep "json"`; do

	sed "s/\": /	/g" $outdir/$json | sed "s/^[ \t]*//" | sed "s/\"//g" | sed "s/,//g" | sed "s/[{}]//g" | sed "s/\[//g" | sed "s/\]//g" | sed '/^\s*$/d' | sed "s/ /_/g" | sed "s/\s/@/g" > $outdir/tmp

	if [ "$first" == "1" ]; then
		cut -f1 -d'@' $outdir/tmp > $outdir/merged.tmp.txt
		first=0
	fi
	cut -f2 -d'@' $outdir/tmp > $outdir/tmp.info
	paste $outdir/merged.tmp.txt $outdir/tmp.info > $outdir/tmp.merged
	rm $outdir/merged.tmp.txt
	mv $outdir/tmp.merged $outdir/merged.tmp.txt
done
rm tmp*
sed -e '2d' $outdir/merged.tmp.txt | sed "s/_	/	/g" | sed "s/_$//" | sed -i "s/^NFR_\/_mono-nuc_reads.*/NFR\/\(mono-nuc_reads\) #==================================================================================/" > $outdir/merged.qc.txt
rm $outdir/merged.tmp.txt

# indicate headers in condensed report 
for header in flagstat_qc \
	nodup_flagstat_qc \
	dup_qc \
	pbc_qc \
	xcor_score \
	frip_macs2_qc \
	overlap_reproducibility_qc \
	idr_reproducibility_qc \
	overlap_frip_qc \
	idr_frip_qc \
	ataqc \
	Raw_peaks \
	Naive_overlap_peaks \
	IDR_peaks \
	 \
	Fraction_of_reads_in_NFR;do
		sed -i "s/^$header.*/$header #==================================================================================/" $outdir/merged.qc.txt
done
