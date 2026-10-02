# 论文 Claim—Evidence Mapping

## 0. 正式证据源与使用规则

本映射只使用项目中实际存在的冻结证据。Phase 2 的正式 integrated analysis 为：

- `paper_research/phase2_full_validation/step7_final_analysis/PHASE2_FINAL_ANALYSIS.md`
- `paper_research/phase2_full_validation/step7_final_analysis/PAPER_RESULT_MAP.csv`

项目中没有完全同名的 `PHASE2_FULL_VALIDATION_REPORT.md`，因此不创建、不引用假想文件。Phase 1/2 正式主报告、Step reports、CSV、MAT 文件、registry/manifest 与现有 figure source 均已盘点。MAT 文件为 Phase 1 正式 workspace/observation/configuration artifacts；Phase 2 正式结果以 CSV 和 report 保存，没有发现 Phase 2 MAT 结果文件。

路径约定：下文 `SOURCE FILE` 中以 `phase1a_baseline/`、`phase1b_fault_absorption/`、`phase1c_m4_method/`、`phase2_full_validation/` 开头的路径，均相对于项目目录 `paper_research/`。

强度遵循冻结 integrated analysis，不因论文表达需要而升级：`STRONG`、`MODERATE`、`WEAK`、`UNSUPPORTED`。其中 C13 的正式 Phase 2 子项状态原为 `UNRESOLVED`；为符合本表四级格式，记为 `WEAK（formal status: UNRESOLVED）`，只允许写配置边界，不允许写机理结论。

## C1 — M2 存在 fault absorption mechanism

