import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from env_config import BASE, TASKS, OBSTACLES
from ga_task_assignment import run_ga
from improved_ga_assignment import run_iga
from cma_optimizer import optimize_task_order, plan_full_path
import matlab.engine
import os
from smooth_path import smooth_path


def get_device_z_height(device_idx):
    if device_idx<10:
        return 0.5
    else:
        return 0

def compute_mission_completion_time(paths, num_uavs, uav_speed=80, ugv_speed=30):
    """
    Calculate the completion time of the collaborative task (minutes)
    paths: List of (vehicle_index, path_points), where path_points is Nx2 ndarray
    num_uavs: The first num_uavs are UAVs, and the rest are UGVs
    uav_speed, ugv_speed: The unit is km/h
    Return:
    - max_time_minutes: Maximum task completion time (minutes)
    - vehicle_times_minutes: The time required for each vehicle to complete the task (minutes)
    """
    vehicle_times_minutes = []

    for idx, path in paths:
        path = np.array(path)
        if len(path) < 2:
            vehicle_times_minutes.append(0.0)
            continue

        total_distance = sum(np.linalg.norm(path[i+1] - path[i]) for i in range(len(path)-1))  # km

        speed = uav_speed if idx < num_uavs else ugv_speed  # km/h
        time_hr = total_distance / speed
        vehicle_times_minutes.append(time_hr * 60)  # Convert to minutes

    max_time = max(vehicle_times_minutes)
    return max_time, vehicle_times_minutes


