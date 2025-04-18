% Load path
addpath(genpath('/Users/abry4213/github/ENIGMA/matlab/'));

% Define data path
github_path='/Users/abry4213/github/Homotopic_FC/';
data_path=sprintf('%s/data/', github_path);

% Read in subcortical HoFC data
subctx_HoFC = readmatrix(sprintf('%s/HCP_subctx_HoFC.txt', data_path));

f = figure, plot_subcortical_annie(subctx_HoFC, 'ventricles', 'False', 'color_range', [0.021 0.714]);

% Apply the viridis colormap after plotting
colormap(viridis)

% Save the .png
saveas(gcf, '../plots/subcortex/Subcortex_HoFC_Pearson_ENIGMA_HCP_fMRI.png');

%%
subctx_indices = [1:7 1:7];


f = figure, plot_subcortical_annie(subctx_indices, 'ventricles', 'False');


% Apply the viridis colormap after plotting
colormap(plasma)


saveas(gcf, '../plots/subcortex/ENIGMA_left_subctx.png');
