
%% set path to Allen CCF files
%download from: http://data.cortexlab.net/allenCCF/
strAllenAtlasPath = 'C:\Users\haak\Desktop\AllenCCF_10um';

%% query user for sParams?
[strParamsFile, strParamsFilePath] = uigetfile('*.mat', 'Select file containing experiment params... ');
load(fullfile(strParamsFilePath, strParamsFile));

%% get results from Ilastik
%this function also removes points - marked in red - that are not on
%the slice and may give problems during transformation to CCF space!
sIlastikResults = getIlastikResults(sParams);
    
%% determine co-localization (optional)
%based on %overlap
% sIlastikResults = getIlastikOverlap(sParams, sIlastikResults);


%% get centroid coordinates in CCF space
cellPointsCCF = RH_histology2ccf(sIlastikResults.cellDetectedCoords_resized(:,2), sParams.strAlignmentSlicesPath);

%% save


%% make some plots