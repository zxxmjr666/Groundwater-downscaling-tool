function [month_grid]=grid_month(GRACE_Down,str_month,month_num)

%找到包含某一月份的全部数据
%例如 month_num=4时，即为寻找包含四月份的全部网格

a=str_month';
b=find(a==month_num);
[~,jj]=size(b);
[~,k] = size(GRACE_Down);
month_grid  = zeros(jj,k);
  
  for j=1:jj
    month_grid(j,:)=GRACE_Down(b(1,j),:);
  end
 
end