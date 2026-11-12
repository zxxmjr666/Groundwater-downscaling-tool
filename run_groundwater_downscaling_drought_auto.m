function run_groundwater_downscaling_drought_auto()
% One-click runner for the Henan groundwater downscaling workflow.
% MATLAB R2023a. Outputs are written to D:\claude matlab\xinshiyan\shuju\auto_output.

base_dir = 'D:\claude matlab\xinshiyan';
code_dir = fullfile(base_dir,'code');
data_dir = fullfile(base_dir,'shuju');
out_dir = fullfile(data_dir,'auto_output');

cfg = struct();
cfg.enabled = true;
cfg.shp_file = fullfile(data_dir,'henan.shp');
cfg.mascon_nc = fullfile(data_dir,'CSR_GRACE_GRACE-FO_RL0603_Mascons_all-corrections.nc');
cfg.gldas_dir = fullfile(data_dir,'gldas_025');
cfg.temp_dir = fullfile(data_dir,'temp0.01');
cfg.rhu_dir = fullfile(data_dir,'rhu0.01');
cfg.pres_dir = fullfile(data_dir,'pres0.01');
cfg.pre_dir = fullfile(data_dir,'pre0.01');
cfg.lst_dir = fullfile(data_dir,'lst1km');
cfg.et_dir = fullfile(data_dir,'et500m');
cfg.ndvi_dir = fullfile(data_dir,'ndvi1km');
cfg.dem_file = fullfile(data_dir,'DEM30m','Henan_SRTM3_90m_clipped.mat');

cfg.mascon_mat = fullfile(out_dir,'CMascon','CMascon_200204_202412.mat');
cfg.fill_mat = fullfile(out_dir,'Cfill','Fill_200204_202412.mat');
cfg.gldas_mat = fullfile(out_dir,'CGLDAS','GLDAS_200204_202412.mat');
cfg.predictor_mat = fullfile(out_dir,'CPredictors','Predictors_200204_202412.mat');
cfg.temp_mat = fullfile(out_dir,'Ctemp','temp_200204_202412.mat');
cfg.rhu_mat = fullfile(out_dir,'Crhu','rhu_200204_202412.mat');
cfg.pres_mat = fullfile(out_dir,'Cpres','pres_200204_202412.mat');
cfg.pre_mat = fullfile(out_dir,'Cpre','pre_200204_202412.mat');
cfg.lst_mat = fullfile(out_dir,'CLST','lst_200204_202412.mat');
cfg.et_mat = fullfile(out_dir,'Cet','et_200204_202412.mat');
cfg.ndvi_mat = fullfile(out_dir,'CNDVI','ndvi_200204_202412.mat');
cfg.dem_mat = fullfile(out_dir,'CDEM','dem_200204_202412.mat');
cfg.rf_mat = fullfile(out_dir,'Cxgb','GWSA_Downscaled_001_200204_202412_xgb.mat');
cfg.gdi_mat = fullfile(out_dir,'Cxgb','GDI_200204_202412.mat');

out_dirs = { ...
    fileparts(cfg.mascon_mat), ...
    fileparts(cfg.fill_mat), ...
    fileparts(cfg.gldas_mat), ...
    fileparts(cfg.temp_mat), ...
    fileparts(cfg.rhu_mat), ...
    fileparts(cfg.pres_mat), ...
    fileparts(cfg.pre_mat), ...
    fileparts(cfg.lst_mat), ...
    fileparts(cfg.et_mat), ...
    fileparts(cfg.ndvi_mat), ...
    fileparts(cfg.dem_mat), ...
    fileparts(cfg.rf_mat) ...
};
for i = 1:numel(out_dirs)
    if ~exist(out_dirs{i},'dir')
        mkdir(out_dirs{i});
    end
end

required_paths = {cfg.shp_file,cfg.mascon_nc,cfg.gldas_dir,cfg.temp_dir, ...
    cfg.rhu_dir,cfg.pres_dir,cfg.pre_dir,cfg.lst_dir,cfg.et_dir, ...
    cfg.ndvi_dir,cfg.dem_file};
