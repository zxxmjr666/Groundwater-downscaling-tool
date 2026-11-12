function [DSI_ALL] =DSI_series(time_series,month)
%  
% 计算时间序列DSI
%   
[~,series_season,series_std,~]=Ca_std(time_series,month);
DSI_ALL=(time_series-series_season)./series_std;
 
end