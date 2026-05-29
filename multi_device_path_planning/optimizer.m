function optimizer(SearchAgents,dimension,indepent_run_times,algorithmname,speedbound)
%     algorithmname='mCOA';
    fbest=zeros(1,2);
    recordfbest=zeros(indepent_run_times,numofUAV);
    recordBestpath=cell(indepent_run_times,numofUAV);
    recordBestPos=zeros(indepent_run_times,numofUAV);
    record_UAV_speed=zeros(indepent_run_times,numofUAV);
%     recordcurve=zeros(indepent_run_times,numofUAV);
    recordruntime=zeros(indepent_run_times);
    for run_time=1:indepent_run_times
        %% 算法变量预设
        PopPos4U1=zeros(SearchAgents,2*dimension);           % Ecosystem Matrix
        cost4U1=zeros(SearchAgents,1);
        Convergence_curve=zeros(2,Max_iter);
        Component_results4U1=zeros(Max_iter,5);
%         Path4U1=cell(SearchAgents,1);
    
        PopPos4U2=zeros(SearchAgents,2*dimension);           % Ecosystem Matrix
        cost4U2=zeros(SearchAgents,1);
        Component_results4U2=zeros(Max_iter,5);
%         Path4U2=cell(SearchAgents,1);
        %% 环境参数
        start=Info.start;
        aim=Info.aim;
        X=Info.map.X;
        Y=Info.map.Y;
        Z=Info.map.Z;
    
        Threat_center=Info.map.Threat_center;
        Threat_radius=Info.map.Threat_radius;
        Threat_kind=Info.map.Threat_kind;
    
        [x,y,z,u,v,w,vortices]=generateVectorField(0,10,100,0,10,100,0,5,40);
        [lowerbound1,upperbound1,a1,b1,d1]=getInit(start(:,1),aim(:,1),X);
        [lowerbound2,upperbound2,a2,b2,d2]=getInit(start(:,2),aim(:,2),X);
        
    
        %% Inilization
        for i=1:2*dimension
            PopPos4U1(:,i) = lowerbound1(i)+rand(SearchAgents,1).*(upperbound1(i) - lowerbound1(i));% Initial population
        end
    
        %% 评估函数
        for i=1:SearchAgents
            [flag,cost4U1(i),Path1{i}]=calFitness(start(:,1), aim(:,1),X,Y,Z,Threat_radius,Threat_kind,Threat_center,vortices,PopPos4U1(i,1:dimension),PopPos4U1(i,1+dimension:2*dimension),PopPos4U2(i,1:dimension),PopPos4U2(i,1+dimension:2*dimension),a1,b1,d1);
            if flag == 1
              cost4U1(i)= 1000000*cost4U1(i);
            end
        end
        [~,index]=sort(cost4U1);
        Xbest(1,:)=PopPos4U1(index,:);
    
        for i=1:2*dimension
            PopPos4U2(:,i) = lowerbound2(i)+rand(SearchAgents,1).*(upperbound2(i) - lowerbound(i));% Initial population
        end
    
        %% 评估函数
        for i=1:SearchAgents
            [flag,cost4U2(i),Path2{i}]=calFitness(start(:,2), aim(:,2),X,Y,Z,Threat_radius,Threat_kind,Threat_center,vortices,PopPos4U2(i,1:dimension),PopPos4U2(i,1+dimension:2*dimension),PopPos4U1(i,1:dimension),PopPos4U1(i,1+dimension:2*dimension),a2,b2,d2);
            if flag == 1
              cost4U2(i)= 1000000*cost4U2(i);
            end
        end
        [~,index]=sort(cost4U2);
        Xbest(2,:)=PopPos4U2(index,:);
        for t=1:Max_iter
            [cost4U1,PopPos4U1,Path1]=mCOA(SearchAgents,dimension,Max_iter,PopPos4U1,cost,Path1,Xbest(2,:),start(:,1),aim(:,1),X,Y,Z,Threat_radius,Threat_kind,Threat_center,vortices,a1,b1,d1);
            [cost4U2,PopPos4U2,Path2]=mCOA(SearchAgents,dimension,Max_iter,PopPos4U2,cost,Path2,Xbest(1,:),start(:,2),aim(:,2),X,Y,Z,Threat_radius,Threat_kind,Threat_center,vortices,a2,b2,d2);
            fbest(1)=cost4U1(1);
            fbest(2)=cost4U2(1);
            Xbest(1,:)=PopPos4U1(1,:); 
            Xbest(2,:)=PopPos4U2(2,:);
            BestPath{1}=Path1{1};
            BestPath{2}=Path2{1};
            pause(0.01);
            plotAllFigure(start,aim,X,Y,Z,BestPath{1},BestPath{2},x,y,z,u,v,w);
            %% 迭代结果存储
            Convergence_curve(1,t)=fbest(1);
            Convergence_curve(2,t)=fbest(2);
            [J2,J3,J4,J5,J6,dis]=record(start(:,1), aim(:,1),X,Y,Z,Threat_radius,Threat_kind,Threat_center,vortices,Xbest(1,1:dimension),Xbest(1,1+dimension:2*dimension),Xbest(2,1:dimension),Xbest(2,1+dimension:2*dimension),a1,b1,d1);
            singinerecord=[J2,J3,J4,J5,J6,dis];
            Component_results4U1(t,:)=singinerecord;
            [J2,J3,J4,J5,J6,dis]=record(start(:,2), aim(:,2),X,Y,Z,Threat_radius,Threat_kind,Threat_center,vortices,Xbest(2,1:dimension),Xbest(2,1+dimension:2*dimension),Xbest(1,1:dimension),Xbest(1,1+dimension:2*dimension),a2,b2,d2);
            singinerecord=[J2,J3,J4,J5,J6,dis];
            Component_results4U2(t,:)=singinerecord;
            display(strcat(num2str(t),'\',num2str(Max_iter),' min1:',num2str(fbest(1)),'min2:',num2str(fbest(2))));
        end
        [flag,index,UAV_speed,BestPath]=timejudge(Path1,Path2,cost4U1,cost4U2,speedbound);
        if flag==0
            fbest(:)=inf;
            recordfbest(run_time,:)=fbest;
            disp('time not compliance');
            continue;
        else
            disp(strcat('time compliance, the cost values are as follow:'));
            disp(strcat('UAV1 cost:',num2str(fbest(index(1))),'UAV2 cost',num2str(fbest(index(2)))));
        end
        %% 独立运行结果存储
        for i=1:numofUAV
            recordfbest(run_time,i)=fbest(index(i));
            recordBestpath{run_time,i}=BestPath{i};
            recordBestPos(run_time,i,:)=Xbest(index(i),:);
            record_UAV_speed(run_time,i)=UAV_speed(i);
%             recordcurve(run_time,i,:)=Convergence_curve(i,:);
            recordruntime(run_time)=toc;
        end
        plotAllFigure(start,aim,X,Y,Z,BestPath{1},BestPath{2},x,y,z,u,v,w);
    end
    result={recordfbest,recordBestpath,recordBestPos,record_UAV_speed,recordruntime};
    path=strcat('.\',algorithmname,'\');
    str0 = num2str(SearchAgents);
    str1 = algorithmname;
    str2 = num2str(dimension); %自动获取维数
    str3 = 'dim_';
    str4 = num2str(Max_iter);
    str5 = '_iter';
    str6='.xls';

    Excel_name = strcat(path,str0,'_', str1,'_', str2, str3, str4, str5,str6);
    mat_file_name = strcat(path,str0,'_', str1,'_', str2, str3,str4,str5);
    save(mat_file_name,"result");

    xlswrite(Excel_name,{str1},'A1:A1');
    xlswrite(Excel_name,{'best'},'A2:A2');
    xlswrite(Excel_name,{'worst'},'A3:A3');
    xlswrite(Excel_name,{'mean'},'A4:A4');
    xlswrite(Excel_name,{'std'},'A5:A5');
    xlswrite(Excel_name,{'UAV speed'},'A6:A6');

    flag=isinf(recordfbest);
    [r,~]=find(flag==1);
    recordfbest(r,:)=[];
    recordBestpath(r,:)=[];
    record_UAV_speed(r,:)=[];
    [min_value,index]=min(recordfbest);
    max_value=max(recordfbest);
    mean_value=mean(recordfbest);
    std_value=std(recordfbest);
    BestPath=cell(1,size(index,2));
    speed=record_UAV_speed(index,i);
    for i=1:size(index,2)
        BestPath{i}=recordBestpath{index(i),i};
    end
    for i=1:numofUAV
        xlswrite(Excel_name,{strcat('UAV',num2str(i))},strcat(65+i,'1:',65+i,'1'));
        xlswrite(Excel_name,{min_value(i)},strcat(65+i,'2:',65+i,'2'));
        xlswrite(Excel_name,max_value(i),strcat(65+i,'3:',65+i,'3'));
        xlswrite(Excel_name,mean_value(i),strcat(65+i,'4:',65+i,'4'));
        xlswrite(Excel_name,std_value(i),strcat(65+i,'5:',65+i,'5'));
        xlswrite(Excel_name,speed(i),strcat(65+i,'6:',65+i,'6'));
    end
    [x,y,z,u,v,w]=generateVectorField(0,10,100,0,10,100,0,5,40);
    plotAllFigure(start,aim,Info.map.X,Info.map.Y,Info.map.Z,BestPath,x,y,z,u,v,w);
    saveas(gcf,strcat(path,str1,'result figure.fig'));

end
        