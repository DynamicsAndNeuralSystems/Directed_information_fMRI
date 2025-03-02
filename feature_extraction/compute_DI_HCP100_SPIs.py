import pandas as pd
from pyspi.calculator import Calculator
import numpy as np
from copy import deepcopy
import glob
import os
import random

# Define data directory
data_dir = "data/numpy_arrays/"

# Load the brain region lookup table
brain_region_lookup = pd.read_csv("Brain_Region_info.csv", index_col=False).reset_index(drop=True)
base_regions = list(set(brain_region_lookup.Base_Region.tolist()))

# Define configuration file
di_gaussian_config_file = "DI_Gaussian_config.yaml"

# Initialise a Calculator object with this configuration file
calc = Calculator(configfile=di_gaussian_config_file)

# Helper function to read in a base region (e.g., bankssts) and compute
# Directed information from left to right and from right to left
def compute_DI_for_region(base_region, brain_region_lookup, subject_ID, subject_data, basecalc):
    left_index = brain_region_lookup.query("Base_Region == @base_region & Hemisphere == 'Left'").Region_Index.tolist()[0]
    right_index = brain_region_lookup.query("Base_Region == @base_region & Hemisphere == 'Right'").Region_Index.tolist()[0]
    
    # Subset the subject_data numpy array to just left_index and right_index
    left_TS = subject_data[left_index,:].reshape(1, -1)
    right_TS = subject_data[right_index,:].reshape(1, -1)
    
    # Combine left_TS and right_TS into a 2 by 1200 numpy array
    bilateral_arr_to_compute = np.concatenate((left_TS, right_TS), axis=0)
    
    # Compute directed information for these two time-series
    calc = deepcopy(basecalc)
    calc.load_dataset(bilateral_arr_to_compute)
    calc.compute()
    
    # Extract directed information results as the calc.table object
    ROI_DI_data = calc.table 
    
    # Flatten the MultiIndex columns to just the process IDs
    ROI_DI_data.columns = ROI_DI_data.columns.get_level_values(1)
    
    # Pivot and clean up ROI directed information data
    ROI_DI_data = (ROI_DI_data
                   .reset_index(level=0) # Convert index to column
                   .rename(columns={"index": "Hemi_from"}) # Rename index as first hemisphere
                   .melt(id_vars="Hemi_from") # Pivot data from wide to long
                   .rename(columns={"process": "Hemi_to"}) # Rename hemisphere receiving the connection
                   .query("Hemi_from != Hemi_to") # Remove self-connections
                   .assign(Sample_ID = subject_ID,
                           Brain_Region = base_region)
                    .assign(Hemi_from=lambda x: x['Hemi_from'].replace({'proc-0': 'left', 'proc-1': 'right'}),
                            Hemi_to=lambda x: x['Hemi_to'].replace({'proc-0': 'left', 'proc-1': 'right'}))
                   )
    
    # Return the final dataframe for this region
    return ROI_DI_data

# Define a base Calculator object
basecalc = Calculator(configfile="DI_Gaussian_config.yaml")

# Initialise a list for all HCP100 directed information
HCP100_DI_list = []

# Iterate over each of the 100 
for subject_filepath in glob.glob(f'{data_dir}/*.npy'):
    
    # Subset to basename for file
    subject_npy = os.path.basename(subject_filepath)
    
    # Get sample ID substring
    subject_ID = subject_npy.replace(".npy", "")
    
    # Load in subject's ROI time series from numpy binary file
    subject_data = np.load(data_dir + subject_npy)
    
    # Initialise a list to store the directed information for each region between left and right hemispheres
    subject_DI_list = []
    
    # Apply compute_DI_for_region to each base region
    for base_region in base_regions:
        ROI_DI_data = compute_DI_for_region(base_region = base_region,
                                            brain_region_lookup = brain_region_lookup,
                                            subject_ID = subject_ID,
                                            subject_data = subject_data,
                                            basecalc = basecalc)
        subject_DI_list.append(ROI_DI_data)
    
    # Concatenate dataframes across regions
    subject_DI = pd.concat(subject_DI_list, axis=0)
    
    HCP100_DI_list.append(subject_DI)

# Combine all the dataframes in the HC100_DI_list into a single dataframe
HCP100_DI = (pd.concat(HCP100_DI_list, axis=0)
             .rename(columns={"value": "di_gaussian"})
             )

HCP100_DI.to_csv("data/HCP100_Directed_Information.csv", index = False)