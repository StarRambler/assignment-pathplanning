function [Population] = getPopulation(SearchAgents,Max_iter,sizeofUAV)
%TEMP 此处显示有关此函数的摘要
%   此处显示详细说明
Population=cell(sizeofUAV,1);
for i=1:sizeofUAV
    Population{i}.Pos=[];
    Population{i}.fitness=zeros(1,SearchAgents);
    Population{i}.Xbest=[];
    Population{i}.fbest=inf;
    Population{i}.Path=cell(SearchAgents,1);
    Population{i}.comp_results=zeros(Max_iter,6);
    Population{i}.lowerbound=[];
    Population{i}.upperbound=[];
    Population{i}.a=0;
    Population{i}.b=0;
    Population{i}.d=0;
    Population{i}.dimension=0;
    Population{i}.type=0;
end

end

