function predictor = hngw_read_predictor_factor(handles, factor, sourcePath, outputFile)
% Read one predictor factor and save it in the split predictor MAT format.
% Dynamic variables are stored as month x pixel matrices; DEM is static.

factor = lower(strtrim(factor));
months = hngw_month_table(handles.trange);
nT = height(months);
n025 = numel(handles.rbi1);
n001 = numel(handles.rbi2);
agg = hngw_make_agg_map(handles);

predictor = struct();
predictor.factor = factor;
predictor.time = months.time;
predictor.year = months.year;
predictor.month = months.month;
predictor.source_path = sourcePath;
predictor.data025 = struct();
predictor.data001 = struct();
predictor.static025 = struct();
predictor.static001 = struct();

switch factor
    case {'temp','rhu','pres','pre'}
        spec = hngw_nc_factor_spec(factor);
        predictor.names = {factor};
        predictor.data025.(factor) = nan(nT,n025,'single');
        predictor.data001.(factor) = nan(nT,n001,'single');
        flist = hngw_index_files(sourcePath,'*.nc');
        h = waitbar(0,sprintf('Reading %s predictor...',factor));
        cleanup = onCleanup(@() delete_waitbar(h)); %#ok<NASGU>
        for t = 1:nT
            f = hngw_find_month_file(flist, months.year(t), months.month(t), factor);
            v001 = hngw_read_nc_lonlat_to_001(f, spec.varCandidates, handles);
            predictor.data001.(factor)(t,:) = single(v001(:)');
            predictor.data025.(factor)(t,:) = single(hngw_agg_001_to_025(v001(:), agg)');
            waitbar(t/nT,h,sprintf('Reading %s %04d-%02d',factor,months.year(t),months.month(t)));
        end

    case 'lst'
        predictor.names = {'lst_day','lst_night'};
        predictor.data025.lst_day = nan(nT,n025,'single');
        predictor.data001.lst_day = nan(nT,n001,'single');
        predictor.data025.lst_night = nan(nT,n025,'single');
        predictor.data001.lst_night = nan(nT,n001,'single');
        flist = hngw_index_files(sourcePath,'*.hdf');
        h = waitbar(0,'Reading LST predictor...');
        cleanup = onCleanup(@() delete_waitbar(h)); %#ok<NASGU>
        for t = 1:nT
            f = hngw_find_month_file(flist, months.year(t), months.month(t), 'lst');
            [day001,night001] = hngw_read_lst_to_001(f, handles);
            predictor.data001.lst_day(t,:) = single(day001(:)');
            predictor.data001.lst_night(t,:) = single(night001(:)');
            predictor.data025.lst_day(t,:) = single(hngw_agg_001_to_025(day001(:), agg)');
            predictor.data025.lst_night(t,:) = single(hngw_agg_001_to_025(night001(:), agg)');
            waitbar(t/nT,h,sprintf('Reading LST %04d-%02d',months.year(t),months.month(t)));
        end

    case 'et'
        predictor.names = {'et'};
        predictor.data025.et = nan(nT,n025,'single');
        predictor.data001.et = nan(nT,n001,'single');
        flist = hngw_index_files(sourcePath,'*.hdf');
        h = waitbar(0,'Reading ET predictor...');
        cleanup = onCleanup(@() delete_waitbar(h)); %#ok<NASGU>
        for t = 1:nT
            f = hngw_find_month_file(flist, months.year(t), months.month(t), 'et');
            et001 = hngw_read_modis_sinu_to_001(f, {'ET_500m','ET'}, handles);
            et001(et001 > 30000) = nan;
            predictor.data001.et(t,:) = single(et001(:)');
            predictor.data025.et(t,:) = single(hngw_agg_001_to_025(et001(:), agg)');
            waitbar(t/nT,h,sprintf('Reading ET %04d-%02d',months.year(t),months.month(t)));
        end

    case 'ndvi'
        predictor.names = {'ndvi'};
        predictor.data025.ndvi = nan(nT,n025,'single');
        predictor.data001.ndvi = nan(nT,n001,'single');
        flist = hngw_index_files(sourcePath,'*.hdf');
        h = waitbar(0,'Reading NDVI predictor...');
        cleanup = onCleanup(@() delete_waitbar(h)); %#ok<NASGU>
        for t = 1:nT
            f = hngw_find_month_file(flist, months.year(t), months.month(t), 'ndvi');
            ndvi001 = hngw_read_modis_sinu_to_001(f, {'1 km monthly NDVI','NDVI'}, handles);
            ndvi001(ndvi001 <= -3000 | ndvi001 > 10000) = nan;
            ndvi001 = ndvi001 ./ 10000;
            predictor.data001.ndvi(t,:) = single(ndvi001(:)');
            predictor.data025.ndvi(t,:) = single(hngw_agg_001_to_025(ndvi001(:), agg)');
            waitbar(t/nT,h,sprintf('Reading NDVI %04d-%02d',months.year(t),months.month(t)));
        end

    case 'dem'
        predictor.names = {'dem'};
        [dem001,dem025] = hngw_read_dem(sourcePath, handles, agg);
        predictor.static001.dem = single(dem001(:)');
        predictor.static025.dem = single(dem025(:)');

    otherwise
        error('Unsupported predictor factor: %s', factor);
end

if nargin >= 4 && ~isempty(outputFile)
    hngw_save_factor(outputFile,predictor);
end
end

function spec = hngw_nc_factor_spec(factor)
switch factor
    case 'temp'
        spec.varCandidates = {'tmpmean','temp','tmean'};
    case 'rhu'
        spec.varCandidates = {'rhu','rh','humidity'};
    case 'pres'
        spec.varCandidates = {'pres','pressure'};
    case 'pre'
        spec.varCandidates = {'prec','pre','precipitation'};
    otherwise
        error('Unsupported NetCDF predictor factor: %s', factor);
end
end

function hngw_save_factor(outputFile,predictor)
outDir = fileparts(outputFile);
if ~isempty(outDir) && ~exist(outDir,'dir')
    mkdir(outDir);
end
predictor025 = predictor.data025; %#ok<NASGU>
predictor001 = predictor.data001; %#ok<NASGU>
predictorStatic025 = predictor.static025; %#ok<NASGU>
predictorStatic001 = predictor.static001; %#ok<NASGU>
predictorNames = predictor.names; %#ok<NASGU>
year = predictor.year; %#ok<NASGU>
month = predictor.month; %#ok<NASGU>
time = predictor.time; %#ok<NASGU>

save(outputFile,'predictor','predictor025','predictor001', ...
    'predictorStatic025','predictorStatic001','predictorNames', ...
    'year','month','time','-v7.3');

for i = 1:numel(predictor.names)
    name = predictor.names{i};
    if isfield(predictor.data025,name)
        eval([name '_025 = predictor.data025.(name);']); %#ok<EVLDOT>
        eval([name '_001 = predictor.data001.(name);']); %#ok<EVLDOT>
        save(outputFile,[name '_025'],[name '_001'],'-append');
    elseif isfield(predictor.static025,name)
        eval([name '_025 = predictor.static025.(name);']); %#ok<EVLDOT>
        eval([name '_001 = predictor.static001.(name);']); %#ok<EVLDOT>
        save(outputFile,[name '_025'],[name '_001'],'-append');
    end
end
end

function months = hngw_month_table(trange)
startDate = datetime(trange(1),trange(2),1);
endDate = datetime(trange(3),trange(4),1);
d = (startDate:calmonths(1):endDate)';
months = table(year(d),month(d),year(d)+(month(d)-1)/12+1/24, ...
    'VariableNames',{'year','month','time'});
end

function files = hngw_index_files(folder, pattern)
d = dir(fullfile(folder,pattern));
if isempty(d)
    error('No files found in %s matching %s', folder, pattern);
end
[~,idx] = sort({d.name});
d = d(idx);
files = struct('name',{},'path',{},'year',{},'month',{});
for i = 1:numel(d)
    [yy,mm] = hngw_parse_year_month(d(i).name);
    if ~isnan(yy)
        files(end+1).name = d(i).name; %#ok<AGROW>
        files(end).path = fullfile(d(i).folder,d(i).name);
        files(end).year = yy;
        files(end).month = mm;
    end
end
end

function [yy,mm] = hngw_parse_year_month(name)
tok = regexp(name,'(?<!\d)(20\d{2})[_-]?([01]\d)(?!\d)','tokens','once');
if isempty(tok)
    tok = regexp(name,'A(20\d{2})([01]\d)','tokens','once');
end
if isempty(tok)
    tok = regexp(name,'A(20\d{2})(\d{3})','tokens','once');
    if isempty(tok)
        yy = nan; mm = nan; return;
    end
    dt = datetime(str2double(tok{1}),1,1) + days(str2double(tok{2})-1);
    yy = year(dt); mm = month(dt);
else
    yy = str2double(tok{1});
    mm = str2double(tok{2});
end
end

function f = hngw_find_month_file(files, yy, mm, label)
idx = find([files.year] == yy & [files.month] == mm,1);
if isempty(idx)
    error('Missing %s file for %04d-%02d', label, yy, mm);
end
f = files(idx).path;
end

function v001 = hngw_read_nc_lonlat_to_001(file, varCandidates, handles)
info = ncinfo(file);
vars = {info.Variables.Name};
varName = '';
for i = 1:numel(varCandidates)
    if any(strcmp(vars,varCandidates{i}))
        varName = varCandidates{i};
        break;
    end
end
if isempty(varName)
    error('Cannot find any candidate variable in %s', file);
end
lon = double(ncread(file,'lon'));
lat = double(ncread(file,'lat'));
lonMin = min(handles.lon2)-0.03; lonMax = max(handles.lon2)+0.03;
latMin = min(handles.lat2)-0.03; latMax = max(handles.lat2)+0.03;
ix = find(lon >= lonMin & lon <= lonMax);
iy = find(lat >= latMin & lat <= latMax);
raw = double(ncread(file,varName,[ix(1),iy(1)],[numel(ix),numel(iy)]));
raw = raw';
[LonSrc,LatSrc] = meshgrid(lon(ix),lat(iy));
grid = interp2(LonSrc,LatSrc,raw,handles.Lon2,handles.Lat2,'linear');
v001 = grid(handles.rbi2);
end

function [day001, night001] = hngw_read_lst_to_001(file, handles)
day = hngw_read_modis_sinu_to_001(file, {'LST_Day_1km','LST_Day_CMG'}, handles);
night = hngw_read_modis_sinu_to_001(file, {'LST_Night_1km','LST_Night_CMG'}, handles);
day(day <= 0) = nan;
night(night <= 0) = nan;
if max(day,[],'omitnan') > 1000
    day = day * 0.02;
end
if max(night,[],'omitnan') > 1000
    night = night * 0.02;
end
day001 = day - 273.15;
night001 = night - 273.15;
end

function v001 = hngw_read_modis_sinu_to_001(file, varCandidates, handles)
varName = hngw_find_hdf_sds(file, varCandidates);
data = double(hdfread(file,varName));
[rows,cols] = size(data);
[xVec,yVecDesc] = hngw_modis_tile_xy(file, rows, cols);
yVec = fliplr(yVecDesc);
data = flipud(data);
[xq,yq] = hngw_lonlat_to_sinu(handles.Lon2(handles.rbi2), handles.Lat2(handles.rbi2));
v001 = interp2(xVec,yVec,data,xq,yq,'linear');
end

function varName = hngw_find_hdf_sds(file, candidates)
for i = 1:numel(candidates)
    try
        hdfread(file,candidates{i});
        varName = candidates{i};
        return;
    catch
    end
end
error('Cannot find requested HDF SDS in %s', file);
end

function [xVec,yVec] = hngw_modis_tile_xy(file, rows, cols)
meta = hngw_get_hdf_attribute(file,'StructMetadata.0');
ul = []; lr = [];
if ~isempty(meta)
    tk = regexp(meta,'UpperLeftPointMtrs=\(([-0-9.]+),([-0-9.]+)\)','tokens','once');
    tk2 = regexp(meta,'LowerRightMtrs=\(([-0-9.]+),([-0-9.]+)\)','tokens','once');
    if ~isempty(tk) && ~isempty(tk2)
        ul = [str2double(tk{1}), str2double(tk{2})];
        lr = [str2double(tk2{1}), str2double(tk2{2})];
    end
end
if isempty(ul)
    R = 6371007.181; %#ok<NASGU>
    tile = 1111950.519667;
    h = 27; v = 5;
    ul = [-20015109.354 + h*tile, 10007554.677 - v*tile];
    lr = [ul(1)+tile, ul(2)-tile];
end
dx = (lr(1)-ul(1))/cols;
dy = (ul(2)-lr(2))/rows;
xVec = ul(1)+dx/2:dx:lr(1)-dx/2;
yVec = ul(2)-dy/2:-dy:lr(2)+dy/2;
end

function value = hngw_get_hdf_attribute(file, name)
value = '';
try
    info = hdfinfo(file);
    if isfield(info,'Attributes')
        for i = 1:numel(info.Attributes)
            if strcmp(info.Attributes(i).Name,name)
                value = info.Attributes(i).Value;
                return;
            end
        end
    end
catch
end
end

function [x,y] = hngw_lonlat_to_sinu(lon,lat)
R = 6371007.181;
latRad = lat*pi/180;
lonRad = lon*pi/180;
x = R .* lonRad .* cos(latRad);
y = R .* latRad;
end

function agg = hngw_make_agg_map(handles)
res = handles.input_resolution;
lon001 = handles.Lon2(handles.rbi2);
lat001 = handles.Lat2(handles.rbi2);
i025 = floor(lon001/res)+1;
j025 = floor((90-lat001)/res)+1;
sz = size(handles.Lon1);
ok = i025 >= 1 & i025 <= sz(2) & j025 >= 1 & j025 <= sz(1);
lin025 = sub2ind(sz,j025(ok),i025(ok));
posMap = zeros(numel(handles.Lon1),1);
posMap(handles.rbi1) = 1:numel(handles.rbi1);
pos = posMap(lin025);
ok2 = pos > 0;
idx001 = find(ok);
agg.idx001 = idx001(ok2);
agg.pos025 = pos(ok2);
agg.n025 = numel(handles.rbi1);
end

function out = hngw_agg_001_to_025(v001, agg)
vals = double(v001(agg.idx001));
ok = isfinite(vals);
out = accumarray(agg.pos025(ok), vals(ok), [agg.n025,1], @mean, nan);
end

function [dem001,dem025] = hngw_read_dem(file, handles, agg)
s = load(file);
if ~isfield(s,'dem') || ~isfield(s,'lon') || ~isfield(s,'lat')
    error('DEM MAT must contain dem, lon, and lat variables: %s', file);
end
dem = double(s.dem);
if isfield(s,'nodata')
    dem(dem == double(s.nodata)) = nan;
end
lon = double(s.lon(:)');
lat = double(s.lat(:)');
if lat(1) > lat(end)
    latSrc = lat;
    demSrc = dem;
else
    latSrc = fliplr(lat);
    demSrc = flipud(dem);
end
[LonSrc,LatSrc] = meshgrid(lon,latSrc);
grid = interp2(LonSrc,LatSrc,demSrc,handles.Lon2,handles.Lat2,'linear');
dem001 = grid(handles.rbi2);
dem025 = hngw_agg_001_to_025(dem001(:), agg);
end

function delete_waitbar(h)
if ishghandle(h)
    delete(h);
end
end
