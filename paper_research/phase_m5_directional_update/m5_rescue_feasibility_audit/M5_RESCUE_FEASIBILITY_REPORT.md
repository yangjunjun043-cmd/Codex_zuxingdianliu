# M5-v2 Rescue Feasibility Audit

## 审核结论

OLD_M5_STATUS: **FAILED_ROBUSTNESS / FROZEN**

SCORE_SPACE_FAULT_ALIGNMENT: **PHASE1B ONLY; NOT STABLY CONCENTRATED ACROSS CASE05/CASE06; STEP5 NOT EVALUABLE**

LEGITIMATE_SEPARABILITY: **INSUFFICIENT; CASE06 SHOWS MATERIAL OVERLAP; STEP5 ORTHOGONAL SEPARATION NOT EVALUABLE**

ONLINE_TEMPLATE_AVAILABLE: **NO**

NEW_TUNABLE_HYPERPARAMETERS: **0**

PHYSICAL_DATA_REUSE: **NO**

M5_RESCUE: **NO_GO**

M5-v1 的正式 Step5 结论保持 `STEP5 = STOP`。本审核没有修改、覆盖或重新解释该结论，也没有实现 M5-v2。

## 1. 审核范围与数据来源

本审核只读取既有冻结数据：

- Phase1B Case05：`observation_blocks_case05.mat` 与 `case05_mechanism_workspace.mat`；
- Phase1B Case06：`observation_blocks_case06.mat` 与 `case06_mechanism_workspace.mat`；
- M5 Step5：150 个冻结 physical conditions 的 `internal/cycle_logs/*.mat`、冻结 robustness matrix 及正式结果表。

没有调用 Simulink，没有生成新的物理样本，没有修改 M4、REW、gate、M5-v1、方向、窗口、阈值、增益或平滑常数。CSV 保留 2,184 个周期级配对记录，其中 Phase1B 330 行、Step5 1,854 行。数值零附近的有效性判定原样复用当前 M4/M5 中的 `sqrt(eps)`、条件数和 invalid-direction fallback；它不是新增的可调参数。所有不可计算行仍保留，并通过 validity 字段和 `invalid_reason` 说明原因。

## 2. Exact information innovation 验证

审核严格使用

\[
q_{total}=h_{star}-(J_{star}+10^{-10}I)\theta_{previous}.
\]

对 Phase1B 的冻结 observation blocks 重放实际 M2 状态递推；对 Step5 直接读取每个 F/CF 周期保存的 `J_star`、`h_star`、`theta_previous`、`theta_M2_raw` 与 `delta_raw`。全体记录满足：

- `theta_M2_raw = (J_star + reg I) \ h_star`：最大绝对误差 **0**；
- `Delta_theta_raw = (J_star + reg I) \ q_total`：最大绝对误差 **9.326e-15 pF**。

误差处于双精度舍入范围，说明 score-space 定义与实际 raw proposal 一致，没有使用近似替代式。

## 3. 在线 score template

Phase1B 保存了完整 `X`、`y_fault`、`y_counterfactual`、时间轴及参考相位。因此，可按预先指定的第一版定义构造模板：先将当前 F 分支的 B 相 residual 投影到 M4 已有的 50/150 Hz in-phase basis，再计算 `v_fault = X' * r_hat_fault` 并归一化。该过程只使用 F 分支当前可观测量，不使用 truth 或 counterfactual；CF 仅用于离线构造审核目标 `q_fault`。

Step5 cycle logs 只保存周期级 tracker 字段，未保存下列任一足够集合：

- `X/y_F/y_CF`；
- `u/i/time` 全波形及可恢复 `X/y` 的参考导数；
- B 相 residual waveform 或 in-phase coefficients；
- 全时间轴的物理波形、噪声 realization 与逐周期 tracker 输入。

因此，Step5 的 `q_F`、`q_CF`、`q_fault` 和 raw parameter increment 可以精确恢复，但预注册的 B 相在线模板不能恢复。审核没有用 `q_fault`、counterfactual、truth 或数据驱动主轴替代模板，因为这些替代会改变模板定义或引入在线不可用信息。

## 4. Fault alignment 与 parameter-space 对照

下表只统计 template、`q_fault` 和 `q_legitimate` 均通过既有 numerical-validity fallback 的相同周期。alignment 使用绝对余弦，1 表示轴向一致；angle 为对应锐角。

| 数据 | 有效周期 | score alignment median / P90 / max | score angle median / P90 / max | score directional-energy ratio median | 旧 parameter alignment median / P90 / max |
|---|---:|---|---|---:|---|
| Case05 | 22 | 0.9919 / 1.0000 / 1.0000 | 7.16° / 25.46° / 82.24° | 0.9839 | 0.9209 / 0.9999 / 1.0000 |
| Case06 | 28 | 0.7824 / 0.9991 / 1.0000 | 38.50° / 67.09° / 79.26° | 0.6124 | 0.9743 / 0.9998 / 1.0000 |
| 合并 | 50 | 0.9509 / 0.9999 / 1.0000 | 18.00° / 66.85° / 82.24° | 0.9043 | 0.9458 / 0.9999 / 1.0000 |

