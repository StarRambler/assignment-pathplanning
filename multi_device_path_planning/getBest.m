function [Population] = getBest(Population)
%GETBEST 此处显示有关此函数的摘要
%   此处显示详细说明
sizeofUAV=size(Population,1);
for i=1:sizeofUAV
    [Population{i}.fbest,index]=min(Population{i}.fitness);
    Population{i}.Xbest=Population{i}.Pos(index,:);
    Population{i}.BestPath=Population{i}.Path{index};
end
end

