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
def selection(population, scores):
    idx = np.argsort(scores)
    return [population[i] for i in idx[:len(population) // 2]]


def crossover(parent1, parent2):
    all_tasks = list(range(len(TASKS)))
    half = len(all_tasks) // 2
    child = parent1[:half] + parent2[half:]
    child = [list(sublist) for sublist in child]
    flat = [item for sublist in child for item in sublist]
    missing = set(all_tasks) - set(flat)
    for m in missing:
        child[random.randint(0, len(child) - 1)].append(m)
    return child


def mutate(individual, rate=0.2):
    for _ in range(int(rate * len(TASKS))):
        a, b = np.random.randint(0, len(individual), 2)
        if individual[a] and individual[b]:
            idx1 = random.randint(0, len(individual[a]) - 1)
            idx2 = random.randint(0, len(individual[b]) - 1)
            individual[a][idx1], individual[b][idx2] = individual[b][idx2], individual[a][idx1]
    return individual


def run_ga(generations=100, pop_size=50, num_devices=15):
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
            child = mutate(child, rate=mutate_rate)
            next_gen.append(child)

        population = next_gen

        if gen % 10 == 0:
            print(f"Generation {gen}: Best Score = {best_score:.2f}")

    return best_solution, history_best