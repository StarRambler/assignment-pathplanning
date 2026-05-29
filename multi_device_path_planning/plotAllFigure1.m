function plotAllFigure1(Info,X,Y,Z, GlobalBest,x1,y1,z1,u,v,w)

startPos=Info.start;
goalPos=Info.aim;
Threat_radius=Info.Threat_radius;
Threat_kind=Info.Threat_kind;
Threat_center=Info.Threat_center;
% 画起点和终点
for i=1:size(startPos,2)
    o=scatter3(startPos(1,i), startPos(2,i), startPos(3,i),100,'bs','MarkerFaceColor','y');
    hold on
    t=scatter3(goalPos(1,i), goalPos(2,i), goalPos(3,i),100,'kp','MarkerFaceColor','y');
    hold on
end
% for wind=1:size(Info.vortices,1)
%  p=scatter3(Info.vortices(wind,1), Info.vortices(wind,2), 50,100,'kh','MarkerFaceColor','g');
% end
% 画山峰曲面
surfc(X,Y,Z)      % 画曲面图
shading flat     % 各小曲面之间不要网格
%画威胁源
for k=1:size(Threat_kind,2)
    [x,y,z]=sphere(15);
    z(z<0)=nan;

    x0=Threat_center(1,k);    y0=Threat_center(2,k);     z0=0;
    XX=x*Threat_radius(1,k)+x0;    YY=y*Threat_radius(1,k)+y0;    ZZ=z*Threat_radius(1,k)+z0; 
    hold on;
 %set(gca, 'Position', [0 0 1 1]);
 %axis equal vis3d on;
    if Threat_kind(1,k)>20
        surf(XX,YY,ZZ,'EdgeColor','black','FaceColor','none');
    elseif Threat_kind(1,k)>10
        surf(XX,YY,ZZ,'EdgeColor','r','FaceColor','none');
    else
        surf(XX,YY,ZZ,'EdgeColor','g','FaceColor','none');
    end
     
  %  hold on;
end
% 画路径

color={'r','g','yellow'};
luxian=cell(1,size(startPos,2));
h=[];
lab=[];
for i=1:size(startPos,2)
    hold on
    luxian{i}=plot3(GlobalBest{i}(:,1),GlobalBest{i}(:,2),GlobalBest{i}(:,3), color{i},'LineWidth',2);
%     hold on;
%     plot3(GlobalBest{i}(:,1),GlobalBest{i}(:,2),GlobalBest{i}(:,3), 'o','LineWidth',1,'MarkerFaceColor',color{i});
    h=[h,luxian{i}];
    lab=[lab,strcat('UAV-',num2str(i))];
end
q=quiver3(x1,y1,z1,u,v,w,'Color',[0,0.67,1]);
legend([luxian{1},luxian{2},luxian{3},q,o,t],'UAV-1','UAV-2','UAV-3','wind','start point','target point');
xlabel('x');
ylabel('y');
hold on;
hold off
grid on
end

