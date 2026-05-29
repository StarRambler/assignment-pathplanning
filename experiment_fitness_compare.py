import pandas as pd
import matplotlib.pyplot as plt

# ================= 读取CSV =================
df1 = pd.read_csv('./outcmaes/scheduling/GA/ga_evolution_data.csv')
df2 = pd.read_csv('./outcmaes/scheduling/IGA/iga_evolution_data.csv')

# ================= 提取数据 =================
x1 = df1['Generation']
y1 = df1['Best_Total_Distance']

x2 = df2['Generation']
y2 = df2['Best_Total_Distance']

plt.rcParams['font.sans-serif'] = ['Microsoft YaHei']
# ================= 创建图像 =================
plt.figure(figsize=(10, 6))
plt.rcParams['axes.unicode_minus'] = False

# ================= 绘制曲线 =================
plt.plot(
    x1,
    y1,
    linewidth=2,
    label='EGA'
)

plt.plot(
    x2,
    y2,
    linewidth=2,
    label='IGA'
)

# ================= 标记最优点 =================
best_idx1 = y1.idxmin()
best_idx2 = y2.idxmin()

plt.scatter(
    x1[best_idx1],
    y1[best_idx1],
    s=80,
    marker='o'
)

plt.scatter(
    x2[best_idx2],
    y2[best_idx2],
    s=80,
    marker='s'
)

# ================= 坐标轴 =================
plt.xlabel('迭代次数', fontsize=12)
plt.ylabel('最优总距离', fontsize=12)

# ================= 标题 =================
plt.title('改进前后算法迭代对比图', fontsize=14)

# ================= 图例 =================
plt.legend()

# ================= 网格 =================
plt.grid(True, linestyle='--', alpha=0.6)

# ================= 紧凑布局 =================
plt.tight_layout()
plt.savefig('outcmaes/scheduling')
# ================= 显示 =================
plt.show()
