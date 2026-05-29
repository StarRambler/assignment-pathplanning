independent_run_times=10;
algorithmname={'AHA','GWO','WOA','ISSA','COA','MDCOA'};
pathcolor={'cyan','m','blue','black','green','r'};
SearchAgents=100;
dimension=10;
Max_iter=100;




for num=1:6
    path=strcat('.\',algorithmname{num},'\');
    str0 = num2str(SearchAgents);
    str1 = algorithmname{num};
    str2 = num2str(2*dimension); %自动获取维数
    str3 = 'dim_';
    str4 = num2str(Max_iter);
    str5 = '_iter';
    mat_file_name = strcat(path,str0,'_', str1,'_', str2, str3,str4,str5);
    data=load(mat_file_name);
    [~,index]=min(sum(data.result{1,2},2));
    UAVpath=data.result{1,3}{index};
    mk(num)=subplot(2,3,num);
        
    if checkDistance(UAVpath{1,1}', UAVpath{1,2}', 2, 45)
        distances = sqrt(sum((UAVpath{1,2}' - UAVpath{1,1}').^2));
        plot(distances);
        
    end
    hold on
    if checkDistance(UAVpath{1,3}', UAVpath{1,1}', 2, 45)
        distances = sqrt(sum((UAVpath{1,3}' - UAVpath{1,1}').^2));
        plot(distances);
    end
    hold on
    if  checkDistance(UAVpath{1,3}', UAVpath{1,2}', 2, 45)
        distances = sqrt(sum((UAVpath{1,3}' - UAVpath{1,2}').^2));
        plot(distances);
    end
    hold on
    yline(2);
    hold on
    yline(45);
    xlim([0,50]);
    lg(num)=legend('UAV-1 & UAV-2','UAV-1 & UAV-3','UAV-2 & UAV-3','Dsafe');
    title(algorithmname{num});
end
set(gcf,'position',[537.5714  282.7143  889.7143  524.5714]);
set(mk(1),'Position',[0.0347    0.56    0.28    0.4022]);
set(mk(2),'Position',[0.3703    0.56    0.28    0.4022]);
set(mk(3),'Position',[0.6950    0.56    0.28    0.4022]);
set(mk(4),'Position',[0.0347    0.09    0.28    0.4022]);
set(mk(5),'Position',[0.3703    0.09    0.28    0.4022]);
set(mk(6),'Position',[0.6950    0.09    0.28    0.4022]);
for i=1:6
    set(lg(i),'Visible','off');
end
set(lg(1),'Visible','on');
set(lg(1), 'Position', [0.2095    0.0024    0.6053    0.0359], 'Orientation', 'horizontal');
% set(lg(1),'Position',[0.1618 0.8 0.1485 0.1000]);
% set(lg(2),'Position',[0.4971 0.8 0.1485 0.1000])
% set(lg(3),'Position',[0.8259 0.8 0.1485 0.1000])
% set(lg(4),'Position',[0.1618 0.33 0.1485 0.1000])
% set(lg(5),'Position',[0.4971 0.33 0.1485 0.1000])
% set(lg(6),'Position',[0.8259 0.33 0.1485 0.1000])