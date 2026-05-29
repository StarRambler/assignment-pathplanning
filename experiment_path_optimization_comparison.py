import numpy as np
import matplotlib.pyplot as plt
import pandas as pd # Import pandas for saving CSV
from env_config import BASE, TASKS
from rrt_star import informed_rrt
from cma_optimizer import optimize_task_order, plan_full_path
from utils import safe_distance

import matplotlib
# matplotlib.rcParams['font.sans-serif'] = ['SimHei']
# matplotlib.rcParams['axes.unicode_minus'] = False


# Select a list of tasks for one device (can be customized)
# Here we manually select 5 task points (assuming this device is responsible for these 5 points)
task_indices = [0, 2, 5, 8, 13]  # e.g., T1, T3, T6, T9, T14 (using 0-based Python indexing)

# No optimization: connect in original order
def plan_path_no_opt(task_indices):
    # Ensure TASKS is a NumPy array for direct indexing if task_indices is a list of ints
    # If TASKS is a list of lists/tuples, convert selected tasks to NumPy array
    if isinstance(TASKS, list):
        tasks_to_process = np.array([TASKS[i] for i in task_indices])
    else: # Assuming TASKS is already a NumPy array
        tasks_to_process = TASKS[task_indices]

    path = [BASE]
    current = BASE
    for target_coords in tasks_to_process: # Iterate over coordinates directly
        segment = informed_rrt(np.array(current), np.array(target_coords))
        if segment and len(segment) > 0: # Check if segment is not None and not empty
            path.extend(segment[1:])  # Remove duplicate points
            current = target_coords # Update current to the actual coordinates of the target
        elif segment is None: # RRT failed to find a path
            print(f"Warning: RRT could not find a path from {current} to {target_coords}. Stopping path generation for this sequence.")
            return np.array(path) # Return partial path
    return np.array(path)

# Calculate total path length
def path_length(path):
    if path is None or len(path) < 2:
        return np.inf # Return infinity if path is invalid or too short
    return sum(np.linalg.norm(path[i+1] - path[i]) for i in range(len(path)-1))

