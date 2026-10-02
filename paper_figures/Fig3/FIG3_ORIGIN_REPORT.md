# Fig.3 Origin 绘图验收报告

## 输出

- Origin 工程：`paper_figures/Fig3/Fig3.opju`
- 论文预览图：`paper_figures/Fig3/Fig3_preview.png`（300 dpi）
- 高分辨率图：`paper_figures/Fig3/Fig3_600dpi.png`（600 dpi）

## 子图数据与曲线

| 子图 | 输入 CSV | Y 曲线数量 | 曲线 |
|---|---|---:|---|
| Fig.3(a) Fault-induced parameter bias | `fig3a_bias_norm.csv` | 3 | VFF-RLS, HG-VFF-RLS, REW-VFF-RLS |
| Fig.3(b) Fault retention error | `fig3b_retention_error.csv` | 3 | VFF-RLS, HG-VFF-RLS, REW-VFF-RLS |
| Fig.3(c) Hard-gate / continuous update-weight response | `fig3c_gate_weight.csv` | 2 | HG-VFF-RLS gate, REW-VFF-RLS weight |

三个 CSV 均直接导入对应 Origin workbook：`Fig3A_Data`、`Fig3B_Data`、`Fig3C_Data`。`fig3_master.csv` 仅用于数据整理阶段的交叉核对，本绘图脚本未从 master 读取或重新生成作图指标。

## X 数据点

`1.05, 1.10, 1.20, 1.30, 1.40, 1.60`

X 轴使用数值轴，数据点保持真实数值间距。没有分类等距处理或人为横向偏移。

## 图形结构与样式

- Origin 图页：`Fig3A_Bias`、`Fig3B_Retention`、`Fig3C_GateWeight`、`Fig3_Combined`。
- 组合图采用上排 (a)+(b)、下排 (c) 跨双栏宽度的 2+1 布局。
- 全部曲线均为 line + symbol，点间使用直线连接，仅作为视觉引导。
- Fig.3(c) 两条曲线使用同一左 Y 轴，范围为 0–1；未使用双 Y 轴。
- Fig.3(c) 未使用 step plot，未绘制阈值竖线，未增加门控切换点。
- 三种方法同时使用不同 symbol shape 与 line style 区分，并保留轻量颜色以兼顾屏幕和黑白打印。
- 图中方法名仅使用 VFF-RLS、HG-VFF-RLS、REW-VFF-RLS。
- 1.60 frozen anchor 正常绘制，未添加醒目的 anchor 标记。

## 数据与处理检查

- Fig.3(a)：6 个 X 点 × 3 个 Y 系列；无额外点。
- Fig.3(b)：6 个 X 点 × 3 个 Y 系列；无额外点。
- Fig.3(c)：6 个 X 点 × 2 个 Y 系列；无额外点。
- Fig.3(c) 全部 Y 值位于 0–1。
- HG-VFF-RLS gate：1.05–1.30 为 0；1.40 与 1.60 为 0.96。
- 未修改任何输入 CSV；绘图前后 SHA-256 一致。

DATA_MODIFIED = NO

SIMULATION_RERUN = NO

SMOOTHING = NO

FITTING = NO

INTERPOLATION = NO

ARTIFICIAL_POINTS = NO
