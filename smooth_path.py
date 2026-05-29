import numpy as np
from scipy import interpolate


def smooth_path(path_points, smoothing_factor=0):
    """
    Use B-spline to smooth the trajectory
    path_points: Input path point array, such as (N,2)
    smoothing_factor: smoothing degree (0 means strictly passing through all points)
    Return the smoothed trajectory points (N_new, 2)
    """
    path_points = np.array(path_points)
    x = path_points[:, 0]
    y = path_points[:, 1]

    # 参数化路径
    t = np.linspace(0, 1, len(x))

    # B样条拟合
    tck, _ = interpolate.splprep([x, y], s=smoothing_factor)

    # 重新采样更多点
    u_fine = np.linspace(0, 1, 300)
    x_new, y_new = interpolate.splev(u_fine, tck)

    smoothed_path = np.vstack((x_new, y_new)).T
    return smoothed_path