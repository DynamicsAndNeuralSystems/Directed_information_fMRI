import pandas as pd
import numpy as np
from pyspi.calculator import Calculator
import os.path as op
from copy import deepcopy
import os

data_path = "/Users/abry4213/data/HCP100"
SPI_subset = "/Users/abry4213/github/Directed_Information_fMRI/feature_extraction/pyspi/fast_extended.yaml"
ROI_lookup_file = "/Users/abry4213/github/Directed_Information_fMRI/data/Brain_Region_info.csv"
connectivity_type = "full"

# Get the base name for SPI_subset file
SPI_subset_base = op.basename(SPI_subset).replace(".yaml", "")

# Time series output path for this subject
time_series_path = f"{data_path}/raw_data/functional_MRI/numpy_files/"
output_feature_path = op.join(data_path, "time_series_features/pyspi")

# Define ROI lookup table
brain_region_lookup = pd.read_csv(ROI_lookup_file)

def run_pyspi_for_df_all(subject_ID, TS_array, calc, brain_region_lookup, output_feature_path, SPI_subset_base="fast_extended"):

    output_file = f"{output_feature_path}/HCP100_{subject_ID}_all_homotopic_FC_pyspi_{SPI_subset_base}_results.csv"

    if op.exists(output_file):
        print(f"Output file already exists: {output_file}")
        return
    
    # Print number of rows in TS_array
    print(f"Number of rows in TS_array: {TS_array.shape[0]}")

    homotopic_region_res_list = []
    for brain_region_base in brain_region_lookup.Base_Region.unique():
        left_index = brain_region_lookup[brain_region_lookup.Brain_Region == f"ctx-lh-{brain_region_base}"].Region_Index.values[0]
        right_index = brain_region_lookup[brain_region_lookup.Brain_Region == f"ctx-rh-{brain_region_base}"].Region_Index.values[0]

        left_right_TS_only = TS_array[[left_index, right_index], :]

        # Make deepcopy of calc 
        calc_copy = deepcopy(calc)

        # Load data 
        calc_copy.load_dataset(left_right_TS_only)

        # Compute SPIs
        calc_copy.compute()

        # Get SPI results
        SPI_res = deepcopy(calc_copy.table)

        SPI_res.columns = SPI_res.columns.to_flat_index()
        SPI_res = SPI_res.rename(columns='__'.join).assign(hemi_from = lambda x: x.index)

        # Reshape from wide to long, and add columns for hemisphere and base region
        SPI_res_long = SPI_res.melt(id_vars='hemi_from', var_name='SPI__hemi_to', value_name='value')
        SPI_res_long["SPI"] = SPI_res_long["SPI__hemi_to"].str.split("__").str[0]
        SPI_res_long = (SPI_res_long
                        .assign(hemi_from = lambda x: np.where(x.hemi_from == 'proc-0', 'left', 'right'),
                                hemi_to = lambda x: np.where(x.SPI__hemi_to.str.contains('proc-0'), 'left', 'right'),
                                base_region_to = brain_region_base,
                                base_region_from = brain_region_base)
                        .drop(columns='SPI__hemi_to')
                        .query("hemi_from != hemi_to")
                        )
        
        # Append to list
        homotopic_region_res_list.append(SPI_res_long)

    # Concatenate all homotopic region results
    homotopic_region_res = pd.concat(homotopic_region_res_list)

    homotopic_region_res.to_csv(output_file, index=False)


# Iterate over subjects in time_series_path
subject_list = [f.replace(".npy", "") for f in os.listdir(time_series_path) if f.endswith(".npy")]

# Create a new Calculator object
calc = Calculator(configfile=SPI_subset)

for subject_ID in subject_list:
    print(f"Processing subject {subject_ID}...")

    # Load the time series data for the subject
    npy_file = f"{time_series_path}/{subject_ID}.npy"
    TS_array = np.load(npy_file)


    # Run pyspi for this subject
    run_pyspi_for_df_all(subject_ID, TS_array, calc, brain_region_lookup, output_feature_path, SPI_subset_base)