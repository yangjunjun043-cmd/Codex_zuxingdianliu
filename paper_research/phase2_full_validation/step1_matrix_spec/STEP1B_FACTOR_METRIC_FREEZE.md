# Phase 2 Step 1B — Experimental Factor & Metric Freeze

## 1. Status and authority

本文件把已通过人工验收的 Step 1A 审计事实转化为 Phase 2 的预注册约束。它是 Step 1 中间冻结文件，不是最终 condition registry，也不授权运行实验。

```text
purpose: PREREGISTRATION / FREEZE
new Phase 2 simulation: NO
method tuning: NO
final condition registry: NOT CREATED
```

优先级：Phase 1A/1B/1C 冻结资产与 `paper_method_v1` 不变；本文件只规定未来 Step 1C/1D 的注册规则。若实现无法满足本文的等价性门槛，相应实验应标记 `BLOCKED`，不能修改冻结算法来迁就实验。

## 2. Algorithm set

Phase 2 deterministic / robustness 主比较只包含：

| ID | Frozen definition | Main matrix | Counterfactual replay |
|---|---|---:|---:|
| M0 | Fixed coupling compensation | Yes | N/A |
| M2 | VFF-RLS without gate | Yes | mechanism reference only |
| M3 | VFF-RLS + hard gate | Yes | primary |
| M4 | REW-AI, `paper_method_v1` | Yes | primary |

不得增加第五个论文主算法。Case07/08 的历史结果没有 M0；其历史证据可原样复用，但四算法矩阵中的 M0 必须标记 `MISSING_FOR_PHASE2_MATRIX`，不能声称历史上已完成四算法比较。

## 3. Deterministic one-factor families

为给 Step 1C 提供无歧义的去重依据，冻结以下非结果驱动 anchor 分配：

- SNR、third-harmonic amplitude、negative sequence、Cself mismatch、CsAC mismatch：以 Case02 slow drift 为物理 anchor；除被扫因素外保持 Case02 冻结定义。
- reference phase error：以 Case05 fault-only、factor 1.60 为物理 anchor，与 Phase 1B 正式 phase sweep 保持连续。
- fault amplitude：分别使用 Case05 fault-only 与 Case06 drift-then-fault family。

该 anchor 分配用于变量隔离和历史连续性，不代表对任何算法有利。Step 1C 不得根据预测结果更换 anchor。

### 3.1 Fault amplitude

- Fault levels：`1.05, 1.10, 1.20, 1.30, 1.40, 1.60`。
- `1.0` 仅为 healthy/no-fault control，不是 fault level。
- Families：A1 `fault_only`；A2 `drift_then_fault`。
- 固定 fault timing、ramp、reference phase、harmonic、negative sequence、Cself 与 noise definition；只允许改变 `fault_factor`。
- Phase 1B M2 sweep 是 `PARTIAL_REUSE`；统一四算法比较是否需要新运行由 Step 1C registry 明示。

### 3.2 Noise / SNR

- Levels：`Inf, 40, 30, 20 dB`；`Inf` 表示 noise-free。
- `Inf` 是 `NEW_PHASE2_CONDITION`，不能标为 Phase 1 exact reuse。
- deterministic sweep 使用 Step 1C 冻结的单一预注册 seed；同一 condition 的 M0/M2/M3/M4 共用完全相同数据与 noise realization。
- 定义保持：`sigma = rms(ideal total leakage current) / 10^(SNR/20)`，逐相对 ideal total leakage current 加 Gaussian noise。

### 3.3 Reference phase error

- Levels：`0, 0.33, 0.5, 1, 2, 3 deg`，主矩阵只取正方向。
- 严格沿用 Phase 1B：`phi1_used = phi1_fitted + deg2rad(delta)`，`phi3_used = phi3_fitted + 3*deg2rad(delta)`；正号表示 reconstructed reference lead。
- 该因素不是一般传感器相位模型，不覆盖独立 50/150 Hz response、delay、filter 或 field-probe phase error。
- Signed lead/lag symmetry 是本轮 limitation，不从结果出发临时追加。

### 3.4 Third-harmonic amplitude

- `h3_ratio = 0.005, 0.02, 0.05, 0.08, 0.10`。
- 固定 `phi3_deg = 0 deg`。
- 本轮只扫 amplitude，不做 amplitude × phase 笛卡尔积。
- 旧 `phi3 = 0/1/3/5/10 deg` 只保留为历史 `PARTIAL_REUSE / background evidence`，不进入本轮主轴。

