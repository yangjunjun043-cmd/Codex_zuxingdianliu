# 第二阶段第七步——最终综合分析与证据冻结

## 1. 任务范围与完整性

本步骤只读取、核对、统计和整合第一阶段及第二阶段既有冻结证据，没有重新运行仿真，没有修改 `AutoComp9`、M0/M2/M3/M4、`paper_method_v1`、门控阈值、VFF 参数、权重参数、随机种子、评价窗口或注册表。

纳入的正式证据包括：

- 第一阶段 A：统一基线与 Case01–Case06；
- 第一阶段 B：故障吸收机理、Case05/06 与受控因素试验；
- 第一阶段 C：M4/REW-AI、Case07/08、消融与方法冻结；
- 第二阶段 Step 2B-2：25 个确定性物理条件、100 个算法评估；
- 第二阶段 Step 3：Cself 与 CsAC 模型失配；
- 第二阶段 Step 4：13 个重叠物理点、52 条主评估及 Case08 反事实重放；
- 第二阶段 Step 5：局部敏感性与适用边界；
- 第二阶段 Step 6：H/F/O 各 50 个物理条件、600 个算法评估。

执行前核验结果为：第一阶段冻结清单 9/9 通过，第二阶段 Step 1 冻结文件 3/3 通过；Step 2–Step 6 正式结果文件均存在，Step 6 完整 CSV 为 600 行。正式 CSV 的关键统计已独立复算。

## 2. 最终论文因果主线

论文的核心因果链冻结为：

```text
真实阻性故障
↓
进入自适应辨识残差
↓
投影进入 coupling parameter subspace
↓
形成 fault-induced false Cs change
↓
产生错误 coupling compensation
↓
造成 resistive fault retention loss
```

第一阶段 B 在 Case05/06 中闭合了这条链。故障向量在 `col(X)` 上存在非零投影，几何可表达比例约为 0.275451；静态 `Delta c_LS,f` 与递归故障诱发偏置方向一致，后者约为 `+4.89/-4.88 pF`。由该虚假 Cs 产生的 B 相错误补偿约为故障基波增量的三分之一，且相位近似同相。M2 的故障倍率估计由真值 1.6 降至约 1.401–1.402；使用反事实参数轨迹后恢复至约 1.601–1.603。

因此，故障吸收不是数值发散，也不是物理投影或变化率约束越界，而是阻性故障残差与耦合参数子空间重叠后形成的有界偏置学习。

## 3. M2、M3 与 M4 的机制区别

| 算法 | 更新机制 | 已证实作用 | 主要代价或失败模式 |
|---|---|---|---|
| M2 | 持续执行 VFF-RLS 更新 | 正常漂移条件下具有参数跟踪能力 | 故障残差持续写入信息状态，形成 fault absorption |
| M3 | 固定阈值触发 hard gate，触发后冻结 | 强故障触发后通常具有最强故障保护 | 弱故障可能漏触发；重叠时同时停止真实漂移学习；对 `gate_ratio` 局部敏感 |
| M4/REW-AI | 根据 residual evidence 连续调节统一信息更新权重 `g` | 相对 M2 减少故障诱导学习，同时保持非零自适应 | 只能减慢而不能消除有偏学习；强故障保护通常弱于 M3；仍有 residual fault contamination |

M4 的创新位置不是“全面超过 M3”，而是把二值冻结改为连续、状态一致的信息加权，在 protection 与 adaptation 之间形成可解释的连续折中。

## 4. 最终结论与证据强度

| 结论 | 证据强度 | 最终判断 |
|---|---|---|
| C1：M2 存在 fault absorption | STRONG | 机理、Case05/06、故障幅值链、重叠矩阵及 Monte-Carlo F/O 证据一致 |
| C2：M3 表现为阈值型保护 | STRONG | 弱故障漏触发、强故障触发及 Monte-Carlo 触发/漏触发比例均得到验证 |
| C3：M3 hard freeze 存在真实漂移学习代价 | STRONG | Case08、带符号参数移动、反事实重放和 Monte-Carlo O 均支持 |
| C4：M4 实现连续 residual-evidence weighting | STRONG | 确定性幅值链、重叠矩阵、局部敏感性及 Monte-Carlo 权重分布共同支持 |
| C5：M4 相对 M2 减少部分 fault absorption | STRONG | 确定性、重叠矩阵和 N=50 配对统计方向一致，但改善幅度依条件而变 |
| C6：M4 与 M3 构成 protection–tracking trade-off | STRONG | 强故障下 M3 更强，M4 保持非零更新；Monte-Carlo 中约半数条件各有优劣 |
| C7：存在明确 validity boundaries | MODERATE | 多因素边界得到描述性验证，但各子边界强度不同，负序内部约定仍未解决 |
| C8：Case08 反事实分解可用于操作性解释 | MODERATE | 分解恒等式数值闭合，但不是 perfect causal identification |

