# python_to_use <- "/Users/abry4213/anaconda3/envs/pyspi/bin/python3"
python_to_use <- "/headnode1/abry4213/.conda/envs/pyspi/bin/python3"
reticulate::use_python(python_to_use)

library(R.matlab)
library(tidyverse)
library(feather)
library(glue)
library(reticulate)

# Define data paths
data_path <- "/headnode1/abry4213/data/HCP100/raw_data/"
fMRI_data_path <- glue("{data_path}/fMRI/")
dMRI_data_path <- glue("{data_path}/dMRI/")
TAF::mkdir(fMRI_data_path)
TAF::mkdir(dMRI_data_path)


# DIY rlist::list.append
list.append <- function (.data, ...) 
{
  if (is.list(.data)) {
    c(.data, list(...))
  }
  else {
    c(.data, ..., recursive = FALSE)
  }
}

################################# Parse data ###################################

# Read in brain region info
brain_region_lookup <- read.csv("~/data/HCP100/Brain_Region_info.csv") %>%
  arrange(Index)

# Pre-process control data
if (!file.exists(glue("{fMRI_data_path}/HCP100_fMRI_TS.feather"))) {
  # List sample IDs
  sample_IDs <- list.files(glue("{fMRI_data_path}/cfg_data/"))
  sample_fMRI_TS_list <- list()
  
  # Iterate over sample IDs and read in their config data
  for (sample_ID in sample_IDs) {
    # Load in matlab data
    sample_TS_data <- as.data.frame(R.matlab::readMat(glue("{fMRI_data_path}/cfg_data/{sample_ID}/cfg.mat"))[[2]][[1]][[1]])
    
    # Link index to brain region
    colnames(sample_TS_data) <- brain_region_lookup$Brain_Region
    sample_TS_data$Sample_ID <- sample_ID
    
    # Pivot from wide to long
    sample_TS_data_long <- sample_TS_data %>% pivot_longer(cols=c(-Sample_ID),
                                                           names_to="Brain_Region",
                                                           values_to="value") %>%
      group_by(Brain_Region) %>%
      mutate(timepoint = row_number())
    
    # Append to growing list
    sample_fMRI_TS_list <- list.append(sample_fMRI_TS_list, sample_TS_data_long)
  }
  # Concatenate data
  sample_fMRI_TS <- do.call(plyr::rbind.fill, sample_fMRI_TS_list)
  
  # Save to feather file
  feather::write_feather(sample_fMRI_TS, glue("{fMRI_data_path}/HCP100_fMRI_TS.feather"))
} else {
  sample_fMRI_TS <- feather::read_feather(glue("{fMRI_data_path}/HCP100_fMRI_TS.feather"))
}

################################################################################
# Pyspi prep
################################################################################

# Helper function to write dataset to a numpy file
write_data_to_numpy <- function(sample_df) {
  
  sample_ID <- unique(sample_df$Sample_ID)
  # Convert to matrix
  sample_mat <- sample_df %>%
    dplyr::select(-Sample_ID, -Brain_Region) %>%
    as.matrix()
  
  # Save to numpy file
  np$save(glue("{numpy_file_path}/{sample_ID}"),
          np$array(sample_mat))
}

# Split by group
rs_fMRI_data_split_sample <- sample_fMRI_TS %>%
  # Z-score data
  group_by(Sample_ID, Brain_Region) %>%
  mutate(value_z = scale(value)) %>%
  pivot_wider(id_cols=c(Sample_ID, Brain_Region), names_from = timepoint, values_from = value_z) %>%
  group_by(Sample_ID) %>%
  group_split()

# Write files to numpy arrays for pyspi processing
np <- reticulate::import("numpy")
numpy_file_path <- as.character(glue("{fMRI_data_path}/numpy_files"))
TAF::mkdir(numpy_file_path)

1:length(rs_fMRI_data_split_sample) %>%
  purrr::map(~ write_data_to_numpy(sample_df = rs_fMRI_data_split_sample[.x][[1]]))

# Create a YAML file for these .npy files
yaml_script_file <- "~/github/pyspi-distribute/create_yaml_for_samples.R"

ID_var <- "Sample_ID"
dim_order <- "ps"
yaml_file_base <- "sample.yaml"

cmd <- glue("Rscript {yaml_script_file} --data_dir {as.character(numpy_file_path)} --numpy_file_base .npy --ID_var {ID_var} --dim_order {dim_order} --yaml_file {yaml_file_base}")
system(cmd)