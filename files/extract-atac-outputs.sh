# !/bin/bash

# Pull out files relevant for QC from all subdirectories

base=/path/to/cromwell-executions/atac
outdir=/path/to/outputs

mkdir -p $outdir

for dir in `ls $base`; do 

	prefix=`ls $base/$dir/call-bowtie2/shard-0/execution | grep -E "trim.merged.bam$" | sed "s/_L001.*//"`
	
	# # filtered BAM file  
	# cp $base/$dir/call-filter/shard-0/execution/${prefix}_L001_R1_001.trim.merged.nodup.bam $outdir
	
	# insert length histogram 
	cp $base/$dir/call-ataqc/shard-0/execution/*trim.merged.inserts.hist_graph.pdf $outdir
	
	# TSS enrichment
	cp $base/$dir/call-ataqc/shard-0/execution/*trim.merged_large_tss-enrich.png $outdir
	cp $base/$dir/call-ataqc/shard-0/execution/*trim.merged_tss-enrich.png $outdir
	
	# qc report
	html=$base/$dir/call-qc_report/execution/qc.html
	cp $html $outdir/$prefix.qc.html
	cp $base/$dir/call-qc_report/execution/qc.json $outdir/$prefix.qc.json
	
	# overlap_reproducibility peak file set 
	cp $base/$dir/call-reproducibility_overlap/execution/optimal_peak.narrowPeak.gz $outdir/${prefix}_overlap_optimal_peak.gz

done