| Field | Mapping |
|---|---|
| **CLAIM** | M2 持续自适应会把真实阻性故障的一部分误学习为耦合参数变化，形成 fault absorption。 |
| **SCIENTIFIC QUESTION** | 当真实 Cs 不变或真实漂移已完成时，M2 的故障后参数移动是否仍显著存在，并与故障保持损失同时出现？ |
| **FORMAL EVIDENCE** | Phase 1A 现象基线；Phase 1B Case05/06 机理闭环；Phase 2 fault severity、overlap 与 MC F/O 扩展。 |
| **CASE/COHORT** | Case05 fault-only；Case06 drift-then-fault；Step 2B-2 fault factor 1.05–1.40；Step 4 13 overlap points；MC F/O 各 50。 |
| **SOURCE FILE** | `phase1a_baseline/baseline_summary.csv`；`phase1b_fault_absorption/PHASE1B_FAULT_ABSORPTION_REPORT.md`；`phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；`step4_overlap_matrix/step4_overlap_results.csv`；`step6_monte_carlo_full/step6_monte_carlo_full_results.csv`。 |
| **METRIC** | `DeltaCs1/2_fault_induced_pF`；`Cs_fault_induced_bias_norm_pF`；`fault_retention_error_pct`；`F_minus_CF_norm_pF`。 |
| **NUMERICAL RESULT** | Case05/06 M2 factor=1.401075/1.402269（true=1.6），apparent `Delta Cs≈+4.92/-4.96` 与 `+5.01/-4.98 pF`；MC F bias norm mean=2.67428 pF、retention error mean=-8.34146%；Step 4 M2 `F-CF norm≈1.15–6.95 pF`。 |
| **CLAIM STRENGTH** | **STRONG** |
| **ALLOWED WORDING** | “在冻结 AB/BC 回归与参考模型下，真实阻性故障会污染持续自适应辨识并形成有界的故障吸收。” |
| **FORBIDDEN WORDING** | “所有 RLS 必然吸收所有类型故障”；“该现象已在现场普遍证明”；“故障吸收等同数值发散”。 |
| **NEED HARDWARE VALIDATION?** | **YES**。仿真机理已强支持，现场/低压外部有效性仍需 Experiment B/C。 |

## C2 — fault residual 在 coupling-parameter subspace 中存在可表达分量

| Field | Mapping |
|---|---|
| **CLAIM** | `r_fault` 在 `col(X)` 上具有非零投影，该可表达分量可诱导等效耦合参数变化。 |
| **SCIENTIFIC QUESTION** | 故障残差是否可分解为回归子空间内与正交子空间两部分，投影是否数值闭合并能预测参数偏置方向？ |
| **FORMAL EVIDENCE** | Phase 1B Case05/06 geometric decomposition；11 条受控 amplitude/phase conditions；projection closure 与 LS prediction error。 |
| **CASE/COHORT** | Case05、Case06；Step 4 amplitude/phase sweep 共 11 unique conditions。 |
| **SOURCE FILE** | `phase1b_fault_absorption/STEP1_THEORY_AND_DATA_DEFINITION.md`；`step2/case05_mechanism_summary.csv`；`step3/case06_mechanism_summary.csv`；`step4/controlled_factor_summary.csv`；`step5/prediction_error_summary.csv`。 |
| **METRIC** | `eta_geom`；projection energy closure；`Delta c_LS,f`；recursive fault-induced `Delta c`；direction agreement。 |
| **NUMERICAL RESULT** | Case05 post-fault `eta_geom=0.275451415...`；projection closure 约 `10^-15`；LS→recursive prediction 方向一致率 100%，amplitude sweep 最大相对误差 0.663%，最大 RMSE 0.001339 pF。 |
| **CLAIM STRENGTH** | **STRONG** |
| **ALLOWED WORDING** | “故障残差在当前 coupling regression subspace 中含非零可表达分量，静态广义逆解能高精度预测递归偏置方向与量级。” |
| **FORBIDDEN WORDING** | “`eta_geom` 单独决定最终 retention”；“静态 LS 与动态递归严格等价”；“该投影比例适用于所有拓扑和故障”。 |
| **NEED HARDWARE VALIDATION?** | **YES**，若要把回归几何结论外推至实际传感器与装置；仿真内部数学闭合不依赖硬件。 |

## C3 — fault-induced false Cs 导致 false compensation 与 fault retention loss

| Field | Mapping |
|---|---|
| **CLAIM** | 可表达故障分量引起 false Cs，进而生成与故障基波近同相的错误 coupling compensation，造成 fault retention loss。 |
| **SCIENTIFIC QUESTION** | 参数偏置是否真正转化为错误 B 相补偿，去除该参数路径后故障因子能否恢复？ |
| **FORMAL EVIDENCE** | Phase 1B Case05/06 actual/counterfactual branch；controlled amplitude chain；false-compensation phase/amplitude analysis。 |
| **CASE/COHORT** | Case05、Case06；fault factor 1.05–1.60 controlled amplitude sweep。 |
| **SOURCE FILE** | `phase1b_fault_absorption/step2/case05_key_metrics.csv`；`step3/case06_key_metrics.csv`；`step4/controlled_factor_summary.csv`；`step5/correlation_summary.csv`；`step5/mechanism_evidence_table.csv`。 |
| **METRIC** | false-compensation fundamental RMS/ratio/phase；actual vs counterfactual fault factor；lost increment。 |
| **NUMERICAL RESULT** | Case05 false-compensation/fault fundamental ratio≈0.333295、相位差≈0°；M2 factor=1.4011，counterfactual-parameter factor=1.6011；Case06 对应 1.4023→1.6026；controlled lost increment 0.015507→0.198925。 |
| **CLAIM STRENGTH** | **STRONG** |
| **ALLOWED WORDING** | “反事实参数重放直接表明，fault-induced false Cs 产生的错误补偿是故障增量损失的主要可操作解释。” |
| **FORBIDDEN WORDING** | “全部 extraction error 均由 fault absorption 造成”；“phase error 条件下 `eta_geom` 是唯一中介”；“counterfactual branch 可在线获得”。 |
| **NEED HARDWARE VALIDATION?** | **YES**，Experiment B 应验证 false Cs 与 retention 的同向趋势。 |

## C4 — M3 表现出 threshold behavior

| Field | Mapping |
|---|---|
| **CLAIM** | M3 hard gate 在已测故障强度与背景条件下呈离散、阈值依赖的触发/冻结行为。 |
| **SCIENTIFIC QUESTION** | 随故障强度或 `gate_ratio` 变化，M3 是否从不动作离散切换为长时间冻结？ |
| **FORMAL EVIDENCE** | deterministic severity chain；overlap matrix；local sensitivity；MC trigger distribution。 |
| **CASE/COHORT** | Step 2B-2 10 fault rows；Step 4 13 points；Case08 sensitivity；MC F/O。 |
| **SOURCE FILE** | `phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；`step4_overlap_matrix/step4_overlap_results.csv`；`step5_sensitivity_validity/step5_sensitivity_results.csv`；`step6_monte_carlo_full/step6_monte_carlo_full_results.csv`。 |
| **METRIC** | `hard_gate_active_ratio`；`hard_gate_latency_s`；gate status under low/nominal/high `gate_ratio`。 |
| **NUMERICAL RESULT** | 1.05–1.30 的 8 个 deterministic 点 gate=0；1.40 两点 gate ratio=0.96；Step 4 中 1.10/1.30 不触发、1.60 gate=1；MC F/O 触发 15/50、16/50。 |
| **CLAIM STRENGTH** | **STRONG** |
| **ALLOWED WORDING** | “M3 在已测试条件中表现出明显的 threshold-dependent discrete behavior。” |
| **FORBIDDEN WORDING** | “M3 的通用检测阈值精确等于 fault factor 1.40”；“未触发等同无故障”；“阈值位置与背景无关”。 |
| **NEED HARDWARE VALIDATION?** | **YES**，实际噪声/传感链可能改变转变区域。 |