### 3.5 Negative sequence

- `Vneg_pu = 0, 0.01, 0.03, 0.05`。
- 用途限定为 configured model-mismatch / validity-boundary test。
- `NEGATIVE_SEQUENCE_INTERNAL_CONVENTION = UNRESOLVED`。在内部精确序分量相位约定未恢复前，禁止作完整机理推导；该限制不阻塞 levels freeze。

## 4. Model-mismatch factors

### 4.1 Common-mode Cself mismatch

固定 `Cself_algorithm_pF = 400`，只改变三相共同的 `Cself_truth_pF`：

```text
Cself_mismatch_pct = 100 * (Cself_truth - Cself_algorithm) / Cself_algorithm
```

| mismatch / % | -10 | -5 | -2 | 0 | +2 | +5 | +10 |
|---:|---:|---:|---:|---:|---:|---:|---:|
| truth / pF | 360 | 380 | 392 | 400 | 408 | 420 | 440 |

Step 1C 必须分别保存 `Cself_truth_pF` 与 `Cself_algorithm_pF`。禁止同步改变 truth 与 assumption；不研究 per-phase independent mismatch。

### 4.2 Weak unmodelled CsAC coupling

- Levels：`0, 0.5, 1, 2, 3 pF`。
- Estimator 仍只估计 `Cs1=AB`、`Cs2=BC`；不得增加第三参数，不得修改 AutoComp9。
- 未来只允许在独立 Phase 2 external-data wrapper 中、在正式 noise 生成之前注入：

```text
iA_AC = CsAC * (duA/dt - duC/dt)
iB_AC = 0
iC_AC = CsAC * (duC/dt - duA/dt)
```

- 正式 mismatch 运行前必须通过 zero-injection regression：`CsAC=0` 路径与 frozen nominal data 在项目数值容差内一致。否则 `CsAC experiment = BLOCKED`。

## 5. Simultaneous drift + fault

### 5.1 Drift rate

Nominal overlap vector 为 `D1=[+3,-2] pF`，L2=`sqrt(13) pF`。Rate multiplier 只改变 cubic-smoothstep temporal scale，不改变总向量：

| rate | duration formula | nominal duration / s |
|---:|---|---:|
| 0.5x | `1.40/0.5` | 2.80 |
| 1.0x | `1.40/1.0` | 1.40 |
| 2.0x | `1.40/2.0` | 0.70 |

Step 1C 负责统一生成 start/end、fault schedule 与 windows，并必须同时满足：三个 rate 都存在真实 overlap；fault factor/ramp 不变；有足够 pre-history 和 post-fault recovery；不退化为 fault-after-drift；所有算法共享同一时间轴。无法满足则标记 `RATE_TIMING_DESIGN_BLOCKED`。

### 5.2 Core matrix and direction extension

- Core：rates `{0.5,1,2}` × fault factors `{1.10,1.30,1.60}` = 9 conditions。
- Directions：`D1=[+3,-2]`、`D2=[-3,+2]`、`D3=[+3,+2] pF`，L2 均为 `sqrt(13) pF`。
- Direction extension：rate=`1.0x`，fault factors `{1.30,1.60}`，directions `{D1,D2,D3}`，原始网格 6 点；D1 两点与 core 重复，故只新增 4 个 unique conditions。
- 不建立 direction × rate × fault 全笛卡尔积；不得因结果不利删除 D2/D3。

## 6. Counterfactual replay and sensitivity

Protection-Schedule Counterfactual Replay 正式纳入为 Phase 2 causal addendum，anchor 为 Case08，主对象为 M3/M4。F/N/P/A 轨迹、分解解释与 `REPLAY_EQUIVALENCE_GATE` 见 `STEP1B_COUNTERFACTUAL_SPEC.md`。

Step 5 只允许 offline sensitivity，不是 tuning。Frozen nominal values 与变体：

| parameter | applicable algorithms | low | frozen | high |
|---|---|---:|---:|---:|
| gate_ratio | M3, M4 | 1.008 | 1.12 | 1.232 |
| gate_quad_ratio | M3, M4 | 1.08 | 1.20 | 1.32 |
| gate_hold_cycles | M3 only | 24 | 25 | 26 |