### 4.1 C1——M2 故障吸收

Case05/06 中，M2 的故障诱发 Cs 偏置约为 `+4.9/-4.9 pF`，故障保持误差约为 -12.4%。第二阶段确定性故障幅值链显示，M2 参数偏置范数随故障强度增加而扩大；重叠矩阵中 M2 的 `F_minus_CF_norm_pF` 约为 1.15–6.95 pF。Monte-Carlo F 组中，M2 的 `Cs_fault_induced_bias_norm_pF` 均值为 2.67428 pF，`fault_retention_error_pct` 均值为 -8.34146%。这些结果把投影机理、虚假参数变化和故障保持损失连接起来。

### 4.2 C2——M3 阈值行为

确定性故障幅值链中，M3 在 1.05–1.30 的两类序列均未触发，在 1.40 的两个点触发，门控比例为 0.96。重叠矩阵中，M3 在 1.10/1.30 点不触发，在 1.60 点全程触发。Monte-Carlo F 组中，M3 在 35/50 条件未触发，在 15/50 条件触发；O 组中触发 16/50。

触发后的保护作用明确：F 组 15 个实际触发条件中，M3 的绝对故障保持误差均值为 4.99223%，同条件 M2 为 11.6322%。但这些结果只能定位已测试条件中的转变区域，不能据此声明精确、普适的检测阈值。

### 4.3 C3——M3 hard-freeze 代价

Case08 强故障重叠中，M3 在门控区间的 F 分支参数移动为零，而真实漂移约为 `[+1.307679,-0.871786] pF`。Step 4 操作性分解中，M3 的 `P-N=[-0.923983,+0.613373] pF`，表示保护日程减少了真实漂移学习；与此同时，`F-A` 与 `P-N` 部分抵消，使表面的 `F-N` 仅为 `[+0.023367,-0.423509] pF`。因此，较小的 `F-N` 不能单独解释为“故障影响已被纯净消除”。

Monte-Carlo O 组中，M3 有 7/50 个条件出现故障诱导移动与真实漂移向量点积为负；其 `post_fault_AUC_pF_s` 均值为 0.135134，高于 M2 的 0.0786279 和 M4 的 0.0763373。这些结果保留了 hard freeze 的漂移损失和释放后记忆代价。

### 4.4 C4——M4 连续加权

确定性幅值链中，M4 的 `mean_update_weight` 随故障因子增强由约 0.916 降至约 0.465；重叠矩阵中，不同速率下因子 1.10/1.30/1.60 的权重大致从 0.80–0.82、下降至 0.54–0.55、再下降至 0.356–0.360。该趋势支持连续响应，但不升级为全局严格单调定理。

局部敏感性进一步表明，Case08 上 `gate_ratio` 从 1.008、1.120 到 1.232 时，M4 平均更新权重由 0.033545、0.360041 增至 0.523789，始终保持非零更新。Monte-Carlo 中，F 组 M4 权重均值为 0.647979；O 组均值为 0.625597，范围为 0.348990–0.866241。正常 H 组均值为 0.974256，说明正常条件下主要保持更新，但仍存在小幅不必要抑制。

### 4.5 C5——M4 相对 M2 的作用

确定性故障幅值链中，M4 在 10/10 条件同时减小了 M2 的绝对保持误差和故障诱发偏置范数；Step 4 的 13/13 重叠点中，M4 减小了 M2 的保持误差与 `F-CF` 移动范数。

正式 Monte-Carlo 配对结果为：

- F 组：M4 在 36/50 条件中具有更小的绝对故障保持误差，在 33/50 条件中具有更小的故障诱发参数偏置范数；
- O 组：M4 在 33/50 条件中具有更小的参数跟踪误差，在 43/50 条件中具有更小的 W1/W2 综合保持距离，在 40/50 条件中具有更小的 `F_minus_CF_norm_pF`。

这些计数是配对证据，不转换为“胜率评分”。F 组 M4 相对 M2 的平均改善幅度较小，且存在未改善条件，因此结论限定为“多数已测条件中减少部分故障吸收”。

### 4.6 C6——M4 相对 M3 的折中

强故障触发后，M3 通常具有更强保护。Case08 中 M3/M4 的故障诱发移动范数分别为 0.424153/6.402670 pF，平均保持比分别接近 0.968/0.745；M4 保留了非零更新，但也保留了显著故障污染。

