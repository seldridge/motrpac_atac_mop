#!/bin/bash

# Usage: bash make_json.sh [SAMPLE_REP1_PREFIX] [SAMPLE_REP2_PREFIX] [SAMPLE_NAME]
# SAMPLE_NAME: name to describe the pair of replicates
# SAMPLE_REP1_PREFIX: sample prefix of FASTQ files for rep1, i.e. ${PREFIX}_L00#_R#_001.fastq.gz
# SAMPLE_REP2_PREFIX: sample prefix of FASTQ files for rep2, i.e. ${PREFIX}_L00#_R#_001.fastq.gz
# By default, this code assumes there are FASTQ files for 4 lanes per read per sample. Change the num_lanes variable for a different number of lanes 

fastq_dir=/path/to/raw/fastq # path to raw FASTQ files
rep1=$1
rep2=$2
sample_name=$3 # name to describe the pair of replicates
num_lanes=4 # number of lanes per read per sample. this must be changed if the --no-lane-splitting option of bcl2fastq option is used to generate the FASTQ files 

json_dir=/path/to/outdir/json
base_json=/path/to/file/base_json # includes global parameters
genome_ref=/path/to/ref/tsv # .tsv file described here: https://github.com/ENCODE-DCC/atac-seq-pipeline/blob/master/docs/build_genome_database.md

#suffix of input fastq files
SUF_R1=_R1_001.fastq.gz
SUF_R2=_R2_001.fastq.gz

### write JSON file for a pair of replicates

json_file=${json_dir}/${sample_name}.json

echo "{" > ${json_file}
echo "    \"atac.title\" : \"${sample_name}\"," >> ${json_file}
echo "    \"atac.description\" : \"ATAC-seq on motrpac\"," >> ${json_file}
echo "    \"atac.pipeline_type\" : \"atac\"," >> ${json_file}
echo "    \"atac.genome_tsv\" : \"${genome_ref}\"," >> ${json_file}

cat ${base_json} >> ${json_file} # includes global parameters

echo >> ${json_file}

# replicate 1, read 1, all lanes
echo "    \"atac.fastqs_rep1_R1\" : [" >> ${json_file}
counter=1
for j in $(ls ${fastq_dir}/${rep1}_*L00*${SUF_R1})
do
	if [ "$counter" = "$num_lanes" ]; then
		echo "        \"${j}\"" >> ${json_file}
	else
		echo "        \"${j}\"," >> ${json_file}
	fi
	counter=$((counter +1))
done
echo "    ]," >> ${json_file}
echo >> ${json_file}

# replicate 1, read 2, all lanes 
echo "    \"atac.fastqs_rep1_R2\" : [" >> ${json_file}
counter=1
for k in $(ls ${fastq_dir}/${rep1}_*L00*${SUF_R2}); do
	if [ "$counter" = "$num_lanes" ]; then
		echo "        \"${k}\"" >> ${json_file}
	else
		echo "        \"${k}\"," >> ${json_file}
	fi
	counter=$((counter +1))
done
echo "    ]" >> ${json_file}

# replicate 2, read 1, all lanes
echo "    \"atac.fastqs_rep2_R2\" : [" >> ${json_file}
counter=1
for k in $(ls ${fastq_dir}/${rep2}_*L00*${SUF_R1}); do
	if [ "$counter" = "$num_lanes" ]; then
		echo "        \"${k}\"" >> ${json_file}
	else
		echo "        \"${k}\"," >> ${json_file}
	fi
	counter=$((counter +1))
done
echo "    ]" >> ${json_file}

# replicate 2, read 2, all lanes 
echo "    \"atac.fastqs_rep2_R2\" : [" >> ${json_file}
counter=1
for k in $(ls ${fastq_dir}/${rep2}_*L00*${SUF_R2}); do
	if [ "$counter" = "$num_lanes" ]; then
		echo "        \"${k}\"" >> ${json_file}
	else
		echo "        \"${k}\"," >> ${json_file}
	fi
	counter=$((counter +1))
done
echo "    ]" >> ${json_file}

echo "}" >> ${json_file}