def run(schedule_algorithm):
    matplotlib.rcParams['font.sans-serif'] = ['SimHei']
    matplotlib.rcParams['axes.unicode_minus'] = False

    # Optimize task allocation
    if schedule_algorithm == 'GA':
        best_assignment, best_fitness_history = run_ga(generations=100, pop_size=50)
    elif schedule_algorithm == 'IGA':
        best_assignment, best_fitness_history = run_iga(generations=100, pop_size=50)
    print(best_assignment)
    # Draw an evolution curve

    schedule_path = os.path.join(os.path.dirname(__file__), 'outcmaes', 'scheduling', schedule_algorithm)
    os.makedirs(schedule_path, exist_ok=True)
    plt.plot(best_fitness_history)
    plt.xlabel('Generation')
    plt.ylabel('Best Total Distance')
    plt.title(f'{schedule_algorithm} Evolution process')
    plt.grid(True)
    plt.savefig(schedule_path + '/evolution_curve.png')

    # Saving GA evolution data
    generations = np.arange(len(best_fitness_history))
    ga_evolution_df = pd.DataFrame({
        'Generation': generations,
        'Best_Total_Distance': best_fitness_history
    })
    csv_path=schedule_path+rf'/{schedule_algorithm.lower()}_evolution_data.csv'
    ga_evolution_df.to_csv(csv_path, index=False)
    print(f"{schedule_algorithm} 进化数据已保存到 {schedule_algorithm.lower()}_evolution_data.csv")
    # Draw all device tracks
    # 2. Generate raw traces for each device
    if schedule_algorithm == 'IGA':
        order_list = []
        for idx, task_indices in enumerate(best_assignment):
            if len(task_indices) == 0:
                order_list.append([])
                continue
            order = optimize_task_order(task_indices)
            order_list.append(order)

        all_start_points = []
        all_goal_points = []
        task_type = []
        path_seg = []
        for device_idx, order in enumerate(order_list):
            current_start = np.array([0, 0, 0])
            if len(order) > 1:
                count = 0
                for task_idx in order:
                    path_seg.append(count)
                    count += 1
                    task_point = TASKS[task_idx]
                    z_height = get_device_z_height(device_idx)
                    goal_3d = np.array([task_point[0], task_point[1], z_height])
                    # 添加起止点对
                    all_start_points.append(current_start)
                    all_goal_points.append(goal_3d)
                    # 更新下一个任务的起点为当前任务的终点
                    current_start = goal_3d
                    if device_idx < 10:
                        task_type.append(1)
                    else:
                        task_type.append(2)
            elif len(order) == 1:
                count = 0
                path_seg.append(count)
                task_point = TASKS[order][0]
                z_height = get_device_z_height(device_idx)
                goal_3d = np.array([task_point[0], task_point[1], z_height])
                all_start_points.append(current_start)
                all_goal_points.append(goal_3d)
                if device_idx < 10:
                    task_type.append(1)
                else:
                    task_type.append(2)
        print(f"all_start_points: {len(all_start_points)}")
        type = [1] * 10 + [2] * 5
        eng = matlab.engine.start_matlab()
        eng.addpath(r'./multi_device_path_planning', nargout=1)
        SearchAgents = matlab.int32(100)
        indepent_runtimes = matlab.int32(1)
        Max_iter = matlab.int32(500)
        numofdevice = matlab.int32(len(all_start_points))  # 所有路径段
        typeofdevice = matlab.int32(task_type)
        save_flag = 1
        save_path = './outcmaes/pathplanning/'
        # 一次性规划所有路径段
        if len(all_start_points) > 0:
            # 转换为MATLAB兼容格式
            start_points_matlab = matlab.double([point.tolist() for point in all_start_points])
            goal_points_matlab = matlab.double([point.tolist() for point in all_goal_points])

            all_paths = eng.path_full_path(start_points_matlab, goal_points_matlab,
                                           SearchAgents, indepent_runtimes, Max_iter,
                                           numofdevice, typeofdevice, path_seg, save_flag, save_path)
            print(f'共有{len(best_assignment)}个设备与{len(all_paths)}段路径')
    elif schedule_algorithm == 'GA':
        original_paths = []  # Save original traces of each device

        for idx, task_indices in enumerate(best_assignment):
            if len(task_indices) == 0:
                continue
            order = optimize_task_order(task_indices)
            path = plan_full_path(BASE, TASKS[order])
            if path is not None:
                original_paths.append((idx, path))  # Save device number and track

        # 3. Smooth the trajectory and draw it
        fig, ax = plt.subplots(figsize=(12, 10))

        # Draw task points
        for i, (x, y) in enumerate(TASKS):
            ax.plot(x, y, 'bo')
            ax.text(x + 0.3, y + 0.3, f'T{i + 1}')

        # Draw device trajectories
        for idx, path in original_paths:
            smoothed_path = smooth_path(path, smoothing_factor=0)  # You can adjust the smoothness
            ax.plot(smoothed_path[:, 0], smoothed_path[:, 1], label=f'Device-{idx + 1}')

        # Draw obstacle area
        for (ox, oy, r) in OBSTACLES:
            circle = plt.Circle((ox, oy), r, color='brown', alpha=0.4)
            ax.add_patch(circle)
            ax.text(ox + r + 0.2, oy, f'Obstacle', fontsize=8, color='brown')

        # Drawing Base
        ax.plot(BASE[0], BASE[1], 'ks', markersize=14, label='Base')
        ax.set_xlim(-11, 11)
        ax.set_ylim(-11, 11)
        ax.set_xlabel('X (km)')
        ax.set_ylabel('Y (km)')
        ax.set_title('EGA规划二维路径结果')
        ax.legend()
        ax.grid(True)
        save_path = './outcmaes/pathplanning/GA'
        plt.savefig(save_path)
        max_time, vehicle_times = compute_mission_completion_time(original_paths,
                                                                  num_uavs=10)  # Assume the first one is UAV
        print(f"Maximum completion time: {max_time:.2f} minutes")
        print("Completion times for each vehicle:", vehicle_times)


    # ... (After path planning and completion time calculation) ...

    # Save environment configuration
    if BASE is not None:
        base_path=schedule_path+r'\base_coordinates.csv'
        np.savetxt(base_path, np.array(BASE).reshape(1, -1), delimiter=',', header='X,Y', comments='')
        print("Base coordinates saved to base_coordinates.csv")

    if TASKS is not None and len(TASKS) > 0:
        task_df = pd.DataFrame(TASKS, columns=['X', 'Y'])
        task_df.index.name = 'Task_ID_Python'  # Python index starts from 0
        task_path=schedule_path+r'\tasks_coordinates.csv'
        task_df.to_csv(task_path)
        print("Task coordinates saved to tasks_coordinates.csv")

    if OBSTACLES is not None and len(OBSTACLES) > 0:
        obstacles_df = pd.DataFrame(OBSTACLES, columns=['CenterX', 'CenterY', 'Radius'])
        obs_path=schedule_path+r'\obstacles_parameters.csv'
        obstacles_df.to_csv(obs_path, index=False)
        print("Obstacle parameters saved to obstacles_parameters.csv")

    # Save task assignment results (best_assignment)
    assignment_data = []
    for device_idx, task_indices_for_device in enumerate(best_assignment):
        if not task_indices_for_device:
            assignment_data.append([device_idx, np.nan])  # Device not assigned any task
        else:
            for task_py_idx in task_indices_for_device:  # task_py_idx is the index in the TASKS list
                assignment_data.append([device_idx, task_py_idx])
    if assignment_data:
        assignment_df = pd.DataFrame(assignment_data, columns=['Device_ID', 'Assigned_Task_Python_Index'])
        assignment_csv_path=schedule_path+rf'/{schedule_algorithm.lower()}_task_assignment_output.csv'
        assignment_df.to_csv(assignment_csv_path, index=False)
        print(f"{schedule_algorithm} task assignment results saved to {schedule_algorithm.lower()}_task_assignment_output.csv")

    # # Save task completion times
    # if 'vehicle_times' in locals() and vehicle_times:  # Check if the variable exists and is not empty
    #     vehicle_ids = [path_info[0] for path_info in original_paths if
    #                    path_info[1] is not None and len(path_info[1]) > 0]
    #     # Ensure vehicle_times and vehicle_ids have the same length
    #     if len(vehicle_ids) == len(vehicle_times):
    #         completion_times_df = pd.DataFrame({
    #             'Device_ID': vehicle_ids,  # Use actual device IDs participating in tasks
    #             'Completion_Time_min': vehicle_times
    #         })
    #         completion_times_df.to_csv('vehicle_completion_times.csv', index=False)
    #         print("Completion times for each vehicle saved to vehicle_completion_times.csv")
    #
    #         with open('max_completion_time.txt', 'w') as f:
    #             f.write(f"Max_Completion_Time_min: {max_time:.2f}\n")
    #         print(f"Maximum completion time {max_time:.2f} minutes recorded in max_completion_time.txt")
    #     else:
    #         print(
    #             "Warning: Mismatch in length between vehicle_ids and vehicle_times. Vehicle completion times not saved.")
    # else:
    #     print("Vehicle completion time data not calculated or unavailable.")

if __name__ == '__main__':
    run('IGA')