Monte-Carlo F 组中，M4 相对 M3 的绝对保持误差改善计数为 25/50，偏置范数改善计数为 22/50。O 组中，M4 相对 M3 的跟踪、综合保持和 `F-CF` 改善计数分别为 26/50、27/50、26/50。该近似对半分布直接支持 trade-off，而不支持 M4 全面优于 M3。

### 4.7 C7——适用边界

| 因素 | 已测范围 | 主要观察 | 证据强度与限制 |
|---|---|---|---|
| 参考相位误差 | 0–3° | 3° 时 M2/M3/M4 的 B 相误差绝对值约 38.986%/43.319%/39.471% | STRONG 边界证据；仅对应冻结的一致相位偏差模型 |
| 负序 | 0–5% | 1% 已明显退化，5% 时 M4 B 相误差约 61.848% | UNRESOLVED；`NEGATIVE_SEQUENCE_INTERNAL_CONVENTION` 未解决，只能作为配置边界 |
| Cself 失配 | -10%–+10% | 参数误差随幅值总体扩大且方向不对称；M2/M3/M4 基本重合 | MODERATE；weighting 不能消除共同模型偏差，未事后设置安全阈值 |
| CsAC 失配 | 0–3 pF | Cs2 侧更明显；3 pF 时 M4 RMSE 范数约 0.840 pF | MODERATE；未建模结构偏差未被 weighting 根本消除 |
| 漂移速率 | 0.5×–2× | 误差响应非单调；强故障下 M3 冻结、M4 保留非零更新 | LIMITED；只覆盖注册组合 |
| 漂移方向 | D1/D2/D3 | 确定性扩展中 M2/M3/M4 的反向点为 2/6、3/6、2/6 | LIMITED；direction evidence 仅作诊断 |
| 参数敏感性 | 注册低值/名义/高值 | `gate_ratio` 最敏感；其他两项在单一锚点形成局部平台 | LIMITED；不是参数优化或最优性证明 |

M4 不解决所有 model mismatch。参考相位误差是明显敏感因素；负序仍属于 configured validity boundary；Cself/CsAC 偏差不能由连续权重根本消除；方向信息不具故障特异性。

## 5. Case08 反事实重放的最终解释

冻结四条轨迹定义为：

- `F`：含故障数据与原保护日程；
- `N`：无故障反事实数据与原无故障日程；
- `P`：无故障数据配合故障分支保护日程；
- `A`：含故障数据配合匹配的适应日程。

分解恒等式为：

```text
F-N = (F-A) + (A-P) + (P-N)
```

其中：

- `F-A`：匹配适应日程下剩余的故障相关作用；
- `A-P`：VFF/适应日程贡献；
- `P-N`：保护日程造成的真实漂移学习减少。

M3 的分解为：`F-A=[+0.915123,-0.981061] pF`，`A-P=[+0.032228,-0.055821] pF`，`P-N=[-0.923983,+0.613373] pF`，最终 `F-N=[+0.023367,-0.423509] pF`。较小的表面 `F-N` 由多项相互抵消形成。

M4 的分解为：`F-A=[+4.575018,-4.578660] pF`，`A-P=[+0.175127,-0.121210] pF`，`P-N=[-0.237935,+0.157388] pF`，最终 `F-N=[+4.512210,-4.542482] pF`。M4 的主要残余问题仍是 `F-A` 所代表的 fault-related contamination。

两种算法的恒等式残差均为 0，重放等价门通过 `1e-12` 容差。该分解只作 operational counterfactual decomposition，不声称实现完美因果识别。

## 6. Monte-Carlo 最终证据

### 6.1 H 组

M4 的 `unnecessary_suppression_ratio` 均值为 0.025744，P95 为 0.087019，最大值为 0.115889。M4 与 M2/M3 的两参数 RMSE 差异范数中位数仅 0.001217 pF；M4 的 B 相误差绝对值仅在 3/50 条件优于 M2/M3。正常工况代价总体较小，但不是零。

### 6.2 F 组

M3 触发 15/50、漏触发 35/50。M4 相对 M2 的保持/偏置改善计数为 36/50、33/50；相对 M3 为 25/50、22/50。M4 的平均更新权重为 0.647979。最差有效条件保留在正式 CSV 中，没有删除极端点。

### 6.3 O 组

M3 触发 16/50。M4 权重均值为 0.625597，中位数为 0.620693，P5/P95 为 0.366525/0.861716。M4 相对 M2 的跟踪/综合保持/污染改善计数为 33/50、43/50、40/50；相对 M3 为 26/50、27/50、26/50。反向移动条件为 M2=0/50、M3=7/50、M4=0/50。M4 的 `post_fault_AUC_pF_s` 均值/P95 为 0.0763373/0.165557。

