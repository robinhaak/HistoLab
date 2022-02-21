
%PRE-PROCESS slice images & ALIGN to Allen CCF
%Robin Haak, 19 Feb '22
%
%-split .czis into multiple .tifs (per scene, per channel)
%-reorder and/or flip slices, if applicable
%-create training set for ilastik (cell detection)
%
%(!)files should be organized so that a folder contains images of 1 subject(!)
%(!)assumes that the same scan profile is used for all images(!)

%% set path to Allen CCF files
%download from: http://data.cortexlab.net/allenCCF/
strAllenAtlasPath = '/Users/robinhaak/Desktop/CCF_10um';

%% query user for experiment metadata
sParams = struct;
sParams.strProject = 'Innate_defense';
sParams.strDataSet = 'xx.xx.xx'; %SD number
sParams.strMouseID = 'xxxxxxx';
sParams.strExperimentDate = 'YYYYMMDD';
sParams.strInvestigator = 'Robin_Haak';
sParams.strCondition = '';

cellPrompt = {'strProject', 'strDataset (i.e., SD number)', 'strMouseID', 'sExperimentDate', 'strInvestigator', 'strCondition'};
strDlgTitle = 'Experiment metadata';
vecDims = [1 50];
cellDefInput = {sParams.strProject, sParams.strDataSet, sParams.strMouseID, sParams.strExperimentDate, sParams.strInvestigator, sParams.strCondition};
cellAnswer = inputdlg(cellPrompt, strDlgTitle, vecDims, cellDefInput);

%update sParams
sParams.strProject = cellAnswer{1};
sParams.strDataset = cellAnswer{2};
sParams.strMouseID = cellAnswer{3};
sParams.strExperimentDate = cellAnswer{4};
sParmas.strInvestigator = cellAnswer{5};
sParams.strCondition = cellAnswer{6};

%% query user for path to czi files
sParams.strSlidePath = uigetdir([], 'Select folder containing slide scans (.czi)...\n\n');

%get names of.czi files
sCziDir = dir(fullfile(sParams.strSlidePath, '*.czi'));
i = 1;
while i <= length(sCziDir)
    if contains(sCziDir(i).name, '_pt')
        sCziDir(i) = [];
    else
        i = i+1;
    end
end

%display in command window & add to sParams
%fprintf('\n\n\nThe folder "%s" contains %d .czi files:\n', sParams.strSlidePath, length(sCziDir));
for intSlide = 1:length(sCziDir)
    %fprintf('- %s\n', sCziDir(intSlide).name);
    sParams.cellCziFiles{intSlide} = sCziDir(intSlide).name;
end

%save sParams
save([sParams.strSlidePath filsep sParams.strMouseID '_' sParams.strExperimentDate '.mat'], sParams);

%% convert .czi to .tifs
%try increasing java heap memory (preferences > general) if this gives an error, ignore log4j warning
h = waitbar(0,'Converting .czis to .tifs...');
for intSlide = 1:length(sParams.cellCziFiles)
    %fprintf('\nConverting "%s"...\n', sParams.cellCziFiles{intSlide});
    strFullSlideName = [sParams.strSlidePath filesep sParams.cellCziFiles{intSlide}];
    [sCziInfo] = czi2tif(strFullSlideName, sParams.strSlidePath, 1 ,false, false);
    waitbar(intSlide/length(sParams.cellCziFiles), h, ['Converting .czis to .tifs (' num2str(intSlide) '/' num2str(length(sParams.cellCziFiles)) ')...']);
end
close(h)

%add to sParams (this is why it's important that same profile is used to scan all!)
sParams.cellChannels = sCziInfo(1).channelname; 
sParams.dblVoxelSizeX_um = sCziInfo(1).voxelSizeX_um;

%organize .tifs - per channel - in new folders
for intChan = 1:length(sParams.cellChannels)
    strNewFolderName = [sParams.strSlidePath filesep sParams.cellChannels{intChan}];
    mkdir(strNewFolderName);
    strChFilter = ['*C' num2str(intChan) '.tif'];
    movefile(fullfile(sParams.strSlidePath, strChFilter), strNewFolderName);
end

%save sParams
save([sParams.strSlidePath filsep sParams.strMouseID '_' sParams.strExperimentDate '.mat'], sParams);
    
%% select channel & resize/white balance images for alignment
%query user for channel (for now, select only one - DAPI works fine)
[intSelectedCh,~] = listdlg('PromptString', {'Select channel for alignment (e.g., DAPI)'}, 'SelectionMode', 'single', ...
    'ListString', sParams.cellChannels);
strSelectedChFolder = [sParams.strSlidePath filesep sParams.cellChannels{intSelectedCh}];

%set resize factor to match Allen CCF
dblAllen_um2px = 10; %10um/voxel, I haven't tried other resolutions
sParams.dblResizeFactor = sParams.dblVoxelSizeX_um/dblAllen_um2px;

%resize & white balance
AP_process_histology(strSelectedChFolder, sParams.dblResizeFactor, true);

%% reorder and/or flip slices
%reorder processed slices using a gui
sParams.strAlignmentSlicesPath = [strSelectedChFolder filesep 'slices'];
h = RH_reorder_flip_histology(sParams.strAlignmentSlicesPath);
uiwait(h);

%apply same changes to the original scenes, for all channels
%-first check:
strAnswer = questdlg('Would you like to apply the same changes to the original .tifs?', ...
	'', 'Yes','No','Yes');
switch strAnswer
    case 'Yes'

    case 'No'
        error('Proceed manually!');
end

%-new files are created (MOUSENAME_DATE_SX_CHANNEL.tif)
%-original files are deleted!
OrganizeOriginalScenes(sParams);

%save sParams
save([sParams.strSlidePath filsep sParams.strMouseID '_' sParams.strExperimentDate '.mat'], sParams);

%% create training set for ilastik (optional)
strAnswer = questdlg('Would you like to create training images for ilastik?', ...
	'', 'Yes','No','Yes');
switch strAnswer
    case 'Yes'
        MakeTrainingImagesIlastik(sParams);
    case 'No'
end

%% align CCF to slices
%load allen atlas
vecTV = readNPY([strAllenAtlasPath filesep 'template_volume_10um.npy']);
vecAV = readNPY([strAllenAtlasPath filesep 'annotation_volume_10um_by_index.npy']);
tblST = loadStructureTree([strAllenAtlasPath filesep 'structure_tree_safe_2017.csv']);

%find CCF slices corresponding to each histology slice
h = RH_grab_histology_ccf(vecTV, vecAV, tblST, sParams.strAlignmentSlicesPath);
uiwait(h);

%align CCF slices and histology slices
%-first: automatically, by outline
RH_auto_align_histology_ccf(sParams.strAlignmentSlicesPath);
%-second: curate manually
RH_manual_align_histology_ccf(vecTV, vecAV, tblST, sParams.strAlignmentSlicesPath);

%display aligned CCF over histology slices
RH_view_aligned_histology(tblST, sParams.strAlignmentSlicesPath);