for i = 1:numel(required_paths)
    if ~exist(required_paths{i},'file') && ~exist(required_paths{i},'dir')
        error('Missing required path: %s', required_paths{i});
    end
end

old_dir = pwd;
cleanup_dir = onCleanup(@() cd(old_dir)); %#ok<NASGU>
addpath(code_dir);
cd(code_dir);

h = groundwater_downscaling_drought;
cleanup_fig = onCleanup(@() safe_close(h)); %#ok<NASGU>
pause(1);

handles = guidata(h);
set(handles.edit3,'String','0.25');
set(handles.edit4,'String','0.01');
set(handles.edit5,'String','2002 4 2024 12');
handles.input_resolution = 0.25;
handles.output_resolution = 0.01;
handles.trange = [2002 4 2024 12];
handles.auto = cfg;
guidata(h,handles);

run_step(h,'pushbutton_readshp_Callback','pushbutton_readshp');
if exist(cfg.fill_mat,'file')
    fprintf('SKIP existing: %s\n', cfg.fill_mat);
elseif exist(cfg.mascon_mat,'file')
    fprintf('SKIP existing: %s\n', cfg.mascon_mat);
    run_step(h,'GP_fill_Callback','GP_fill');
else
    run_step(h,'pushbutton_readMacson_Callback','pushbutton_readMacson');
    run_step(h,'GP_fill_Callback','GP_fill');
end
if exist(cfg.gldas_mat,'file')
    fprintf('SKIP existing: %s\n', cfg.gldas_mat);
else
    run_step(h,'read_gldas_Callback','read_gldas');
end
run_factor_step(h,'read_temp_Callback','pushbutton_read_factor_temp',cfg.temp_mat);
run_factor_step(h,'read_rhu_Callback','pushbutton_read_factor_rhu',cfg.rhu_mat);
run_factor_step(h,'read_pres_Callback','pushbutton_read_factor_pres',cfg.pres_mat);
run_factor_step(h,'read_pre_Callback','pushbutton_read_factor_pre',cfg.pre_mat);
run_factor_step(h,'read_lst_Callback','pushbutton_read_factor_lst',cfg.lst_mat);
run_factor_step(h,'read_et_Callback','pushbutton_read_factor_et',cfg.et_mat);
run_factor_step(h,'read_ndvi_Callback','pushbutton_read_factor_ndvi',cfg.ndvi_mat);
run_factor_step(h,'read_dem_Callback','pushbutton_read_factor_dem',cfg.dem_mat);
run_step(h,'pushbutton8_Callback','pushbutton8');

outputs = {cfg.mascon_mat,cfg.fill_mat,cfg.gldas_mat,cfg.temp_mat,cfg.rhu_mat, ...
    cfg.pres_mat,cfg.pre_mat,cfg.lst_mat,cfg.et_mat,cfg.ndvi_mat,cfg.dem_mat,cfg.rf_mat};
for i = 1:numel(outputs)
    if exist(outputs{i},'file')
        fprintf('OK: %s\n', outputs{i});
    else
        warning('Missing output: %s', outputs{i});
    end
end
fprintf('Pipeline finished.\n');

function run_step(hFig,cb_name,h_field)
handles_local = guidata(hFig);
h_obj = handles_local.(h_field);
fprintf('[%s] %s\n', datestr(now,'yyyy-mm-dd HH:MM:SS'), cb_name);
groundwater_downscaling_drought(cb_name,h_obj,[],handles_local);
drawnow;
close_non_main_figures(hFig);

function run_factor_step(hFig,cb_name,h_field,out_file)
if exist(out_file,'file')
    fprintf('SKIP existing: %s\n', out_file);
else
    run_step(hFig,cb_name,h_field);
end

function close_non_main_figures(mainFig)
figs = findall(0,'Type','figure');
for i = 1:numel(figs)
    if figs(i) ~= mainFig
        try
            close(figs(i));
        catch
        end
    end
end

function safe_close(hFig)
if ishghandle(hFig)
    try
        close(hFig);
    catch
    end
end