## C5 — M3 在 weak fault 下可能 miss

| Field | Mapping |
|---|---|
| **CLAIM** | M3 可能漏过弱故障；此时其轨迹与 M2 相同，无法提供额外保护。 |
| **SCIENTIFIC QUESTION** | 低于门控转变区的真实故障是否仍产生吸收，而 M3 gate 保持关闭？ |
| **FORMAL EVIDENCE** | Phase 1C Case07；Step 2B-2 low severity；Step 4 factor 1.10/1.30；MC F miss count。 |
| **CASE/COHORT** | Case07 factor 1.30；deterministic factors 1.05–1.30；MC F 50。 |
| **SOURCE FILE** | `phase1c_m4_method/STEP5_SIMULTANEOUS_DRIFT_FAULT.md`；`phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；`step4_overlap_matrix/step4_overlap_results.csv`；`step6_monte_carlo_full/step6_monte_carlo_full_results.csv`。 |
| **METRIC** | gate ratio/latency；M2=M3 equality；retention error；fault-induced bias norm。 |
| **NUMERICAL RESULT** | Case07 M3 never triggers and equals M2；Step 2B-2 8/10 new severity points未触发；MC F 中 35/50 未触发。 |
| **CLAIM STRENGTH** | **STRONG** |
| **ALLOWED WORDING** | “固定 hard-gate 在部分弱故障和背景组合下可能 miss，未触发时不能抑制 fault absorption。” |
| **FORBIDDEN WORDING** | “M3 对所有弱故障都会漏检”；“35/50 是现场漏检率”；“M4 因此全面优于 M3”。 |
| **NEED HARDWARE VALIDATION?** | **YES**，Experiment B 应包含至少一个弱故障点。 |

## C6 — M3 hard freeze 在 simultaneous drift + fault 下损失真实 drift learning

| Field | Mapping |
|---|---|
| **CLAIM** | M3 触发后冻结信息与参数状态，在阻性故障重叠真实 Cs 漂移时同时抑制了真实 drift learning。 |
| **SCIENTIFIC QUESTION** | 强故障门控区间内真实 Cs 仍变化时，M3 是否停止移动，并在反事实分解中出现 protection-induced drift-learning loss？ |
| **FORMAL EVIDENCE** | Case08 gate interval；Step 4 signed movement 与 F/N/P/A replay；MC O reverse movement/post-fault memory。 |
| **CASE/COHORT** | Case08；Step 4 D1/D2/D3；MC O 50。 |
| **SOURCE FILE** | `phase1c_m4_method/step5b_triggered_overlap/tables/gate_interval_adaptation.csv`；`phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv`；`step6_monte_carlo_full/step6_monte_carlo_full_results.csv`。 |
| **METRIC** | gate-interval F movement；true drift；`P_minus_N`；signed dot product；post-fault AUC。 |
| **NUMERICAL RESULT** | Case08 M3 gate interval F movement=`[0,0] pF`，true drift≈`[+1.307679,-0.871786] pF`；replay `P-N=[-0.923983,+0.613373] pF`；MC O reverse movement=7/50，AUC mean=0.135134 pF·s。 |
| **CLAIM STRENGTH** | **STRONG** |
| **ALLOWED WORDING** | “hard freeze 的故障保护以同时停止真实漂移学习为代价，且可能留下释放后记忆。” |
| **FORBIDDEN WORDING** | “所有 M3 触发都会使最终估计更差”；“反向移动可以特异识别 fault”；“较小 F-N 证明无污染”。 |
| **NEED HARDWARE VALIDATION?** | **YES**，Experiment C 是关键外部验证。 |

## C7 — M4 / REW-AI 提供 continuous information weighting

| Field | Mapping |
|---|---|
| **CLAIM** | REW-AI 以 `0<g<=1` 连续、状态一致地调节 `J/h/baseIn` 的 information-state increment，而非事后缩放参数变化。 |
| **SCIENTIFIC QUESTION** | M4 是否在结构上保持 RLS 状态一致性、在 `g=1` 时退化为 M2，并在故障强度变化时产生连续非零权重？ |
| **FORMAL EVIDENCE** | `paper_method_v1` freeze；A_NO_WEIGHT equivalence；deterministic/overlap/sensitivity/MC weight distributions。 |
| **CASE/COHORT** | Case02/05/07/08；Step 2B-2；Step 4；Case08 sensitivity；MC H/F/O。 |
| **SOURCE FILE** | `phase1c_m4_method/step6_ablation/PAPER_METHOD_V1_FREEZE.md`；`phase1c_m4_method/step6_ablation/tables/no_weight_equivalence.csv`；`phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；`phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv`；`phase2_full_validation/step6_monte_carlo_full/step6_monte_carlo_full_results.csv`。 |
| **METRIC** | exact M2 equivalence；`mean_update_weight`；USR；information-state increment suppression。 |
| **NUMERICAL RESULT** | A_NO_WEIGHT=M2 7/7 exact；severity chain `g≈0.916→0.465`（1.60 anchor约0.361）；overlap range 0.356309–0.820334；MC H/F/O mean `g=0.974256/0.647979/0.625597`。 |
| **CLAIM STRENGTH** | **STRONG** |
| **ALLOWED WORDING** | “REW-AI reduces the influence of fault-related residual information on parameter updating while retaining non-zero adaptation.” |
| **FORBIDDEN WORDING** | “M4 准确区分故障和漂移”；“g 是 fault probability”；“M4 只是把 `Delta Cs` 乘权”；“direction 进入 M4 控制”。 |
| **NEED HARDWARE VALIDATION?** | 公式与代码结构 **NO**；实时证据量与性能趋势 **YES**。 |

