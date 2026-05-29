import numpy as np
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
from improved_ga_assignment import run_iga
# Assume env_config, ga_task_assignment, and utils are in the same directory or accessible
# Make sure these imports work in your environment
try:
    from env_config import TASKS, BASE
    from ga_task_assignment import run_ga
    from utils import safe_distance
except ImportError:
    # Provide dummy data/functions if the imports fail, for demonstration
    print("Warning: Could not import from env_config, ga_task_assignment, or utils. Using dummy data/functions.")
    np.random.seed(42) # for reproducible dummy data
    BASE = np.array([50, 50])
    TASKS = np.random.rand(30, 2) * 100 # 30 tasks
    num_devices = 5 # Reduce for dummy example if needed

    def safe_distance(p1, p2):
        return np.linalg.norm(np.array(p1) - np.array(p2))

    # Dummy run_ga function
    def run_ga(generations=10, pop_size=10):
        print("Using dummy GA function.")
        assignment = [[] for _ in range(num_devices)]
        tasks_indices = list(range(len(TASKS)))
        np.random.shuffle(tasks_indices)
        # Ensure there are tasks to split and enough devices for splitting
        if len(TASKS) > 1 and num_devices > 1 and len(TASKS) >= num_devices :
             split_indices = np.sort(np.random.choice(len(TASKS)-1, num_devices-1, replace=False))
        elif len(TASKS) > 0 : # If fewer tasks than devices or only one device, assign all tasks to first few/one device(s)
             split_indices = [] # No splits needed or possible in the same way
        else: # No tasks
             split_indices = []
             return assignment, 0


        start = 0
        for i, split_idx in enumerate(split_indices):
            assignment[i] = tasks_indices[start:split_idx+1]
            start = split_idx + 1
        # Assign remaining tasks to the last designated device slot if tasks remain
        if start < len(tasks_indices) and num_devices > 0 :
            assignment[min(len(split_indices), num_devices-1)] = tasks_indices[start:]
        elif not tasks_indices and num_devices > 0: # No tasks, ensure all assignments are empty lists
            assignment = [[] for _ in range(num_devices)]
        elif num_devices == 1 and tasks_indices: # Single device gets all tasks
            assignment[0] = tasks_indices

        return assignment, 0 # Return dummy fitness



# Original parameters (adjust if using dummy data above)
# num_devices = 15 # Use the one defined above if dummy data is used
uav_speed = 60  # km/h
ugv_speed = 30  # km/h


def random_assignment():
    perm = list(np.random.permutation(len(TASKS)))
    # np.array_split returns a list containing NumPy arrays
    # Handle edge case where len(TASKS) < num_devices
    if len(TASKS) == 0: # No tasks
        return [[] for _ in range(num_devices)]
    if len(TASKS) < num_devices:
        assign = [[] for _ in range(num_devices)]
        for i, task_idx in enumerate(perm):
            assign[i].append(task_idx) # Assign each task to a separate device if possible
        return assign
    else:
        # Ensure correct splitting when num_devices might be 1
        if num_devices == 0: # Avoid division by zero or empty splits
            return [] # Or handle as an error
        if num_devices == 1:
            return [perm] # All tasks to the single device
        return [list(arr) for arr in np.array_split(perm, num_devices)] # Ensure list of lists


def kmeans_assignment():
    # Handle edge case where n_clusters > n_samples or no tasks
    if len(TASKS) == 0:
        return [[] for _ in range(num_devices)] # Return empty assignments if no tasks
    n_clusters = min(num_devices, len(TASKS))
    if n_clusters == 0: # Should not happen if len(TASKS) > 0, but as a safeguard
        return [[] for _ in range(num_devices)]


    kmeans = KMeans(n_clusters=n_clusters, random_state=0, n_init=10).fit(TASKS)
    assignment = [[] for _ in range(num_devices)] # Always create num_devices lists
    for idx, label in enumerate(kmeans.labels_):
         # Ensure label index is within bounds if n_clusters < num_devices
         if label < num_devices: # kmeans.labels_ will be from 0 to n_clusters-1
            assignment[label].append(idx)
    return assignment


