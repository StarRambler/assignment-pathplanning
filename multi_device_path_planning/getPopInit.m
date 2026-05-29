function [Populations]=getPopInit(Populations,start,aim,Info,D,type)
    numofdevice=size(Populations,1);
    distance=zeros(1,numofdevice);
    
    for num=1:numofdevice
        distance(num)=sqrt(sum((start(:,num)'-aim(:,num)').^2));   %起点到终点的距离
        Populations{num}.a=(aim(1,num)-start(1,num))./distance(num);      
        Populations{num}.b=(aim(2,num)-start(2,num))./distance(num);
        aim_transform(1)=Populations{num}.a*(aim(1,num)-start(1,num))+Populations{num}.b*(aim(2,num)-start(2,num));
        aim_transform(2)=-Populations{num}.b*(aim(1,num)-start(1,num))+Populations{num}.a*(aim(2,num)-start(2,num));
        aim_transform(3)=aim(3,num); 
        Populations{num}.d=aim_transform(1)/(D+1);

        % 对障碍物坐标进行同样的坐标变换，获取Terrain_transform_Y
        threat_centers = Info.Threat_center;
            Terrain_transform_Y = [];
            
            % 对每个障碍物中心进行坐标变换，使用与aim_transform相同的参数
            for number = 1:numofdevice
                % 使用当前设备的变换参数
                a = Populations{number}.a;
                b = Populations{number}.b;
                
                for i = 1:size(threat_centers, 2)
                    dx = threat_centers(1, i) - start(number);  % 第1行是x坐标
                    dy = threat_centers(2, i) - start(2,number);  % 第2行是y坐标
                    
                    % 应用与aim_transform相同的坐标变换
                    y_transformed = -b * dx + a * dy;
                    Terrain_transform_Y = [Terrain_transform_Y, y_transformed];
                end
            end

        lb = min(min(Terrain_transform_Y))-1;%自变量搜索域(Path)的最小值：xmin
        ub = max(max(Terrain_transform_Y))+1;%自变量搜索域(Path)的最大值：xmax
        disp('lb:');
        disp(lb);
        disp('ub:');
        disp(ub);
        lb_z=0;
        ub_z=3;
        dimension=D;
        %disp(['当前处理第' num2str(num) '个设备'])
        Populations{num}.type = type(num);
        %disp(['设备' num2str(num) '的设备类型为' num2str(Populations{num}.type)])
        if Populations{num}.type==1
            Populations{num}.lowerbound = [ones(1,dimension)*lb,ones(1,dimension)*lb_z]; % upper bound
            Populations{num}.upperbound = [ones(1,dimension)*ub,ones(1,dimension)*ub_z]; % lower bound
            Populations{num}.dimension = 2*dimension;
        end
        if Populations{num}.type==2
            Populations{num}.lowerbound = ones(1,dimension)*lb; % upper bound
            Populations{num}.upperbound = ones(1,dimension)*ub;% lower bound
            Populations{num}.dimension = dimension;
        end
        
    end
end