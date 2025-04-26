# Homotopic functional connectivity analysis resting-state fMRI

This repository contains all code and intermediate data needed to replicate analyses in our preprint, ['Mapping functional, cytoarchitectonic, and transcriptomic underpinnings of homotopic connectivity']().


<img src="plots/final_figures/HoFC_gradients_HCP.png" width="90%">

## About the data

### Resting-state fMRI data

Two distinct datasets were included in this project, both of which are openly available: (1) the [Human Connectome Project (HCP)]() and (2) the [UCLA Consortium for Neuropsychiatric Phenomics LA5c study (CNP)]().
The first dataset in this analysis (`Dataset 1') is comprised of $N=207$ unrelated participants ($N=83$ males, $28.7 \pm 3.7$ years of age) from the S1200 release of the Human Connectome Project~\citep{van2013wu}, as curated and preprocessed by the ENIGMA Consortium~\citep{lariviere2021enigma}.
Structural and functional connectivity matrices from the HCP dataset were pre-processed and made available by the [ENIGMA Consortium](https://enigma-toolbox.readthedocs.io/en/latest/pages/05.HCP/).

The second dataset in this analysis (UCLA CNP) includes N=252 participants (N=116 controls, N=48 schizophrenia, N=49 bipolar I disorder, and N=39 attention-deficity hyperactivity disorder).
Resting-state fMRI data, along with structural MRI, were downloaded from openNeuro and preprocessed in previous work (see [Aquino et al. (2020)]() and [Bryant et al. (2024)]()).
Group-averaged functional connectivity matrices from the UCLA CNP dataset were compiled in [Bryant et al. (2024)]() and are included here in the [data/]() folder for reproducibility.