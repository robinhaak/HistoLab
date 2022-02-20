
%PRE-PROCESS & ALIGN slice images
%Robin Haak, 19 Feb '22
%
%-split czi into multiple tiffs
%-reorder and/or flip slices, if applicable
%-create training set for ilastik (cell detection), optional
%
%(!)files should be organized so that a folder contains images of 1 subject(!)
%(!)assumes that the same scan profile is used for all images(!)


%% query user for path to czi files
strSlicePath = uigetdir([], 'Select folder containing slide scans (.czi)...\n\n');

%determine the number of files
sCziDir = dir(fullfile(strSlicePath, '*.czi'));
i = 1;
while i <= length(sCziDir)
    if contains(sCziDir(i).name, '_pt')
        sCziDir(i) = [];
    else
        i = i+1;
    end
end
fprintf('\n\n\nThe folder "%s" contains %d .czi files:\n', strSlicePath, length(sCziDir));
for i = 1:length(sCziDir)
    fprintf('- %s\n', sCziDir(i).name);
end

%% convert czi to tiffs
%try increasing java heap memory (preferences > general) if this gives an error, ignore log4j warning
for i = 1:length(sCziDir)
    fprintf('\nConverting "%s"...\n', sCziDir(i).name);
    strsCziDirFullName = [strSlicePath filesep sCziDir(i).name];
    [sCziInfo] = czi2tif(strsCziDirFullName, strSlicePath,1 ,false, false); %get info from one .czi 
end

%% create training set for ilastik (optional)



%% select channel for alignment & resize/white balance images
%query user for channel (for, now only select one - DAPI works fine)
[intSelectedCh,~] = listdlg('PromptString', {'Select channel(s) for alignment (max. 3)'}, 'SelectionMode', 'single', ...
    'ListString', sCziInfo(1).channelname);

%create a temporary folder to move .tifs for alignment
strTempPath = [strSlicePath filesep 'temp'];
mkdir(strTempPath);
strChFilter = ['*C' num2str(intSelectedCh) '.tif'];
movefile(fullfile(strSlicePath, strChFilter), strTempPath);

%set resize factor to match Allen CCF
dblAllen_um2px = 10; %10um/voxel
dblResizeFactor = sCziInfo(1).voxelSizeX_um/dblAllen_um2px;

%resize & white balance
AP_process_histology(strTempPath, dblResizeFactor, true);

% move .tifs back from 'temp' folder
movefile(fullfile(strTempPath, strChFilter), strSlicePath);

%% reorder and/or flip slices
%reorder processed slices using a gui
strTempSlicesPath = [strTempPath filesep 'slices'];
RH_reorder_flip_histology_gui(strTempSlicesPath);
RH_reorder_flip_temp_slices(strTempSlicesPath);





%apply same changes to the original histology
% RH_reorder_flip_og_histology


%% align CCF to slices

%load allen atlas
strAllenAtlasPath = '/Users/robinhaak/Desktop/CCF_10um';
vecTV = readNPY([strAllenAtlasPath filesep 'template_volume_10um.npy']);
vecAV = readNPY([strAllenAtlasPath filesep 'annotation_volume_10um_by_index.npy']);
tabST = loadStructureTree([strAllenAtlasPath filesep 'structure_tree_safe_2017.csv']);


AP_grab_histology_ccf(vecTv,vecAV,tabST,slice_path);


%align CCF slices and histology slices
%-first: automatically, by outline
RH_auto_align_histology_ccf(slice_path);
%-second: curate manually
RH_manual_align_histology_ccf(vecTv,vecAV,tabST,slice_path);

