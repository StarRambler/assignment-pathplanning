function Population=judgePopulation(Population,newPopulation,SearchAgents,sizeofUAV)
    for i=1:sizeofUAV
        for j=1:SearchAgents
            if newPopulation{i}.fitness(j)<Population{i}.fitness(j)
                Population{i}.fitness(j)=newPopulation{i}.fitness(j);
                Population{i}.Pos(j,:)=newPopulation{i}.Pos(j,:);
                Population{i}.Path{j}=newPopulation{i}.Path{j};
            end
        end
    end
end