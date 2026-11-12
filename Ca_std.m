function [month_average,series_season,series_std,S]=Ca_std(time_series,str_month)

% 提取数据中相同月份平均值,季节项，标准差

a=str2double(string(str_month));
[~,ii]=size(a);
month_average=zeros(12,1);
series_season = zeros(ii,1);
for month_num=1:12
    month_average(month_num,:)=mean(series_month(time_series,str_month,month_num));
end

for i=1:ii
    series_season(i,1)=month_average(a(1,i),1);
end

for month_num=1:12
    s=std(series_month(time_series,str_month,month_num));
    S(month_num,1)=s;
end

for i=1:ii
    series_std(i,1)=S(a(1,i),1);
end

end