if __name__ == "__main__":
    print("Starting trajectory optimization comparison simulation experiment...")

    # Unoptimized path
    no_opt_path = plan_path_no_opt(task_indices)
    no_opt_length = path_length(no_opt_path)
    print(f"Total length of unoptimized path: {no_opt_length:.2f} km")

    # Optimized path
    # Ensure TASKS is a NumPy array before passing to optimize_task_order and plan_full_path if they expect it
    tasks_for_opt = TASKS
    if isinstance(TASKS, list):
        tasks_for_opt = np.array(TASKS)

    opt_order_indices = optimize_task_order(task_indices, tasks_array=tasks_for_opt) # Pass the full TASKS array
    # opt_order_indices will be the reordered original indices from task_indices

    # plan_full_path expects coordinates, so we get them using the optimized order of original indices
    if opt_order_indices is not None and len(opt_order_indices) > 0:
        # Ensure opt_order_indices contains valid indices for tasks_for_opt
        # The indices in opt_order_indices are the original indices from TASKS,
        # but reordered.
        # We need to select the coordinates of these tasks from tasks_for_opt
        # Example: if task_indices = [0, 2, 5] and opt_order_indices = [5, 0, 2]
        # this means task 5 (original index) should be visited first, then task 0, then task 2.
        # So, we should pass TASKS[[5, 0, 2]] to plan_full_path
        ordered_task_coords = tasks_for_opt[opt_order_indices]
        opt_path = plan_full_path(BASE, ordered_task_coords) # Pass the coordinates in the optimized order
    else:
        print("Warning: Optimization did not return a valid order. Skipping optimized path generation.")
        opt_path = None # Or handle as an error
        opt_order_indices = [] # Ensure it's an empty list for saving

    opt_length = path_length(opt_path)
    print(f"Total length of the optimized path: {opt_length:.2f} km")

    # --- Data Saving Section ---
    print("\nStarting to save data...")

    # 1. Save unoptimized trajectory
    if no_opt_path is not None and len(no_opt_path) > 0:
        no_opt_df = pd.DataFrame(no_opt_path, columns=['X', 'Y'])
        no_opt_df.to_csv('unoptimized_trajectory_comp.csv', index=False)
        print("Unoptimized trajectory saved to unoptimized_trajectory_comp.csv")
    else:
        print("Unoptimized path is empty or not generated, not saving.")

    # 2. Save optimized trajectory
    if opt_path is not None and len(opt_path) > 0:
        opt_df = pd.DataFrame(opt_path, columns=['X', 'Y'])
        opt_df.to_csv('optimized_trajectory_comp.csv', index=False)
        print("Optimized trajectory saved to optimized_trajectory_comp.csv")
    else:
        print("Optimized path is empty or not generated, not saving.")

    # 3. Save selected task points for this comparison (based on task_indices)
    # Ensure TASKS is a NumPy array or a list that can be indexed
    try:
        # TASKS should be accessible here. Ensure it's defined and populated.
        # task_indices contains the original Python indices for TASKS
        tasks_to_save_data = []
        for original_py_idx in task_indices:
            # original_py_idx is the index in the original TASKS list/array
            # TASKS[original_py_idx] are the coordinates of this task
            if original_py_idx < len(TASKS): # Check bounds
                 tasks_to_save_data.append([original_py_idx, TASKS[original_py_idx][0], TASKS[original_py_idx][1]])
            else:
                 print(f"Warning: Task index {original_py_idx} is out of bounds for TASKS (length {len(TASKS)}).")


        if tasks_to_save_data:
            selected_tasks_df = pd.DataFrame(tasks_to_save_data, columns=['Original_Task_Python_Index', 'X', 'Y'])
            selected_tasks_df.to_csv('selected_tasks_for_comparison.csv', index=False)
            print(f"Task points participating in comparison (original indices: {task_indices}) saved to selected_tasks_for_comparison.csv")
        else:
            print("No valid selected tasks to save for comparison.")
    except IndexError as e:
        print(f"Error: One or more indices in task_indices {task_indices} are out of range for TASKS. Details: {e}")
    except TypeError as e:
        print(f"Error: TASKS might not be the expected type (e.g., NumPy array or list). Current type: {type(TASKS)}. Details: {e}")


    # 4. Save base coordinates
    if BASE is not None:
        base_df = pd.DataFrame([BASE], columns=['X', 'Y'])  # BASE should be [x, y]
        base_df.to_csv('base_point_comp.csv', index=False)
        print(f"Base coordinates {BASE} saved to base_point_comp.csv")

    # 5. Save path length comparison data (for bar chart)
    comparison_lengths_data = {
        'Method': ['Unoptimized', 'Optimized'],
        'Path_Length_km': [no_opt_length if no_opt_length != np.inf else 'N/A',
                           opt_length if opt_length != np.inf else 'N/A']
    }
    comparison_lengths_df = pd.DataFrame(comparison_lengths_data)
    comparison_lengths_df.to_csv('path_lengths_comp_data.csv', index=False)
    print("Path length comparison data saved to path_lengths_comp_data.csv")

    # 6. Save optimized task order (sequence of original task indices)
    if opt_order_indices and len(opt_order_indices) > 0: # Check if opt_order_indices is not None and not empty
        opt_order_df = pd.DataFrame(opt_order_indices, columns=['Optimized_Task_Python_Index_Sequence'])
        opt_order_df.to_csv('optimized_task_order_comp.csv', index=False)
        print(f"Optimized task index sequence {opt_order_indices} saved to optimized_task_order_comp.csv")
    else:
        print("Optimized task order not generated or is empty.")

    print("Data saving complete.\n")
    # --- Data Saving End ---

    # --- Plotting Trajectory Overlay ---
    fig, ax = plt.subplots(figsize=(10, 8))

    # Plot unoptimized trajectory
    if no_opt_path is not None and len(no_opt_path) > 1: # Ensure there are at least two points to plot a line
        ax.plot(no_opt_path[:,0], no_opt_path[:,1], 'r--', label='Unoptimized Trajectory')

    # Plot optimized trajectory
    if opt_path is not None and len(opt_path) > 1: # Ensure there are at least two points to plot a line
        ax.plot(opt_path[:,0], opt_path[:,1], 'b-', label='Optimized Trajectory')

    # Plot task points
    # Ensure TASKS is defined and accessible
    if 'TASKS' in globals() and TASKS is not None:
        for original_idx in task_indices: # Iterate through the original indices selected for this device
            if original_idx < len(TASKS): # Check bounds
                x, y = TASKS[original_idx]
                ax.plot(x, y, 'ko', markersize=7) # 'ko' for black circle
                # Displaying 1-based task number for human readability if desired
                ax.text(x + 0.3, y + 0.3, f'Task {original_idx + 1}', fontsize=9)
            else:
                print(f"Warning: Cannot plot task with original index {original_idx}, out of bounds.")
    else:
        print("Warning: TASKS variable not found or is None. Cannot plot task points.")


    if BASE is not None:
        ax.plot(BASE[0], BASE[1], 'gs', markersize=10, label='Base') # 'gs' for green square

    ax.set_xlim(-11, 11) # Adjust limits based on your coordinate system if necessary
    ax.set_ylim(-11, 11) # Adjust limits based on your coordinate system if necessary
    ax.set_xlabel('X (km)')
    ax.set_ylabel('Y (km)')
    ax.set_title('Comparison of Trajectories Before and After Optimization')
    ax.legend()
    ax.grid(True)
    plt.tight_layout()
    plt.show()

    # --- Plotting Path Length Bar Chart ---
    methods = ['Before Optimization', 'After Optimization']
    # Use np.nan for inf values if they are to be plotted or handled by plotting library
    # For simple bar chart, it's better to filter them or represent as a very large number if necessary
    # Or, as done before, use 'N/A' for CSV and skip plotting if inf
    values_for_plot = []
    if no_opt_length != np.inf:
        values_for_plot.append(no_opt_length)
    else:
        # Decide how to handle inf: skip, use a placeholder, or a very large number
        # For this plot, we'll skip if inf, or you can set a max displayable value
        print("Unoptimized path length is infinite, will not be plotted accurately in bar chart.")
        # values_for_plot.append(0) # Or some placeholder

    if opt_length != np.inf:
        values_for_plot.append(opt_length)
    else:
        print("Optimized path length is infinite, will not be plotted accurately in bar chart.")
        # values_for_plot.append(0) # Or some placeholder

    # Adjust methods list if any value was skipped
    if len(values_for_plot) < len(methods):
        # This logic needs to be more robust if you want to selectively remove methods
        # For simplicity, if one is inf, the bar chart might be misleading or incomplete.
        # Here, we'll plot what we have.
        if no_opt_length == np.inf and opt_length != np.inf:
            methods_for_plot = ['After Optimization']
            values_for_plot = [opt_length]
        elif no_opt_length != np.inf and opt_length == np.inf:
            methods_for_plot = ['Before Optimization']
            values_for_plot = [no_opt_length]
        elif no_opt_length == np.inf and opt_length == np.inf:
            methods_for_plot = []
            values_for_plot = []
        else: # Both are valid
            methods_for_plot = methods
            # values_for_plot is already set
    else:
        methods_for_plot = methods


    if values_for_plot: # Only plot if there's valid data
        plt.figure(figsize=(6,5))
        bars = plt.bar(methods_for_plot, values_for_plot, color=['red', 'blue'][:len(values_for_plot)])
        for bar in bars:
            yval = bar.get_height()
            plt.text(bar.get_x() + bar.get_width()/2, yval + 0.05 * max(values_for_plot, default=1), f'{yval:.1f}', ha='center', va='bottom') # Adjust text offset

        plt.ylabel('Total Path Length (km)')
        plt.title('Comparison of Trajectory Optimization Effects')
        plt.grid(axis='y', linestyle='--')
        plt.tight_layout()
        plt.show()
    else:
        print("No valid path lengths to plot for the bar chart.")

