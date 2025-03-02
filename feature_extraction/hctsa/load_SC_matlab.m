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
%% Load structural connectivity for subject:
%-------------------------------------------------------------------------------
load('Data\subs100.mat');
subjects = table2array(subs100(:,{'subs'}));

% test with the first subject
subjID = subjects(1);

% Get ROI conn data
connDataWeighted = GiveMeSC(subjID);
switch dataParams.whichHemispheres
    case 'both'
        connDataWeighted = GiveMeSC(subjID);
    case 'left'
        connDataWeighted = connDataWeighted(1:end/2,1:end/2);
    case 'right'
        connDataWeighted = connDataWeighted';
        connDataWeighted = connDataWeighted(1:end/2,1:end/2);
end
