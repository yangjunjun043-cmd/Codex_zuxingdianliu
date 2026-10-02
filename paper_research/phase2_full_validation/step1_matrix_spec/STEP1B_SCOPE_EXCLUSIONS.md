# Phase 2 Step 1B — Scope Exclusions

## 1. Formally excluded from the main Phase 2 scope

| ID | Excluded item | Reason / treatment |
|---|---|---|
| X01 | Independent harmonic-phase sweep | Main matrix freezes phi3=0° and sweeps amplitude only; historical phase points remain background evidence. |
| X02 | Per-phase independent Cself mismatch | Only three-phase common-mode truth mismatch is frozen, to avoid three new coupled degrees of freedom. |
| X03 | General sensor gain/bias/filter/delay model | Reference phase axis is the narrow Phase 1B coherent-shift definition, not a field-sensor chain. |
| X04 | Full direction × rate × fault Cartesian product | Use the 9-point core plus 4 new unique direction-extension points. |
| X05 | Negative sequence in primary Monte-Carlo | Keep as deterministic validity-boundary test; internal phase convention remains unresolved. |
| X06 | CsAC in primary Monte-Carlo | Keep as deterministic model-mismatch test subject to zero-injection regression. |
| X07 | New fault-detector threshold | Would change the method/evaluation problem and invite tuning. |
| X08 | Detection rate / false-alarm rate as primary metrics | No new detector is introduced; only frozen gate response diagnostics remain secondary. |
| X09 | Any new learning algorithm or M5 | Main algorithm set is M0/M2/M3/M4 only. |
| X10 | Results-driven parameter optimization | Sensitivity variants are descriptive only and cannot replace frozen parameters. |

## 2. Additional interpretation boundaries

- 不把 positive-only reference phase sweep解释为 signed lead/lag symmetry validation。
- 不把 negative-sequence configured sweep解释为完整机理证明，直到内部 convention 被独立恢复。
- 不把 CsAC external injection解释为 AutoComp9 已包含 A-C coupling。
- 不把 `information_suppression_ratio` 解释为 final bias reduction。
- 不把 `drift_adaptation_purity` 作为 purity fraction、performance score 或主要结论。
- 不定义 performance-based pass/fail threshold；failure rate 仅指 numerical/execution failures。
- 不从 Pilot 的算法表现决定 MC 是否扩样。
- 不因“不利”结果删除 D2/D3、低 SNR、大 mismatch 或任何预注册 level。

## 3. Future-work status

以上内容可以在论文中明确列为 scope limitation / future work，但不得在查看 Phase 2 结果后临时加入本轮主矩阵以修饰结论。任何扩展都需要新的 protocol amendment 或后续阶段冻结。

## 4. Step boundary

本文件不创建 Step 1C registry，不授权实现传感器模型、CsAC wrapper、counterfactual wrapper 或 Monte-Carlo runner。

