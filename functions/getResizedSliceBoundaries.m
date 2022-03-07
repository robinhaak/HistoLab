
function cellSliceBoundaries_resized = getResizedSliceBoundaries(sParams)
%get fns of resized slices
sTifDir = dir([sParams.strAlignmentSlicesPath filesep '*.tif']);
cellTifFileNames = natsortfiles(cellfun(@(path,fn) [path filesep fn], {sTifDir.folder},{sTifDir.name},'uni',false));
%load CCF slices aligned to data
strCcfFileName = [sParams.strAlignmentSlicesPath filesep 'histology_ccf.mat'];
load(strCcfFileName); %#ok<*LOAD>
%load histology/CCF alignment
strCcfAlignmentFileName = [sParams.strAlignmentSlicesPath filesep 'atlas2histology_tform_manual.mat'];
if exist(strCcfAlignmentFileName, 'file')
    load(strCcfAlignmentFileName);
    tformObj = projective2d;
else
    strCcfAlignmentFileName = [sParams.strAlignmentSlicesPath filesep 'atlas2histology_tform_auto.mat'];
    load(strCcfAlignmentFileName);
    tformObj = affine2d;
end
cellHistologyCcfAlignment = atlas2histology_tform;
%warp atlas by histology alignment, loop through slices per channel
cellSliceBoundaries_resized = cell(size(histology_ccf, 1), 1);
for intScene = 1:size(histology_ccf, 1)
    vecCurrSliceTV = histology_ccf(intScene).av_slices;
    vecCurrSliceTV(isnan(vecCurrSliceTV)) = 1;
    tformObj.T = cellHistologyCcfAlignment{intScene};
    vecCurrSliceImg = imread(cellTifFileNames{intScene});
    tformSizeObj = imref2d([size(vecCurrSliceImg, 1) ,size(vecCurrSliceImg, 2)]);
    vecHistologyAlignedAV = imwarp(vecCurrSliceTV, tformObj, 'nearest', 'OutputView', tformSizeObj);
    vecSliceMask = bwlabel(imfill(vecHistologyAlignedAV > 1, 'holes'));
    cellSliceBoundaries_resized{intScene} = cell2mat(bwboundaries(vecSliceMask));
end
end