
function MakeTrainingImagesIlastik(sParams)

[intSelectedCh,~] = listdlg('PromptString', {'Select channels to make a training set for ilastik'}, 'ListString', sParams.cellChannels);
for intChan = 1:length(intSelectedCh)
    strSelectedChFolder = [sParams.strSlidePath filesep sParams.cellChannels{intSelectedCh(intChan)}];
    sTifDir = dir([strSelectedChFolder filesep '*.tif']) ;
    cellTifFileNames = natsortfiles(cellfun(@(path,fn) [path filesep fn], {sTifDir.folder},{sTifDir.name},'uni',false));
    cellTifsForTraining = cellTifFileNames(unique([[2 round(length(cellTifFileNames)/2) length(cellTifFileNames)-2]]));
    
    intCount = 0;
    vecImgCutout = cell(4*length(cellTifsForTraining), 1);
    for intTif = 1:length(cellTifsForTraining)
        vecCurrentImg = imread(cellTifsForTraining{intTif});
        %find coordinates that work for your specific project
        vecImgCutout{intCount+1} = vecCurrentImg(9251:10000,7001:8250);
        vecImgCutout{intCount+2} = vecCurrentImg(4251:5000,3001:4250);
        vecImgCutout{intCount+3} = vecCurrentImg(7751:8500,10001:11250);
        vecImgCutout{intCount+4} = vecCurrentImg(10251:11000,9501:10750);
        
        intCount = intCount + 4;
    end
    
    %show
    h = figure;
    imgMontage = montage(vecImgCutout(1, :));
    
    %white balance
    vecMontageCData = imgMontage.CData;
    vecCDataCounts = histcounts(vecMontageCData(vecMontageCData > 0),0:max(vecMontageCData(:)));
    vecCDataCounts = smooth(vecCDataCounts, 50, 'loess');
    vecCDataCountsDeriv = [0; diff(vecCDataCounts)];
    %-the signal minimum is the valley between background and signal
    [~,intBgDown] = min(vecCDataCountsDeriv);
    intBgSigalMin = find(vecCDataCountsDeriv(intBgDown:end) > 0,1) + intBgDown;
    %-the signal maximum is < 1% median value
    [~, intBgMedianRel] = max(vecCDataCounts(intBgSigalMin:end));
    intSignalMedian = intBgMedianRel + intBgSigalMin - 1;
    dblSignalHighCutoff = vecCDataCounts(intSignalMedian)*0.01;
    intSignalHighRel = find(vecCDataCounts(intSignalMedian:end) < dblSignalHighCutoff,1);
    intSignalHigh = intSignalHighRel + intSignalMedian;
    %(if no < 1%, just take max)
    if(isempty(intSignalHigh))
        intSignalHigh = length(vecCDataCounts);
    end
    intCMin = intBgSigalMin;
    intCMax = intSignalHigh;
    
    pause(1);
    caxis([intCMin, intCMax]); % apply WB
    pause(2)
    close(h)
    
    strTrainingOutputPath = [strSelectedChFolder filesep 'training'];
    mkdir(strTrainingOutputPath);
    for i = 1:intCount
        imwrite(vecImgCutout{i},fullfile(strTrainingOutputPath,['test_S' num2str(i,'%03d') '_' sParams.cellChannels{intSelectedCh(intChan)} '.tif']));
    end
end

end