M4 没有 hold cycles。变体不能替代 `paper_method_v1`，不能用于选择“最优参数”，只报告 sensitivity、boundary、failure region。

## 7. Metric freeze

### 7.1 Healthy / drift tracking

- Primary：`Cs1_RMSE_pF`、`Cs2_RMSE_pF`。
- Secondary：`B_resistive_fundamental_error_pct`、`Cs1_max_abs_error_pF`、`Cs2_max_abs_error_pF`。
- M4 cost：`unnecessary_suppression_ratio`。

### 7.2 Persistent fault

- Primary：`fault_factor_true`、`fault_factor_est`、`fault_retention_error_pct`、`DeltaCs1_fault_induced_pF`、`DeltaCs2_fault_induced_pF`。
- Derived primary contamination magnitude：`Cs_fault_induced_bias_norm_pF = sqrt(DeltaCs1_fault_induced_pF^2 + DeltaCs2_fault_induced_pF^2)`；它不是 purity。
- Secondary：`first_gate_trigger_s`、`hard_gate_latency_s`、`hard_gate_active_ratio`；M4 另报 `mean_update_weight`、`material_suppression_onset_s`、`information_suppression_ratio_J`、`information_suppression_ratio_h`。
- ISR 不等价于 final bias reduction。

### 7.3 Temporary overlap

- Primary：`overlap_Cs1_RMSE_pF`、`overlap_Cs2_RMSE_pF`、`fault_increment_retention_ratio`。Retention 必须分别按 W1/W2 报告，或明确标注 combined window。
- 强制保存 `true_drift_vector`、`F_movement_vector`、`CF_movement_vector`、`F_minus_CF_vector`；每个向量必须含 Cs1 signed、Cs2 signed、L2 norm，禁止只存 norm。
- Secondary：`parameter_error_RMS_norm_pF`、`mean_memory_norm_pF`、`endpoint_memory_norm_pF`、`post_fault_AUC_pF_s`；M3 另报 gate ratio/latency，M4 另报 mean update weight。

禁止将历史 `drift_adaptation_purity = ||Delta c_CF||/||Delta c_F||` 作为 purity fraction、performance score 或主要论文结论；仅可保留 provenance。

`NUMERICAL_FAILURE` 只包括 simulation abort、missing required output、NaN、Inf、validator failure、corrupt result。不得以性能误差事后定义 pass/fail threshold；本轮只统计 numerical/execution failure count。

## 8. Monte-Carlo freeze

- Cohorts：H healthy/drift、F fault only、O simultaneous drift+fault。
- Pilot：每 cohort N=20，是 formal registry 的前 20 个，不是额外样本。
- Formal：每 cohort N=50，共 150 stochastic conditions、600 algorithm evaluations；四算法共享 condition data。
- Step 1C 必须分别冻结 `truth_seed`、`noise_seed`。
- Candidate variables：SNR、reference phase error、fault factor、fault onset、Cs initial value、drift amplitude、drift rate、Cself mismatch；各 cohort 只启用适用子集。
- Negative sequence 与 CsAC 不进入 primary MC。

推荐分布提案标记为 `DISTRIBUTION_PENDING_STEP1C_REGISTRY_FREEZE`：

- SNR：在 `{20,30,40 dB}` 等概率分类抽样，`Inf` 保留为 deterministic control；
- reference phase error：在六个冻结 levels 中等概率分类抽样；
- fault factor：F 使用六个冻结 fault levels，O 使用 `{1.10,1.30,1.60}`，均为等概率分类；
- drift rate：在 `{0.5,1,2}` 中等概率分类；
- Cself mismatch：在七个冻结 levels 中等概率分类；
- fault onset、Cs initial value、drift amplitude：采用独立有界分布的原则，但数值 bounds 尚未冻结，标记 `BOUNDS_UNRESOLVED_STEP1C`，不得在 Step 1B invent numbers；
- 不允许用高度相关变量重复控制同一物理量。

若 N=50 因 runtime/memory/storage 无法执行，只能在查看正式性能统计前提交 `PROTOCOL_AMENDMENT`，记录证据、时间和原因；不能依据算法表现改变 N。

## 9. Budget and scope boundary

