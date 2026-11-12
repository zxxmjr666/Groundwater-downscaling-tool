function run_xgb_cluster_residual_final_only()
% Final-stage XGBoost downscaling with cluster-internal Kriging residual correction.
% It reuses saved intermediate MAT files and does not rerun GRACE gap filling
% or predictor reading.

base_dir = 'D:\claude matlab\xinshiyan';
code_dir = fullfile(base_dir,'code');
data_dir = fullfile(base_dir,'shuju');
out_dir = fullfile(data_dir,'auto_output');

addpath(code_dir);

cfg = struct();
cfg.fill_mat = fullfile(out_dir,'Cfill','Fill_200204_202412.mat');
cfg.gldas_mat = fullfile(out_dir,'CGLDAS','GLDAS_200204_202412.mat');
cfg.grid_seed_mat = fullfile(out_dir,'henan_grid_seed.mat');
cfg.temp_mat = fullfile(out_dir,'Ctemp','temp_200204_202412.mat');
cfg.rhu_mat = fullfile(out_dir,'Crhu','rhu_200204_202412.mat');
cfg.pres_mat = fullfile(out_dir,'Cpres','pres_200204_202412.mat');
cfg.pre_mat = fullfile(out_dir,'Cpre','pre_200204_202412.mat');
cfg.lst_mat = fullfile(out_dir,'CLST','lst_200204_202412.mat');
cfg.et_mat = fullfile(out_dir,'Cet','et_200204_202412.mat');
cfg.ndvi_mat = fullfile(out_dir,'CNDVI','ndvi_200204_202412.mat');
cfg.dem_mat = fullfile(out_dir,'CDEM','dem_200204_202412.mat');
cfg.output_mat = fullfile(out_dir,'Cxgb','GWSA_Downscaled_001_200204_202412_xgb.mat');
cfg.model_dir = fullfile(out_dir,'Cxgb','xgb_models');
cfg.temp_dir = fullfile(out_dir,'Cxgb','xgb_tmp');
cfg.prediction_cache_dir = fullfile(cfg.temp_dir,'prediction_cache');

required = {cfg.fill_mat,cfg.gldas_mat,cfg.grid_seed_mat,cfg.temp_mat, ...
    cfg.rhu_mat,cfg.pres_mat,cfg.pre_mat,cfg.lst_mat,cfg.et_mat, ...
    cfg.ndvi_mat,cfg.dem_mat};
for i = 1:numel(required)
    if ~exist(required{i},'file')
        error('Missing required intermediate file: %s', required{i});
    end
end
if ~exist(fileparts(cfg.output_mat),'dir'), mkdir(fileparts(cfg.output_mat)); end
if ~exist(cfg.model_dir,'dir'), mkdir(cfg.model_dir); end
if ~exist(cfg.temp_dir,'dir'), mkdir(cfg.temp_dir); end
if ~exist(cfg.prediction_cache_dir,'dir'), mkdir(cfg.prediction_cache_dir); end
% Preserve completed models so an interrupted run never removes prior work.
hngw_delete_matching(cfg.temp_dir,'*.mat');

fprintf('Loading saved intermediate data...\n');
F = load(cfg.fill_mat,'grid_fill','time');
G = load(cfg.gldas_mat,'gldas');
S = load(cfg.grid_seed_mat);

gwsa = double(F.grid_fill) - double(G.gldas);
time = F.time(:);
[predictor025,predictor001,predictorStatic025,predictorStatic001,predictorNames] = ...
    hngw_load_split_predictors(cfg);

k = hngw_common_time_length(gwsa,predictor025,predictor001);
gwsa = gwsa(1:k,:);
time = time(1:k);
predictor025 = hngw_trim_dynamic_predictors(predictor025,k);
predictor001 = hngw_trim_dynamic_predictors(predictor001,k);

n025 = size(gwsa,2);
n001 = numel(S.rbi2);
if n025 ~= numel(S.rbi1)
    error('0.25 GWSA columns (%d) do not match grid seed cells (%d).',n025,numel(S.rbi1));
end
if ~hngw_check_predictor_width(predictor025,predictorStatic025,n025)
    error('0.25 predictor spatial sizes are inconsistent with GWSA.');
end
if ~hngw_check_predictor_width(predictor001,predictorStatic001,n001)
    error('0.01 predictor spatial sizes are inconsistent with output grid.');
end

model_type = 'xgboost';
residual_interp_method = 'cluster_kriging';
xgb_lag_months = 6;
xgb_corr_threshold = 0.85;
xgb_model_dir = cfg.model_dir;
xgb_model_files = cell(k,1);
xgb_feature_selection = cell(k,1);

ypred = nan(k,n025,'single');
Y_pred = nan(k,n001,'single');

