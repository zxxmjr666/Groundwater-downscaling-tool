function zt()
% Draw Henan 0.01 x 0.01 mean GWSA map from the auto downscaling output.

project_dir = 'D:\claude matlab\xinshiyan';
data_dir = fullfile(project_dir,'shuju');

preferred_file = fullfile(data_dir,'auto_output','Cxgb','GWSA_Downscaled_001_200204_202412_xgb.mat');
xgb_spline_file = fullfile(data_dir,'auto_output','Cxgb','GWSA_Downscaled_001_200204_202412_xgb_spline.mat');
fallback_file = fullfile(data_dir,'auto_output','Crf','GWSA_Downscaled_001_200204_202412.mat');
legacy_file = fullfile(project_dir,'auto_output','Crf','GWSA_Downscaled_001_200204_202412.mat');
if exist(preferred_file,'file')
    crf_file = preferred_file;
elseif exist(xgb_spline_file,'file')
    crf_file = xgb_spline_file;
elseif exist(fallback_file,'file')
    crf_file = fallback_file;
elseif exist(legacy_file,'file')
    crf_file = legacy_file;
else
    error('Cannot find GWSA downscaled file. Tried:\n%s\n%s\n%s\n%s', preferred_file, xgb_spline_file, fallback_file, legacy_file);
end

shp_file = fullfile(data_dir,'henan.shp');
if ~exist(shp_file,'file')
    error('Cannot find shapefile: %s', shp_file);
end

out_dir = fileparts(crf_file);
data = load(crf_file,'CSR_Down','time','model_type','residual_interp_method');
if ~isfield(data,'CSR_Down')
    error('Variable CSR_Down is missing in %s', crf_file);
end
CSR_Down = data.CSR_Down;
ws001_vec = mean(CSR_Down,1,'omitnan')';
if isfield(data,'model_type')
    model_label = char(data.model_type);
else
    [~,base_name,~] = fileparts(crf_file);
    if contains(lower(base_name),'xgb')
        model_label = 'xgboost';
    else
        model_label = 'model';
    end
end
if isfield(data,'residual_interp_method')
    method_label = char(data.residual_interp_method);
    if ~isempty(method_label)
        model_label = sprintf('%s_%s',model_label,method_label);
    end
end

Sxy = shaperead(shp_file);
Sgeo = shaperead(shp_file,'UseGeoCoords',true);
[xv,yv] = merge_polygon_xy(Sxy);
lon_min = min(xv,[],'omitnan');
lon_max = max(xv,[],'omitnan');
lat_min = min(yv,[],'omitnan');
lat_max = max(yv,[],'omitnan');

lon001_min = max(0.005, floor(lon_min/0.01)*0.01 - 0.01);
lon001_max = min(359.995, ceil(lon_max/0.01)*0.01 + 0.01);
lat001_min = max(-89.995, floor(lat_min/0.01)*0.01 - 0.01);
lat001_max = min(89.995, ceil(lat_max/0.01)*0.01 + 0.01);
lon001 = lon001_min:0.01:lon001_max;
lat001 = lat001_max:-0.01:lat001_min;
[Lon001,Lat001] = meshgrid(lon001,lat001);
mask001 = inpolygon(Lon001,Lat001,xv,yv);
idx001 = find(mask001);

if numel(idx001) ~= numel(ws001_vec)
    error(['CSR_Down column count (%d) does not match 0.01 mask cells (%d). ' ...
        'Please check shp/data consistency.'], numel(ws001_vec), numel(idx001));
end

tbl001 = table(Lon001(idx001),Lat001(idx001),ws001_vec, ...
    'VariableNames',{'Lon','Lat','GWSA_mm'});
table_file = fullfile(out_dir,sprintf('GWSA_Downscaled_001_mean_table_%s.csv',model_label));
writetable(tbl001,table_file);

map001 = nan(size(Lon001));
map001(idx001) = tbl001.GWSA_mm;

fig = figure('Color','w','Position',[120,80,900,700]);
axesm('Mercator','frame','on','flinewidth',0.9,'MapParallels',10, ...
    'mlinelocation',2,'grid','on','maplatlim',[lat_min,lat_max], ...
    'maplonlim',[lon_min,lon_max],'MLineLocation',2,'MLabelRound',0, ...
    'MeridianLabel','on','PLineLocation',2,'PLabelRound',0, ...
    'ParallelLabel','on','MLabelParallel','south');
axis off;
hold on;
g = geoshow(Lat001,Lon001,map001,'DisplayType','texturemap');
g.AlphaDataMapping = 'none';
g.FaceAlpha = 'texturemap';
alpha(g,double(~isnan(map001)));
geoshow(Sgeo,'facecolor','none','edgecolor','k','LineWidth',0.9);
colormap(parula(256));
cb = colorbar;
ylabel(cb,'GWSA (mm)');
title(sprintf('Henan Mean GWSA (0.01 x 0.01 deg, 2002-04 to 2024-12, %s)',model_label),'FontSize',12);

png_file = fullfile(out_dir,sprintf('Henan_GWSA_001_mean_200204_202412_%s.png',model_label));
fig_file = fullfile(out_dir,sprintf('Henan_GWSA_001_mean_200204_202412_%s.fig',model_label));
saveas(fig,png_file);
savefig(fig,fig_file);

fprintf('Input:\n%s\n', crf_file);
fprintf('Saved:\n%s\n%s\n', png_file, fig_file);
fprintf('Saved table:\n%s\n', table_file);
end

function [xv,yv] = merge_polygon_xy(S)
xv = [];
yv = [];
for i = 1:numel(S)
    if isfield(S,'X') && isfield(S,'Y')
        xv = [xv, nan, S(i).X]; %#ok<AGROW>
        yv = [yv, nan, S(i).Y]; %#ok<AGROW>
    elseif isfield(S,'Lon') && isfield(S,'Lat')
        xv = [xv, nan, S(i).Lon]; %#ok<AGROW>
        yv = [yv, nan, S(i).Lat]; %#ok<AGROW>
    end
end
end
