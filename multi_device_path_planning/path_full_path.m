function BestPath = path_full_path(start, aim, SearchAgents,indepent_runtimes,Max_iter,numofdevice,type,seg_path,save_flag,save_path)
    %% 无人机及种群参数
    global dsafe;
    dsafe=[0.1,40];
    start=start';
    aim=aim';
    keypoint=10;
    algorithmname={'AHA'};
    fobj={@AHA};
    % 获得环境信息
    Info=getMap(start,aim);
    for num=1:1
        recordcomp_results=cell(indepent_runtimes,numofdevice);
        recordfbest=zeros(indepent_runtimes,numofdevice);
        recordBestpath=cell(indepent_runtimes,1);
        recordcurve=cell(indepent_runtimes,1);
        recordruntime=zeros(indepent_runtimes,1);
        for run_time=1:indepent_runtimes
            disp(strcat('第',num2str(run_time),'次独立运行'))
            tic
            Populations=getPopulation(SearchAgents,Max_iter,numofdevice);
            Populations=getPopInit(Populations,start,aim,Info,keypoint,type);
            Populations=initialization(Populations,SearchAgents,Info,seg_path);
            
            [Populations,BestPath,Curve]=fobj{num}(SearchAgents,Populations,Max_iter,Info,seg_path);
            toc
            disp(toc);
            recordcurve{run_time}=Curve;
            recordruntime(run_time)=toc;
            recordBestpath{run_time}=BestPath;
            for i=1:numofdevice
                recordcomp_results{run_time,i}=Populations{i}.comp_results;
                recordfbest(run_time,i)=Populations{i}.fbest;
            end
        end
        %% 存储
        if save_flag==1
            %% 存储
            path=strcat(save_path,'\',algorithmname{num},'\');
            str0 = num2str(SearchAgents);
            str1 = algorithmname{num};
            str4 = num2str(Max_iter);
            str5 = '_iter';
            str6='.xls';
            
            % 确保文件夹存在
            if ~exist(path, 'dir')
                mkdir(path);
            end
            
            Excel_name = strcat(path,str0,'_', str1,'_', str4, str5,str6);
            
            xlswrite(Excel_name,{str1},'A1:A1');
            xlswrite(Excel_name,{'best'},'A2:A2');
            xlswrite(Excel_name,{'worst'},'A3:A3');
            xlswrite(Excel_name,{'mean'},'A4:A4');
            xlswrite(Excel_name,{'std'},'A5:A5');
            xlswrite(Excel_name,{'UAV speed'},'A6:A6');
            
            % flag=isinf(recordfbest);
            % [r,~]=find(flag==1);
            % recordfbest(r,:)=[];
            % recordBestpath(r)=[];
            J2 = 0;
            performedtime=0;
            devicetype=zeros(1,size(BestPath,2));
            for i=1:size(BestPath,2)
                bpath=BestPath{i};
                dx = diff(bpath(:,1));
                dy = diff(bpath(:,2));
                dz = diff(bpath(:,3));
                seg=sum(sqrt(dx.^2 + dy.^2 + dz.^2));
                devicetype(i)=Populations{i}.type;
                J2=J2+seg;
                if devicetype(i)==1
                    speed=60;
                else
                    speed=30;
                end
                performedtime=performedtime+seg/speed;
            end
            disp(strcat("共有路径：",num2str(size(BestPath,2))));
            disp("总距离为：");
            disp(J2);
            plotAllFigure(Info,BestPath,devicetype)
            mat_file_name = strcat(path,str0,'_', str1,'_', str4,str5,'.mat');
            result={performedtime,J2, recordfbest,BestPath,recordcurve,recordruntime};
            save(mat_file_name,"result");
            save_path=strcat(path,'multi_device_paths_3d.fig');
            saveas(gcf, save_path);
            
            
            % [~,index]=max(totalfbest);
            % max_value=recordfbest(index,:);
            % mean_value=mean(recordfbest,1);
            % std_value=std(recordfbest,0,1);
            % disp(recordBestpath)
            % [~,index]=min(totalfbest);
            % min_value=recordfbest(index,:);
            % BestPath=recordBestpath{index};
            xlswrite(Excel_name,{strcat('总距离',num2str(i))},strcat(65+i,'1:',65+i,'1'));
            xlswrite(Excel_name,{J2},strcat(65+i,'2:',65+i,'2'));

        end
    end

end