import pandas as pd
import numpy as np
from pyspi.calculator import Calculator
import os.path as op
from copy import deepcopy
import os

data_path = "/Users/abry4213/data/HCP100"
SPI_subset = "/Users/abry4213/github/Directed_Information_fMRI/feature_extraction/pyspi/Pearson.yaml"
ROI_lookup_file = "/Users/abry4213/github/Directed_Information_fMRI/data/Brain_Region_info.csv"
connectivity_type = "full"

# Get the base name for SPI_subset file
SPI_subset_base = op.basename(SPI_subset).replace(".yaml", "")

# Time series output path for this subject
time_series_path = f"{data_path}/raw_data/functional_MRI/numpy_files/"
output_feature_path = op.join(data_path, "time_series_features/pyspi")

# Define ROI lookup table
brain_region_lookup = pd.read_csv(ROI_lookup_file)

def run_pyspi_for_df_all(subject_ID, TS_array, calc, brain_region_lookup, output_feature_path, SPI_subset_base="Pearson"):

    output_file = f"{output_feature_path}/HCP100_{subject_ID}_all_pyspi_{SPI_subset_base}_results.csv"

    if op.exists(output_file):
        print(f"Output file already exists: {output_file}")
        return
    
    # Print number of rows in TS_array
    print(f"Number of rows in TS_array: {TS_array.shape[0]}")

    # Make deepcopy of calc 
    calc_copy = deepcopy(calc)

    # Load data 
    calc_copy.load_dataset(TS_array)

    # Compute SPIs
    calc_copy.compute()

    # Get SPI results
    SPI_res = deepcopy(calc_copy.table)
    SPI_res.columns = SPI_res.columns.to_flat_index()

    SPI_res = SPI_res.rename(columns='__'.join).assign(region_from = lambda x: x.index)
    SPI_res_long = SPI_res.melt(id_vars='region_from', var_name='SPI__region_to', value_name='value')

    # Reshape from wide to long, and add columns for hemisphere and base region
    SPI_res_long["SPI"] = SPI_res_long["SPI__region_to"].str.split("__").str[0]
    SPI_res_long["region_to"] = SPI_res_long["SPI__region_to"].str.split("__").str[1]

    SPI_res_long = (SPI_res_long.rename(columns={"region_from": "region_from_index", "region_to": "region_to_index"})
                        .reset_index(drop=True)
                        .assign(region_from_index = lambda x: x.region_from_index.str.replace("proc-", ""),
                            region_to_index = lambda x: x.region_to_index.str.replace("proc-", ""))
                        .astype({"region_from_index": int, "region_to_index": int})
                        .merge(brain_region_lookup[["Region_Index", "Base_Region", "Hemisphere"]], left_on="region_from_index", right_on="Region_Index", how="left")
                        .rename(columns={"Base_Region": "base_region_from", "Hemisphere": "hemi_from"})
                        .drop(columns=["Region_Index"])
                        .merge(brain_region_lookup[["Region_Index", "Base_Region", "Hemisphere"]], left_on="region_to_index", right_on="Region_Index", how="left")
                        .rename(columns={"Base_Region": "base_region_to", "Hemisphere": "hemi_to"})
                        .drop(columns=["Region_Index", "region_from_index", "region_to_index", "SPI__region_to"])
                        .assign(Subject_ID = subject_ID)
                    )

    SPI_res_long.to_csv(output_file, index=False)


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