Case05 的 score alignment 中位数高于旧 parameter alignment，但 Case06 的中位数下降至 0.7824，并低于同周期 parameter alignment 0.9743。Case06 的 angle P90 为 67.09°。因此，score-space 方向没有在两个优先 Phase1B case 中表现为一致的集中方向，也没有满足“明显不差于 parameter-update space”的条件。Step5 nuisance 下没有可用在线模板，不能把 Phase1B 的局部结果外推为 robustness 结论。

## 5. Legitimate-update separability

`q_legitimate` 使用同周期 CF/drift 分支的 exact information innovation。separation margin 定义为 `fault_alignment - legitimate_alignment`。

| 数据 | legitimate alignment median | separation median | separation P10 | separation > 0 fraction |
|---|---:|---:|---:|---:|
| Case05 | 0.6455 | 0.3379 | -0.0159 | 0.9091 |
| Case06 | 0.6859 | 0.0137 | -0.2856 | 0.6071 |
| 合并 | 0.6732 | 0.1859 | -0.2688 | 0.7400 |

Case06 的 separation 中位数接近零，11/28 个有效周期的 margin 不大于零。该重叠不是少数尾部异常，不能支持清晰的 fault-versus-legitimate separation。Step5 中 ORTHOGONAL、MIXED、PARALLEL 的模板 alignment 均不可计算，所以关键的 ORTHOGONAL 外部验证条件未得到证据支持。

## 6. J-metric projector 次级审计

审核使用固定 `d_f=[1,-1]/sqrt(2)` 计算

\[
\Pi_{f,J}=d_f(d_f^T J_{star}d_f)^{-1}d_f^T J_{star}.
\]

在 Step5 的三个 geometry 中，`||Pi_f_J - Pi_f_E||_F` 的中位数均为 **3.237e-16**，P90 均为 **8.455e-16**。对 fault-induced raw increment 的 effective decomposition change 中位数约 **2.22e-16**，P90 约 **3.46e-16**。在本冻结设计中，J-metric projector 与旧 Euclidean projector 在数值精度内等价；information geometry 不能解释 M5-v1 的 Step5 robustness failure，也没有提供独立救援依据。

## 7. Physical data reuse 审核

`PHYSICAL_DATA_REUSE = NO`。现有 Step5 输出不足以仅重跑 tracker 而避免 450 次 Simulink calls。除了上节列出的 `X/y` 和波形缺失外，cycle logs 只覆盖正式 overlap windows，而不是从初始化到结束的完整 tracker 输入序列。未来若需 tracker-only reanalysis，必须在不改动物理设计的前提下预先冻结并保存至少以下数据：

1. F/CF 的 `t, ua, ub, uc, ia, ib, ic` 或逐周期 `X, y_F, y_CF`；
2. `ref.ua/ref.ub/ref.uc/ref.dua/ref.dub/ref.duc`；
3. B 相 residual decomposition 所需的 basis coefficients 或可重建 waveform；
4. 精确噪声 realization，而不只是 seed/signature；
5. 初始化后的完整逐周期输入与状态边界。

这些缺失项是数据留存问题，不授权重新运行本次审核的物理仿真。

## 8. GO / NO-GO 逐项判断

| 条件 | 结果 | 依据 |
|---|---|---|
| Phase1B 与 Step5 nuisance 中方向稳定集中 | FAIL | Case06 分散；Step5 template 不可恢复 |
| 稳定性明显不差于旧 parameter space | FAIL | Case06 score median 0.7824，parameter median 0.9743 |
| Orthogonal legitimate separation 清晰 | NOT DEMONSTRATED | Step5 ORTHOGONAL 无法计算 template alignment |
| 在线 template 仅依赖现有可观测量 | PARTIAL / FAIL FOR FROZEN STEP5 | Phase1B 可构造；Step5 输出不足 |
| 新增 tunable scalar 为零 | PASS | 没有新增 threshold、gain 或 smoothing constant |
| 可形成 state-consistent RLS | ALGEBRAICALLY POSSIBLE, NOT SUFFICIENT | exact identities 通过；其余 GO 条件失败 |

`M5_RESCUE = NO_GO`。fault score 与 legitimate score 在 Case06 仍有大量重叠，且 Step5 nuisance 数据无法验证在线模板和 ORTHOGONAL separability。依据预注册规则，M5 到此结束；不得据此设计 M5-v3，也不得自动进入新的性能实验。

## 9. 可复核性与文件说明

`M5_RESCUE_SCORE_AUDIT.csv` 保存所有周期级 raw values、validity flags、identity errors、score/parameter alignment、separation、J-metric projector 差异、phase-error、rate/projection-active 状态及不可计算原因。NaN 表示预注册量无法从冻结数据计算，不代表零或改善。

FUNCTIONAL-COMPLETENESS RETROSPECTIVE

- Scope covered: Phase1B Case05/06 与 Step5 150 个冻结 physical conditions 的 score-space feasibility audit。
- Authority and locks: M5-v1 `STEP5 = STOP` 保持冻结；未修改冻结算法、数据或判据。
- Alignment: exact information identities 通过；在线 template 与 Step5 输出的数据留存不匹配。
- Change propagation: 仅新增本报告和周期级 CSV。
- Deterministic and visual checks: MATLAB 数值核对完成；CSV 结构审计另行执行；无图形输出要求。
- Open issues and unknowns: Step5 缺少 X/y/波形，导致 score alignment 与 ORTHOGONAL separability 不可验证。
- Readiness: **not ready for M5-v2 preregistration; M5 rescue closed as NO_GO**。