def compute_total_length(assignment):
    """Maintain original path calculation method (Base → Task points connected in order)"""
    total_length = 0
    for task_indices in assignment:
        if not task_indices: # Check if list is empty
            continue
        # Ensure task_indices contains valid indices for TASKS
        valid_indices = [idx for idx in task_indices if idx < len(TASKS)]
        if not valid_indices:
            continue

        path = np.vstack(([BASE], TASKS[valid_indices]))
        for i in range(len(path) - 1):
            total_length += safe_distance(path[i], path[i + 1])
    return total_length


def compute_mission_time(assignment, num_uavs=10):
    """Added time calculation (maintaining original path calculation method)"""
    device_times = []
    # Ensure num_uavs is not greater than num_devices
    actual_num_uavs = min(num_uavs, num_devices if 'num_devices' in globals() else 0)


    for device_idx, task_indices in enumerate(assignment):
        if not task_indices: # Check if list is empty
             continue
        # Ensure task_indices contains valid indices for TASKS
        valid_indices = [idx for idx in task_indices if idx < len(TASKS)]
        if not valid_indices:
            continue

        # Path calculation consistent with compute_total_length
        path = np.vstack(([BASE], TASKS[valid_indices]))
        distance = sum(safe_distance(path[i], path[i + 1]) for i in range(len(path) - 1))
        speed = uav_speed if device_idx < actual_num_uavs else ugv_speed
        if speed <= 0: # Avoid division by zero
             time = float('inf')
        else:
             time = distance / speed * 60 # minutes
        device_times.append(time)
    return max(device_times) if device_times else 0


# --- MODIFIED FUNCTION ---
def plot_comparison(values, title, ylabel,path):
    plt.rcParams['font.sans-serif'] = ['Microsoft YaHei']
    """Optimized plotting function, using different colors"""
    methods = ['Random Assignment', 'KMeans Allocation', 'GA Optimization','IGA Optimization']
    # Define a list of colors, one for each method
    # Using matplotlib default colors: blue, orange, green
    bar_colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728']

    fig, ax = plt.subplots(figsize=(10, 6))
    # Pass the list of colors to the color parameter
    bars = ax.bar(methods, values, color=bar_colors)

    # Display values on top of the bars
    for bar in bars:
        height = bar.get_height()
        # Adjust text position to be directly above the top of the bar
        ax.text(bar.get_x() + bar.get_width() / 2, height,
                f'{height:.1f}', ha='center', va='bottom', fontsize=10) # You can adjust fontsize

    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.grid(axis='y', linestyle='--', alpha=0.7)
    # Automatically adjust y-axis range to make space for text at the top
    ax.margins(y=0.1)
    plt.tight_layout()
    plt.savefig(path)
    plt.show()