理论预算见 `STEP1B_EXPERIMENT_BUDGET.md`。冻结口径为：54 个 unique deterministic physical conditions；主矩阵 216 个 condition×algorithm evaluations，其中 30 个已有冻结结果可直接复用、2 个 Case07/08 M0 缺失、184 个来自 46 个新增条件。另有 10 个 sensitivity evaluations 和 4 个新增 replay trajectory evaluations，总 deterministic planned evaluations 为 230。Formal MC 独立为 150 conditions、600 evaluations；pilot 是其子集。

正式排除项见 `STEP1B_SCOPE_EXCLUSIONS.md`。

## 10. Required final answers

1. **正式 Phase 2 algorithm set？** M0、M2、M3、M4；不得增加第五个主算法。
2. **Fault amplitude levels？** 1.05、1.10、1.20、1.30、1.40、1.60；1.0 仅为 control。
3. **SNR levels？** Inf、40、30、20 dB。
4. **Reference phase error levels？** 0、0.33、0.5、1、2、3 deg，按 Phase 1B 正方向定义。
5. **Third harmonic 扫什么？** 只扫 amplitude 0.5%/2%/5%/8%/10%，固定 phi3=0°；不扫 amplitude×phase。
6. **Negative sequence levels？** 0、1%、3%、5%；内部 convention 仍 `UNRESOLVED`。
7. **Cself mismatch 符号？** `100*(truth-algorithm)/algorithm`，正值表示 truth 大于 400 pF assumption。
8. **Cself truth levels？** 360、380、392、400、408、420、440 pF；algorithm 始终 400 pF。
9. **CsAC 是否进入 Phase 2？** 是，作为 deterministic unmodelled-coupling mismatch axis；不进入 MC。
10. **如何不修改 AutoComp9？** 用独立 external-data wrapper 在 ideal physical current 后、formal noise 前注入 A-C 电流，并先通过 CsAC=0 zero-injection regression。
11. **Drift rate 如何定义？** 固定总向量，以 cubic-smoothstep duration `1.40/r` 改变时间尺度；levels 0.5x/1x/2x。
12. **Drift directions？** D1=[+3,-2]、D2=[-3,+2]、D3=[+3,+2] pF，L2 均为 sqrt(13) pF。
13. **Overlap core 多大？** 3 rates × 3 factors = 9 conditions。
14. **Direction extension 多大？** 原始 6 点，去除与 core 重复的 D1 两点后新增 4 unique conditions。
15. **Counterfactual replay 是否纳入？** 是，作为 Case08 上 M3/M4 causal addendum。
16. **Equivalence gate？** 相同输入与记录 schedule 的 natural-schedule replay 必须在项目数值容差内复现 frozen trajectory；否则 `COUNTERFACTUAL_REPLAY=BLOCKED`。
17. **Primary metrics？** Healthy/drift：Cs1/2 RMSE；persistent fault：true/estimated factor、retention error、signed fault-induced Cs1/2 change及其 bias norm；temporary overlap：Cs1/2 overlap RMSE、W1/W2 retention，并强制保存 signed movement vectors。
18. **禁止哪个历史 metric 作主要评价？** `drift_adaptation_purity`；ISR 也不能解释为 final bias reduction。
19. **MC pilot N？** 20 per cohort，3 cohorts 共 60 conditions/240 evaluations，是 formal 子集。
20. **Formal MC N？** 50 per cohort，共 150 conditions/600 evaluations。
21. **Negative sequence / CsAC 进 primary MC？** 不进入。
22. **正式排除什么？** Harmonic phase 独立 sweep、per-phase Cself、一般传感器链、全 direction×rate×fault 网格、negative-sequence/CsAC MC、新 detector threshold、detection/false-alarm 主指标、新算法、结果驱动优化。
23. **理论 budget？** 54 deterministic physical conditions、216 main evaluations；加 10 sensitivity 与 4 incremental replay 后为 230 deterministic evaluations。Formal MC 另计 150 conditions/600 evaluations；全部合计 204 physical/stochastic conditions、830 evaluations/trajectories。Pilot 不重复计数。
24. **是否运行任何新 Simulink？** 否。
25. **是否修改任何 frozen source？** 否，仅新增本步骤七个中间文件。

## 11. Stop condition

```text
STEP 1B STATUS:
COMPLETE

NEW PHASE2 SIMULATION:
NO

FROZEN SOURCE MODIFIED:
NO

STEP 1C STARTED:
NO
```

