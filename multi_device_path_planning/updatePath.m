function [path] = updatePath(X,dimension,startPos,goalPos,a,b,d,type)
%UPDATEPATH 此处显示有关此函数的摘要
%此处显示详细说明
    if type==1
        dimension=dimension/2;
        pos_y=X(1:dimension);
        pos_z=X(1+dimension:2*dimension);
         %% ------坐标系反变换---------------------------
        x_seq=[startPos(1)];
        y_seq=[startPos(2)];
        z_seq=[startPos(3)];
        for i=1:length(pos_y)
           x_seq=[x_seq,a*i*d-b*pos_y(i)+startPos(1)];
           y_seq=[y_seq,b*i*d+a*pos_y(i)+startPos(2)];
           z_seq=[z_seq,pos_z(i)];
        end
        x_seq=[x_seq,goalPos(1)];
        y_seq=[y_seq,goalPos(2)];
        z_seq=[z_seq,goalPos(3)];
        % 利用三次样条拟合散点
        k = length(x_seq);
        i_seq = linspace(0,1,k);
        I_seq = linspace(0,1,50);
        
        % 检查并处理NaN值

        X_seq = interp1(i_seq,x_seq,I_seq,'linear','extrap');
        Y_seq = interp1(i_seq,y_seq,I_seq,'linear','extrap');
        Z_seq = interp1(i_seq,z_seq,I_seq,'linear','extrap');

        path = [X_seq', Y_seq', Z_seq'];
    end
    if type==2
        pos_y=X(1:dimension);
         %% ------坐标系反变换---------------------------
        x_seq=[startPos(1)];
        y_seq=[startPos(2)];
        for i=1:length(pos_y)
           x_seq=[x_seq,a*i*d-b*pos_y(i)+startPos(1)];
           y_seq=[y_seq,b*i*d+a*pos_y(i)+startPos(2)];
        end
        x_seq=[x_seq,goalPos(1)];
        y_seq=[y_seq,goalPos(2)];
        % 利用三次样条拟合散点
        k = length(x_seq);
        i_seq = linspace(0,1,k);
        I_seq = linspace(0,1,50);
        
        % 检查并处理NaN值
        if any(isnan(x_seq)) || any(isnan(y_seq))
            % 如果有NaN，使用线性插值代替样条
            X_seq = interp1(i_seq,x_seq,I_seq,'linear','extrap');
            Y_seq = interp1(i_seq,y_seq,I_seq,'linear','extrap');
        else
            % 没有NaN时使用样条插值
            X_seq = spline(i_seq,x_seq,I_seq);
            Y_seq = spline(i_seq,y_seq,I_seq);
        end
        path = [X_seq', Y_seq', zeros(1,size(X_seq,2))'];
    end
end

