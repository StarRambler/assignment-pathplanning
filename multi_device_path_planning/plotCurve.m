clear
clc
close all
independent_run_times=10;
algorithmname={'AHA','GWO','WOA','ISSA','COA','MDCOA'};
pathcolor={'cyan','m','blue','black','green','r'};
SearchAgents=100;
dimension=20;
Max_iter=100;



% Info=getMap('map30.mat');
% [x,y,z,u,v,w]=generateVectorField(0,10,100,0,10,100,0,5,70,Info);

UAVpath=cell(6,3);
figure;
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
    curvet=[];
    for i=1:10
        if ~isempty(data.result{1,5}{i,1})
            curvet=[curvet;data.result{1,5}{i,1}{1}];
        end
    end
    Curve(num,:)=mean(curvet);
end
h1=subplot(1,3,1);
for i=1:6
    plot(Curve(i,:),'color',pathcolor{i});
    hold on;
end
set(gca,'YScale','log');
xlabel('iteration');
ylabel('cost value(log)');
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
    curvet=[];
    for i=1:10
        if ~isempty(data.result{1,5}{i,1})
            curvet=[curvet;data.result{1,5}{i,1}{2}];
        end
    end
    Curve(num,:)=mean(curvet);
end
h2=subplot(1,3,2);
h=[];
for i=1:6
    hi=plot(Curve(i,:),'color',pathcolor{i});
    h=[h,hi];
    hold on;
end
set(gca,'YScale','log');
xlabel('iteration');
ylabel('cost value(log)');
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
    curvet=[];
    for i=1:10
        if ~isempty(data.result{1,5}{i,1})
            curvet=[curvet;data.result{1,5}{i,1}{3}];
        end
    end
    Curve(num,:)=mean(curvet);
end
h3=subplot(1,3,3);
for i=1:6
    plot(Curve(i,:),'color',pathcolor{i});
    hold on;
end
set(gca,'YScale','log');
xlabel('iteration');
ylabel('cost value(log)');
lgd=legend(h,algorithmname,'Orientation','horizontal');
set(h1,'Position',[0.05    0.2    0.26    0.7]);
set(h2,'Position',[0.38    0.2    0.26    0.7]);
set(h3,'Position',[0.7    0.2    0.26    0.7]);
set(lgd, 'Position', [0.2095    0.02    0.6053    0.0359]);
set(gcf,'position',[250 300 900 320]);
annotation('textbox',[.14 .7 .3 .3],'String','UAV-1','EdgeColor','none','FontSize',13);
annotation('textbox',[.47 .7 .3 .3],'String','UAV-2','EdgeColor','none','FontSize',13);
annotation('textbox',[.79 .7 .3 .3],'String','UAV-3','EdgeColor','none','FontSize',13);