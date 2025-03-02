#!/usr/bin/env bash

# Define the batch job array command
github_dir=/headnode1/abry4213/github/Directed_information_fMRI
input_model_file=$github_dir/HCP100_subject_list.txt

##################################################################################################
# Running pyspi across subjects -- homotopic connectivity
##################################################################################################

# Run pyspi for the 100 HCP subjects
connectivity_type=homotopic

fast_ext_yaml=$github_dir/feature_extraction/pyspi/fast_extended.yaml
cmd="qsub -o $github_dir/cluster_output/HCP100_pyspi_^array_index^_fast_extended.out \
   -J 1-100 \
   -N HCP100_pyspi \
   -l select=1:ncpus=1:mem=20GB:mpiprocs=1 \
   -v input_model_file=$input_model_file,SPI_subset=$fast_ext_yaml,connectivity_type=$connectivity_type \
   run_pyspi_for_HCP100_subject.pbs"
$cmd