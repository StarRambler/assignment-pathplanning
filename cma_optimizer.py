import numpy as np
import cma
from rrt_star import informed_rrt
from env_config import BASE, TASKS

def plan_full_path(start, task_list):
    full_path = []
    current = start
    for target in task_list:
        path = informed_rrt(np.array(current), np.array(target))
        if path:
            if full_path:
                full_path.extend(path[1:])
            else:
                full_path.extend(path)
            current = target
    return np.array(full_path)

def path_cost(path):
    if path is None or len(path) < 2:
        return np.inf
    dist = sum(np.linalg.norm(path[i+1] - path[i]) for i in range(len(path)-1))
    return dist

def optimize_task_order(task_indices):
    if len(task_indices) <= 1:
        return task_indices  # There are only 0 or 1 mission points, no optimization is required
    tasks = TASKS[task_indices]
    def evaluate(order):
        order = np.argsort(order)
        ordered_tasks = [tasks[i] for i in order]
        path = plan_full_path(BASE, ordered_tasks)
        return path_cost(path)

    init_guess = np.random.rand(len(task_indices))
    es = cma.CMAEvolutionStrategy(init_guess, 0.5)
    es.optimize(evaluate)

    best_order = np.argsort(es.result.xbest)
    return [task_indices[i] for i in best_order]