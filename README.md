# MoTrPAC ATAC-Seq MOP (ENCODE pipeline)

This repository documents the specific parameters used to run the ENCODE ATAC pipeline for ATAC-seq data processing within the MoTrPAC consortium.  

Note that the ENCODE ATAC-seq pipeline has separate instructions for multiple platforms, including Stanford SCG, Stanford Sherlock 2.0, local system with docker, local system with Conda, etc. The following documentation is specific for analysis on a **local system with Conda**. Platform-specific instructions can be found here: https://github.com/ENCODE-DCC/atac-seq-pipeline  

**Contact:** Nicole Gay (nicolerg@stanford.edu) 

**Resources:**

- GitHub repository for the ATAC pipeline: https://github.com/ENCODE-DCC/atac-seq-pipeline
- ENCODE ATAC pipeline documentation: https://www.encodeproject.org/atac-seq/
- ENCODE terms and definitions: https://www.encodeproject.org/data-standards/terms/

**Table of Contents:**

1. Before you do anything else...
2. Install and test ENCODE ATAC-seq pipeline and dependencies
3. Build a genome database 
4. Generate JSON files 
5. Run pipeline
6. Collect important QC metrics
7. ENCODE data quality standards

### 1. Before you do anything else...

Good-quality ATAC analysis requires high-output sequencing data. ENCODE stipulates that a sample should have 25M non-duplicated, filtered, non-mitochondial fragments for downstream analysis. That corresponds to 50M reads for paired-end sequencing and 25M reads for single-end sequencing AFTER a number of filtering steps. Therefore, your raw paired-end FASTQ files should have appreciably more than 50M reads per sample. Run the following code to get read counts per sample, assuming you have compressed (`.gz`) FASTQ files following the naming convention `${SAMPLE}_L00#_R#_001.fastq.gz`:

```bash
INDIR=/path/to/raw/fastq/files

for prefix in `ls $INDIR | grep "L001_R1_001.fastq.gz" | sed "s/_L001_R1_001.fastq.gz//"`; do
	total=0
	for fastq in `ls $indir | grep "$prefix"`; do 
		count1=`zcat $indir/$fastq | wc -l`
		count2=$((total + count1))
		total=$count2
	done
	y=4
	count=$((total / y))
	echo $prefix	$count
done
```

Raw read counts should be included in metadata/QC metric reports for all samples.  

### 2. Install and test ENCODE ATAC-seq pipeline and dependencies

Follow Steps 1-8 found here: https://github.com/ENCODE-DCC/atac-seq-pipeline/blob/master/docs/tutorial_local_conda.md  

### 3. Build a genome database

**For human:**  
Follow the instructions for **How to build a genome database** found here: https://github.com/ENCODE-DCC/atac-seq-pipeline/blob/master/docs/build_genome_database.md using `GENOME=hg38`. Note that the path `conda/install_genome_data.sh` is located within the `atac-seq-pipeline` directory cloned in Step 1.   

**For rat:**  
Follow the instructions for **How to build genome database for your own genome** found here: https://github.com/ENCODE-DCC/atac-seq-pipeline/blob/master/docs/build_genome_database.md. Note that the path `conda/install_genome_data.sh` is located within the `atac-seq-pipeline` directory cloned in Step 1.  

In Step 4, add a couple of extra things:

- `REF_FA` points to a genome sequence file. Use the UCSC soft-masked RGSC 6.0/rn6 assembly of the rat genome. Note that Ensembl rat FASTA file formats, specifically how chromosomes are named, are currently incompatible with the ATAC pipeline (*updated 4 Nov 2018*).  
- `BLACKLIST` points to a BED file of regions to be masked from the rat genome. The URL below provides a dummy blacklist file that does not actually mask any regions in the rat genome. This may be changed in the future.  
- `TSS_ENRICH` points to a BED file of transcripition start site (TSS) annotations. The URL below includes rat TSS annotations curated from BioMart.  

Note that the pipeline (at least the local version with Conda) requires that these inputs be provided as URLs. Inputting a path to a file in a local directory will not work. The rat blacklist and TSS annotation files can be moved to a more permanent location in the future.  

So find these lines in `${PATH_TO_PIPELINE}/conda/install_genome_data.sh`:

```bash 
  ...

  elif [[ $GENOME == "YOUR_OWN_GENOME" ]]; then
    REF_FA="URL_FOR_YOUR_FASTA_OR_2BIT"
    BLACKLIST= # leave it empty if you don't have it

  ...
```
and replace them with these:  

```bash
  ...

  elif [[ $GENOME == "rn6" ]]; then
    REF_FA="http://hgdownload.cse.ucsc.edu/goldenPath/rn6/bigZips/rn6.fa.gz"
    BLACKLIST="http://web.stanford.edu/~nicolerg/blacklist.bed.gz"
    TSS_ENRICH="http://web.stanford.edu/~nicolerg/tss.rn6.bed.gz"

  ...
```

### 4. Generate JSON files

