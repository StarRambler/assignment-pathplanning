function plotAllFigure(Info, GlobalBest, devicetype)

startPos = Info.start;
goalPos  = Info.aim;
Threat_radius = Info.Threat_radius;
Threat_kind   = Info.Threat_kind;
Threat_center = Info.Threat_center;

% 画威胁源
for k = 1:size(Threat_kind,2)
    [x,y,z] = sphere(15); z(z<0) = nan;
    x0=Threat_center(1,k); y0=Threat_center(2,k); z0=0;
    XX=x*Threat_radius(1,k)+x0; YY=y*Threat_radius(1,k)+y0; ZZ=z*Threat_radius(1,k)+z0; 
    hold on;
    if Threat_kind(1,k)>20
        surf(XX,YY,ZZ,'EdgeColor','k','FaceColor','none');
    elseif Threat_kind(1,k)>10
        surf(XX,YY,ZZ,'EdgeColor','r','FaceColor','none');
    else
        surf(XX,YY,ZZ,'EdgeColor','g','FaceColor','none');
    end
end

% ================= 路径绘制 & 颜色/图例管理 =================
numPaths = size(startPos, 2);
luxian   = cell(1, numPaths);      % 句柄容器
pathDeviceIdx  = zeros(1, numPaths); % 记录每段路径对应的设备序号
pathDeviceType = zeros(1, numPaths); % 记录每段路径对应的设备类型（1=UAV, 2=UGV）

% 图例专用句柄和标签（严格保持 1:1 对应）
h_legend = [];
lab = {};

% 独立颜色池（UAV用lines，UGV用hsv，彻底杜绝跨类型撞色）
cmapUAV = lines(max(50, numPaths)); 
cmapUGV = hsv(max(50, numPaths));

countUAV = 0;
countUGV = 0;

for i = 1:numPaths
    startPt = startPos(:, i);
    isContinuation = false;
    targetIdx = [];
    
    % 检测起点是否匹配历史终点
    for j = 1:size(goalPos, 2)
        if all(abs(goalPos(:, j) - startPt) < 1e-6)
            isContinuation = true;
            targetIdx = j;
            break;
        end
    end
    
    hold on;
    if isContinuation && ~isempty(targetIdx) && ishandle(luxian{targetIdx})
        % 【延续路径】严格继承上一段的设备序号与类型
        devIdx  = pathDeviceIdx(targetIdx);
        devType = pathDeviceType(targetIdx);
        
        if devType == 1
            currentColor = cmapUAV(devIdx, :);
        else
            currentColor = cmapUGV(devIdx, :);
        end
    else
        % 【新设备】分配全新设备序号、类型和颜色
        devType = devicetype(i);
        if devType == 1
            countUAV = countUAV + 1;
            devIdx = countUAV;
            currentColor = cmapUAV(devIdx, :);
            lab{end+1} = sprintf('UAV-%d', countUAV);
        else
            countUGV = countUGV + 1;
            devIdx = countUGV;
            currentColor = cmapUGV(devIdx, :);
            lab{end+1} = sprintf('UGV-%d', countUGV);
        end
    end
    
    % 记录当前段所属的设备序号和类型（供后续延续逻辑读取）
    pathDeviceIdx(i)  = devIdx;
    pathDeviceType(i) = devType;
    
    % 绘制路径（显式指定颜色，完全脱离MATLAB默认色轮）
    if devType == 1
        p = plot3(GlobalBest{i}(:,1), GlobalBest{i}(:,2), GlobalBest{i}(:,3), ...
                  'LineWidth', 2, 'Color', currentColor);
    else
        p = plot3(GlobalBest{i}(:,1), GlobalBest{i}(:,2), GlobalBest{i}(:,3), ...
                  'LineWidth', 2, 'Color', currentColor, 'LineStyle', '--');
    end
    
    luxian{i} = p;
    
    % 仅当为“新设备首段”时，才将句柄加入图例列表
    if ~isContinuation
        h_legend = [h_legend, p];
    end
end

% 画起点 (修复原代码 startPos(1,0) 索引越界问题)
if size(startPos, 2) > 0
    s_start = scatter3(startPos(1,1), startPos(2,1), startPos(3,1), 100, ...
                       'o', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k');
    hold on;
    h_legend = [h_legend, s_start];
    lab{end+1} = '起点';
end

% 画终点
if size(goalPos, 2) > 0
    % 视觉绘制所有终点
    for i = 1:size(goalPos,2)
        scatter3(goalPos(1,i), goalPos(2,i), goalPos(3,i), 100, ...
                 'kp', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k');
    end
    % 仅提取第一个终点的句柄用于图例，避免重复条目
    s_goal = scatter3(goalPos(1,1), goalPos(2,1), goalPos(3,1), 100, ...
                      'kp', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k');
    h_legend = [h_legend, s_goal];
    lab{end+1} = '目标节点';
end

% 统一添加图例（此时 h_legend 与 lab 长度严格一致）
if ~isempty(h_legend)
    legend(h_legend, lab, 'Location', 'best');
end

title("多智能体路径俯视图");
xlabel('x'); ylabel('y'); zlabel('z');
view(2); % 强制切换为俯视角，贴合标题
grid on; hold off;
end