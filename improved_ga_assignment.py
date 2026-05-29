import numpy as np
import random
from utils import safe_distance, segment_energy, run_time
from env_config import TASKS, BASE, VEHICLE_TYPE


def init_population(pop_size, num_devices):
    population = []
    for _ in range(pop_size):
        perm = list(np.random.permutation(len(TASKS)))
        split = np.array_split(perm, num_devices)
        population.append(split)
    return population


def fitness(individual):
    total_length = 0

    for sublist in individual:
        if len(sublist) == 0:
            continue
        path = np.vstack(([BASE], TASKS[sublist]))
        for i in range(len(path) - 1):
            total_length += safe_distance(path[i], path[i + 1])

    return total_length


def fitness2(individual):
    """适应度函数：总能耗（越低越好）"""
    # 若未指定车型，默认全为无人机s
    total_time = 0.0
    total_length = 0.0
    total_energy = 0.0
    for idx, sublist in enumerate(individual):
        if len(sublist) == 0:
            continue

        v_type = VEHICLE_TYPE[idx]
        path = np.vstack(([BASE], TASKS[sublist]))

        for i in range(len(path) - 1):
            total_energy += segment_energy(path[i], path[i + 1], v_type)
            dis= safe_distance(path[i], path[i + 1])
            total_length += dis
            total_time += run_time(dis, v_type)

    return 0.2*total_energy+0.4*total_length+0.4*total_time


def repair_individual(individual):
    """确保所有任务都被分配且不重复"""
    all_tasks = set(range(len(TASKS)))
    assigned_tasks = set()

    # 收集已分配的任务
    for sublist in individual:
        assigned_tasks.update(sublist)

    # 找出缺失的任务
    missing_tasks = list(all_tasks - assigned_tasks)

    # 如果有缺失任务，分配给第一个设备
    if missing_tasks:
        individual[0].extend(missing_tasks)

    # 去除重复任务（保留每个任务的第一个出现）
    seen = set()
    for sublist in individual:
        unique_sublist = []
        for task in sublist:
            if task not in seen:
                seen.add(task)
                unique_sublist.append(task)
        sublist[:] = unique_sublist

    return individual

def selection(population, scores):
    idx = np.argsort(scores)
    return [population[i] for i in idx[:len(population) // 2]]


def crossover(parent1, parent2):
    all_tasks = set(range(len(TASKS)))
    half = len(parent1) // 2

    # 拼接子代
    child = parent1[:half] + parent2[half:]
    child = [list(sublist) for sublist in child]

    # 展平并去重（保持顺序）
    flat = []
    for sublist in child:
        for task in sublist:
            if task not in flat:
                flat.append(task)

    # 补充缺失任务
    missing = list(all_tasks - set(flat))
    flat.extend(missing)

    # 重新分配到设备（保持各设备原有长度比例）
    lens = [len(sublist) for sublist in child]
    new_child = []
    idx = 0
    for l in lens:
        new_child.append(flat[idx:idx + l])
        idx += l

    return new_child


def gaussian_mutate(individual, rate=0.2, sigma=1.0):
    """高斯变异：基于距离的任务重分配"""
    for _ in range(int(rate * len(TASKS))):
        # 选择一个有任务的设备
        devices_with_tasks = [i for i, dev in enumerate(individual) if len(dev) > 0]
        if not devices_with_tasks:
            continue

        source_device = random.choice(devices_with_tasks)
        task_idx = random.randint(0, len(individual[source_device]) - 1)
        task = individual[source_device][task_idx]

        # 基于任务位置的高斯选择目标设备
        task_pos = TASKS[task]
        distances = [np.linalg.norm(task_pos - np.mean(TASKS[dev], axis=0)) if dev else np.inf
                     for dev in individual]

        # 高斯分布选择目标设备（距离越近概率越高）
        weights = np.exp(-np.array(distances) ** 2 / (2 * sigma ** 2))
        weights /= weights.sum()

        target_device = np.random.choice(len(individual), p=weights)

        if target_device != source_device:
            individual[source_device].pop(task_idx)
            individual[target_device].append(task)

    return individual


def cauchy_mutate(individual, rate=0.2, scale=1.0):
    """柯西变异：大幅度的任务重新分配"""
    for _ in range(int(rate * len(TASKS))):
        # 柯西分布选择变异强度
        mutation_strength = abs(np.random.standard_cauchy() * scale)
        num_swaps = min(int(mutation_strength) + 1, len(TASKS) // 2)

        # 执行多次交换
        for _ in range(num_swaps):
            a, b = np.random.randint(0, len(individual), 2)
            if individual[a] and individual[b]:
                idx1 = random.randint(0, len(individual[a]) - 1)
                idx2 = random.randint(0, len(individual[b]) - 1)
                individual[a][idx1], individual[b][idx2] = individual[b][idx2], individual[a][idx1]

    return individual


def adaptive_mutate(individual, rate=0.2, generation=0, max_generations=100):
    """自适应变异：根据进化阶段调整变异策略"""
    progress = generation / max_generations

    if progress < 0.3:
        # 早期：柯西变异，强探索
        return cauchy_mutate(individual, rate * 1.5, scale=2.0)
    elif progress > 0.7:
        # 后期：高斯变异，精细调整
        return gaussian_mutate(individual, rate * 0.5, sigma=0.5)
    else:
        # 中期：混合策略
        if random.random() < 0.5:
            return gaussian_mutate(individual, rate, sigma=1.0)
        else:
            return cauchy_mutate(individual, rate, scale=1.0)


def run_iga(generations=100, pop_size=50, num_devices=15):
    population = init_population(pop_size, num_devices)
    best_solution = None
    best_score = np.inf
    elite_ratio = 0.05  # Elite retention ratio
    base_mutate_rate = 0.2  # Initial mutation rate

    history_best = []

    for gen in range(generations):
        # --- Evaluating fitness ---
        scores = [fitness2(ind) for ind in population]

        # --- Update current best ---
        if min(scores) < best_score:
            best_score = min(scores)
            best_solution = population[np.argmin(scores)]

        history_best.append(best_score)

        # --- Elite Retention ---
        num_elite = max(1, int(elite_ratio * pop_size))
        elite_indices = np.argsort(scores)[:num_elite]
        elites = [population[i] for i in elite_indices]

        # --- choose ---
        selected = selection(population, scores)

        # --- Dynamic mutation rate adjustment ---
        if gen < generations * 0.3:
            mutate_rate = base_mutate_rate * 2  # More exploration in the early stages
        elif gen > generations * 0.7:
            mutate_rate = base_mutate_rate * 0.5  # Less convergence in the late stage
        else:
            mutate_rate = base_mutate_rate

        # --- Generate a new generation ---
        next_gen = elites.copy()
        while len(next_gen) < pop_size:
            p1, p2 = random.sample(selected, 2)
            child = crossover(p1, p2)
            child = adaptive_mutate(child, rate=mutate_rate,
                                    generation=gen, max_generations=generations)
            child = repair_individual(child)
            next_gen.append(child)

        population = next_gen

        if gen % 10 == 0:
            print(f"Generation {gen}: Best Score = {best_score:.2f}")

    return best_solution, history_best