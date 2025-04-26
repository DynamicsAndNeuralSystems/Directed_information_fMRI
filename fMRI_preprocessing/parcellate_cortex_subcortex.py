import pandas as pd
import numpy as np
import random

# File operations
from copy import deepcopy
import glob
import os
from pathlib import Path

# Neuroimaging
from nibabel import freesurfer as fs
import nibabel as nib
import abagen

# Set seed to 127
random.seed(127)

# Parse arguments
import argparse
parser = argparse.ArgumentParser(description='Parcellate cortex and subcortex.')
parser.add_argument('--subject', type=str, required=True, help='Subject ID')
parser.add_argument('--atlas_data_path', type=str, required=True, help='Atlas name')
parser.add_argument('--fMRI_data_path', type=str, required=True, help='fMRI data path')

args = parser.parse_args()

# HCP subject ID
subject = args.subject

# Paths
atlas_data_path = args.atlas_data_path
fMRI_data_path = args.fMRI_data_path

# Function for the given phase encoding direction
def parcellate_phase_enc(fMRI_data_path, cifti_data, subject, phase_enc, parc_labels, parc_lookup, atlas_name='Schaefer300_homotopic'):
    """
    Parcellate the fMRI data for the given phase encoding direction.
    """
    # Check output doesn't already exist
    if os.path.exists(f'{fMRI_data_path}/parcellated_time_series/{subject}_{atlas_name}_parcel_timeseries_{phase_enc}.csv'):
        print(f'Output already exists for {subject} {atlas_name} {phase_enc}. Skipping.')
        return
        
    #############################################################################
    #### Apply parcellation ####
    #############################################################################
    unique_labels = np.unique(parc_labels)
    unique_labels = unique_labels[unique_labels != 0]  # Exclude unlabeled (0)

    # Mean time series for each parcel
    parcel_timeseries = []
    for label in unique_labels:
        idx = np.where(parc_labels == label)[0]
        parcel_ts = cifti_data[:, idx].mean(axis=1)  # Mean across grayordinates
        parcel_timeseries.append(parcel_ts)

    # Convert to DataFrame for convenience
    parcel_TS_df = pd.DataFrame(parcel_timeseries).T  # shape: (timepoints, parcels)
    parcel_TS_df.columns = parc_lookup.Region

    #############################################################################
    #### Save the results to .csv files ####
    #############################################################################

    # Save the cortical timeseries
    parcel_TS_df.to_csv(f'{fMRI_data_path}/parcellated_time_series/{subject}_{atlas_name}_parcel_timeseries_{phase_enc}.csv', index=False)

# Run for the two phase encoding directions
for phase_enc in ['LR', 'RL']:

    # Load the CIFTI grayordinate timeseries
    cifti_file = f'{fMRI_data_path}/raw_data/{subject}/rfMRI_REST1_{phase_enc}_Atlas_MSMAll_hp2000_clean.dtseries.nii'
    dtseries = nib.load(cifti_file)
    cifti_data = dtseries.get_fdata()  # shape: (timepoints, grayordinates)

    ############## Schaefer300-homotopic parcellation ##############
    schaefer300_homotopic_labels = nib.load(f'{atlas_data_path}/Schaefer/HCP/Yan2023_Homotopic/300Parcels_Yeo2011_7Networks.dlabel.nii').get_fdata().squeeze().astype(int)
    schaefer300_homotopic_lookup = pd.read_table(f'{atlas_data_path}/Schaefer/HCP/Yan2023_Homotopic/300Parcels_Yeo2011_7Networks_info.txt', header=None)

    # Take every other row of cortical_lookup, ignoring the lookup color rows
    schaefer300_homotopic_lookup = (schaefer300_homotopic_lookup
                       .iloc[::2, :]
                       .reset_index(drop=True)
                       .rename(columns={0: 'Region'})
                       .assign(Region_Index = lambda x: range(1, x.shape[0] + 1))
    )

    parcellate_phase_enc(fMRI_data_path=fMRI_data_path, cifti_data=cifti_data,
                         subject=subject, phase_enc=phase_enc, 
                         parc_labels=schaefer300_homotopic_labels, 
                         parc_lookup=schaefer300_homotopic_lookup, atlas_name='Schaefer300_homotopic')
    
    ############## Desikan-Killiany parcellation ##############
    desikan_killiany_labels = nib.load(f'{atlas_data_path}/DesikanKilliany/fsaverage/atlas-desikankilliany.dscalar.nii').get_fdata().squeeze().astype(int)  # shape: (grayordinates,)
    desikan_killiany_lookup = pd.read_csv(f'{atlas_data_path}/DesikanKilliany/fsaverage/dk_lookup_single_hemi.csv')

    parcellate_phase_enc(fMRI_data_path=fMRI_data_path, cifti_data=cifti_data,
                         subject=subject, phase_enc=phase_enc, 
                         parc_labels=desikan_killiany_labels, 
                         parc_lookup=desikan_killiany_lookup, atlas_name='Desikan_Killiany')
    
    ############## Tian subcortex S1 parcellation ##############
    subcortical_labels = nib.load(f'{atlas_data_path}/Tian_Subcortex/Tian_Subcortex_S1_3T_32k.dscalar.nii').get_fdata().squeeze().astype(int)  # shape: (grayordinates,)
    subcortical_lookup = pd.read_table(f'{atlas_data_path}/Tian_Subcortex/Tian_Subcortex_S1_3T_label.txt', header=None)

    subcortical_lookup = (subcortical_lookup
                          .rename(columns={0: 'Region'})
                          .assign(Region_Index = lambda x: range(1, x.shape[0] + 1),
                                  Base_Region = lambda x: x['Region'].str.split('-').str[0],
                                  Hemisphere = lambda x: x['Region'].str.split('-').str[1])
    )

    parcellate_phase_enc(fMRI_data_path=fMRI_data_path, cifti_data=cifti_data,
                            subject=subject, phase_enc=phase_enc, 
                            parc_labels=subcortical_labels, 
                            parc_lookup=subcortical_lookup, atlas_name='Tian_Subcortex_S1')