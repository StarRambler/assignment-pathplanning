function [J1,J2,J3,J4,J5,vortex_threat] = com_record(path,Populations,indexforUAV,Info)    
    XX=Info.X;
    YY=Info.Y;
    ZZ=Info.Z;
    Threat_radius=Info.Threat_radius;
    Threat_kind=Info.Threat_kind;
    Threat_center=Info.Threat_center;
    
    sizeofPop=size(Populations,1);
    pathbest=cell(sizeofPop-1,1);
    for i=1:sizeofPop
        if(i~=indexforUAV)
            pathbest{i} = Populations{i}.BestPath;
        end
    end
    
    % 判断生成的曲线是否与与障碍物相交
    J1 = 0;
    for i = 2:size(path,1)
        x = path(i,1);
        y = path(i,2);
        z_interp = interp2(XX,YY,ZZ,x,y);
        if path(i,3) < z_interp+2
            J1=inf;
            break
        end
    end


    %% 计算三次样条得到的离散点的路径长度（适应度）
    J2 = 0;
    dx = diff(path(:,1));
    dy = diff(path(:,2));
    dz = diff(path(:,3));
    J2=J2+sum(sqrt(dx.^2 + dy.^2 + dz.^2));

    xx =[];
    yy =[];
    zz =[];
    for iiii=1:(size(path,1)-1)
    %每一段向量分成10个点
        x_r = linspace(path(iiii,1)',path(iiii+1,1),10);
        y_r= linspace(path(iiii,2)',path(iiii+1,2),10);
        z_r =linspace(path(iiii,3)',path(iiii+1,3),10);
        xx = [xx,x_r];
        yy = [yy,y_r];
        zz =[zz ,z_r];
    end
    %J3 - threat cost
    J3=0;
    for jj=1:size(Threat_kind,2)
      distace=sqrt((xx-Threat_center(1,jj)).^2+(yy-Threat_center(2,jj)).^2+(zz).^2);
      v = max(1-distace/Threat_radius(1,jj),0);
      J3=J3+Threat_kind(1,jj)*mean(v);%这里是平均值
    end
   
    
   % J4 - Smooth cost
    J4 = 0;
    turning_max = 45;
    climb_max = 45;
    for i = 1:(size(path,1)-2)
        
        % Projection of line segments to Oxy ~ (x,y,0)
        for j = i:-1:1
             segment1_proj = [path(j+1,1); path(j+1,2); 0] - [path(j,1); path(j,2); 0];
             if nnz(segment1_proj) ~= 0
                 break;
             end
        end

        for j = i:(size(path,1)-2)
            segment2_proj = [path(j+2,1); path(j+2,2); 0] - [path(j+1,1); path(j+1,2); 0];
             if nnz(segment2_proj) ~= 0
                 break;
             end
        end
        climb_angle1 = atan2d(path(i+1,3) - path(i,3),norm(segment1_proj));
        climb_angle2 = atan2d(path(i+2,3) - path(i+1,3),norm(segment2_proj));
        turning_angle = atan2d(norm(cross(segment1_proj,segment2_proj)),dot(segment1_proj,segment2_proj));
       
        if abs(turning_angle) > turning_max
            J4 = J4 + abs(turning_angle);
        end
        if abs(climb_angle2 - climb_angle1) > climb_max
            J4 = J4 + abs(climb_angle2 - climb_angle1);
        end
       
    end

    dsafe=[3,40];
    J5=0;
    for UAV=1:sizeofPop
        if(UAV~=indexforUAV)
            dis=sqrt(sum((path-pathbest{UAV})'.^2));
            for j=2:size(dis,2)
                if(dis(j)<dsafe(1))
                    J5=J5+10000/dis(j);
                end
                if dis(j)>dsafe(2)
                    J5=J5+dis(j);
                end
            end
        end
    end
    
end
function result=normalization(x)
    result=1/(1+exp(1)^(-x/500));
end