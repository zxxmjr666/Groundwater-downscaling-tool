function [DSI_ALL] =DSI_grid(GRACE_Down,month)
%  
% 计算格网DSI
%   
[~,grid_season,grid_std,~]=Ca_grid_std(GRACE_Down,month);
DSI_ALL=(GRACE_Down-grid_season)./grid_std;
 
end