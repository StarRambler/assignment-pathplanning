function [Info] = getMap(start,aim)
    Info.Threat_center=[1,-5,-7,6,0;
        2,6,-6,-2,-8];   %威胁区域中心
    Info.Threat_radius = [1.5  1.0  1.0  1.2  1.0];
    Info.Threat_kind = [12 8 10 10 10];  %威胁程度
    Info.start = start;
    Info.aim = aim;
end

