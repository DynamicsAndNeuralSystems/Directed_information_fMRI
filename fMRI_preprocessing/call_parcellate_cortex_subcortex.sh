#!/usr/bin/env bash

# Define the batch job array command
github_dir=/taiji1/abry4213/github/Homotopic_FC
input_model_file=$github_dir/HCP100_subject_list.txt

##################################################################################################

##################################################################################################
# Running parcellation across subjects
##################################################################################################

# Compute cortical + subcortical parcellations for each subject

cd $github_dir/fMRI_preprocessing

cmd="qsub -o $github_dir/cluster_output/HCP100_cortex_subcortex_parc_^array_index^.out \
   -J 1-100 \
   -N HCP100_parc \
   -l select=1:ncpus=1:mem=6GB:mpiprocs=1 \
   -v input_model_file=$input_model_file \
   parcellate_cortex_subcortex.pbs"
$cmd
