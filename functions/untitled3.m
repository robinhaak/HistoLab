
function IlastikResults = getIlastikResults(sParams)

%first, get slice boundaries to determine which points fall outside the slices
%>these have to be removed, as they hinder later transformation to CCF space
cellSliceBoundaries_resized = getResizedSliceBoundaries(sParams);

%query user for which channels to load results
[intSelectedCh,~] = listdlg('PromptString', {'Select channels to load Ilastik results'}, 'ListString', sParams.cellChannelsIlastik);

%loop through selected channels & get ilastik results
for intChan = 1:length(intSelectedCh)
    strSelectedChFolder = [sParams.strSlidePath filesep sParams.cellChannelsIlastik{intSelectedCh(intChan)}];
    sH5Dir = dir([strSelectedChFolder filesep '*' sParams.cellChannelsIlastik{intSelectedCh(intChan)} '.h5']);
    for intScene = 1:length(sH5Dir)
        tblH5 = h5read([strSelectedChFolder filesep sH5Dir(intScene).name],'/table');
        logiCellIdx = logical(tblH5.ProbabilityOfLabel1); %label 1 = cell
        vecDetected  = [tblH5.CenterOfTheObject_0(logiCellIdx), tblH5.CenterOfTheObject_1(logiCellIdx)]; %[x,y]
        vecDetected_resized  = vecDetected*sParams.dblResizeFactor; %[x,y]
        vecRadii = sqrt(tblH5.SizeInPixels/pi);
        
        %determine whether they fall within the slice
        intInSlice = inpolygon(vecDetected_resized(:,1), vecDetected_resized(:,2), cellSliceBoundaries_resized{intScene}(:,2), cellSliceBoundaries_resized{intScene}(:,1));
        figure;
        plot(cellSliceBoundaries_resized{intScene}(:,2), cellSliceBoundaries_resized{intScene}(:,1), 'k');
        gscatter(vecDetected_resized(:,1), vecDetected_resized(:,2), intInSlice, 'rb')
        set(gca,'Ydir','Reverse'); legend off;
        title([sParams.cellChannelsIlastik{intSelectedCh(intChan)} ' - slice: ' num2str(intScene)])
     
        %keep only those that do
        cellDetectedCoords{intScene, intChan} = vecDetected(intInSlice);
        cellDetectedCoords_resized{intScene, intChan} = vecDetected_resized(intInSlice);
        cellRadii{intScene, intChan} = vecRadii(intInSlice);
    end
end

IlastikResults = struct;
IlastikResults.cellDetectedCoords = cellDetectedCoords;
IlastikResults.cellDetectedCoord_resized = cellDetectedCoord_resized;
IlastikResults.cellRadii = cellRadii;