三组统计不构成总体算法排名。

## 7. 报告与正式 CSV 一致性审计

本步骤按正式 CSV 复算并核对了以下项目：

- Step 2B-2 的 M3 触发点、M4 权重与故障幅值关系；
- Step 3 的 Cself/CsAC 误差、方向不对称与门控/权重行为；
- Step 4 的 52 条主记录、重放记录和分解恒等式；
- Step 5 的 `gate_ratio` 局部敏感性；
- Step 6 的 600 行完整性、H/F/O 各 50 条物理条件及全部配对计数。

未发现需要阻止冻结的报告—CSV 数值矛盾。需要特别说明的是：负序内部约定仍为 `UNRESOLVED`，但这是已声明的解释边界，不是数据文件之间的冲突。

## 8. 论文作图规划

| Figure ID | 论文目的 | 数据来源 | 横轴 | 纵轴 | 算法 | 建议图型 | source file / metric | 优先级 |
|---|---|---|---|---|---|---|---|---|
| Fig.1 | 展示 fault absorption 因果链与 REW-AI 连续加权位置 | 第一阶段 B/C 方法定义 | 机制流程 | 物理量与算法状态 | M2/M3/M4 | 机制框图 | `PHASE1B_FAULT_ABSORPTION_REPORT.md`；`PHASE1C_M4_METHOD_REPORT.md` | CORE |
| Fig.2 | 展示 Case05/06 中虚假 Cs 与保持损失 | 第一阶段 B Case05/06 | 时间或故障阶段 | Cs 偏置、故障倍率 | M2/M3/M4 | 轨迹图与局部放大 | `case05_case06_comparison.csv`；`fault_preservation_summary.csv` | CORE |
| Fig.3 | 展示故障强度、保持误差和参数偏置关系 | Step 2B-2 | `fault_factor` | 绝对保持误差、偏置范数 | M2/M3/M4 | 双面板折线图 | `step2b2_deterministic_results.csv` | CORE |
| Fig.4 | 对比 M3 离散门控与 M4 连续权重 | Step 2B-2、Step 4 | `fault_factor` | `hard_gate_active_ratio`、`mean_update_weight` | M3/M4 | 阶梯线与连续线 | `step2b2_deterministic_results.csv`；`step4_overlap_results.csv` | CORE |
| Fig.5 | 展示 drift-rate × fault-factor 重叠折中 | Step 4 | 漂移速率与故障因子 | 跟踪误差、保持距离、污染 | M2/M3/M4 | 分面热图或气泡图 | `step4_overlap_results.csv` | CORE |
| Fig.6 | 解释 Case08 的 F/N/P/A 分解 | Step 4 replay | 分解项 | 带符号 Cs1/Cs2 移动 | M3/M4 | 分组堆叠或向量图 | `step4_overlap_results.csv` 中 `F_minus_A`、`A_minus_P`、`P_minus_N` | CORE |
| Fig.7 | 汇总相位、负序、Cself、CsAC 适用边界 | Step 2B-2、Step 3 | 各因素水平 | 参数 RMSE 与 B 相误差 | M2/M3/M4 | 四面板折线图 | `step2b2_deterministic_results.csv`；`step3_model_mismatch_results.csv` | CORE |
| Fig.8 | 展示门控参数局部敏感性 | Step 5 | 参数低值/名义/高值 | 门控比例、权重、移动范数 | M3/M4 | 分组点线图 | `step5_sensitivity_results.csv` | SUPPLEMENTARY |
| Fig.9 | 展示 H/F/O 总体分布与尾部 | Step 6 | 指标或 cohort | 分布统计 | M0/M2/M3/M4 | 箱线图或小提琴图 | `step6_monte_carlo_full_results.csv` | OPTIONAL |
| Fig.10 | 展示条件内 M4-M2 与 M4-M3 配对差异 | Step 6 | 配对差异 | 条件排序或经验累积分布 | M4-M2、M4-M3 | 配对差异点图或 ECDF | `step6_monte_carlo_full_results.csv` | CORE |

正文优先保留 Fig.1、Fig.2、Fig.3、Fig.4、Fig.5、Fig.6、Fig.7、Fig.10，共 8 张；Fig.9 可按版面进入正文或补充材料，Fig.8 优先放补充材料。

## 9. 正文与补充材料的数据分配

正文应使用：

