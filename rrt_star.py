import numpy as np
import random
from utils import in_obstacle, safe_distance


def informed_rrt(start, goal, max_iter=3000):
    nodes = [start]
    parents = {tuple(start): None}

    for _ in range(max_iter):
        sample = goal if random.random() < 0.2 else np.random.uniform(-10, 10, size=2)
        dists = [np.linalg.norm(np.array(n) - sample) for n in nodes]
        nearest = nodes[np.argmin(dists)]
        direction = sample - nearest
        if np.linalg.norm(direction) == 0:
            continue
        direction = direction / np.linalg.norm(direction) * 1.0
        new_node = nearest + direction

        if in_obstacle(new_node[0], new_node[1]):
            continue
        if collision(nearest, new_node):
            continue

        nodes.append(new_node)
        parents[tuple(new_node)] = tuple(nearest)

        if np.linalg.norm(new_node - goal) < 1.0:
            path = [goal]
            current = tuple(new_node)
            while current is not None:
                path.append(np.array(current))
                current = parents.get(current, None)
            return path[::-1]
    return None


def collision(p1, p2):
    steps = int(np.linalg.norm(p2 - p1) / 0.5)
    for i in range(steps + 1):
        u = i / steps
        x = p1[0] * (1 - u) + p2[0] * u
        y = p1[1] * (1 - u) + p2[1] * u
        if in_obstacle(x, y):
            return True
    return False