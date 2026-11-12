nc1 = 'D:/claude matlab/xinshiyan/shuju/CSR_GRACE_GRACE-FO_RL0603_Mascons_all-corrections.nc';
nc2 = 'D:/claude matlab/xinshiyan/shuju/CSR_GRACE_GRACE-FO_RL06_Mascons_all-corrections_v02.nc';

diary('D:/claude matlab/xinshiyan/nc_info.txt');

fprintf('========== File 1: RL0603 ==========\n');
ncdisp(nc1);

fprintf('\n\n========== File 2: RL06 v02 ==========\n');
ncdisp(nc2);

diary off;
exit;
