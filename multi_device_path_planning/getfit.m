function Population=getfit(Population,SearchAgents,Info,sizeofUAV)
    if sizeofUAV==1
        startPos=Info.start(:,1);
        dimension=Population{1}.dimension;
        goalPos=Info.aim(:,1);
        for j=1:SearchAgents
            Population{1}.Path{j} = updatePath(Population{1}.Pos(j,:),dimension,startPos,goalPos,Population{1}.a,Population{1}.b,Population{1}.d,Population{1}.type);
            Population{1}.fitness(j)=calFitness1(Population{1}.Path{j},Info);
        end


    end
    for i=1:sizeofUAV
        startPos=Info.start(:,i);
        dimension=Population{i}.dimension;
        goalPos=Info.aim(:,i);
        for j=1:SearchAgents
            Population{i}.Path{j} = updatePath(Population{i}.Pos(j,:),dimension,startPos,goalPos,Population{i}.a,Population{i}.b,Population{i}.d,Population{i}.type);
            Population{i}.fitness(j)=calFitness(Population{i}.Path{j},Population,i,Info);
        end
    end
end