function [month_average,grid_season,grid_std,S]=Ca_grid_std(GRACE_Down,str_month)

% 提取数据中相同月份平均值,季节项，标准差

a=str2double(string(str_month));
[~,ii]=size(a);
[~,k] = size(GRACE_Down);
month_average=zeros(12,k);
grid_season = zeros(ii,k);
for month_num=1:12
    month_average(month_num,:)=mean(grid_month(GRACE_Down,str_month,month_num));
end

for i=1:ii
    grid_season(i,:)=month_average(a(1,i),:);
end

for month_num=1:12
    s=std(grid_month(GRACE_Down,str_month,month_num));
    S(month_num,:)=s;
end

for i=1:ii
    grid_std(i,:)=S(a(1,i),:);
end

end