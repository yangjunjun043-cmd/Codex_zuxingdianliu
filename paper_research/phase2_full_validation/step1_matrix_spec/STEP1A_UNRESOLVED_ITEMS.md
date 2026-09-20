# Phase 2 Step 1A — Unresolved Items

本文件只记录 Step 1A 结束时仍缺少正式定义或仍需人工冻结的事项。它不是 Phase 2 condition matrix，也不授权执行 Step 1B 或新仿真。

## 1. Condition matrix 尚未冻结

- Phase 2 最终 axis、level、配对规则、随机化规则和运行数量尚未定义。
- 当前不得生成完整笛卡尔积。
- Case01–Case08 可以作为冻结 anchor 复用，但它们是否全部进入 Phase 2 主表，留待 Step 1B–1D 决定。

## 2. Drift rate 的正式定义

Case02、Case03、Case06–Case08 都采用 cubic smoothstep。`Delta C / duration` 只是本审计报告的平均向量率；真实瞬时率随时间变化。Step 1B 需要决定 Phase 2 的 `drift_rate` 指：

- 平均向量率；
- 最大瞬时向量率；
- smoothstep 时间尺度；
- 或每周期最大真值变化。

同时必须保证改变 rate 时不改变总 `Delta Cs`，否则会混入幅值效应。

Case04 是持续的 seeded sinusoidal + moving-average random path，没有单一 final value、drift vector 或 rate。相关字段保持 `UNRESOLVED`。

## 3. Reference phase 与一般 model mismatch

Phase 1B 正式 `reference_phase_error` 已解决：它是只作用于重构参考的相干时间偏移，基波增加 `delta`，三次谐波增加 `3 delta`。但是：

- `reference/model mismatch` 是更宽泛术语，并不是一个独立冻结变量；
- 尚无独立的 50 Hz 与 150 Hz 相位误差接口；
- 尚无真实电场传感器增益、邻相场耦合、偏置、漂移、滤波或延迟模型。

因此不能把历史 phase sweep 当成一般传感器链路验证。

## 4. Negative sequence 的内部约定

已确认 `Vneg_pu` 被 cfg 传给 AutoComp9，正式注释将其定义为负序电压标幺比；历史非统一扫描使用 `0/0.01/0.03/0.05`。但本次审计读取的正式 Phase 1 源码和报告没有记录模型内部负序相位序列的精确数学式，因此该内部 convention 仍为 `UNRESOLVED`。

已有边界事实不受影响：单 B 相平衡假设参考在历史 1%/3%/5% 负序下出现约 11.193%/35.030%/61.991% 的 B 相基波误差，且当前没有 validity gate。

## 5. Cself mismatch 的独立控制

低层接口原则上可分开：AutoComp9 接收 `Cself_pF` 作为 truth，算法函数接收 `selfPF` 作为 assumption。但所有正式 runner 都从同一 `cfg.Cself_pF=400 pF` 同时构造两者。

尚未冻结：

- `Cself_truth` 与 `Cself_algorithm` 的命名和传递方式；
- mismatch 正负号约定；
- 百分比相对哪一个量；
- 单相共同误差还是三相独立误差；
- 候选 level。

在这些内容冻结前，不能声称已有 Cself mismatch 接口或正式证据。

## 6. CsAC weak coupling

AutoComp9 正式 current equation、root external inputs、coupling regressor 和 resistive-current extractor都只有 `Cs1=AB` 与 `Cs2=BC`。没有 CsAC truth port、A-C current term或第三估计列。

因此 CsAC 目前不能通过现有正式接口在不改变证据生成路径的情况下独立注入。Step 1B 必须选择并冻结：

- 仅在外部 data wrapper 注入失配电流；
- 创建新的模型副本；
- 或本轮 Phase 2 不包含该 axis。

不得修改 AutoComp9。

## 7. Counterfactual causal confounding

Phase 1B 的 M2 replay 在同一个递归算法内使用：

- F branch：`y_fault`；
- CF branch：`y_fault-r_fault`；
- 两分支故障前状态相同，之后独立递归。

由于 M2 没有保护控制，`c_F-c_CF` 可用于隔离 fault observation 对 M2 递归状态的影响。

Phase 1C Case07/08 则对 F、CF 数据分别完整运行 M3/M4。故障会改变 M3 gate 或 M4 `g`，所以：

```text
c_F - c_CF
= direct fault-related parameter effect
+ protection-schedule-mediated drift-learning difference
```

Step 5B 明确记录 optional protection-schedule replay 未执行。因此：

```text
CAUSAL_CONFOUNDING_REMAINS
```

本步骤不修复。Step 1B 需决定是否预注册 Protection-Schedule Counterfactual Replay；任何实现都不得修改冻结 M3/M4 core。

## 8. Evaluation-window 统一规则

Phase 1 存在三套正式窗口：

- 全局：`t >= 0.80 s`；
- persistent fault：pre `[2.60,2.90)`、post `[3.40,3.80)`；
- overlap：W0–W4，以及 Case08 exact M3 gate interval。

Phase 2 尚未决定哪些指标使用哪套窗口，也未定义跨不同 fault timing 的窗口归一化规则。不同算法必须共享同一 condition data 和同一窗口，但不能把不同 case 的窗口无标签合并。

## 9. Candidate range 依据不足

以下候选值有 Phase 1B 正式依据：

- fault factor：`1.05/1.10/1.20/1.30/1.40/1.60`，但只有 M2 mechanism sweep；
- reference phase error：`0/0.33/0.5/1/2/3 deg`；
- overlap factors：`1.30/1.60` 两个冻结 anchor。

以下范围仅有 pre-unified historical evidence，不是 Phase 1A/B/C 的完整 M0/M2/M3/M4 正式验证：

- SNR：`Inf/40/30/20 dB`；
- third-harmonic ratio：`0.5%/2%/5%/8%/10%`；
- third-harmonic phase：`0/1/3/5/10 deg`；
- negative sequence：`0/1%/3%/5%`。

以下尚无正式候选范围：

- Cself mismatch；
- CsAC weak coupling；
- controlled drift-rate levels；
- controlled drift-direction rotations；
- Monte-Carlo 联合分布和样本量；
- fault timing/ramp sweep。

## 10. New metrics requiring freeze

Phase 1 没有正式定义以下指标：

- fault detection rate；
- false-trigger rate；
- missed-trigger rate；
- robustness failure rate；
- Phase 2 pass/fail threshold；
- 多条件统计 P95 的统一 signed/absolute 规则。

这些全部标记为 `NEW_METRIC_REQUIRES_FREEZE`。

## 11. Historical artifact boundaries

旧 `results_phase1` SNR/harmonic/negative-sequence 结果可作为范围和失败边界的历史依据，但其执行链不是 Phase 1A-C 的统一 AutoComp9 + M0/M2/M3/M4 schema，不能升级为 `EXACT_REUSE`。

## 12. Read-only model inspection note

本步骤尝试只读加载 AutoComp9 定位 `Vneg_pu/h3_ratio/phi3_deg` 的内部 block expression；未运行仿真。MATLAB 在当前受限首选项目录环境中先出现权限错误，改用隔离 preference 目录后又在模型遍历时异常退出。因此没有从失败命令推断内部公式，负序内部 convention 保持 `UNRESOLVED`。
