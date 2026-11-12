function [series_month]=series_month(time_series,str_month,month_num)

%找到包含某一月份的全部数据
%例如 month_num=4时，即为寻找包含四月份的全部数据

a=str_month';
b=find(a==month_num);
[~,jj]=size(b);
series_month  = zeros(jj,1);
  
  for j=1:jj
    series_month(j,:)=time_series(b(1,j),:);
  end
 
end