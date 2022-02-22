
function OrganizeIndividualScenes(sParams)
%ORGANIZE INDIVIDUAL SCENES
%
%
%Robin Haak, Feb '22

%load new order/flip info
load(fullfile(sParams.strAlignmentSlicesPath, 'reorderedflipped_histology.mat'));

h = waitbar(0,'Organizing/flipping original histology...');
for intChan = 1:length(sParams.cellChannels)
    strSelectedChFolder = [sParams.strSlidePath filesep sParams.cellChannels{intChan}];
    sTifDir = dir([strSelectedChFolder filesep '*.tif']) ;
    cellTifFileNames = natsortfiles(cellfun(@(path,fn) [path filesep fn], {sTifDir.folder},{sTifDir.name},'uni',false));
    % > filter for 'C'
    for intScene = 1:length(cellTifFileNames)
        vecCurrentImg = imread(cellTifFileNames{intScene});
        intNewPos = find(gui_data.slice_order==intScene);
        if gui_data.flipped_lr(intNewPos) == 1
            vecCurrentImg = fliplr(vecCurrentImg);
        end
        if gui_data.flipped_ud(intNewPos) == 1
            vecCurrentImg = flipud(vecCurrentImg);
        end
        slice_im_new_fn = [strSelectedChFolder filesep sParams.strMouseID '_' sParams.strExperimentDate '_' sprintf('S%03d', intNewPos) '_' sParams.cellChannels{intChan} '.tif']; 
        imwrite(vecCurrentImg, slice_im_new_fn);
        
        %delete original file
        delete(cellTifFileNames{intScene})
    end
    waitbar(intChan/length(sParams.cellChannels), h, ['Organizing/flipping original histology (' num2str(intChan) '/' num2str(length(sParams.cellChannels)) ')...']);
end
close(h)


end