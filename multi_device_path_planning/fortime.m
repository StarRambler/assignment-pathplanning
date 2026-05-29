independent_run_times=10;
algorithmname={'AHA','GWO','WOA','ISSA','COA','MDCOA'};
pathcolor={'cyan','m','blue','black','green','r'};
SearchAgents=100;
dimension=20;
Max_iter=100;



UAVpath=cell(6,3);
time=zeros(1,6);
distances=zeros(3,6);
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
    speed=data.result{1,6}(index,1);
    time(num)=getDistance(UAVpath{num,1}')/speed;
    for i=1:3
        distances(i,num)=getDistance(UAVpath{num,i}');
    end
end
resultfotxls=[distances;time];

writematrix(resultfotxls,'./结果图/time and distances.xlsx');