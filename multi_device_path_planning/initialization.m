function [Population] = initialization(Population,SearchAgents,Info,seg_path)
    %INITIALIZATION 此处显示有关此函数的摘要
    %   此处显示详细说明
    %disp('initialization population:')
    sizeofUAV=size(Population,1);
    for i=1:sizeofUAV
        disp(['路径段' num2str(i) '的设备类型为' num2str(Population{i}.type)])
        Population{i}.Xbest = Population{i}.lowerbound+rand(1,Population{i}.dimension).*(Population{i}.upperbound - Population{i}.lowerbound);% Initial population
        Population{i}.BestPath = updatePath(Population{i}.Xbest,Population{i}.dimension,Info.start(:,i),Info.aim(:,i),Population{i}.a,Population{i}.b,Population{i}.d,Population{i}.type);
        % Population{i}.fbest=calFitness(Population{i}.BestPath,Population,i,Info,seg_path);
    end

    for i=1:sizeofUAV
        for j=1:SearchAgents
            Population{i}.Pos(j,:) = Population{i}.lowerbound+rand(1,Population{i}.dimension).*(Population{i}.upperbound - Population{i}.lowerbound);% Initial population
            Population{i}.Path{j} = updatePath(Population{i}.Pos(j,:),Population{i}.dimension,Info.start(:,i),Info.aim(:,i),Population{i}.a,Population{i}.b,Population{i}.d,Population{i}.type);
            Population{i}.fitness(j)=calFitness(Population{i}.Path{j},Population,i,Info,seg_path);
        end
        [Population{i}.fbest,index]=min(Population{i}.fitness);
        Population{i}.Xbest=Population{i}.Pos(index,:);
        Population{i}.BestPath=Population{i}.Path{index};
    end

end