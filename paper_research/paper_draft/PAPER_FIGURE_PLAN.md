# 论文核心图规划

## 0. 总体原则

正文规划 8 张核心图，优先使用 multi-panel 合并机制、对照与边界，避免把实验数量等同于证据强度。所有正式图片都应从下列冻结 CSV/MAT/FIG 重新排版生成，不能改变数据、窗口、算法参数或工况定义。本阶段不制作正式图片。

路径约定：缩写路径 `phase1a_baseline/`、`phase1b_fault_absorption/`、`phase1c_m4_method/`、`phase2_full_validation/` 均相对于项目目录 `paper_research/`。

正文推荐顺序为 Fig.1–Fig.8。局部敏感性的完整图、完整 25 条 deterministic 条件、全部方向点和 Monte-Carlo 全量极端记录优先进入补充材料。

## Fig.1 MOA 自适应监测、故障吸收与 REW-AI 整体机理框架

1. **Scientific purpose：** 用一张图建立全文因果主线：dynamic coupling 需要 adaptive identification；真实阻性故障污染 residual；可表达分量进入 coupling-parameter subspace；形成 false Cs、false compensation 和 retention loss；M3 与 M4 分别提供 hard freeze 与 continuous information weighting。
2. **Source data file：** 概念与方程来自 `paper_research/phase1b_fault_absorption/PHASE1B_FAULT_ABSORPTION_REPORT.md`、`paper_research/phase1c_m4_method/step6_ablation/PAPER_METHOD_V1_FREEZE.md`、`paper_research/phase2_full_validation/step7_final_analysis/PHASE2_FINAL_ANALYSIS.md`。不使用新仿真数据。
3. **x/y variables：** 无传统数值坐标；横向流程为物理系统 → 回归残差 → 投影/参数学习 → 补偿输出；纵向分支为 M2/M3/M4。
4. **Algorithms compared：** M2 持续更新、M3 二值冻结、M4/REW-AI 连续权重。
5. **Planned panels：** (a) 三相 MOA 与 AB/BC coupling；(b) `y=Xc_true+r_fault+n` 与 `P_Xr_fault`；(c) fault absorption chain；(d) M3 `g∈{0,1}` 与 M4 `0<g<=1` 对 information-state increment 的作用位置。
6. **Expected claim：** 本文首先解释 fault absorption mechanism，再提出状态一致的连续信息加权抑制；M4 的定位是 trade-off mechanism，不是“新 RLS 名称”。
7. **Claim strength：** `STRONG`（机理与方法结构）；不包含性能普适性声明。
8. **Plotting caution：** M4 权重必须画在 `J/h/baseIn` 的信息增量上，不能画成对已求得 `Delta Cs` 的事后乘权；direction evidence 不进入控制路径；Cself/CsAC 不得画成已在线辨识。
9. **Hardware supplement：** 后续不需要硬件复刻框图，但可在第 5 章实验平台图中沿用同一信号链标注。

## Fig.2 Case05/Case06 fault absorption mechanism trajectories

1. **Scientific purpose：** 以两个 representative cases 把故障发生、false Cs movement、错误补偿、fault factor attenuation 与 counterfactual restoration 串成可视化闭环。
2. **Source data file：** `paper_research/phase1b_fault_absorption/step2/case05_mechanism_summary.csv`、`step2/case05_key_metrics.csv`、`step3/case06_mechanism_summary.csv`、`step3/case06_key_metrics.csv`、`step3/case05_case06_comparison.csv`；MAT 源为 `case05_mechanism_workspace.mat`、`case06_mechanism_workspace.mat`；可复用现有 `.fig` 视觉元素，但正式图重绘应直接读数据。
3. **x/y variables：** x 为 time/cycle；y 依次为 fault factor、`Cs1/Cs2` truth 与 estimates、false B-phase coupling compensation/current increment、estimated fault factor。摘要面板可用 `Delta Cs` 与 factor 的离散对比。
4. **Algorithms compared：** 主线 M2 actual 与 M2 counterfactual；辅助对照 M3，必要时加入 M4 但不让本图变成算法排名图。
5. **Planned panels：** (a) Case05 fault-only 的 fault onset 与 Cs false drift；(b) Case05 `r_parallel/r_perp` 或 `eta_geom`；(c) false compensation 与 fault increment 的基波幅相关系；(d) Case05/06 actual factor 与 counterfactual-restored factor；(e) Case06 true drift 与 fault-induced additional movement 的区分。
6. **Expected claim：** Case05/06 中真实阻性故障产生约 `+4.89/-4.88 pF` 的递归虚假偏置；错误补偿约占故障基波增量三分之一；M2 factor 从真值 1.6 降至约 1.401–1.402，反事实参数恢复至约 1.601–1.603。
7. **Claim strength：** `STRONG`。
8. **Plotting caution：** counterfactual curve 必须明确标注为 analysis branch，不是在线可用信号；Case05 与 Case06 的窗口不能混用；不能用双 y 轴制造视觉相关；`eta_geom` 不画成 retention predictor。
9. **Hardware supplement：** 是。Experiment B 应补充 fault-only 下参数漂移和阻性故障保持趋势；Experiment C 可补充 drift+fault 趋势，但不要求硬件实现完整 counterfactual replay。

