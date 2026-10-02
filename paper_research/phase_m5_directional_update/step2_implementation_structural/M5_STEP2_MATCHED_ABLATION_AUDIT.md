# M5 Step2 matched ablation 审计

## Q1. 为什么冻结 M3/M4 不能被严格解释为 operator-matched 2×2 factorial controls？

冻结 M3 的 hard gate 会在 gate 激活时保持旧的 `J/h/theta`，冻结 M4 则对信息矩阵增量和信息向量增量实施全局权重；它们与 M5 的“先形成同一 unweighted M2 raw proposal，再对参数增量施加 operator，并重构 h”不是同一内部 state realization。因此直接比较 M3 vs M5-DH 或 M4 vs M5-Full，会同时混入 scope 和内部状态实现差异，不能把差异唯一归因于 Global vs Directional。冻结 M3/M4 仍是历史参考基线，不是严格配对对照。

## Q2. GH 与 M5-DH 是否仅有 Global vs Directional 这一项结构差异？

**是。** 两者共享同一 `delta_raw`、`J_star/h_star`、hard gate、`w_hard`、h reconciliation、rate limit、box projection、baseIn 语义和日志路径。唯一变化是：GH 使用 `w_hard*I`，M5-DH 使用 `P_perp+w_hard*P_f`。结构测试还验证了：完全平行输入时输出相同；完全 perpendicular 输入时 directional 原样通过而 global 乘以 `w`。

## Q3. GC 与 M5-Full 是否仅有 Global vs Directional 这一项结构差异？

**是。** 两者共享同一 `delta_raw`、`J_star/h_star`、冻结 `m4_fault_evidence` 返回的同一 `w_REW`、h reconciliation、rate limit、box projection、baseIn 语义和日志路径。唯一变化是：GC 使用 `w_REW*I`，M5-Full 使用 `P_perp+w_REW*P_f`。

## Q4. Hard vs Continuous 是否复用原有 gate/REW weight 且没有新参数？

**是。** Hard 使用继承的 M3 `gate` 与 `w_hard=1-gate`；Continuous 每周期只调用一次冻结 `m4_fault_evidence` 并直接使用其 `update_weight`。代码没有新增 threshold、gain、floor 或 exponent。单元测试中的 `forced_selected_weight` 只用于 `w=0/1` 代码等价和中间权重代数测试，不参与自然生产 smoke，也不计为算法可调超参数。

## Q5. 未来 Step4 factorial ablation 是否已经具有 clean interpretation？

**结构上是。** 当前四格为 GH、GC、M5-DH、M5-Full；Factor A 仅改变 scope（Global/Directional），Factor B 仅改变既有 weight type（Hard/Continuous）。结构检查和运行日志证明四者使用相同 raw proposal、状态协调及约束路径。因此未来在预注册并冻结实验设计后，可以把四格差异按这两个 factor 解释。当前 Step2 没有运行性能 factorial，也没有对交互效应作结论。

## 审计结论

GH/GC matched controls 的结构等价性检查通过；它们均明确标记为 `ABLATION_ONLY_*`，不是新增正式算法。No-double-REW 审计通过：M5-Full 从 unweighted M2 raw proposal 进入 operator，M4 tracker 调用数为 0，evidence helper 每周期调用一次。
