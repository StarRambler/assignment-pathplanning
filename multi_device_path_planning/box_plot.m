independent_run_times=10;
savepath='./结果图/箱线图.fig';
algorithmname={'AHA','GWO','WOA','ISSA','COA','MDCOA'};
pathcolor={'cyan','m','blue','black','green','r'};
SearchAgents=100;
dimension=20;
Max_iter=100;
Excel_name='length.xls';
plotdataUAV1=[];
plotdataUAV2=[];
plotdataUAV3=[];
mycolor = [
        1,0,0;
        0,1,1;
        0.862745098039216,0.827450980392157,0.117647058823529;...
        0.949019607843137,0.650980392156863,0.121568627450980;...
        0.72,0.27,1;...
        0,1,0;];  %设置一个颜色库

for num=1:6
    path=strcat('.\',algorithmname{num},'\');
    str0 = num2str(SearchAgents);
    str1 = algorithmname{num};
    str2 = num2str(dimension); %自动获取维数
    str3 = 'dim_';
    str4 = num2str(Max_iter);
    str5 = '_iter';
    mat_file_name = strcat(path,str0,'_', str1,'_', str2, str3,str4,str5);
    data=load(mat_file_name);
    flag=isinf(data.result{1,2});
    [r,c]=find(flag==1);
    data.result{1,2}(r,:)=NaN;
    plotdataUAV1=[plotdataUAV1,data.result{1,2}(:,1)];   
    plotdataUAV2=[plotdataUAV2,data.result{1,2}(:,2)];
    plotdataUAV3=[plotdataUAV3,data.result{1,2}(:,3)];
end
plotdata=[plotdataUAV1,plotdataUAV2,plotdataUAV3];
% group = [repmat("UAV-1", 6, 1); repmat("UAV-2", 6, 1);repmat("UAV-3", 6, 1)];
% group = repmat(group, 1, size(plotdata, 2) / 18);  % 适配plotdata列数
algorithmname={'AHA','GWO','WOA','ISSA','COA','MDCOA','AHA','GWO','WOA','ISSA','COA','MDCOA','AHA','GWO','WOA','ISSA','COA','MDCOA'};
% subgroup = repmat(algorithmname, 1, 3);  % 每个UAV的子组是相同的算法
box_figure=boxplot(plotdata);
%设置线宽
set(box_figure,'Linewidth',1);
boxobj = findobj(gca,'Tag','Box');
for i = 1:1   %因为总共有5个算法，这里根据自身实际情况更改！
    patch(get(boxobj(i),'XData'),get(boxobj(i),'YData'),mycolor(i,:),'FaceAlpha',0.6,...
        'LineWidth',0.7);
end
for i = 2:6   %因为总共有5个算法，这里根据自身实际情况更改！
    patch(get(boxobj(i),'XData'),get(boxobj(i),'YData'),mycolor(i,:),'FaceAlpha',0.1,...
        'LineWidth',0.7);
end
for i = 7:7   %因为总共有5个算法，这里根据自身实际情况更改！
    patch(get(boxobj(i),'XData'),get(boxobj(i),'YData'),mycolor(i-6,:),'FaceAlpha',0.6,...
        'LineWidth',0.7);
end
for i = 8:12   %因为总共有5个算法，这里根据自身实际情况更改！
    patch(get(boxobj(i),'XData'),get(boxobj(i),'YData'),mycolor(i-6,:),'FaceAlpha',0.1,...
        'LineWidth',0.7);
end
for i = 13:13   %因为总共有5个算法，这里根据自身实际情况更改！
    patch(get(boxobj(i),'XData'),get(boxobj(i),'YData'),mycolor(i-12,:),'FaceAlpha',0.6,...
        'LineWidth',0.7);
end
for i = 14:18   %因为总共有5个算法，这里根据自身实际情况更改！
    patch(get(boxobj(i),'XData'),get(boxobj(i),'YData'),mycolor(i-12,:),'FaceAlpha',0.1,...
        'LineWidth',0.7);
end
set(gcf,'position',[250 300 705 360]);
xticklabels(algorithmname);
xline(6.5,'LineWidth',1);
xline(12.5,'LineWidth',1);
ylabel('cost function value');
set(gca,'FontSize',14);
annotation('textbox',[.21 .7 .3 .3],'String','UAV-1','EdgeColor','none','FontSize',13);
annotation('textbox',[.45 .7 .3 .3],'String','UAV-2','EdgeColor','none','FontSize',13);
annotation('textbox',[.72 .7 .3 .3],'String','UAV-3','EdgeColor','none','FontSize',13);
saveas(gca,savepath)