## Fig.3 Fault severity validation

1. **Scientific purpose：** 展示故障程度增加时 M2 fault-induced bias/retention、M3 threshold behavior 与 M4 continuous weight 的共同变化。
2. **Source data file：** `paper_research/phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；1.60 anchor 从 `paper_research/phase1a_baseline/baseline_summary.csv` 与 `paper_research/phase1c_m4_method/step4_fault_preservation/tables/fault_preservation_summary.csv` 按 registry reuse 规则补入；注册关系见 `paper_research/phase2_full_validation/step1_matrix_spec/phase2_condition_registry.csv`。
3. **x/y variables：** x=`fault_factor` 1.05–1.60；y1=`Cs_fault_induced_bias_norm_pF`；y2=`abs(fault_retention_error_pct)`；y3=M3 `hard_gate_active_ratio`；y4=M4 `mean_update_weight`。
4. **Algorithms compared：** M2/M3/M4；fault-only 与 drift-then-fault 用线型或小面板区分，不混成重复独立样本。
5. **Planned panels：** (a) M2/M3/M4 bias norm；(b) absolute retention error；(c) M3 gate ratio 与 M4 mean `g` 的同 x 对照；(d) 可选用带符号 `Delta Cs1/Delta Cs2` 小图确认方向。
6. **Expected claim：** M2 bias/loss 随已测 severity 总体扩大；M3 在已测转变区呈离散切换；M4 权重约从 0.916 连续降至 0.36–0.47，并在 10/10 新幅值条件中相对 M2 减小 retention error 与 bias norm。
7. **Claim strength：** `STRONG`（限已测范围）。
8. **Plotting caution：** 不用平滑拟合暗示精确阈值或全局单调定理；1.60 是冻结 anchor reuse，图注必须说明不是 Step 2B-2 新运行；retention error 建议显示绝对值同时在图注保留原始负号含义。
9. **Hardware supplement：** 是。Experiment B 可选择弱/中/强三个等级验证主要趋势，无需复刻全部幅值点。

## Fig.4 M3 hard gate 与 M4 continuous weighting

1. **Scientific purpose：** 直接对比 M3 的 threshold/step-like 行为与 M4 的连续、非零、状态一致权重，并显示 weak-fault miss 与强故障响应。
2. **Source data file：** Phase 1C Case07/08：`paper_research/phase1c_m4_method/step5_simultaneous_drift_fault/diagnostics/m3_fault_cycle_diagnostics.csv`、`paper_research/phase1c_m4_method/step5_simultaneous_drift_fault/diagnostics/m4_fault_cycle_diagnostics.csv`、`paper_research/phase1c_m4_method/step5b_triggered_overlap/diagnostics/m3_fault_cycle_diagnostics.csv`、`paper_research/phase1c_m4_method/step5b_triggered_overlap/diagnostics/m4_fault_cycle_diagnostics.csv`；局部敏感性：`paper_research/phase2_full_validation/step5_sensitivity_validity/step5_sensitivity_results.csv`。
3. **x/y variables：** 时间面板 x=time，y=M3 gate active 与 M4 `g`；敏感性面板 x=`gate_ratio` low/nominal/high，y=M3 gate ratio、M4 mean `g` 与 fault-induced movement norm。
4. **Algorithms compared：** M3、M4；M2 只作为 `g=1` 参考线。
5. **Planned panels：** (a) Case07 factor 1.30：M3 gate=0、M4 `g≈0.546`；(b) Case08 factor 1.60：M3 gate=1、M4 `g≈0.360`；(c) gate_ratio local sensitivity：M3 离散切换与 M4 0.033545→0.523789 连续非零权重；(d) information-state update 示意小插图。
6. **Expected claim：** hard gate 对阈值敏感并存在 weak-fault miss；REW-AI 在已测条件提供连续信息写入强度，而不是 update/freeze 二值决策。
7. **Claim strength：** `STRONG`；敏感性结论为 `LIMITED` 单锚点证据。
8. **Plotting caution：** 不把三个 gate_ratio 水平连成“最优参数曲线”；不称 M4 为 threshold-free，因为 `gate_ratio` 仍进入证据缩放；`gate_quad_ratio` 独立贡献当前未证明。
9. **Hardware supplement：** 是。Experiment B/C 可用实时 gate/weight log 验证离散与连续响应趋势。

## Fig.5 Simultaneous drift + fault protection–adaptation trade-off

1. **Scientific purpose：** 在 drift rate×fault factor 矩阵和方向扩展中，同时呈现 tracking、retention、contamination 与 signed movement，证明这是多目标冲突而非单一排名。
2. **Source data file：** `paper_research/phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv`；定义与解释来自 `paper_research/phase2_full_validation/step4_overlap_matrix/STEP4_SIMULTANEOUS_DRIFT_FAULT_MATRIX.md`；Case07/08 原始图源位于 Phase 1C step5/step5b。
3. **x/y variables：** heatmap x=`fault_factor`，y=`drift_rate_multiplier`，颜色分别为 `parameter_error_RMS_norm_pF`、retention distance、`F_minus_CF_norm_pF`；方向面板用 x/y 分别为 signed Cs1/Cs2 movement。
4. **Algorithms compared：** M2/M3/M4；M0 仅可作为 fixed-compensation context，不纳入 adaptive trade-off 排名。
5. **Planned panels：** (a) tracking error heatmaps；(b) W1/W2 retention distance heatmaps；(c) F-CF contamination heatmaps；(d) D1/D2/D3 true drift 与 fault-induced movement vectors。
6. **Expected claim：** M4 在 13/13 点相对 M2 减小 retention error 与 F-CF norm；相对 M3 仅部分点更优；强故障触发时 M3 protection 更强但会冻结真实漂移，M4 保留非零更新与残余污染。
7. **Claim strength：** `STRONG`（trade-off）；direction specificity 仅 `LIMITED`。
8. **Plotting caution：** 三类指标必须分面且统一各自色标，不能合成 composite score；不使用 `||Delta c_CF||/||Delta c_F||` 作为 purity；反向移动必须保留；速率响应不强行画成单调趋势。
9. **Hardware supplement：** 是。Experiment C 是核心补充，只需选择代表性 drift/fault 组合验证趋势。

## Fig.6 Case08 F/N/P/A counterfactual decomposition

1. **Scientific purpose：** 解释为什么小 final `F-N` 不等于算法正确区分 fault 与 drift，并区分 fault-related effect、VFF/adaptation schedule 与 protection-induced true-drift learning loss。
2. **Source data file：** `paper_research/phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv` 中 `COUNTERFACTUAL_REPLAY` / decomposition rows；规格见 `step1_matrix_spec/STEP1B_COUNTERFACTUAL_SPEC.md`。
3. **x/y variables：** x=decomposition term `F-A`、`A-P`、`P-N`、sum `F-N`；y=signed movement in pF，Cs1/Cs2 分开或用二维向量。
4. **Algorithms compared：** M3、M4。
5. **Planned panels：** (a) F/N/P/A trajectory definitions；(b) M3 signed decomposition；(c) M4 signed decomposition；(d) vector-sum closure and identity residual=0 annotation。
6. **Expected claim：** M3 的 `F-A=[+0.915123,-0.981061]` 与 `P-N=[-0.923983,+0.613373] pF` 显著抵消，形成较小 `F-N`；M4 的主要残余为 `F-A=[+4.575018,-4.578660] pF`。
7. **Claim strength：** `MODERATE`，仅 operational counterfactual decomposition。
8. **Plotting caution：** 不用普通正值堆叠柱图掩盖符号抵消；必须有零线和 Cs1/Cs2 分量；不得写 perfect causal identification；equivalence pass 仅是实现校验。
9. **Hardware supplement：** 否，除非后续平台能预先实现严格 matched replay；普通实验不强求复现四轨迹分解。

## Fig.7 Robustness 与 validity boundary

1. **Scientific purpose：** 用有限面板明确哪些因素是已验证的明显边界，哪些属于未解决模型偏差，避免把 M4 写成普遍鲁棒。
2. **Source data file：** phase error/negative sequence：`step2b2_deterministic_results.csv`；Cself/CsAC：`step3_model_mismatch_results.csv`；解释边界：`step5_sensitivity_validity/STEP5_SENSITIVITY_VALIDITY_BOUNDARY.md`。
3. **x/y variables：** (a) x=reference phase error 0–3°；(b) x=Cself mismatch -10%–+10%；(c) x=CsAC 0–3 pF；(d) x=negative sequence 0–5%；y 使用 Cs RMSE norm 与 `abs(B_resistive_fundamental_error_pct)`，避免只看单个输出。
4. **Algorithms compared：** M0/M2/M3/M4；重点说明 M2/M3/M4 在共同模型失配下常接近。
5. **Planned panels：** 四面板分别对应 phase、Cself、CsAC、negative sequence；必要时用第二纵轴或上下子面板分别呈现 Cs error 与 B error。
6. **Expected claim：** 3° phase error 时 M2/M3/M4 B 相误差约 38.986%/43.319%/39.471%；Cself/CsAC 不能由 weighting 根本消除；negative sequence 只构成 configured validity boundary。
7. **Claim strength：** phase=`STRONG`；Cself/CsAC=`MODERATE`；negative sequence=`WEAK / formal status UNRESOLVED`。
8. **Plotting caution：** negative-sequence panel 必须标注 `NEGATIVE_SEQUENCE_INTERNAL_CONVENTION=UNRESOLVED` 与 `CONFIGURED_VALIDITY_BOUNDARY_ONLY`；不得设置事后 PASS/FAIL 安全阈值；不得用 B 相误差偶然较小掩盖 Cs RMSE 失效。
9. **Hardware supplement：** 是。优先补 reference phase/gain chain 与 Cself 偏差的少量边界点；不要求硬件覆盖全部负序机制，除非先解决定义与可观测性。

## Fig.8 Monte-Carlo H/F/O statistical validation

1. **Scientific purpose：** 以条件内配对差异和分布统计验证 representative cases 的方向是否在冻结多因素组合中保持，同时展示尾部与失败区域。
2. **Source data file：** `paper_research/phase2_full_validation/step6_monte_carlo_full/step6_monte_carlo_full_results.csv`；统计核对见 `paper_research/phase2_full_validation/step6_monte_carlo_full/STEP6_MONTE_CARLO_FULL.md` 与 `paper_research/phase2_full_validation/step7_final_analysis/PHASE2_FINAL_ANALYSIS.md`。
3. **x/y variables：** H：M4 USR 与 M4−M2 RMSE difference；F：M4−M2、M4−M3 的 absolute retention error/bias norm paired difference；O：tracking error、retention distance、F-CF norm paired difference。ECDF x=paired difference，y=empirical cumulative probability；箱线图 x=algorithm/cohort，y=metric。
4. **Algorithms compared：** M4−M2、M4−M3 为主；必要时用 M2/M3/M4 原始分布作背景，不建立 M0–M4 总排名。
5. **Planned panels：** (a) H USR distribution；(b) F paired-difference ECDF；(c) O 三指标 paired-difference ECDF/forest；(d) M3 trigger/miss 与 O reverse-movement counts；可将原始 600 行箱线图放补充材料。
6. **Expected claim：** H 正常抑制较小但非零；F/O 中 M4 在多数已测条件相对 M2 减少部分吸收；相对 M3 约半数各有优劣，支持 trade-off 而非普遍优越。
7. **Claim strength：** `STRONG`（冻结仿真框架内的统计支持）；不是硬件 external validation。
8. **Plotting caution：** improvement count 不称“胜率”；零差/并列必须保留；ECDF 零线必须突出；H/F/O 使用不同物理因素和指标，不可合成综合 score；极端点不删除、不缩尾。
9. **Hardware supplement：** 后续硬件只需验证核心趋势，无需复刻 150 条 Monte-Carlo；图本身不要求硬件版替换。

## 9. 正文与补充材料分配建议

| 内容 | 建议位置 | 原因 |
|---|---|---|
| Fig.1–Fig.8 | 正文 | 形成机理→方法→确定性→重叠/反事实→边界→统计的完整链 |
| gate_quad_ratio / hold_cycles 完整敏感性 | 补充材料 | 单锚点局部平台，正文证据密度较低 |
| 全部 25 条 deterministic rows | 补充材料 | 正文用聚合趋势，完整数据用于可追溯性 |
| D1/D2/D3 全部向量点 | Fig.5 或补充材料 | 若正文版面不足，只保留代表性反向点并在补充材料给全量 |
| Monte-Carlo 原始算法箱线图与极端条件表 | 补充材料 | 正文优先 paired ECDF，避免 600 行信息堆积 |
| 既有 Phase 1 多张诊断图 | 补充材料/不直接采用 | 作为重绘源，不原样堆入正文 |

## 10. 图间去重检查

- Fig.3 回答“severity 如何改变 bias/retention/gate/weight”；Fig.4 回答“二值与连续更新在时间和局部参数扰动上如何不同”。
- Fig.5 回答“重叠多目标 trade-off”；Fig.6 专门解释同一 Case08 中 effect cancellation，不重复画 heatmap。
- Fig.7 只讲 validity boundary；Fig.8 只讲随机组合下的配对统计，不用 MC 再重复每个确定性边界曲线。
