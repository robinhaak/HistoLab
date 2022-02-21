
OrganizeIndividualScenes(sParams)
%ORGANIZE INDIVIDUAL SCENES
%
%
%Robin Haak, Feb '22

load(fullfile(sParams.strAlignmentSlicesPath, 'reorderedflipped_histology.mat'));

h = waitbar(0,'Organizing/flipping original histology...');
for intChan = 1:length(sParams.cellChannels)
    strSelectedChFolder = ['/Users/robinhaak/Downloads/test_slices' filesep sParams.cellChannels{intChan}];
    sTifDir = dir([strSelectedChFolder filesep '*.tif']) ;
    sTifFileNames = natsortfiles(cellfun(@(path,fn) [path filesep fn], {sTifDir.folder},{sTifDir.name},'uni',false));
    % > filter for 'C'
    for intScene = 1:length(sTifFileNames)
        vecCurrent = imread(sTifFileNames{intScene});
        intNewPos = find(gui_data.slice_order==intScene);
        if gui_data.flipped_lr(intNewPos) == 1
            vecCurrent = fliplr(vecCurrent);
        end
        if gui_data.flipped_ud(intNewPos) == 1
            vecCurrent = flipud(vecCurrent);
        end
        slice_im_new_fn = [strSelectedChFolder filesep sParams.strMouseID '_' sParams.strExperimentDate '_' sprintf('S%03d', intNewPos) '_' sParams.cellChannels{intChan} '.tif']; 
        imwrite(vecCurrent, slice_im_new_fn);
    end
end