fprintf('Training monthly XGBoost models (%d months, lag=%d)...\n',k,xgb_lag_months);
for kk = 1:k
    modelFile = hngw_xgb_model_file(cfg.model_dir,kk,time);
    modelMetaFile = [modelFile(1:end-5),'_meta.json'];
    cacheFile = hngw_xgb_prediction_cache_file(cfg.prediction_cache_dir,kk,time);
    [cacheHit,y025,y001,featureSelection] = hngw_load_xgb_prediction_cache( ...
        cacheFile,kk,time(kk),n025,n001,xgb_lag_months,xgb_corr_threshold);
    if cacheHit && exist(modelFile,'file') == 2 && exist(modelMetaFile,'file') == 2
        ypred(kk,:) = single(y025(:)');
        Y_pred(kk,:) = single(y001(:)');
        xgb_model_files{kk} = modelFile;
        xgb_feature_selection{kk} = featureSelection;
        if mod(kk,12) == 0 || kk == k
            fprintf('  XGBoost %d/%d finished. (cached)\n',kk,k);
        end
        continue;
    end
    if cacheHit
        fprintf('  Cache exists but model is missing for month %d; retraining.\n',kk);
    end

    [X025_all,xgb_feature_names,xgb_feature_lags] = hngw_lagged_rf_matrix( ...
        predictor025,predictorStatic025,predictorNames,kk,xgb_lag_months);
    X001_all = hngw_lagged_rf_matrix( ...
        predictor001,predictorStatic001,predictorNames,kk,xgb_lag_months);
    [X025,X001,selected_feature_names,removed_feature_names,selected_feature_index] = ...
        hngw_remove_collinear_lag_features(X025_all,X001_all,xgb_feature_names, ...
        xgb_feature_lags,xgb_corr_threshold);

    Y025 = gwsa(kk,:)';
    [y025,y001] = hngw_xgb_predict_month(X025,Y025,X001,kk,cfg.temp_dir,modelFile);

    ypred(kk,:) = single(y025(:)');
    Y_pred(kk,:) = single(y001(:)');
    xgb_model_files{kk} = modelFile;
    featureSelection = struct( ...
        'month_index',kk, ...
        'lag_months',xgb_lag_months, ...
        'corr_threshold',xgb_corr_threshold, ...
        'all_feature_names',{xgb_feature_names}, ...
        'selected_feature_names',{selected_feature_names}, ...
        'removed_feature_names',{removed_feature_names}, ...
        'selected_feature_index',selected_feature_index);
    xgb_feature_selection{kk} = featureSelection;
    hngw_save_xgb_prediction_cache(cacheFile,y025,y001,featureSelection, ...
        kk,time(kk),n025,n001,xgb_lag_months,xgb_corr_threshold);

    if mod(kk,12) == 0 || kk == k
        fprintf('  XGBoost %d/%d finished.\n',kk,k);
    end
end

fprintf('Building cluster Kriging residual correction...\n');
cluster_candidates = 3:8;
cluster_result = hngw_cluster_gwsa_series(gwsa,S,cluster_candidates);
cluster_labels_025 = cluster_result.labels(:);
fine_to_coarse = hngw_fine_to_coarse_map(S);
cluster_labels_001 = cluster_labels_025(fine_to_coarse);

fine_area_weight = cosd(S.Lat2(S.rbi2));
fine_area_weight = double(fine_area_weight(:));
coarse_area_weight = cosd(S.Lat1(S.rbi1));
coarse_area_weight = double(coarse_area_weight(:));

Y_XGB_agg = hngw_aggregate_fine_to_coarse(Y_pred,fine_to_coarse, ...
    fine_area_weight,n025);
Residual_region = single(gwsa - Y_XGB_agg);

[cluster_residual,cluster_counts] = hngw_cluster_monthly_residual( ...
    double(Residual_region),cluster_labels_025,coarse_area_weight,cluster_result.selected_k);

kriging_options = hngw_cluster_kriging_options();
[Residual_region_001,kriging_result] = hngw_cluster_kriging_residual_to_fine( ...
    double(Residual_region),cluster_labels_025,cluster_labels_001,S,kriging_options);

residual_smoothing = struct();
residual_smoothing.enabled = true;
residual_smoothing.kernel = [ ...
    1 8 28 56 70 56 28 8 1; ...
    8 64 224 448 560 448 224 64 8; ...
    28 224 784 1568 1960 1568 784 224 28; ...
    56 448 1568 3136 3920 3136 1568 448 56; ...
    70 560 1960 3920 4900 3920 1960 560 70; ...
    56 448 1568 3136 3920 3136 1568 448 56; ...
    28 224 784 1568 1960 1568 784 224 28; ...
    8 64 224 448 560 448 224 64 8; ...
    1 8 28 56 70 56 28 8 1] / 65536;
residual_smoothing.strength = 1.0;
residual_smoothing.preserve_cluster_mean = false;
residual_smoothing.preserve_global_bias = true;
Residual_region_001 = hngw_smooth_fine_residual_field(Residual_region_001,S,residual_smoothing);

CSR_Down = double(Y_pred) + double(Residual_region_001);
Y_final_agg = hngw_aggregate_fine_to_coarse(CSR_Down,fine_to_coarse, ...
    fine_area_weight,n025);
if isfield(residual_smoothing,'preserve_global_bias') && residual_smoothing.preserve_global_bias
    residual_smoothing.global_bias_adjustment = mean(gwsa - Y_final_agg,'all','omitnan');
    Residual_region_001 = single(double(Residual_region_001) + residual_smoothing.global_bias_adjustment);
    CSR_Down = double(Y_pred) + double(Residual_region_001);
    Y_final_agg = hngw_aggregate_fine_to_coarse(CSR_Down,fine_to_coarse, ...
        fine_area_weight,n025);
end
cluster_validation = hngw_scale_validation(gwsa,Y_XGB_agg,Y_final_agg);

fprintf('Cluster k selected: %d\n',cluster_result.selected_k);
fprintf('Kriging clusters: %d ordinary, %d IDW fallback, %d mean fallback.\n', ...
    kriging_result.method_counts.ordinary_kriging, ...
    kriging_result.method_counts.idw, ...
    kriging_result.method_counts.mean);
fprintf('RMSE before/after: %.4f -> %.4f\n', ...
    cluster_validation.RMSE_before,cluster_validation.RMSE_after);
fprintf('Bias before/after: %.4f -> %.4f\n', ...
    cluster_validation.Bias_before,cluster_validation.Bias_after);
fprintf('NSE before/after: %.4f -> %.4f\n', ...
    cluster_validation.NSE_before,cluster_validation.NSE_after);

fprintf('Computing trend and basin time series...\n');
[time_series,trend_down] = hngw_downscaled_series_and_trend(CSR_Down,time,S);

cluster_correction = struct();
cluster_correction.method = residual_interp_method;
cluster_correction.cluster_candidates = cluster_candidates;
cluster_correction.cluster_result = cluster_result;
cluster_correction.cluster_residual = cluster_residual;
cluster_correction.cluster_counts = cluster_counts;
cluster_correction.kriging_options = kriging_options;
cluster_correction.kriging_result = kriging_result;
cluster_correction.cluster_labels_025 = cluster_labels_025;
cluster_correction.cluster_labels_001 = cluster_labels_001;
cluster_correction.fine_to_coarse = fine_to_coarse;
cluster_correction.fine_area_weight = fine_area_weight;
cluster_correction.coarse_area_weight = coarse_area_weight;
cluster_correction.Y_XGB_agg = Y_XGB_agg;
cluster_correction.Y_final_agg = Y_final_agg;
cluster_correction.validation = cluster_validation;
cluster_correction.residual_smoothing = residual_smoothing;

fprintf('Saving output: %s\n',cfg.output_mat);
save(cfg.output_mat,'CSR_Down','-v7.3');
save(cfg.output_mat,'-append','ypred');
save(cfg.output_mat,'-append','Residual_region');
save(cfg.output_mat,'-append','Residual_region_001');
save(cfg.output_mat,'-append','Y_pred');
save(cfg.output_mat,'-append','trend_down');
save(cfg.output_mat,'-append','time_series');
save(cfg.output_mat,'-append','time');
save(cfg.output_mat,'-append','model_type');
save(cfg.output_mat,'-append','residual_interp_method');
save(cfg.output_mat,'-append','xgb_model_dir');
save(cfg.output_mat,'-append','xgb_model_files');
save(cfg.output_mat,'-append','xgb_lag_months');
save(cfg.output_mat,'-append','xgb_corr_threshold');
save(cfg.output_mat,'-append','xgb_feature_selection');
save(cfg.output_mat,'-append','cluster_correction');
save(cfg.output_mat,'-append','cluster_validation');
save(cfg.output_mat,'-append','cluster_result');
save(cfg.output_mat,'-append','cluster_labels_025');
save(cfg.output_mat,'-append','cluster_labels_001');
save(cfg.output_mat,'-append','fine_to_coarse');
save(cfg.output_mat,'-append','Y_XGB_agg');
save(cfg.output_mat,'-append','Y_final_agg');

model_exists = cellfun(@(f) exist(f,'file') == 2,xgb_model_files);
meta_exists = cellfun(@(f) exist([f(1:end-5),'_meta.json'],'file') == 2,xgb_model_files);
if ~all(model_exists) || ~all(meta_exists)
    error('Model verification failed: %d model files and %d metadata files are missing.', ...
        nnz(~model_exists),nnz(~meta_exists));
end
fprintf('Verified all %d XGBoost models and metadata files.\n',k);

hngw_delete_matching(cfg.temp_dir,'*.mat');
hngw_delete_matching(cfg.prediction_cache_dir,'*.mat');
fprintf('Cluster residual corrected downscaling finished.\n');

function [predictor025,predictor001,static025,static001,names] = hngw_load_split_predictors(cfg)
files = {cfg.temp_mat,cfg.rhu_mat,cfg.pres_mat,cfg.pre_mat,cfg.lst_mat, ...
    cfg.et_mat,cfg.ndvi_mat,cfg.dem_mat};
predictor025 = struct();
predictor001 = struct();
static025 = struct();
static001 = struct();
names = {};
for i = 1:numel(files)
    S = load(files{i},'predictor');
    p = S.predictor;
    pNames = p.names;
    for j = 1:numel(pNames)
        name = pNames{j};
        if isfield(p.data025,name) && isfield(p.data001,name)
            predictor025.(name) = p.data025.(name);
            predictor001.(name) = p.data001.(name);
        elseif isfield(p.static025,name) && isfield(p.static001,name)
            static025.(name) = p.static025.(name);
            static001.(name) = p.static001.(name);
        else
            error('Predictor file %s is missing %s.',files{i},name);
        end
        names{end+1} = name; %#ok<AGROW>
    end
end

function k = hngw_common_time_length(gwsa,predictor025,predictor001)
k_all = size(gwsa,1);
f = fieldnames(predictor025);
for i = 1:numel(f), k_all(end+1) = size(predictor025.(f{i}),1); end %#ok<AGROW>
f = fieldnames(predictor001);
for i = 1:numel(f), k_all(end+1) = size(predictor001.(f{i}),1); end %#ok<AGROW>
k = min(k_all);
if k < 1, error('No overlapping time steps found.'); end

function predictor = hngw_trim_dynamic_predictors(predictor,k)
f = fieldnames(predictor);
for i = 1:numel(f)
    if size(predictor.(f{i}),1) > k
        predictor.(f{i}) = predictor.(f{i})(1:k,:);
    end
end

function ok = hngw_check_predictor_width(dynamicData,staticData,n)
ok = true;
f = fieldnames(dynamicData);
for i = 1:numel(f)
    ok = ok && size(dynamicData.(f{i}),2) == n;
end
f = fieldnames(staticData);
for i = 1:numel(f)
    ok = ok && numel(staticData.(f{i})) == n;
end

function [X,featureNames,featureLags] = hngw_lagged_rf_matrix(dynamicData,staticData,names,kk,lagMonths)
cols = {};
featureNames = {};
featureLags = [];
for i = 1:numel(names)
    name = names{i};
    if isfield(dynamicData,name)
        for lag = 0:lagMonths
            t = max(1,kk-lag);
            cols{end+1} = double(dynamicData.(name)(t,:)'); %#ok<AGROW>
            featureNames{end+1} = sprintf('%s_lag%d',name,lag); %#ok<AGROW>
            featureLags(end+1) = lag; %#ok<AGROW>
        end
    elseif isfield(staticData,name)
        cols{end+1} = double(staticData.(name)(:) ); %#ok<AGROW>
        featureNames{end+1} = name; %#ok<AGROW>
        featureLags(end+1) = -1; %#ok<AGROW>
    else
        error('Missing predictor variable: %s',name);
    end
end
X = [cols{:}];
for j = 1:size(X,2)
    col = X(:,j);
    med = median(col(isfinite(col)));
    if isempty(med) || isnan(med), med = 0; end
    col(~isfinite(col)) = med;
    X(:,j) = col;
end

function [X025,X001,selectedNames,removedNames,selectedIndex] = hngw_remove_collinear_lag_features(X025All,X001All,featureNames,featureLags,threshold)
keep = true(1,size(X025All,2));
R = corrcoef(X025All,'Rows','pairwise');
R(~isfinite(R)) = 0;
for i = 1:size(R,1)-1
    if ~keep(i), continue; end
    for j = i+1:size(R,2)
        if ~keep(j), continue; end
        if abs(R(i,j)) > threshold
            drop = hngw_choose_collinear_feature_to_drop(i,j,featureLags);
            keep(drop) = false;
        end
    end
end
selectedIndex = find(keep);
removedIndex = find(~keep);
X025 = X025All(:,selectedIndex);
X001 = X001All(:,selectedIndex);
selectedNames = featureNames(selectedIndex);
removedNames = featureNames(removedIndex);

function drop = hngw_choose_collinear_feature_to_drop(i,j,featureLags)
lagI = featureLags(i);
lagJ = featureLags(j);
if lagI > 0 || lagJ > 0
    if lagI > lagJ
        drop = i;
    elseif lagJ > lagI
        drop = j;
    else
        drop = j;
    end
else
    drop = j;
end

function modelFile = hngw_xgb_model_file(modelDir,monthIndex,timeVector)
yy = floor(timeVector(monthIndex));
mm = round((timeVector(monthIndex)-yy)*12 + 0.5);
mm = max(1,min(12,mm));
label = sprintf('%04d%02d',yy,mm);
modelFile = fullfile(modelDir,['xgb_model_',label,'.json']);

function cacheFile = hngw_xgb_prediction_cache_file(cacheDir,monthIndex,timeVector)
yy = floor(timeVector(monthIndex));
mm = round((timeVector(monthIndex)-yy)*12 + 0.5);
mm = max(1,min(12,mm));
label = sprintf('%04d%02d',yy,mm);
cacheFile = fullfile(cacheDir,['xgb_prediction_',label,'.mat']);

function [ok,y025,y001,featureSelection] = hngw_load_xgb_prediction_cache( ...
    cacheFile,monthIndex,timeValue,n025,n001,lagMonths,corrThreshold)
ok = false;
y025 = [];
y001 = [];
featureSelection = [];
if ~exist(cacheFile,'file')
    return;
end
try
    C = load(cacheFile,'y025','y001','featureSelection','cache_meta');
    if ~isfield(C,'cache_meta') || ~isfield(C,'y025') || ~isfield(C,'y001')
        return;
    end
    M = C.cache_meta;
    sameMeta = M.month_index == monthIndex && abs(M.time_value - timeValue) < 1e-9 && ...
        M.n025 == n025 && M.n001 == n001 && ...
        M.lag_months == lagMonths && abs(M.corr_threshold - corrThreshold) < 1e-12;
    sameSize = numel(C.y025) == n025 && numel(C.y001) == n001;
    if sameMeta && sameSize
        y025 = double(C.y025(:));
        y001 = double(C.y001(:));
        featureSelection = C.featureSelection;
        ok = true;
    end
catch
    ok = false;
end

function hngw_save_xgb_prediction_cache(cacheFile,y025,y001,featureSelection, ...
    monthIndex,timeValue,n025,n001,lagMonths,corrThreshold)
cache_meta = struct();
cache_meta.month_index = monthIndex;
cache_meta.time_value = timeValue;
cache_meta.n025 = n025;
cache_meta.n001 = n001;
cache_meta.lag_months = lagMonths;
cache_meta.corr_threshold = corrThreshold;
y025 = single(y025(:));
y001 = single(y001(:));
save(cacheFile,'y025','y001','featureSelection','cache_meta','-v7');

function [y025,y001] = hngw_xgb_predict_month(X025,Y025,X001,monthIndex,tempDir,modelFile)
if ~exist(tempDir,'dir'), mkdir(tempDir); end
inputFile = [tempname(tempDir),'.mat'];
outputFile = [tempname(tempDir),'.mat'];
X025 = single(X025);
Y025 = single(Y025(:));
X001 = single(X001);
save(inputFile,'X025','Y025','X001','-v7');
scriptFile = fullfile(fileparts(mfilename('fullpath')),'hngw_xgboost_predict_month.py');
pythonExe = hngw_python_executable();
cmd = sprintf('"%s" "%s" --input "%s" --output "%s" --month-index %d --model-output "%s"', ...
    pythonExe,scriptFile,inputFile,outputFile,monthIndex,modelFile);
[status,cmdout] = system(cmd);
hngw_delete_file(inputFile);
if status ~= 0
    hngw_delete_file(outputFile);
    error('XGBoost failed for month index %d:\n%s',monthIndex,cmdout);
end
R = load(outputFile,'ypred025','ypred001');
hngw_delete_file(outputFile);
y025 = double(R.ypred025(:));
y001 = double(R.ypred001(:));

function pythonExe = hngw_python_executable()
candidates = {'D:\python\python.exe','python'};
for i = 1:numel(candidates)
    if exist(candidates{i},'file') || strcmp(candidates{i},'python')
        [status,~] = system(sprintf('"%s" --version',candidates{i}));
        if status == 0
            pythonExe = candidates{i};
            return;
        end
    end
end
error('Cannot find a usable Python executable for XGBoost.');

function cluster_result = hngw_cluster_gwsa_series(gwsa,S,kCandidates)
X = gwsa';
mu = mean(X,2,'omitnan');
sg = std(X,0,2,'omitnan');
sg(~isfinite(sg) | sg == 0) = 1;
X = (X - mu) ./ sg;
X(~isfinite(X)) = 0;

lon = S.Lon1(S.rbi1);
lat = S.Lat1(S.rbi1);
metrics = repmat(struct('k',[],'silhouette',[],'davies_bouldin',[], ...
    'calinski_harabasz',[],'connectivity',[],'component_count',[],'score',[]), ...
    numel(kCandidates),1);
allLabels = cell(numel(kCandidates),1);
allCentroids = cell(numel(kCandidates),1);
for i = 1:numel(kCandidates)
    kk = kCandidates(i);
    [labels,centroids] = hngw_simple_kmeans(X,kk,20,200);
    M = hngw_cluster_metrics(X,labels,centroids,S);
    metrics(i).k = kk;
    metrics(i).silhouette = M.silhouette;
    metrics(i).davies_bouldin = M.davies_bouldin;
    metrics(i).calinski_harabasz = M.calinski_harabasz;
    metrics(i).connectivity = M.connectivity;
    metrics(i).component_count = M.component_count;
    allLabels{i} = labels;
    allCentroids{i} = centroids;
end
sil = [metrics.silhouette]';
db = [metrics.davies_bouldin]';
ch = [metrics.calinski_harabasz]';
conn = [metrics.connectivity]';
score = hngw_norm_high(sil) + hngw_norm_low(db) + hngw_norm_high(ch) + hngw_norm_high(conn);
for i = 1:numel(metrics), metrics(i).score = score(i); end
[~,best] = max(score);
cluster_result = struct();
cluster_result.selected_k = kCandidates(best);
cluster_result.labels = allLabels{best};
cluster_result.centroids = allCentroids{best};
cluster_result.metrics = metrics;
cluster_result.coarse_lon = lon(:);
cluster_result.coarse_lat = lat(:);
cluster_result.standardization = 'each coarse-pixel time series z-score over months';
cluster_result.selection_rule = 'max normalized silhouette + inverse DB + CH + spatial connectivity';

function v = hngw_norm_high(x)
x = x(:);
mn = min(x); mx = max(x);
if ~isfinite(mn) || ~isfinite(mx) || mx == mn
    v = 0.5 * ones(size(x));
else
    v = (x - mn) ./ (mx - mn);
end

function v = hngw_norm_low(x)
v = hngw_norm_high(-x);

function [labels,centroids] = hngw_simple_kmeans(X,k,replicates,maxIter)
n = size(X,1);
bestSse = inf;
labels = ones(n,1);
centroids = X(1:k,:);
for rep = 1:replicates
    C = hngw_init_centroids(X,k,rep);
    lastLabels = zeros(n,1);
    for iter = 1:maxIter
        D = hngw_sqdist(X,C);
        [~,lab] = min(D,[],2);
        if isequal(lab,lastLabels), break; end
        lastLabels = lab;
        for c = 1:k
            idx = lab == c;
            if any(idx)
                C(c,:) = mean(X(idx,:),1);
            else
                [~,farIdx] = max(min(D,[],2));
                C(c,:) = X(farIdx,:);
            end
        end
    end
    D = hngw_sqdist(X,C);
    [dmin,lab] = min(D,[],2);
    sse = sum(dmin);
    if sse < bestSse
        bestSse = sse;
        labels = lab;
        centroids = C;
    end
end

function C = hngw_init_centroids(X,k,rep)
n = size(X,1);
C = zeros(k,size(X,2));
first = mod(37*rep,n) + 1;
C(1,:) = X(first,:);
minD = hngw_sqdist(X,C(1,:));
for c = 2:k
    [~,idx] = max(minD);
    C(c,:) = X(idx,:);
    minD = min(minD,hngw_sqdist(X,C(c,:)));
end

function D = hngw_sqdist(A,B)
D = max(0,sum(A.^2,2) + sum(B.^2,2)' - 2*(A*B'));

function M = hngw_cluster_metrics(X,labels,centroids,S)
n = size(X,1);
k = size(centroids,1);
Dmat = sqrt(hngw_sqdist(X,X));
sil = nan(n,1);
for i = 1:n
    same = labels == labels(i);
    same(i) = false;
    if any(same)
        a = mean(Dmat(i,same));
    else
        a = 0;
    end
    b = inf;
    for c = 1:k
        if c == labels(i), continue; end
        idx = labels == c;
        if any(idx), b = min(b,mean(Dmat(i,idx))); end
    end
    sil(i) = (b - a) / max(a,b);
end
silhouetteVal = mean(sil,'omitnan');

Swithin = zeros(k,1);
for c = 1:k
    idx = labels == c;
    if any(idx)
        Swithin(c) = mean(sqrt(sum((X(idx,:) - centroids(c,:)).^2,2)));
    end
end
CD = sqrt(hngw_sqdist(centroids,centroids));
DBc = zeros(k,1);
for c = 1:k
    vals = -inf(k,1);
    for d = 1:k
        if c ~= d
            vals(d) = (Swithin(c) + Swithin(d)) / max(CD(c,d),eps);
        end
    end
    DBc(c) = max(vals);
end
db = mean(DBc);

globalMean = mean(X,1);
W = 0;
B = 0;
for c = 1:k
    idx = labels == c;
    nc = nnz(idx);
    if nc > 0
        W = W + sum(sum((X(idx,:) - centroids(c,:)).^2));
        B = B + nc * sum((centroids(c,:) - globalMean).^2);
    end
end
ch = (B / max(k-1,1)) / max(W / max(n-k,1),eps);

[connectivity,componentCount] = hngw_spatial_connectivity(labels,S);
M = struct('silhouette',silhouetteVal,'davies_bouldin',db, ...
    'calinski_harabasz',ch,'connectivity',connectivity, ...
    'component_count',componentCount);

function [connectivity,componentCount] = hngw_spatial_connectivity(labels,S)
n = numel(labels);
k = max(labels);
regionOfGlobal = zeros(numel(S.Lon1),1);
regionOfGlobal(S.rbi1) = 1:n;
[rows,cols] = ind2sub(size(S.Lon1),S.rbi1(:));
componentCount = 0;
largestTotal = 0;
for c = 1:k
    members = find(labels == c);
    memberMask = false(n,1);
    memberMask(members) = true;
    visited = false(n,1);
    largest = 0;
    comps = 0;
    for m = members(:)'
        if visited(m), continue; end
        comps = comps + 1;
        queue = m;
        visited(m) = true;
        count = 0;
        while ~isempty(queue)
            q = queue(end);
            queue(end) = [];
            count = count + 1;
            rr = rows(q); cc = cols(q);
            neigh = [rr-1 cc; rr+1 cc; rr cc-1; rr cc+1];
            for ni = 1:4
                r2 = neigh(ni,1); c2 = neigh(ni,2);
                if r2 < 1 || r2 > size(S.Lon1,1) || c2 < 1 || c2 > size(S.Lon1,2)
                    continue;
                end
                rid = regionOfGlobal(sub2ind(size(S.Lon1),r2,c2));
                if rid > 0 && memberMask(rid) && ~visited(rid)
                    visited(rid) = true;
                    queue(end+1) = rid; %#ok<AGROW>
                end
            end
        end
        largest = max(largest,count);
    end
    largestTotal = largestTotal + largest;
    componentCount = componentCount + comps;
end
connectivity = largestTotal / n;

function fine_to_coarse = hngw_fine_to_coarse_map(S)
n025 = numel(S.rbi1);
n001 = numel(S.rbi2);
coarseLookup = zeros(numel(S.Lon1),1,'uint32');
coarseLookup(S.rbi1) = uint32(1:n025);
lonFine = S.Lon2(S.rbi2);
latFine = S.Lat2(S.rbi2);
lonIdx = round((lonFine - S.lon1(1)) / 0.25) + 1;
latIdx = round((S.lat1(1) - latFine) / 0.25) + 1;
lonIdx = max(1,min(numel(S.lon1),lonIdx));
latIdx = max(1,min(numel(S.lat1),latIdx));
globalIdx = sub2ind(size(S.Lon1),latIdx(:),lonIdx(:));
fine_to_coarse = double(coarseLookup(globalIdx));
bad = fine_to_coarse < 1;
if any(bad)
    lonCoarse = S.Lon1(S.rbi1);
    latCoarse = S.Lat1(S.rbi1);
    badIdx = find(bad);
    for ii = 1:numel(badIdx)
        b = badIdx(ii);
        [~,nearest] = min((lonCoarse - lonFine(b)).^2 + (latCoarse - latFine(b)).^2);
        fine_to_coarse(b) = nearest;
    end
end
fine_to_coarse = fine_to_coarse(:);
if numel(fine_to_coarse) ~= n001
    error('Fine-to-coarse map size mismatch.');
end

function coarse = hngw_aggregate_fine_to_coarse(fineData,fine_to_coarse,weights,n025)
k = size(fineData,1);
coarse = nan(k,n025);
den = accumarray(fine_to_coarse,weights,[n025 1],@sum,NaN);
for t = 1:k
    vals = double(fineData(t,:)');
    good = isfinite(vals) & isfinite(weights);
    num = accumarray(fine_to_coarse(good),weights(good).*vals(good),[n025 1],@sum,NaN);
    coarse(t,:) = (num ./ den)';
end

function opts = hngw_cluster_kriging_options()
opts.min_kriging_points = 10;
opts.min_idw_points = 3;
opts.idw_power = 2;
opts.model = 'spherical';
opts.range_fractions = [0.25 0.40 0.55 0.70 0.85 1.00 1.20];
opts.sill_factors = [0.75 1.00 1.25 1.50];
opts.nugget_fractions = [0 0.02 0.05 0.10 0.20];
opts.min_range_km = 5;
opts.kriging_jitter_fraction = 1e-8;
opts.block_months = 24;

function [residual001,kriging_result] = hngw_cluster_kriging_residual_to_fine( ...
    residual025,labels025,labels001,S,opts)
T = size(residual025,1);
n001 = numel(labels001);
k = max(labels025);
residual001 = nan(T,n001,'single');

lon025 = S.Lon1(S.rbi1);
lat025 = S.Lat1(S.rbi1);
lon001 = S.Lon2(S.rbi2);
lat001 = S.Lat2(S.rbi2);

emptyVariogram = hngw_empty_variogram();
emptyInfo = struct('cluster',[],'n_coarse',[],'n_fine',[], ...
    'interpolator','','variogram',emptyVariogram, ...
    'condition_number',NaN,'message','');
clusterInfo = repmat(emptyInfo,k,1);

for c = 1:k
    coarseIdx = find(labels025 == c);
    fineIdx = find(labels001 == c);
    coarseIdx = coarseIdx(:);
    goodObs = any(isfinite(residual025(:,coarseIdx)),1);
    goodObs = goodObs(:);
    goodLon = isfinite(lon025(coarseIdx));
    goodLat = isfinite(lat025(coarseIdx));
    goodObs = goodObs & goodLon(:) & goodLat(:);
    if numel(goodObs) ~= numel(coarseIdx)
        error('Cluster %d valid-observation mask size mismatch.',c);
    end
    coarseIdx = coarseIdx(goodObs);

    info = emptyInfo;
    info.cluster = c;
    info.n_coarse = numel(coarseIdx);
    info.n_fine = numel(fineIdx);

    if isempty(fineIdx)
        info.interpolator = 'none';
        info.message = 'No fine pixels in this cluster.';
        clusterInfo(c) = info;
        continue;
    end
    if isempty(coarseIdx)
        info.interpolator = 'none';
        info.message = 'No coarse residual points in this cluster.';
        clusterInfo(c) = info;
        continue;
    end

    V = residual025(:,coarseIdx);
    obsLon = lon025(coarseIdx);
    obsLat = lat025(coarseIdx);
    predLon = lon001(fineIdx);
    predLat = lat001(fineIdx);

    if numel(coarseIdx) >= opts.min_kriging_points
        try
            [pred,info] = hngw_apply_ordinary_kriging_cluster( ...
                V,obsLon,obsLat,predLon,predLat,opts,info);
        catch ME
            [pred,info] = hngw_apply_idw_cluster( ...
                V,obsLon,obsLat,predLon,predLat,opts,info);
            info.message = ['Kriging failed; IDW fallback. ', ME.message];
        end
    elseif numel(coarseIdx) >= opts.min_idw_points
        [pred,info] = hngw_apply_idw_cluster( ...
            V,obsLon,obsLat,predLon,predLat,opts,info);
        info.message = 'Too few points for stable Kriging; IDW fallback.';
    else
        [pred,info] = hngw_apply_mean_cluster(V,numel(fineIdx),info);
        info.message = 'Too few points for Kriging or IDW; cluster mean fallback.';
    end

    residual001(:,fineIdx) = single(pred);
    clusterInfo(c) = info;
end

kriging_result = struct();
kriging_result.method = 'cluster_internal_ordinary_kriging';
kriging_result.variogram_strategy = 'one variogram per cluster fitted from all monthly residuals';
kriging_result.clusters = clusterInfo;
kriging_result.method_counts = hngw_cluster_method_counts(clusterInfo);

function [pred,info] = hngw_apply_ordinary_kriging_cluster( ...
    V,obsLon,obsLat,predLon,predLat,opts,info)
[obsXY,predXY] = hngw_lonlat_to_xy_km(obsLon,obsLat,predLon,predLat);
Doo = sqrt(hngw_sqdist(obsXY,obsXY));
Dop = sqrt(hngw_sqdist(obsXY,predXY));
variogram = hngw_fit_cluster_variogram(V,Doo,opts);
[weights,conditionNumber] = hngw_build_ordinary_kriging_weights(Doo,Dop,variogram,opts);
pred = hngw_predict_with_weights(V,weights,opts);
info.interpolator = 'ordinary_kriging';
info.variogram = variogram;
info.condition_number = conditionNumber;

function [pred,info] = hngw_apply_idw_cluster( ...
    V,obsLon,obsLat,predLon,predLat,opts,info)
[obsXY,predXY] = hngw_lonlat_to_xy_km(obsLon,obsLat,predLon,predLat);
Dop = sqrt(hngw_sqdist(obsXY,predXY));
weights = hngw_idw_weights(Dop,opts.idw_power);
pred = hngw_predict_with_weights(V,weights,opts);
info.interpolator = 'idw';
info.variogram = hngw_empty_variogram();
info.condition_number = NaN;

function [pred,info] = hngw_apply_mean_cluster(V,nFine,info)
T = size(V,1);
pred = nan(T,nFine,'single');
for t = 1:T
    vals = V(t,:);
    vals = vals(isfinite(vals));
    if ~isempty(vals)
        pred(t,:) = single(mean(vals));
    end
end
info.interpolator = 'mean';
info.variogram = hngw_empty_variogram();
info.condition_number = NaN;

function pred = hngw_predict_with_weights(V,weights,opts)
T = size(V,1);
nFine = size(weights,2);
pred = nan(T,nFine,'single');
allFinite = all(isfinite(V),2);
rows = find(allFinite);
blockMonths = max(1,opts.block_months);
for startIdx = 1:blockMonths:numel(rows)
    r = rows(startIdx:min(startIdx+blockMonths-1,numel(rows)));
    pred(r,:) = single(double(V(r,:)) * weights);
end
badRows = find(~allFinite);
for ii = 1:numel(badRows)
    t = badRows(ii);
    vals = V(t,:);
    good = isfinite(vals);
    if ~any(good), continue; end
    W = weights(good,:);
    den = sum(W,1);
    den(abs(den) < eps) = NaN;
    pred(t,:) = single((double(vals(good)) * W) ./ den);
end

function variogram = hngw_fit_cluster_variogram(V,Doo,opts)
[pairDist,pairGamma] = hngw_pair_semivariances(V,Doo);
good = isfinite(pairDist) & isfinite(pairGamma) & pairDist > 0 & pairGamma >= 0;
pairDist = pairDist(good);
pairGamma = pairGamma(good);

flat = V(:);
flat = flat(isfinite(flat));
if isempty(flat)
    baseSill = 1;
else
    baseSill = var(double(flat),0);
    if ~isfinite(baseSill) || baseSill <= 0
        baseSill = max(mean(abs(double(flat))),1);
    end
end

if numel(pairDist) < 3
    variogram = hngw_make_variogram(0,baseSill,max(opts.min_range_km,max(Doo(:))));
    variogram.fit_note = 'Default variogram; too few point pairs.';
    return;
end

[binDist,binGamma,binCount] = hngw_binned_variogram(pairDist,pairGamma);
if isempty(binDist)
    variogram = hngw_make_variogram(0,baseSill,max(opts.min_range_km,max(pairDist)));
    variogram.fit_note = 'Default variogram; empty empirical bins.';
    return;
end

maxDist = max(pairDist);
baseSill = max([baseSill,median(pairGamma,'omitnan'),max(binGamma)*0.75,eps]);
rangeCandidates = unique(max(opts.min_range_km,maxDist .* opts.range_fractions));
sillCandidates = unique(max(eps,baseSill .* opts.sill_factors));

bestErr = inf;
best = hngw_make_variogram(0,baseSill,max(opts.min_range_km,0.7*maxDist));
for sill = sillCandidates(:)'
    for nuggetFraction = opts.nugget_fractions(:)'
        nugget = min(0.8*sill,nuggetFraction*sill);
        partialSill = max(sill - nugget,eps);
        for rangeKm = rangeCandidates(:)'
            candidate = hngw_make_variogram(nugget,partialSill,rangeKm);
            predGamma = hngw_variogram_gamma(binDist,candidate);
            err = sum(binCount(:) .* (predGamma(:) - binGamma(:)).^2) / sum(binCount);
            if err < bestErr
                bestErr = err;
                best = candidate;
            end
        end
    end
end
best.empirical_distance = binDist(:);
best.empirical_gamma = binGamma(:);
best.empirical_count = binCount(:);
best.fit_error = bestErr;
best.fit_note = 'Spherical variogram grid search on binned residual semivariances.';
variogram = best;

function [pairDist,pairGamma] = hngw_pair_semivariances(V,Doo)
n = size(V,2);
pairDist = nan(n*(n-1)/2,1);
pairGamma = nan(n*(n-1)/2,1);
p = 0;
for i = 1:n-1
    for j = i+1:n
        diffVals = V(:,i) - V(:,j);
        good = isfinite(diffVals);
        if any(good)
            p = p + 1;
            pairDist(p) = Doo(i,j);
            pairGamma(p) = 0.5 * mean(double(diffVals(good)).^2);
        end
    end
end
pairDist = pairDist(1:p);
pairGamma = pairGamma(1:p);

function [binDist,binGamma,binCount] = hngw_binned_variogram(pairDist,pairGamma)
maxDist = max(pairDist);
if ~isfinite(maxDist) || maxDist <= 0
    binDist = [];
    binGamma = [];
    binCount = [];
    return;
end
nbins = max(5,min(12,round(sqrt(numel(pairDist)))));
edges = linspace(0,maxDist,nbins+1);
binDist = nan(nbins,1);
binGamma = nan(nbins,1);
binCount = zeros(nbins,1);
for b = 1:nbins
    if b == 1
        idx = pairDist >= edges(b) & pairDist <= edges(b+1);
    else
        idx = pairDist > edges(b) & pairDist <= edges(b+1);
    end
    if any(idx)
        binDist(b) = median(pairDist(idx),'omitnan');
        binGamma(b) = median(pairGamma(idx),'omitnan');
        binCount(b) = nnz(idx);
    end
end
good = isfinite(binDist) & isfinite(binGamma) & binCount > 0;
binDist = binDist(good);
binGamma = binGamma(good);
binCount = binCount(good);

function variogram = hngw_make_variogram(nugget,partialSill,rangeKm)
variogram = hngw_empty_variogram();
variogram.model = 'spherical';
variogram.nugget = max(0,nugget);
variogram.partial_sill = max(eps,partialSill);
variogram.sill = variogram.nugget + variogram.partial_sill;
variogram.range_km = max(eps,rangeKm);

function variogram = hngw_empty_variogram()
variogram = struct('model','','nugget',NaN,'partial_sill',NaN, ...
    'sill',NaN,'range_km',NaN,'empirical_distance',[], ...
    'empirical_gamma',[],'empirical_count',[],'fit_error',NaN,'fit_note','');

function gamma = hngw_variogram_gamma(distanceKm,variogram)
h = max(0,double(distanceKm));
rangeKm = max(eps,variogram.range_km);
hr = h ./ rangeKm;
shape = ones(size(h));
inside = hr < 1;
shape(inside) = 1.5 .* hr(inside) - 0.5 .* hr(inside).^3;
gamma = variogram.nugget + variogram.partial_sill .* shape;
gamma(h == 0) = 0;

function [weights,conditionNumber] = hngw_build_ordinary_kriging_weights(Doo,Dop,variogram,opts)
n = size(Doo,1);
GammaOO = hngw_variogram_gamma(Doo,variogram);
GammaOO(1:n+1:end) = 0;
jitter = max(variogram.sill * opts.kriging_jitter_fraction,eps);
GammaOO = GammaOO + eye(n) * jitter;
K = [GammaOO, ones(n,1); ones(1,n), 0];
rhs = [hngw_variogram_gamma(Dop,variogram); ones(1,size(Dop,2))];
rc = rcond(K);
if rc <= 0 || ~isfinite(rc)
    conditionNumber = inf;
else
    conditionNumber = 1 / rc;
end
if rc < 1e-12 || ~isfinite(rc)
    solution = pinv(K) * rhs;
else
    solution = K \ rhs;
end
weights = solution(1:n,:);
badCols = any(~isfinite(weights),1);
if any(badCols)
    weights(:,badCols) = hngw_idw_weights(Dop(:,badCols),opts.idw_power);
end

function weights = hngw_idw_weights(D,powerValue)
D = max(double(D),0);
[n,m] = size(D);
weights = zeros(n,m);
isZero = D < 1e-9;
zeroCols = any(isZero,1);
if any(zeroCols)
    z = double(isZero(:,zeroCols));
    weights(:,zeroCols) = z ./ sum(z,1);
end
cols = ~zeroCols;
if any(cols)
    Dnz = max(D(:,cols),1e-6);
    W = 1 ./ (Dnz .^ powerValue);
    weights(:,cols) = W ./ sum(W,1);
end

function [obsXY,predXY] = hngw_lonlat_to_xy_km(obsLon,obsLat,predLon,predLat)
obsLon = double(obsLon(:));
obsLat = double(obsLat(:));
predLon = double(predLon(:));
predLat = double(predLat(:));
lonRef = mean(obsLon,'omitnan');
latRef = mean(obsLat,'omitnan');
if ~isfinite(lonRef), lonRef = 0; end
if ~isfinite(latRef), latRef = 0; end
kmPerDegLon = 111.320 * cosd(latRef);
kmPerDegLat = 110.574;
obsXY = [(obsLon - lonRef) * kmPerDegLon, (obsLat - latRef) * kmPerDegLat];
predXY = [(predLon - lonRef) * kmPerDegLon, (predLat - latRef) * kmPerDegLat];

function counts = hngw_cluster_method_counts(clusterInfo)
counts = struct('ordinary_kriging',0,'idw',0,'mean',0,'none',0);
for i = 1:numel(clusterInfo)
    method = clusterInfo(i).interpolator;
    if strcmp(method,'ordinary_kriging')
        counts.ordinary_kriging = counts.ordinary_kriging + 1;
    elseif strcmp(method,'idw')
        counts.idw = counts.idw + 1;
    elseif strcmp(method,'mean')
        counts.mean = counts.mean + 1;
    else
        counts.none = counts.none + 1;
    end
end

function residual001 = hngw_smooth_fine_residual_field(residual001,S,smoothing)
if ~smoothing.enabled
    return;
end
T = size(residual001,1);
if isfield(smoothing,'strength')
    alpha = max(0,min(1,smoothing.strength));
else
    alpha = 1;
end
for t = 1:T
    vals = double(residual001(t,:));
    grid = nan(size(S.Lon2),'single');
    grid(S.rbi2) = single(vals);
    smoothedGrid = hngw_nan_gaussian(grid,smoothing.kernel);
    smoothed = smoothedGrid(S.rbi2);
    bad = ~isfinite(smoothed);
    smoothed(bad) = single(vals(bad));
    residual001(t,:) = single((1-alpha) * vals(:)' + alpha * double(smoothed(:)'));
end

function [cluster_residual,cluster_counts] = hngw_cluster_monthly_residual(residual025,labels,weights,k)
T = size(residual025,1);
cluster_residual = nan(T,k);
cluster_counts = zeros(k,1);
for c = 1:k
    idx = labels == c;
    cluster_counts(c) = nnz(idx);
    w = weights(idx);
    for t = 1:T
        vals = residual025(t,idx)';
        good = isfinite(vals) & isfinite(w);
        if any(good)
            cluster_residual(t,c) = sum(vals(good).*w(good)) / sum(w(good));
        end
    end
end

function residual001 = hngw_expand_cluster_residual_to_fine(cluster_residual,labels001,S,smoothing,weights001)
T = size(cluster_residual,1);
n001 = numel(S.rbi2);
residual001 = nan(T,n001,'single');
for t = 1:T
    vals = cluster_residual(t,labels001);
    if smoothing.enabled
        grid = nan(size(S.Lon2),'single');
        grid(S.rbi2) = single(vals);
        grid = hngw_nan_gaussian(grid,smoothing.kernel);
        smoothed = grid(S.rbi2);
        bad = ~isfinite(smoothed);
        smoothed(bad) = single(vals(bad));
        if isfield(smoothing,'strength')
            alpha = max(0,min(1,smoothing.strength));
        else
            alpha = 1;
        end
        smoothed = single((1-alpha) * vals(:) + alpha * double(smoothed(:)));
        if isfield(smoothing,'preserve_cluster_mean') && smoothing.preserve_cluster_mean
            smoothed = hngw_preserve_cluster_residual_mean(smoothed,vals(:),labels001,weights001);
        end
        residual001(t,:) = single(smoothed(:)');
    else
        residual001(t,:) = single(vals(:)');
    end
end

function smoothed = hngw_preserve_cluster_residual_mean(smoothed,original,labels,weights)
k = max(labels);
for c = 1:k
    idx = labels == c;
    w = weights(idx);
    good = isfinite(smoothed(idx)) & isfinite(original(idx)) & isfinite(w);
    if ~any(good)
        continue;
    end
    local = find(idx);
    local = local(good);
    w = w(good);
    target = sum(double(original(local)).*w) / sum(w);
    current = sum(double(smoothed(local)).*w) / sum(w);
    smoothed(local) = single(double(smoothed(local)) + target - current);
end

function out = hngw_nan_gaussian(grid,kernel)
mask = isfinite(grid);
vals = grid;
vals(~mask) = 0;
num = conv2(double(vals),kernel,'same');
den = conv2(double(mask),kernel,'same');
out = num ./ den;
out(den == 0) = NaN;
out(~mask) = NaN;
out = single(out);

function validation = hngw_scale_validation(obs,before,after)
validation = struct();
validation.RMSE_before = hngw_rmse(obs,before);
validation.RMSE_after = hngw_rmse(obs,after);
validation.Bias_before = hngw_bias(obs,before);
validation.Bias_after = hngw_bias(obs,after);
validation.NSE_before = hngw_nse(obs,before);
validation.NSE_after = hngw_nse(obs,after);

function v = hngw_rmse(obs,pred)
d = obs - pred;
v = sqrt(mean(d(isfinite(d)).^2));

function v = hngw_bias(obs,pred)
d = obs - pred;
v = mean(d(isfinite(d)));

function v = hngw_nse(obs,pred)
good = isfinite(obs) & isfinite(pred);
o = obs(good);
p = pred(good);
v = 1 - sum((o-p).^2) / max(sum((o-mean(o)).^2),eps);

function [time_series,trend_down] = hngw_downscaled_series_and_trend(CSR_Down,time,S)
lat = S.lat2;
[jj,ii] = size(S.Lon2);
grid_weight = zeros(jj,ii);
for j = 1:jj
    grid_weight(j,:) = cos(lat(j)*pi/180);
end
grid_weight = grid_weight .* S.mask2;
weights = grid_weight(:);
weights = weights(S.rbi2);
weights = weights(:)';
time_series = sum(CSR_Down .* weights,2,'omitnan') ./ sum(weights);

epochs = size(CSR_Down,1);
omega = 2*pi;
A = [ones(epochs,1), time(:), cos(omega*time(:)), sin(omega*time(:)), ...
    cos(2*omega*time(:)), sin(2*omega*time(:))];
NM = (A' * A) \ A';
Trend = nan(1,size(CSR_Down,2));
for i = 1:size(CSR_Down,2)
    y = CSR_Down(:,i);
    if all(isfinite(y))
        x = NM * y;
        Trend(i) = x(2);
    end
end
trend = nan(1,numel(S.Lon2));
trend(S.rbi2) = Trend;
trend_down = reshape(trend,size(S.Lon2));

function hngw_delete_matching(folder,pattern)
if ~exist(folder,'dir'), return; end
d = dir(fullfile(folder,pattern));
for i = 1:numel(d)
    hngw_delete_file(fullfile(folder,d(i).name));
end

function hngw_delete_file(fileName)
if exist(fileName,'file')
    try
        delete(fileName);
    catch
    end
end
