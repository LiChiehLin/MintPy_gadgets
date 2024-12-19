%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%                             Lin,Li-Chieh                                %
%                     Earth and Planetary Sciences                        %
%                  University of California, Riverside                    %
%                              2024.12.18                                 %
%                                                                         %
% Extract the LOS displacement timeseries from MintPy product into an text%
% file. e.g. "timeseries.h5", "timeseries_ERA5_ramp_demErr.h5" etc.       %
%                                                                         %
% Note that: Typically, the h5 timeseries file is usually pretty big,     %
% several GBs. The output text file will be even bigger. Make sure you    %
% have enough memory and do not overload your computer.                   %
%                                                                         %
% Input:                                                                  %
% 1. h5TS: String. Path to the timeseries h5 file                         %
% 2. h5TempMask: String. Path to the temporal coherence mask h5 file      %
% Leave blank to not mask with temporal coherence mask                    %
% 3. Bbox: 4x1 or 1x4 vector. Coordinates to make a subset of the         %
%    timeseries. The order is (W,E,S,N). e.g.:                            %
%    Bbox(1): Min Longitude                                               %
%    Bbox(2): Max Longitude                                               %
%    Bbox(3): Min Latitude                                                %
%    Bbox(4): Max Latitude                                                %
% Leave blank to output every pixel in the timeseries                     %
%                                                                         %
% Note that: It cannot be executed with h5TS and BBox. This will induce   %
% errors. The inputs can only be put as the order shown above.            %
%                                                                         %
% Output:                                                                 %
% This function does not output any variabes but outputs the timeseries in%
% text files in the local timeseries_textfile/ folder (auto-created)      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h5TS_to_Text(h5TS,h5TempMask,Bbox,varargin)
tmp = strsplit(h5TS,{'/','\','.'});
TSname = tmp{end-1};
switch nargin
    case 1
        disp('*** Extract timeseries without masking or subsetting')
        disp(strcat('* h5 timeseries file:',32,h5TS))
        disp('------------------------------------------')
        flag = 1;
        outname = strcat(TSname,'_.txt');
    case 2
        disp('*** Extract timeseries with masking but without subsetting')
        disp(strcat('* h5 timeseries file:',32,h5TS))
        disp(strcat('* Temporal coherence mask file:',32,h5TempMask))
        disp('------------------------------------------')
        flag = 2;
        outname = strcat(TSname,'_masked.txt');
    case 3
        disp('*** Extract timeseries with masking and subsetting')
        disp(strcat('* h5 timeseries file:',32,h5TS))
        disp(strcat('* Temporal coherence mask file:',32,h5TempMask))
        disp('* Subset bounding box:')
        disp('------------------------------------------')
        disp(Bbox)
        flag = 3;
        outname = strcat(TSname,'_masked_subset.txt');
    otherwise
        error('Only support up to 3 input arguments')
end

if ~isfolder('timeseries_textfile/')
    mkdir('timeseries_textfile/')
end

%% Get all the epoch dates
disp('*** Getting epoch dates')
TSFile = h5info(h5TS);
tmp = h5read(h5TS,'/date');
TSDates = zeros(size(tmp,1),1);
for i = 1:length(tmp)
    TSDates(i,1) = str2double(tmp(i));
end

%% Get the Lon Lat 
disp('*** Calculating Longitudes and Latitudes')
disp('------------------------------------------')
TSDim = TSFile.Datasets(3).Dataspace.Size;
Attr = cell(length(TSFile.Attributes),1);
for i = 1:length(TSFile.Attributes)
    Attr{i,1} = TSFile.Attributes(i).Name;
end
Lonstart = str2double(TSFile.Attributes(strcmp(Attr,'X_FIRST')).Value);
Lonstep = str2double(TSFile.Attributes(strcmp(Attr,'X_STEP')).Value);
Lonend = Lonstart+Lonstep*TSDim(1);
Lonstep = (Lonend - Lonstart)/(TSDim(1)-1);

Latstart = str2double(TSFile.Attributes(strcmp(Attr,'Y_FIRST')).Value);
Latstep = str2double(TSFile.Attributes(strcmp(Attr,'Y_STEP')).Value);
Latend = Latstart+Latstep*TSDim(2);
Latstep = (Latend - Latstart)/(TSDim(2)-1);

Lon = Lonstart:Lonstep:(TSDim(1)-1)*Lonstep+Lonstart;
Lat = Latstart:Latstep:(TSDim(2)-1)*Latstep+Latstart;
if (Lat(1) > Lat(end))
    Lat = fliplr(Lat);
end


%% Read in timeseries
% Two things:
% 1. Mask with temporal coherence mask 
% 2. Make a subset of the timeseries
disp('*** Reading timeseries file...')
TS = h5read(h5TS,'/timeseries',[1 1 1],[TSDim(1) TSDim(2) TSDim(3)]);
TS = permute(TS,[2,1,3]);
TS = flipud(TS);

% 1. Masking
if (flag == 2) || (flag == 3)
    Mask = h5read(h5TempMask,'/mask');
    Mask = strcmpi(Mask,'true');
    Mask = double(Mask);
    Mask = permute(Mask,[2,1,3]);
    Mask = flipud(Mask);
    Mask(Mask==0) = nan;
    for i = 1:size(TS,3)
        TS(:,:,i) = TS(:,:,i).*Mask;
    end
end

% 2. Subsetting
if flag == 3
    Xmin = Bbox(1);
    Xmax = Bbox(2);
    Ymin = Bbox(3);
    Ymax = Bbox(4);
    LonInd = find((Lon >= Xmin) & (Lon <= Xmax));
    LatInd = find((Lat >= Ymin) & (Lat <= Ymax));
    Lon = Lon(LonInd);
    Lat = Lat(LatInd);
    TS = TS(LatInd,LonInd,:);
end

%% Loop through the timeseries to get the displacement history
TSTable = zeros(size(TS,1)*size(TS,2),size(TS,3)+2);
i = 0;
for c = 1:length(Lon)
    lon = Lon(c);
    for r = 1:length(Lat)
        i = i + 1;
        disp(strcat('*** Retrieving at pixel count',32,num2str(i),'/',num2str(size(TS,1)*size(TS,2))))
        lat = Lat(r);
        TStmp = TS(r,c,:);
        TStmp = TStmp(:);
        TSTable(i,[1,2]) = [lon,lat];
        TSTable(i,3:end) = TStmp';
    end
end
% Exclude nan values
TSTable = TSTable(~isnan(TSTable(:,3)),:);

%% Output
Header = cell(1,3);
Header{1} = 'Lon'; Header{2} = 'Lat';
Header{3} = TSDates';
disp(strcat('*** Writing timeseries into',32,outname))
writecell(Header,strcat('timeseries_textfile/',outname))
writematrix(TSTable,strcat('timeseries_textfile/',outname),'WriteMode','append')


end