if __name__ == "__main__":
    # Ensure num_devices is defined before use if not using dummy data section
    if 'num_devices' not in globals():
        num_devices = 15 # Set default if not defined earlier
    # Ensure TASKS is defined, especially if not using the dummy data section
    if 'TASKS' not in globals():
        TASKS = [] # Initialize as empty list or load appropriately

    print("Starting simulation experiment...")

    # 1. Random assignment
    random_assign = random_assignment()
    random_length = compute_total_length(random_assign)
    random_time = compute_mission_time(random_assign)

    # 2. KMeans assignment
    kmeans_assign = kmeans_assignment()
    kmeans_length = compute_total_length(kmeans_assign)
    kmeans_time = compute_mission_time(kmeans_assign)

    # 3. GA optimization assignment
    # Ensure run_ga returns an assignment that is a list of lists or list of arrays compatible with downstream functions
    # Handle case where GA might return None or unexpected format
    ga_result = run_ga(generations=100, pop_size=50, num_devices=15)
    if ga_result and isinstance(ga_result, tuple) and len(ga_result) > 0:
        ga_assign, _ = ga_result
        # Ensure ga_assign is a list of lists/arrays
        if not isinstance(ga_assign, list) or not all(isinstance(sublist, (list, np.ndarray)) for sublist in ga_assign):
             print("Warning: GA returned unexpected format. Attempting fallback assignment.")
             # Fallback: Assign tasks randomly or use KMeans if GA fails
             ga_assign = kmeans_assignment() # Or random_assignment()
    else:
        print("Warning: GA did not return a result or returned an unexpected format. Using KMeans assignment as fallback.")
        ga_assign = kmeans_assignment() # Fallback if GA fails

    ga_length = compute_total_length(ga_assign)
    ga_time = compute_mission_time(ga_assign)

    iga_result = run_iga(generations=100, pop_size=50, num_devices=15)
    if iga_result and isinstance(iga_result, tuple) and len(iga_result) > 0:
        iga_assign, _ = iga_result
        # Ensure iga_assign is a list of lists/arrays
        if not isinstance(iga_assign, list) or not all(isinstance(sublist, (list, np.ndarray)) for sublist in iga_assign):
            print("Warning: GA returned unexpected format. Attempting fallback assignment.")
            # Fallback: Assign tasks randomly or use KMeans if GA fails
            iga_assign = kmeans_assignment()  # Or random_assignment()
    else:
        print(
            "Warning: GA did not return a result or returned an unexpected format. Using KMeans assignment as fallback.")
        iga_assign = kmeans_assignment()  # Fallback if GA fails

    iga_length = compute_total_length(iga_assign)
    iga_time = compute_mission_time(iga_assign)

    # Print results
    print(f"\n[Path Length Comparison]")
    print(f"Random Assignment: {random_length:.1f} km")
    print(f"KMeans Allocation: {kmeans_length:.1f} km")
    print(f"EGA Optimization: {ga_length:.1f} km")
    print(f"EGA Optimization: {iga_length:.1f} km")

    print(f"\n[Completion Time Comparison]")
    print(f"Random Assignment: {random_time:.1f} minutes")
    print(f"KMeans Allocation: {kmeans_time:.1f} minutes")
    print(f"EGA Optimization: {ga_time:.1f} minutes")
    print(f"IGA Optimization: {iga_time:.1f} minutes")

    name=60


    # Plot comparison graphs
    plot_comparison([random_length, kmeans_length, ga_length, iga_length],
                    '不同任务分配策略的总路径长度对比', '总路径长度(km)',f'./outcmaes/scheduling/compare/{name}_length.png')

    plot_comparison([random_time, kmeans_time, ga_time, iga_time],
                    '不同任务分配策略的任务完成时间对比', '最大完成时间 (min)',f'./outcmaes/scheduling/compare/{name}_time.png')
    import pandas as pd

    # 每个变量加 [] 转为单元素列表
    df_length = pd.DataFrame({
        'Random': [random_length],
        'KMeans': [kmeans_length],
        'GA': [ga_length],
        'IGA': [iga_length]
    })

    df_time = pd.DataFrame({
        'Random': [random_time],
        'KMeans': [kmeans_time],
        'GA': [ga_time],
        'IGA': [iga_time]
    })

    # 保存（index=False 避免写入多余的行号）
    df_length.to_csv('path_lengths.csv', index=False)
    df_time.to_csv('completion_times.csv', index=False)

    # 2. 保存为独立的 CSV 文件
    df_length.to_csv(f'./outcmaes/scheduling/compare/{name}_path_lengths.csv', index=False, encoding='utf-8-sig')
    df_time.to_csv(f'./outcmaes/scheduling/compare/{name}_completion_times.csv', index=False, encoding='utf-8-sig')

    # # 3. （可选）保存到一个 Excel 文件的两个 Sheet 中
    # with pd.ExcelWriter('task_allocation_results.xlsx', engine='openpyxl') as writer:
    #     df_length.to_excel(writer, sheet_name='Path Length (km)', index=False)
    #     df_time.to_excel(writer, sheet_name='Completion Time (min)', index=False)

    print("✅ 数据已保存完成！")