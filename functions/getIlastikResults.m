
function sIlastikResults = getIlastikResults(sParams)

%first, get slice boundaries to determine which points fall outside the slices
%>these have to be removed, as they hinder later transformation to CCF space
cellSliceBoundaries_resized = getResizedSliceBoundaries(sParams);

%query user for which channels to load results
[intSelectedCh,~] = listdlg('PromptString', {'Select channels to load Ilastik results'}, 'ListString', sParams.cellChannelsIlastik);

%loop through selected channels & get ilastik results
h = figure;
for intChan = 1:length(intSelectedCh)
    strSelectedChFolder = [sParams.strSlidePath filesep sParams.cellChannelsIlastik{intSelectedCh(intChan)}];
    sH5Dir = dir([strSelectedChFolder filesep '*' sParams.cellChannelsIlastik{intSelectedCh(intChan)} '.h5']);
    %pre-allocate
    cellDetectedCoords  = cell(length(sH5Dir), length(intSelectedCh));
    cellDetectedCoords_resized = cell(length(sH5Dir), length(intSelectedCh));
    cellRadii = cell(length(sH5Dir), length(intSelectedCh));
    for intScene = 1:length(sH5Dir)
        tblH5 = h5read([strSelectedChFolder filesep sH5Dir(intScene).name],'/table');
        logiCellIdx = logical(tblH5.ProbabilityOfLabel1); %label 1 = cell
        vecDetected  = [tblH5.CenterOfTheObject_0(logiCellIdx), tblH5.CenterOfTheObject_1(logiCellIdx)]; %[x,y]
        vecDetected_resized  = vecDetected*sParams.dblResizeFactor; %[x,y]
        vecRadii = sqrt(tblH5.SizeInPixels/pi);
        
        %determine whether they fall within the slice
        vecInSlice = inpolygon(vecDetected_resized(:,1), vecDetected_resized(:,2), cellSliceBoundaries_resized{intScene}(:,2), cellSliceBoundaries_resized{intScene}(:,1));
        plot(cellSliceBoundaries_resized{intScene}(:,2), cellSliceBoundaries_resized{intScene}(:,1), 'k');
        gscatter(vecDetected_resized(:,1), vecDetected_resized(:,2), vecInSlice, 'rb')
        set(gca,'Ydir','Reverse'); legend off;
        title([sParams.cellChannelsIlastik{intSelectedCh(intChan)} ' - slice: ' num2str(intScene)])
        drawnow;
     
        %keep only those that do
        cellDetectedCoords{intScene, intChan} = vecDetected(vecInSlice, :);
        cellDetectedCoords_resized{intScene, intChan} = vecDetected_resized(vecInSlice, :);
        cellRadii{intScene, intChan} = vecRadii(vecInSlice);
    end
end

%create output struct
sIlastikResults = struct;
sIlastikResults.cellChannels = sParams.cellChannelsIlastik{intSelectedCh};
sIlastikResults.cellDetectedCoords = cellDetectedCoords;
sIlastikResults.cellDetectedCoords_resized = cellDetectedCoords_resized;
sIlastikResults.cellRadii = cellRadii;

%close figure
pause(2); close(h);

end



