clc;
close all;
clear;

%% 无人机及种群参数
numofUAV=4;
low_speed=40;
up_speed=60;
global dsafe;
dsafe=[3,40];    
SearchAgents=10;
indepent_runtimes=1;
Max_iter=10;
keypoint=10;
numofalgorithm=5;
algorithmname={'COA','AHA','GWO','WOA','ISSA','MDCOA'};
fobj={@COA,@AHA,@GWO,@WOA,@ISSA,@MDCOA};


pathpoint=50;
dimension=2*keypoint;


% 获得环境信息
Info=getMap('map30.mat');
start = Info.start;
aim = Info.aim;
recordcurve=cell(1,indepent_runtimes);
start(3,2)=0;
aim(3,2)=0;

for num=2:2
    recordcomp_results=cell(indepent_runtimes,numofUAV);
    recordfbest=zeros(indepent_runtimes,numofUAV);
    recordBestpath=cell(indepent_runtimes,1);
    
    % recordBestPos=zeros(indepent_runtimes,numofUAV,dimension);
    record_UAV_speed=zeros(indepent_runtimes,numofUAV);
    recordcurve=cell(indepent_runtimes,1);
    recordruntime=zeros(indepent_runtimes,1);

    for run_time=1:indepent_runtimes
        disp(strcat('第',num2str(run_time),'次独立运行'))
        tic
        Populations=getPopulation(SearchAgents,Max_iter,numofUAV);
        Populations=getPopInit(Populations,start,aim,Info,keypoint);
        Populations=initialization(Populations,SearchAgents,Info);
        
        [Populations,BestPath,Curve]=fobj{num}(SearchAgents,Populations,Max_iter,Info);
        
        toc
        disp(toc);
        recordcurve{run_time}=Curve;
        recordruntime(run_time)=toc;
        recordBestpath{run_time}=BestPath;
        for i=1:numofUAV
            recordcomp_results{run_time,i}=Populations{i}.comp_results;
            recordfbest(run_time,i)=Populations{i}.fbest;
        end
    end
end