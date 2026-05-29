independent_run_times=10;
algorithmname={'AHA','GWO','WOA','ISSA','COA','MDCOA'};
pathcolor={'cyan','m','blue','black','green','r'};
Max_iter=100;
SearchAgents=100;
dimension=20;
savepath='./结果图/路径图.fig';


Info=getMap('map30.mat');
[x,y,z,u,v,w]=generateVectorField(0,5,100,0,5,100,0,5,60,Info);

UAVpath=cell(6,3);
for num=1:6
    path=strcat('.\',algorithmname{num},'\');
    str0 = num2str(SearchAgents);
    str1 = algorithmname{num};
    str2 = num2str(dimension); %自动获取维数
    str3 = 'dim_';
    str4 = num2str(Max_iter);
    str5 = '_iter';
    mat_file_name = strcat(path,str0,'_', str1,'_', str2, str3,str4,str5);
    data=load(mat_file_name);
    a=sum(data.result{1,2},2);
    [~,index]=min(a);
    UAVpath(num,:)=data.result{1,3}{index};
    h(num)=subplot(2,3,num);
    if checkDistance(UAVpath{num,1}', UAVpath{num,2}', 1, 40) 
        plotAllFigure1(Info,Info.X,Info.Y,Info.Z,UAVpath(num,:),x,y,z,u,v,w);
    end
    lgd(num) = get(h(num), 'Legend');
    camorbit(350,5);
    title(algorithmname{num});
end
for i=1:6
    set(lgd(i),'Visible','off');
end
set(lgd(1),'Visible','on');
set(lgd(1), 'Position', [0.2095    0.0024    0.6053    0.0359], 'Orientation', 'horizontal');
set(gcf,'position',[250 300 800 400]);
set(gcf,'position',[537.5714  282.7143  889.7143  524.5714]);
set(h(1),'Position',[0.0347    0.5665    0.27    0.3908]);
set(h(2),'Position',[0.3703    0.5533    0.27    0.3908]);
set(h(3),'Position',[0.6980    0.5628    0.27    0.3908]);
set(h(4),'Position',[0.0347    0.09    0.27    0.3908]);
set(h(5),'Position',[0.3703    0.09    0.27    0.3908]);
set(h(6),'Position',[0.6980    0.09    0.27    0.3908]);     
saveas(gcf,savepath);