A JSON file specifying input parameters is required for each sample. Find documentation of definable parameters here: https://github.com/ENCODE-DCC/atac-seq-pipeline/blob/master/docs/input.md  

The `files` directory of this repository includes a couple of files to help: 

- `base_json`: Global parameters used for all samples and included in the generation of each JSON file through `make_json.sh`  
- `make_json.sh`: Example code to generate JSON files for samples with 2 replicates. See script for usage details.  
- `example.json`: Example of a JSON file for a sample with two replicates  

Note that the `genome_ref` variable in `make_json.sh` (which is the path to the `.tsv` file generated in Step 3) must correspond to the correct species (i.e. human or rat). 

### 5. Run pipeline

Actually asking the pipeline to run is easy:  

```bash 
source activate encode-atac-seq-pipeline # IMPORTANT!
INPUT=files/example.json
SRCDIR=/path/to/atac-seq-pipeline
java -jar -Dconfig.file=${SRCDIR}/backends/backend.conf ${SRCDIR}/cromwell-34.jar run ${SRCDIR}/atac.wdl -i ${INPUT}
```

It takes the better part of a day for the pipeline to finish running for one sample (at least with the limited resources allocated by the parameters documented in the `files` directory). Note that a `cromwell-executions` directory containing all of the pipeline outputs is created in whatever directory from which you run the above command, so choose wisely. One arbitrarily-named subdirectory for each JSON file will be written in `cromwell-executions/atac`.  

### 6. Collect important QC metrics  

The structure of the pipeline output is a bit complex. Most of the important metrics are in a JSON report in the `call-qc_report` subdirectory of each run. The are also plots of TSS enrichment in `call-ataqc` subdirectories. The `extract-atac-rep-outputs.sh` script in `files` pulls out these files as well as HTML QC reports, filtered BAM files, and optimal reproducibility_overlap peak files from all runs of pipeline and compiles them in a single folder. It also collapses all JSON reports into a single tab-delimited file called `merged.qc.txt` with section headers indicated by `##########`. Note that, as written, the collapsed JSON file will not make sense if different samples have different numbers of replicates.  

**The following metadata and QC metrics should be compiled and reported for every sample:**

- sample name 
- FASTQ prefix
- sequencing run
- platform
- species
- tissue
- sample treatment
- number of raw FASTQ reads
- TSS enrichment plots (from pipeline)
- insert size distribution plot (from pipeline)

Values from JSON report:  

- flagstat_qc: total
- falgstat_qc: mapped
- flagstat_qc: mapped_pct
- flagstat_qc: paired
- flagstat_qc: paired_properly
- flagstat_qc: paired_properly_pct
- nodup_flagstat_qc: total
- dup_qc: paired_reads
- dup_qc: paired_dupes
- dup_qc: dupes_pct
- pbc_qc: total_read_pairs
- pbc_qc: distinct_read_pairs
- pbc_qc: NRF
- pbc_qc: PBC1
- pbc_qc: PBC2
- FRiP_macs2_qc: all FRiP values
- overlap_reproducibility_qc: N_opt
- idr_reproducibility: N_opt
- overlap_frip_qc: FRiP values
- idr_frip_qc: FRiP values 

Other values that should be output by ATAQC module of pipeline (troubleshooting in progress):

- mitochondrial reads
- final reads (after all filters) - both number and percent
- presence of NFR peak
- TSS enrichment 
- FRiP in enhancer, promoter, DHS regions (at least for human)  

See https://www.encodeproject.org/data-standards/terms/ for an explanation of some of these terms.

### 7. ENCODE data quality standards (https://www.encodeproject.org/atac-seq/#standards) 

Metric                                       | Range        | Quality
-------------------------------------------- | ------------ | -----------
Number of non-dup, non-MT aligned reads (PE) | > 50M        | Recommended
-------------------------------------------- | ------------ | -----------
% mapped reads								               | > 95%		    | Ideal
.                                            | > 80%		    | Acceptable 
-------------------------------------------- | ------------ | -----------
NRF											                     | > 0.9        | Recommended
-------------------------------------------- | ------------ | -----------
PBC1										                     | > 0.9        | Recommended
-------------------------------------------- | ------------ | -----------
PBC2										                     | > 3			    | Recommended
-------------------------------------------- | ------------ | -----------
Number of `reproducibitily_overlap` peaks	   | > 150k		    | Ideal
.											                       | > 100k 		  | Acceptable
-------------------------------------------- | ------------ | -----------
Number of `reproducibililty_idr` peaks		   | > 70k		    | Ideal
.											                       | > 50k		    | Acceptable
-------------------------------------------- | ------------ | -----------
FRiP (fraction of reads in peaks)			       | > 0.3		    | Ideal
. 											                     | > 0.2		    | Acceptable
-------------------------------------------- | ------------ | -----------
TSS enrichment (GRCh38)						           | > 7			    | Ideal 
. 											                     | 5-7			    | Acceptable
.											                       | < 5			    | Concerning

