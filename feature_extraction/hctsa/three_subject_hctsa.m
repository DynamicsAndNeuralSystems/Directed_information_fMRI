study='D:\Virtual_Machines\Shared_Folder\github\testing_env';
cd(study);
run('D:\Virtual_Machines\Shared_Folder\github\hctsa\startup');

hctsa_dir='D:\Virtual_Machines\Shared_Folder\github\hctsa';
run(strcat(hctsa_dir, '\startup'));

params = GiveMeDefaultParams();
dataParams = params.data;
doRandomize = false;

% load lookup table from region number to region names
opts = detectImportOptions('data\fallon_2020_HCP\region_lookup.csv');
region_lut = table2cell(readtable("data\fallon_2020_HCP\region_lookup.csv", opts));

%-------------------------------------------------------------------------------
% Load in data for each subject
%-------------------------------------------------------------------------------
load('Data\subs100.mat');
subjects = table2array(subs100(:,{'subs'}));
keywords = {};
labels = {};
timeSeriesData = {};
%for i = 1:length(subjects)
for i = 1:3
       subjID = subjects(i);
       subject_file=fullfile(study, 'Data', 'rsfMRI', num2str(subjID), 'cfg.mat');
       subject_file_in = load(subject_file);

       % check the parameters defined in inFile.cfg.parcFiles
       % default parcellation = "DK"
       switch dataParams.whatParcellation
           case {'DK','aparc'}
               timeSeriesDataRaw = subject_file_in.cfg.roiTS{1}; % CHANGE THIS 1 = all voxels; 5 = equivolume 49 voxels; 2 = HCP parcellation
           case 'HCP'
               timeSeriesDataRaw = subject_file_in.cfg.roiTS{2};
           case 'cust200'
               timeSeriesDataRaw = subject_file_in.cfg.roiTS{3};
           otherwise
               error('Unknown parcellation: ''%s''',whatParcellation);
       end

       [numTime,numRegions] = size(timeSeriesDataRaw); % time x region

       fprintf(1,'Subject %s: %u regions, %u time points\n',num2str(subjID),numRegions,numTime);

       % z-score data and filter by hemisphere:
       % Normalize the data so every time series has mean 0 and std of 1:
       timeSeriesDataMat = zscore(timeSeriesDataRaw);

       if doRandomize
           fprintf(1,'RANDOMIZING TIME-SERIES STRUCTURE??!?!?!\n')
           % Independently randomize each region
           for i = 1:numRegions
               timeSeriesDataRaw(:,i) = timeSeriesDataRaw(randperm(numTime),i);
           end
           timeSeriesDataMat = zscore(timeSeriesDataRaw);
       end

       % Filter hemisphere:
       switch dataParams.whichHemispheres
           case 'both'
               % Don't filter
           case 'left'
               timeSeriesDataMat = timeSeriesDataMat(:,1:end/2);
               fprintf(1,'We filtered from %u to %u regions\n',...
                   size(timeSeriesDataRaw,2),size(timeSeriesDataMat,2))
               numRegions = size(timeSeriesDataMat,2);
           case 'right'
               timeSeriesDataMat = timeSeriesDataMat(:,((end/2)+1):end);
               fprintf(1,'We filtered from %u to %u regions\n',...
                   size(timeSeriesDataRaw,2),size(timeSeriesDataMat,2))
               numRegions = size(timeSeriesDataMat,2);
       end

       % Prep data for hctsa:
       keywords_subj    = cell(numRegions,1);
       keywords_subj(:) = {num2str(subjID)};
       keywords = [keywords; keywords_subj];

       % labels
       labels_subj = cellstr(strcat(num2str(subjID), "_", region_lut(:,2)));
       labels = [labels; labels_subj];

       % time series data
       timeSeriesDataTest = timeSeriesDataMat.';
       rowDist = repelem(1, numRegions);
       timeSeriesDataTest = mat2cell(timeSeriesDataTest,rowDist);
       timeSeriesData_subj = cellfun(@transpose,timeSeriesDataTest,'un',0);
       timeSeriesData = [timeSeriesData; timeSeriesData_subj];

end

% combine keywords, labels, and time-series data into a .mat file
save test_scripts\All100_Subject_HCTSA_input.mat keywords labels timeSeriesData;

% Initialize data for TS analysis
TS_Init(strcat(study, '\test_scripts\All100_Subject_HCTSA_input.mat'));
TS_Compute(true);
