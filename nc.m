% 打开 CSR GRACE Mascon 文件
fname = 'D:\claude matlab\xinshiyan\shuju\CSR_GRACE_GRACE-FO_RL0603_Mascons_all-corrections.nc';

% 1. 打印全部信息
ncdisp(fname)

% 2. 读结构体
info = ncinfo(fname);

% 查看变量列表
fprintf('\n=== 变量列表 (%d个) ===\n', length(info.Variables));
for i = 1:length(info.Variables)
    v = info.Variables(i);
    fprintf('  %-20s [%s]\n', v.Name, mat2str(v.Size));
end

% 查看维度
fprintf('\n=== 维度 ===\n');
for i = 1:length(info.Dimensions)
    d = info.Dimensions(i);
    fprintf('  %s: %d\n', d.Name, d.Length);
end

% 3. 读取核心变量（先用 ncdisp 确认变量名再改这里）
lon   = ncread(fname, 'lon');
lat   = ncread(fname, 'lat');
time  = ncread(fname, 'time');
lwe   = ncread(fname, 'lwe_thickness');

fprintf('\n=== 数据概况 ===\n');
fprintf('lon:  %d 个, [%.2f, %.2f]\n', length(lon), min(lon), max(lon));
fprintf('lat:  %d 个, [%.2f, %.2f]\n', length(lat), min(lat), max(lat));
fprintf('time: %d 个\n', length(time));
fprintf('lwe_thickness: %s, range [%.2f, %.2f] cm\n', ...
    mat2str(size(lwe)), min(lwe(:)), max(lwe(:)));
