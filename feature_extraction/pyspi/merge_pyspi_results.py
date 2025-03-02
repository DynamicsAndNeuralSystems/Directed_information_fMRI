import pandas as pd
import numpy as np
from pyspi.calculator import Calculator
import os.path as op
from copy import deepcopy
import argparse
import pickle

def load_pyspi_results_for_subject(calc_file):
        
        # Load calc_file, which is a .pkl file
        with open(calc_file, 'rb') as f:
            SPI_res = pickle.load(f)

        # Iterate over each SPI
        SPI_res.columns = SPI_res.columns.to_flat_index()

        SPI_res = SPI_res.rename(columns='__'.join).assign(meta_ROI_from = lambda x: x.index)
        SPI_res_long = SPI_res.melt(id_vars='meta_ROI_from', var_name='SPI__meta_ROI_to', value_name='value')

        SPI_res_long["SPI"] = SPI_res_long["SPI__meta_ROI_to"].str.split("__").str[0]
        SPI_res_long["meta_ROI_to"] = SPI_res_long["SPI__meta_ROI_to"].str.split("__").str[1]

        SPI_res_long = (SPI_res_long
                        .drop(columns='SPI__meta_ROI_to')
                        .query('meta_ROI_from != meta_ROI_to')
                        .assign(meta_ROI_from = lambda x: x['meta_ROI_from'].map(ROI_lookup),
                                meta_ROI_to = lambda x: x['meta_ROI_to'].map(ROI_lookup))
                        .filter(items=['SPI', 'meta_ROI_from', 'meta_ROI_to', 'value'])
                        .assign(stimulus_type = df['stimulus_type'].unique()[0],
                                relevance_type = df['relevance_type'].unique()[0],
                                duration = df['duration'].unique()[0],
                                stimulus_presentation = df['stimulus'].unique()[0],
                                subject_ID = subject_id)
        )

        return SPI_res_long