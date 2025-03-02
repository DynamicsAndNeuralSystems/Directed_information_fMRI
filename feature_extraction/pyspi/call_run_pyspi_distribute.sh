#!/usr/bin/env tcsh

set github_dir=/headnode1/abry4213/github
set pyspi_script_dir=${github_dir}/pyspi-distribute/
set pkl_file=calc.pkl
set pyspi_config=${github_dir}/HCP100_analysis/feature_extraction/fast_extended.yaml
set template_pbs_file=${pyspi_script_dir}/template.pbs
set email=abry4213@uni.sydney.edu.au
set conda_env=pyspi
set queue=yossarian
set pyspi_walltime_hrs=8
set pyspi_ncpus=2
set pyspi_mem=20
set data_path=/headnode1/abry4213/data/HCP100/raw_data/functional_MRI/
set sample_yaml=sample.yaml

# Activate given conda env
source /usr/physics/python/Anaconda3-2022.10/etc/profile.d/conda.csh
conda activate ${conda_env}

python $pyspi_script_dir/distribute_jobs.py \
--data_dir ${data_path}/numpy_files/ \
--calc_file_name $pkl_file \
--compute_file $pyspi_script_dir/pyspi_compute.py \
--template_pbs_file $template_pbs_file \
--pyspi_config $pyspi_config \
--sample_yaml $sample_yaml \
--pbs_notify a \
--email $email \
--conda_env $conda_env \
--queue $queue \
--walltime_hrs $pyspi_walltime_hrs \
--cpu $pyspi_ncpus \
--mem $pyspi_mem \
--table_only
