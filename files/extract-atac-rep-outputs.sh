#!/bin/bash

# collect outputs from samples run with more than one replicate (specified by n_reps)

base=/path/to/cromwell-executions/atac
outdir=/path/to/outdir

if [ ! -d "$outdir" ]; then
	mkdir $outdir
fi

n_reps=2
c=1
((max_shard = n_reps - c))

for dir in `ls $base`; do 

	sample=`head -2 $base/$dir/call-qc_report/execution/qc.json | tail -1 | sed "s/.*\": \"//" | sed "s/\",//"`

	# collect important files from each replicate 
	for rep in $(seq 0 $max_shard); do 

		prefix=`ls $base/$dir/call-bowtie2/shard-${rep}/execution | grep -E "trim.merged.bam$" | sed "s/_L001.*//"`

		# filtered BAM files
		cp $base/$dir/call-filter/shard-${rep}/execution/${prefix}_L001_R1_001.trim.merged.nodup.bam $outdir
		# insert length histograms
		cp $base/$dir/call-ataqc/shard-${rep}/execution/*trim.merged.inserts.hist_graph.pdf $outdir
		# TSS enrichments
		cp $base/$dir/call-ataqc/shard-${rep}/execution/*trim.merged_large_tss-enrich.png $outdir
		cp $base/$dir/call-ataqc/shard-${rep}/execution/*trim.merged_tss-enrich.png $outdir
		# # signal bigwigs
		# cp $base/$dir/call-macs2/shard-${rep}/execution/*trim.merged.nodup.tn5.fc.signal.bigwig $outdir
		# cp $base/$dir/call-macs2/shard-${rep}/execution/*trim.merged.nodup.tn5.pval.signal.bigwig $outdir

	done

	# qc report
	html=$base/$dir/call-qc_report/execution/qc.html
	cp $html $outdir/${prefix}.qc.html
	cp $base/$dir/call-qc_report/execution/qc.json $outdir/${prefix}.qc.json
	# peak files 
	cp $base/$dir/call-reproducibility_idr/execution/optimal_peak.gz $outdir/${prefix}_idr_optimal_peak.gz
	cp $base/$dir/call-reproducibility_overlap/execution/optimal_peak.gz $outdir/${prefix}_overlap_optimal_peak.gz

done

# condense JSON reports (this will only make sense if all JSONs included the same number of replicates)
first=1
for json in `ls $outdir | grep "json"`; do

	sed "s/\": / /g" $outdir/$json | sed "s/^[ \t]*//" | sed "s/\"//g" | sed "s/,//g" | sed "s/[{}]//g" | sed "s/\[//g" | sed "s/\]//g" | sed '/^\s*$/d' | sed "s/\s/@/g" > $outdir/tmp

	if [ "$first" == "1" ]; then
		cut -f1 -d'@' $outdir/tmp > $outdir/merged.qc.txt
		first=0
	fi
	cut -f2 -d'@' $outdir/tmp > $outdir/tmp.info
	paste $outdir/merged.qc.txt $outdir/tmp.info > $outdir/tmp.merged
	rm $outdir/merged.qc.txt
	mv $outdir/tmp.merged $outdir/merged.qc.txt
done
rm tmp*
sed -i -e '2d' $outdir/merged.qc.txt

# indicate headers
for header in flagstat_qc \
	nodup_flagstat_qc \
	dup_qc \
	pbc_qc \
	xcor_score \
	frip_macs2_qc \
	overlap_reproducibility_qc \
	idr_reproducibility_qc \
	overlap_frip_qc \
	idr_frip_qc; do
		sed -i "s/^$header/$header ##########/" $outdir/merged.qc.txt
done