## C8 — M4 可减少部分 M2 fault absorption

| Field | Mapping |
|---|---|
| **CLAIM** | 在多数已测 fault/overlap 条件中，M4 相对 M2 减少部分 fault absorption，但改善幅度依条件而变。 |
| **SCIENTIFIC QUESTION** | 相同物理数据下，M4 是否比 M2 具有更小的绝对 retention error、fault-induced bias 或 F-CF contamination？ |
| **FORMAL EVIDENCE** | deterministic paired comparisons；13-point overlap；MC F/O paired differences。 |
| **CASE/COHORT** | 10 new severity rows；13 overlap points；MC F/O。 |
| **SOURCE FILE** | `phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；`step4_overlap_matrix/step4_overlap_results.csv`；`step6_monte_carlo_full/step6_monte_carlo_full_results.csv`；`step7_final_analysis/PAPER_RESULT_MAP.csv`。 |
| **METRIC** | paired `abs(retention error)`；bias norm；parameter error；retention distance；`F_minus_CF_norm_pF`。 |
| **NUMERICAL RESULT** | deterministic 10/10 同时改善 retention/bias；overlap 13/13 改善 M2 retention 与 F-CF norm；MC F 改善 36/50、33/50；MC O 改善 33/50、43/50、40/50。 |
| **CLAIM STRENGTH** | **STRONG** |
| **ALLOWED WORDING** | “在多数已测故障与重叠条件中，M4 相对 M2 减少了部分故障吸收。” |
| **FORBIDDEN WORDING** | “M4 在所有条件都优于 M2”；“36/50 是胜率”；“改善证明 fault/drift 已正确分离”。 |
| **NEED HARDWARE VALIDATION?** | **YES**，Experiment B/C 应验证相对趋势。 |

## C9 — M4 不能完全消除 fault contamination

| Field | Mapping |
|---|---|
| **CLAIM** | 非零标量权重主要降低向有偏解移动的速度，不能完全消除 residual fault contamination 或保证改变有偏固定点。 |
| **SCIENTIFIC QUESTION** | 即使信息增量被明显抑制，M4 是否仍积累显著 false Cs，且强故障保护明显弱于 M3？ |
| **FORMAL EVIDENCE** | Phase 1C ablation；Case05 pure fault；Case08 triggered overlap；counterfactual decomposition；MC F/O tails。 |
| **CASE/COHORT** | Case05、Case08；MC F/O。 |
| **SOURCE FILE** | `phase1c_m4_method/STEP6_ABLATION_AND_FREEZE.md`；`step6_ablation/tables/case05_ablation.csv`；`phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv`；`step6_monte_carlo_full/step6_monte_carlo_full_results.csv`。 |
| **METRIC** | ISR J/h；steady bias norm；retention error；M4 `F-A`；`F-CF norm`。 |
| **NUMERICAL RESULT** | Case05 M4 ISR≈63.9%，但 bias norm 仅比 M2 降 3.75%，retention error仍 -11.9637%；Case08 M4 `F-CF norm=6.402670 pF`，`F-A=[+4.575018,-4.578660] pF`；M3同点 `F-CF norm=0.424153 pF`。 |
| **CLAIM STRENGTH** | **STRONG** |
| **ALLOWED WORDING** | “M4 slows and reduces part of the biased learning, but residual fault contamination remains.” |
| **FORBIDDEN WORDING** | “M4 completely solves/eliminates fault absorption”；“ISR 可直接解释为最终 bias reduction”；“非零 g 表示安全更新”。 |
| **NEED HARDWARE VALIDATION?** | **YES**，硬件结果必须同样报告残余污染，不能只报改善。 |

## C10 — M4 与 M3 是 protection–adaptation trade-off，而不是普遍优劣关系

| Field | Mapping |
|---|---|
| **CLAIM** | M3 强调触发后的 fault protection，M4 强调连续 adaptation；两者在不同条件各有优势，不存在现有证据支持的普遍排名。 |
| **SCIENTIFIC QUESTION** | M4 保留非零漂移学习的收益是否伴随更弱强故障保护，并在随机条件中呈近似对半分布？ |
| **FORMAL EVIDENCE** | Case07 weak overlap；Case08 triggered overlap；Step 4 13 points；MC F/O paired counts。 |
| **CASE/COHORT** | Case07/08；Step 4；MC F/O。 |
| **SOURCE FILE** | `phase1c_m4_method/PHASE1C_M4_METHOD_REPORT.md`；`phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv`；`step6_monte_carlo_full/step6_monte_carlo_full_results.csv`；`step7_final_analysis/PHASE2_FINAL_ANALYSIS.md`。 |
| **METRIC** | retention；parameter tracking；F/CF movement；F-CF norm；post-fault AUC；paired improvement counts。 |
| **NUMERICAL RESULT** | Case08 retention M3≈0.968、M4≈0.745，M4 gate-interval movement norm=0.479655 pF而M3=0；MC F M4 vs M3 retention/bias improvements=25/50、22/50；MC O=26/50、27/50、26/50。 |
| **CLAIM STRENGTH** | **STRONG** |
| **ALLOWED WORDING** | “M4 and hard gating provide different protection–adaptation trade-offs.” |
| **FORBIDDEN WORDING** | “M4 综合性能优于 M3”；“M3 已被 M4 取代”；“以单一 composite score 选择 winner”。 |
| **NEED HARDWARE VALIDATION?** | **YES**，Experiment C 应验证 trade-off 趋势。 |

## C11 — reference phase error 是明显 sensitivity boundary

| Field | Mapping |
|---|---|
| **CLAIM** | 冻结一致相位偏差模型下，reference phase error 同时污染参数辨识与阻性电流提取，是明显适用边界。 |
| **SCIENTIFIC QUESTION** | phase error 增大时，Cs tracking 与 B 相误差是否显著退化，且能否仅由 `eta_geom` 变化解释？ |
| **FORMAL EVIDENCE** | Phase 1B phase sweep；Phase 2 0–3° deterministic matrix；Step 5 boundary synthesis。 |
| **CASE/COHORT** | phase error 0/0.33/0.5/1/2/3°。 |
| **SOURCE FILE** | `phase1b_fault_absorption/step4/controlled_factor_summary.csv`；`phase2_full_validation/step2b2_deterministic_core/step2b2_deterministic_results.csv`；`step5_sensitivity_validity/STEP5_SENSITIVITY_VALIDITY_BOUNDARY.md`。 |
| **METRIC** | Cs RMSE；B fundamental error；pre-fault bias；counterfactual retention；`eta_geom` effect size。 |
| **NUMERICAL RESULT** | 3° 时 M2/M3/M4 B 相误差绝对值约 38.986%/43.319%/39.471%；Phase 1B 中 `eta_geom` 仅相对增 0.2191%，而 M2 retention 从 -12.43% 恶化至 -21.01%。 |
| **CLAIM STRENGTH** | **STRONG** |
| **ALLOWED WORDING** | “Reference phase error is a significant sensitivity/validity boundary under the frozen coherent phase-offset model.” |
| **FORBIDDEN WORDING** | “M4 对相位误差鲁棒”；“该结果覆盖完整场探头幅频/相频、滤波和延迟”；“`eta_geom` 可解释全部 phase degradation”。 |
| **NEED HARDWARE VALIDATION?** | **YES**，应优先用实际参考链路验证。 |

## C12 — Cself / CsAC mismatch 不能由 M4 根本解决

| Field | Mapping |
|---|---|
| **CLAIM** | Cself 共同假设错误与未建模 CsAC 结构偏差不会被 residual-evidence weighting 根本消除，M2/M3/M4 常表现接近。 |
| **SCIENTIFIC QUESTION** | 当模型结构本身错误而非 fault residual 增大时，M4 是否能显著降低参数与电流误差？ |
| **FORMAL EVIDENCE** | Phase 2 Step 3 Cself/CsAC mismatch；Step 5 boundary summary。 |
| **CASE/COHORT** | Cself -10/-5/-2/+2/+5/+10%；CsAC 0.5/1/2/3 pF（0 为 anchor）。 |
| **SOURCE FILE** | `phase2_full_validation/step3_model_mismatch/step3_model_mismatch_results.csv`；`phase2_full_validation/step3_model_mismatch/STEP3_MODEL_MISMATCH_ROBUSTNESS.md`；`phase2_full_validation/step5_sensitivity_validity/STEP5_SENSITIVITY_VALIDITY_BOUNDARY.md`。 |
| **METRIC** | Cs1/Cs2 RMSE；B error；M3 gate；M4 mean `g`/USR。 |
| **NUMERICAL RESULT** | Cself -10% 时 M4 RMSE=12.598/8.210 pF、B error=11.053%；+10% 时 15.897/16.061 pF、2.092%；CsAC=3 pF 时 M2/M3/M4 RMSE norm=0.839394/0.839394/0.840362 pF。 |
| **CLAIM STRENGTH** | **MODERATE** |
| **ALLOWED WORDING** | “M4 weighting does not fundamentally remove the tested common Cself assumption error or unmodelled CsAC structural bias.” |
| **FORBIDDEN WORDING** | “M4 具有很强模型失配鲁棒性”；“M4 已解决 Cself/CsAC”；“由已测范围定义普适安全区”。 |
| **NEED HARDWARE VALIDATION?** | **YES**，Experiment A/C 可选择代表性失配点。 |

## C13 — negative sequence 当前只能作为 configured validity boundary

| Field | Mapping |
|---|---|
| **CLAIM** | 非零负序结果只支持“冻结配置下严重退化”的边界提示；当前不能支持完整 negative-sequence mechanism 或一般不平衡适用性结论。 |
| **SCIENTIFIC QUESTION** | 在 internal phase convention 尚未解决时，现有数值能支持何种最低限度表述？ |
| **FORMAL EVIDENCE** | Phase 2 registry interpretation flag；Step 2B-2 nonzero NS rows；Step 5 boundary statement；Step 7 formal map `C7-NS=UNRESOLVED`。 |
| **CASE/COHORT** | negative sequence 1%/3%/5%，0% anchor。 |
| **SOURCE FILE** | `phase2_full_validation/step1_matrix_spec/phase2_condition_registry.csv`；`step2b2_deterministic_core/step2b2_deterministic_results.csv`；`step5_sensitivity_validity/STEP5_SENSITIVITY_VALIDITY_BOUNDARY.md`；`step7_final_analysis/PAPER_RESULT_MAP.csv`。 |
| **METRIC** | B fundamental error；Cs RMSE；interpretation flag；M3 gate；M4 weight。 |
| **NUMERICAL RESULT** | M4 B 相误差绝对值在 1%/3%/5% 为 11.072%/34.900%/61.848%；M3 未触发，M4 `g≈0.976–0.978`；所有非零点标记 `NEGATIVE_SEQUENCE_INTERNAL_CONVENTION=UNRESOLVED`。 |
| **CLAIM STRENGTH** | **WEAK（formal status: UNRESOLVED）** |
| **ALLOWED WORDING** | “Under the configured but unresolved negative-sequence convention, performance degraded markedly; these cases are used only as a configured validity boundary.” |
| **FORBIDDEN WORDING** | “M4 适用于各种电网不平衡状态”；“已揭示负序机理”；“1% 是普适失效阈值”；“单 B 相可恢复任意不平衡三相电压”。 |
| **NEED HARDWARE VALIDATION?** | **YES，但先需解决 convention/observability 定义**；当前不宜直接安排为结论性硬件验证。 |

## C14 — counterfactual replay 表明 small final F-N 不一定意味着算法正确区分 fault 和 drift

| Field | Mapping |
|---|---|
| **CLAIM** | final `F-N` 可能由 fault-related effect、adaptation schedule contribution 与 protection-induced drift-learning loss 相互抵消；小净值不等于纯净分离。 |
| **SCIENTIFIC QUESTION** | Case08 中 M3 的小 `F-N` 是低污染，还是多个大项的向量抵消？ |
| **FORMAL EVIDENCE** | Case08 F/N/P/A operational replay；replay equivalence；decomposition identity。 |
| **CASE/COHORT** | Case08，M3/M4。 |
| **SOURCE FILE** | `phase2_full_validation/step1_matrix_spec/STEP1B_COUNTERFACTUAL_SPEC.md`；`phase2_full_validation/step4_overlap_matrix/step4_overlap_results.csv`；`phase2_full_validation/step4_overlap_matrix/STEP4_SIMULTANEOUS_DRIFT_FAULT_MATRIX.md`。 |
| **METRIC** | `F-A`、`A-P`、`P-N`、`F-N` signed vectors；identity residual；replay equivalence difference。 |
| **NUMERICAL RESULT** | M3：`F-A=[+0.915123,-0.981061]`、`A-P=[+0.032228,-0.055821]`、`P-N=[-0.923983,+0.613373]`，sum `F-N=[+0.023367,-0.423509] pF`；identity residual=0；equivalence pass at 1e-12。 |
| **CLAIM STRENGTH** | **MODERATE** |
| **ALLOWED WORDING** | “The replay provides an operational decomposition showing that a small net F-N can result from cancellation among distinct schedule-related effects.” |
| **FORBIDDEN WORDING** | “F/N/P/A 实现完美因果识别”；“F-A 是唯一真实 fault effect”；“小 F-N 证明算法准确区分 fault 与 drift”。 |
| **NEED HARDWARE VALIDATION?** | **NO** 对仿真 replay 恒等式；**YES** 若要把分解解释外推至实物系统。 |

## C15 — Monte-Carlo H/F/O 对 Phase 1 representative conclusions 提供统计层面的外部验证

| Field | Mapping |
|---|---|
| **CLAIM** | H/F/O 多因素冻结 cohort 将 Phase 1 representative conclusions 扩展到统计分布层面，并保留未改善与极端条件。 |
| **SCIENTIFIC QUESTION** | 正常代价、fault protection 与 overlap trade-off 是否在随机组合中保持方向性，同时暴露长尾和失败区域？ |
| **FORMAL EVIDENCE** | frozen MC registry；H/F/O 各 N=50；600 evaluations；paired differences；extreme-condition audit。 |
| **CASE/COHORT** | H=50、F=50、O=50 physical conditions；M0/M2/M3/M4。 |
| **SOURCE FILE** | `phase2_full_validation/step1_matrix_spec/STEP1C_MC_REGISTRY_SPEC.md`；`phase2_full_validation/step1_matrix_spec/phase2_condition_registry.csv`；`phase2_full_validation/step6_monte_carlo_full/step6_monte_carlo_full_results.csv`；`phase2_full_validation/step6_monte_carlo_full/STEP6_MONTE_CARLO_FULL.md`；`phase2_full_validation/step7_final_analysis/PHASE2_FINAL_ANALYSIS.md`。 |
| **METRIC** | mean/std/median/IQR/P5/P95；paired differences；trigger counts；USR；retention/bias/tracking/F-CF/AUC；numerical failure。 |
| **NUMERICAL RESULT** | 150/150 conditions、600/600 evaluations、0 numerical failures；H USR mean/P95=0.025744/0.087019；F M4 vs M2 retention/bias improvements=36/50、33/50；O tracking/retention/contamination=33/50、43/50、40/50；M4 vs M3 约半数各有优劣。 |
| **CLAIM STRENGTH** | **MODERATE**（统计外部验证相对于 Phase 1 representative cases；并非独立硬件外部验证） |
| **ALLOWED WORDING** | “The frozen H/F/O cohorts provide distribution-level validation of the representative Phase 1 trends within the same Simulink framework.” |
| **FORBIDDEN WORDING** | “Monte-Carlo 已完成现场外部验证”；“improvement count 是算法胜率”；“600 evaluations 证明普遍最优”；“数值失败为零表示性能无失败”。 |
| **NEED HARDWARE VALIDATION?** | **YES**，统计仿真不能替代 Experiment A/B/C。 |

## 16. 已知限制的 claim crosswalk

| Frozen limitation | 对应 claim/章节 | 必须保留的论文表达 |
|---|---|---|
| M4 does not completely eliminate fault absorption | C9；3.6；6 | 残余污染与强故障弱于 M3 |
| M3 stronger after successful strong-fault trigger | C10；3.4 | “通常更强”，不写 M4 全面替代 |
| M3 may miss weak faults | C5 | 只限已测条件，不给普适阈值 |
| Hard freeze suppresses true drift learning | C6；C14 | signed movement 与 P-N 证据 |
| M4 non-zero adaptation retains contamination | C7–C10 | non-zero `g` 不是安全或正确分离证明 |
| Reference phase error is significant boundary | C11 | 仅冻结 coherent phase model |
| Negative-sequence convention unresolved | C13 | `CONFIGURED_VALIDITY_BOUNDARY_ONLY` |
| Cself mismatch not solved | C12 | weighting 不能消除共同模型偏差 |
| CsAC mismatch not solved | C12 | 未建模结构偏差仍在 |
| Direction evidence diagnostic only | C6/C10；4.4 | 不作 fault detector，不进入 M4 control |
| Small normal M4 suppression | C15；3.6 | H USR 非零；Case02 tracking 小幅退化 |
| Scalar weighting may not change biased fixed point | C9 | 改速率不等于消除偏置 |
| ISR is not final bias reduction | C9 | Case05 63.9% ISR vs 3.75% bias-norm reduction |
| Primary evidence is frozen Simulink | 全部 | 所有强度均限仿真证据体系 |
| Low-voltage experiment incomplete | 第 5 章 | `NEEDS_EXPERIMENT`，不虚构数据 |

## 17. Evidence gaps

### Gap G1 — 低压硬件验证为空

- **Status：** `NEEDS_EXPERIMENT`。
- **Affected claims：** C1–C12、C15 的实际装置外推。
- **Action in paper：** 第 5 章只保留 Experiment A/B/C 接口；在实验完成前，不提交含“实验验证”结论的完整稿，或明确标记为待补章节。

### Gap G2 — negative-sequence internal convention unresolved

- **Status：** `WEAK / formal UNRESOLVED`。
- **Affected claim：** C13。
- **Action in paper：** 仅作为 Fig.7 configured boundary；不写机制、不定义普适阈值、不声称强不平衡适用。

### Gap G3 — 文献证据尚未映射

- **Status：** `PARTIAL`，不是仿真缺口。
- **Affected section：** 引言与相关工作。
- **Action in paper：** Paper Stage 2 单独完成中文核心/英文数据库文献检索与专利差异定位，不用项目内部报告替代外部引用。

### Gap G4 — phase-consistency factor 独立贡献未证明

- **Status：** `UNSUPPORTED` 作为独立贡献。
- **Formal evidence：** A_FULL 与 A_BACKGROUND_ONLY 在全部正式指标相同，`p_q≈1` 饱和。
- **Action in paper：** 可按冻结公式保留 `p_q`，但不得把它列为独立创新点或已验证性能来源。

### Gap G5 — direction evidence 不具 fault specificity

- **Status：** `UNSUPPORTED` 作为 fault detector；`LIMITED` 作为 diagnostic。
- **Formal evidence：** normal drift 与 fault cosine distributions 重叠，确定性方向扩展存在反向点。
- **Action in paper：** 只用于诊断 signed movement，不进入 REW-AI 控制图与贡献列表。

## 18. 超出数据支持的框架风险检查

当前给定论文框架本身可成立，但以下潜在表述必须在写作阶段删除或改写：

1. 若第 3.5 节把 M4 写成“准确区分故障和漂移”，超出 C7/C9 证据；应改为连续降低 fault-related residual information 写入。
2. 若第 4.4 节用单一综合指标宣布 M4 优于 M3，超出 C10；应保留多指标 trade-off。
3. 若第 4.6 节把 negative sequence 写成完整鲁棒性结论，超出 C13；只能写 configured boundary。
4. 若摘要用 ISR 百分比代表最终 bias reduction，违反 C9；两者必须分开。
5. 若讨论把 Cself/CsAC 结果写成 M4 robustness，违反 C12；正式证据显示 M2/M3/M4 接近。
6. 若把 direction cosine 或 signed movement 作为 fault-specific detector，现有证据为 `UNSUPPORTED`。
7. 若把 MC 称为“外部实验验证”，超出 C15；它只是同一 Simulink 框架内相对于 representative cases 的统计外部验证。

## 19. Evidence readiness summary

| Category | Ready? | Comment |
|---|---|---|
| Fault absorption mechanism | YES | C1–C3 STRONG |
| M3 threshold / weak miss / hard-freeze cost | YES | C4–C6 STRONG |
| REW-AI formulation and continuous weighting | YES | C7 STRONG |
| M4 partial mitigation and residual contamination | YES | C8–C9 STRONG |
| M3–M4 trade-off | YES | C10 STRONG |
| Reference phase boundary | YES | C11 STRONG |
| Cself/CsAC boundary | YES, bounded | C12 MODERATE |
| Negative-sequence mechanism | NO | C13 WEAK / UNRESOLVED；仅 configured boundary |
| Counterfactual operational interpretation | YES, bounded | C14 MODERATE |
| Monte-Carlo distribution-level validation | YES, simulation-only | C15 MODERATE |
| Low-voltage experimental validation | NO | Experiment A/B/C 均待完成 |
