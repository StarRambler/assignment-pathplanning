classdef Pop
    %POPULATION 此处显示有关此类的摘要
    %   此处显示详细说明
    
    properties
        Populations
        sizeofUAV
        SearchAgents
        dimension
        startPos
        goalPos
        a
        b
        d
    end
    
    methods
        function obj = Pop(SearchAgents,dimension,sizeofUAV,Max_iter,start,aim,a,b,d)
            %POPULATION 构造此类的实例
            %   此处显示详细说明
            obj.Populations=cell(sizeofUAV,1);
            for i=1:sizeofUAV
                obj.Populations{i}.Pos=zeros(SearchAgents,dimension);
                obj.Populations{i}.fitness=zeros(SearchAgents,dimension);
                obj.Populations{i}.Xbest=zeros(dimension);
                obj.Populations{i}.fbest=inf;
                obj.Populations{i}.Path=cell(SearchAgents,1);
                obj.Populations{i}.comp_results=zeros(Max_iter,5);
                obj.sizeofUAV=sizeofUAV;
                obj.startPos=start;
                obj.goalPos=aim;
                obj.a=a;
                obj.b=b;
                obj.d=d;
            end
        end
        
        function obj = getBest(obj)
            %METHOD1 此处显示有关此方法的摘要
            %   此处显示详细说明
            for i=1:obj.sizeofUAV
                [obj.Populations{i}.fbest,index]=min(obj.Populations{i}.fitness);
                obj.Populations{i}.Xbest=obj.Populations{i}.Pos(index,:);
                obj.Populations{i}.BestPath=obj.Populations{i}.Path{index};
            end
        end


        function obj = updatePos(obj,newPopulation)
            for num=1:obj.sizeofUAV
                for i=1:obj.SearchAgents
                    if newPopulation{num}.fitness(i)<obj.Populations{num}.fitness(i)
                        obj.Populations{num}.fitness(i)=newPopulation{num}.fitness(i);
                        obj.Populations{num}.Pos(i,:)=newPopulation{num}.Pos(i,:);
                    end
                end
            end
        end

        function obj = updatePath(obj,num,agent)
            %METHOD1 此处显示有关此方法的摘要
            %   此处显示详细说明
            dim=size(obj.dimension)/2;
            pos_y=X(1:dim);
            pos_z=X(1+dim:2*dim);

             %% ------坐标系反变换---------------------------
            x_seq=[obj.startPos(1,num)];
            y_seq=[obj.startPos(2,num)];
            z_seq=[obj.startPos(3,num)];
            for i=1:length(pos_y)
               x_seq=[x_seq,obj.a*i*obj.d-obj.b*pos_y(i)+obj.startPos(1)];
               y_seq=[y_seq,obj.b*i*obj.d+obj.a*pos_y(i)+obj.tartPos(2)];
               z_seq=[z_seq,pos_z(i)];
            end
            x_seq=[x_seq,obj.goalPos(1,num)];
            y_seq=[y_seq,obj.goalPos(2,num)];
            z_seq=[z_seq,obj.goalPos(3,num)];
            % 利用三次样条拟合散点
            k = length(x_seq);
            i_seq = linspace(0,1,k);
            I_seq = linspace(0,1,50);
            X_seq = spline(i_seq,x_seq,I_seq);
            Y_seq = spline(i_seq,y_seq,I_seq);
            Z_seq = spline(i_seq,z_seq,I_seq);
            obj.Populations{num}.Path{agent}= [X_seq', Y_seq', Z_seq'];
        end
    end
end