- Case05/06 的投影—虚假 Cs—错误补偿—保持损失闭环；
- 故障幅值链中 M3 阈值切换与 M4 连续权重；
- Step 4 重叠矩阵的核心速率×强度结果；
- Case08 的 F/N/P/A 操作性分解；
- 相位、负序、Cself、CsAC 的主要边界；
- N=50/cohort 的配对改善计数与关键分布统计。

补充材料应保留：

- 完整 25 条确定性条件表；
- Cself/CsAC 全部水平；
- D1/D2/D3 全部带符号移动；
- Step 5 的全部局部敏感性记录；
- Monte-Carlo 600 行极端条件、完整分位数及全部算法明细。

## 10. 论文结果章节建议结构

### 4.1 统一基线与故障吸收机理

说明统一数据入口、M2 故障吸收的投影机制及 Case05/06 因果闭环。

### 4.2 确定性故障强度验证

展示故障强度增加时 M2 偏置扩大、M3 阈值切换及 M4 连续权重响应。

### 4.3 同时漂移—故障下的保护—跟踪折中

使用速率×强度矩阵、方向扩展和带符号移动比较 M2/M3/M4。

### 4.4 Case08 反事实重放

解释 F/N/P/A 与 `F-N=(F-A)+(A-P)+(P-N)`，强调操作性分解及相互抵消现象。

### 4.5 鲁棒性与适用边界

整合参考相位、负序、Cself、CsAC、漂移速率和漂移方向。

### 4.6 局部敏感性分析

报告 `gate_ratio` 的明显敏感性及其他参数在单一锚点的局部平台，不作调参结论。

### 4.7 Monte-Carlo 统计验证

分别报告 H/F/O，不建立综合评分；突出条件内配对统计和尾部结果。

### 4.8 局限性

明确 M4 的残余故障污染、M3 的阈值与冻结代价、模型失配边界、负序未解决约定及仿真证据外推限制。

## 11. 最终创新点冻结

论文创新点冻结为：

1. 揭示真实阻性故障通过耦合参数子空间投影进入自适应辨识并形成 fault-induced parameter absorption 的完整机制；
2. 提出 residual-evidence weighted adaptive identification，以连续且状态一致的权重调节信息更新，而不是仅采用 binary freeze；
3. 建立 hard gate 与 continuous weighting 在 fault/drift overlap 中的 protection–tracking trade-off，并用带符号参数移动和反事实重放解释二者差异；
4. 通过确定性矩阵、操作性反事实、局部敏感性和 N=50/cohort Monte-Carlo 多层证据，确定方法的有效区间与失败边界。

大量仿真、Monte-Carlo 数量和模型外观不作为创新点。

## 12. 最终限制

1. M4 不能完全消除 fault absorption，也不是故障/漂移的完美分离器。
2. 强故障触发后，M3 的故障保护通常强于 M4。
3. M3 会漏过部分弱故障，并可能在重叠条件中损失真实漂移学习。
4. M4 的非零更新同时保留了 adaptation 与 residual fault contamination。
5. 参考相位误差是明显敏感因素。
6. 负序内部约定仍未完全建立，只能作为 configured validity boundary。
7. Cself 与 CsAC 模型偏差不能由 M4 权重根本消除。
8. 方向证据仅能用于诊断，不能直接作为故障判据。
9. 局部敏感性不等于参数最优性；本步骤没有调参。
10. 现有结论来自冻结仿真体系，不能直接外推为现场普遍性能。

## 13. 冻结结论

现有证据足以支持第二阶段正式冻结。支持范围是：M4/REW-AI 提供一种连续、可解释的 protection–adaptation 调节机制；相对 M2，它在多数已测故障及重叠条件中减少故障吸收；相对 M3，它保留更多连续自适应，但在强故障保护上通常较弱。所有负结果、失败边界和未解决问题均已保留。

本结论不包含“普遍最优”“模型失配普遍鲁棒”“完全消除故障吸收”或“完美因果识别”。

## 14. 最终状态

```text
STEP 7 STATUS:
PASS

PHASE 1 EVIDENCE INTEGRATED:
YES

PHASE 2 DETERMINISTIC EVIDENCE:
COMPLETE

MODEL-MISMATCH EVIDENCE:
COMPLETE

OVERLAP / REPLAY EVIDENCE:
COMPLETE

SENSITIVITY EVIDENCE:
COMPLETE

MONTE-CARLO EVIDENCE:
COMPLETE

FINAL CLAIM MAP:
COMPLETE

PAPER FIGURE PLAN:
COMPLETE

FROZEN SOURCE MODIFIED:
NO

PHASE 2 STATUS:
COMPLETE

READY FOR PAPER FIGURE STAGE:
YES

READY FOR PAPER WRITING:
YES
```
