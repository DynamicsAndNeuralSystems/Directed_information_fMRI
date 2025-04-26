import pandas as pd
import numpy as np
from pyspi.calculator import Calculator
import os.path as op
from copy import deepcopy
import argparse

parser=argparse.ArgumentParser()
parser.add_argument('--sub',
                    type=str,
                    default='100307',
                    help='subject_id (e.g. "100307")')
parser.add_argument('--data_path',
                    type=str,
                    default='/headnode1/abry4213/data/HCP100/',
                    help='Path to the HCP100 root directory')
parser.add_argument('--ROI_lookup_file',
                    type=str,
                    default='/headnode1/abry4213/data/HCP100/',
                    help='Path to the ROI lookup file')
parser.add_argument('--connectivity_type',
                    type=str,
                    default='homotopic',
                    help='Whether to look at all pairwise combinations or just homotopic connectivity')
parser.add_argument('--SPI_subset',
                    type=str,
                    default='fast',
                    help='Subset of SPIs to compute')
opt=parser.parse_args()

subject_id = opt.sub 
data_path = opt.data_path
SPI_subset = opt.SPI_subset
ROI_lookup_file = opt.ROI_lookup_file
connectivity_type = opt.connectivity_type

# Get the base name for SPI_subset file
SPI_subset_base = op.basename(SPI_subset).replace(".yaml", "")

# Time series output path for this subject
time_series_path = f"{data_path}/raw_data/functional_MRI/numpy_files/"
output_feature_path = op.join(data_path, "time_series_features/pyspi")

# Define ROI lookup table
brain_region_lookup = pd.read_csv(ROI_lookup_file)

# Check if pyspi results already exist for this subject
if connectivity_type == "full":
    output_file = f"{output_feature_path}/HCP100_{subject_id}_all_pyspi_{SPI_subset_base}_results.csv"
else:
    output_file = f"{output_feature_path}/HCP100_{subject_id}_homotopic_pyspi_{SPI_subset_base}_results.csv"

if op.isfile(output_file):
    print(f"{SPI_subset_base} SPI results for {subject_id} already exist. Skipping.")
    exit() 

# Load in the .npy file
npy_file = f"{time_series_path}/{subject_id}.npy"
TS_data = np.load(npy_file)

def run_pyspi_for_df_all(TS_array, calc, brain_region_lookup):
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
                    )

    return SPI_res_long


def run_pyspi_for_df_homotopic(TS_array, calc, brain_region_lookup):
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

    return homotopic_region_res

# Initialise a base calculator
if SPI_subset == "fast":
    calc = Calculator(subset='fast')
else:
    calc = Calculator(configfile=SPI_subset)

# Run for data
if connectivity_type == "full":
    pyspi_res = run_pyspi_for_df_all(TS_data, calc, brain_region_lookup).assign(Subject=subject_id).reset_index()
else:
    pyspi_res = run_pyspi_for_df_homotopic(TS_data, calc, brain_region_lookup).assign(Subject=subject_id).reset_index()

pyspi_res.to_csv(output_file, index=False)