
% Load group connectomes
data_path='/Users/abry4213/data/HCP100';
load(sprintf('%s/raw_data/diffusion_MRI/aparc_acpc_connectome_data.mat', data_path));

% Consistency-based thresholding, as in https://github.com/DynamicsAndNeuralSystems/humanStructureFunction/blob/master/Analysis/GroupNodeStrength.m

% Consistency-based group connectome parameters
groupMethod = 'consistency';
threshold = 0.75; % consistency threshold as per Van den Heuvel & Sporns (2011)
dens = 0.29; % density threshold for variance method (if > .29, then values don't change)

% Use standard_length
distances = standard_length;
adjMatGroup = GroupAdjConsistency(SIFT2, distances, threshold, 'both');

% Save resulting group adjmat
writematrix(adjMatGroup, sprintf('%s/raw_data/diffusion_MRI/aparc_HCP100_group_avg_SIFT2_consistency_75.csv', data_path));