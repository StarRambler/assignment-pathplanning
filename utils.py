import numpy as np
from env_config import OBSTACLES

def in_obstacle(x, y):
    for (ox, oy, r) in OBSTACLES:
        if np.sqrt((x - ox)**2 + (y - oy)**2) <= r:
            return True
    return False

def safe_distance(p1, p2):
    if in_obstacle((p1[0]+p2[0])/2, (p1[1]+p2[1])/2):
        return np.linalg.norm(p1 - p2) * 10
    return np.linalg.norm(p1 - p2)


import numpy as np

# ================= 能耗系数配置 =================
# 调整此处即可控制差异幅度，当前设置 UAV ≈ 3倍 UGV
ENERGY_COEFF = {
    'UAV': {'base': 3.0, 'climb': 2.0},  # 基础能耗系数, 爬升惩罚系数
    'UGV': {'flat': 1.0}  # 平路能耗系数
}
OBSTACLE_PENALTY = 10.0  # 保持您原有的障碍惩罚倍数


def run_time(dis, v_type='UAV'):
    if v_type == 1:
        speed = 60
    elif v_type == 2:
        speed = 30
    return dis/speed

def segment_energy(p1, p2, v_type='UAV'):
    """单段路径能耗计算（极简版）"""
    p1, p2 = np.array(p1), np.array(p2)

    # 距离与高差（兼容2D/3D坐标）
    d_3d = np.linalg.norm(p2 - p1)
    d_2d = np.linalg.norm(p2[:2] - p1[:2]) if len(p1) >= 2 else d_3d
    dz = p2[2] - p1[2] if len(p1) == 3 else 0.0

    # 障碍惩罚（复用您原有的中点检测逻辑）
    mid = (p1 + p2) / 2
    penalty = OBSTACLE_PENALTY if in_obstacle(mid[0], mid[1]) else 1.0

    # 能耗计算
    if v_type == 1: # UAV
        cost = ENERGY_COEFF['UAV']['base'] * d_3d + \
               ENERGY_COEFF['UAV']['climb'] * max(0, dz)
    elif v_type == 2:  # UGV
        cost = ENERGY_COEFF['UGV']['flat'] * d_2d

    return cost * penalty

