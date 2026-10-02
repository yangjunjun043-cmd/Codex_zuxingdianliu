# M5 Step2 GO / NO-GO

## 判定

**STEP2 = GO**

仅表示 M5 implementation is structurally valid；不表示 M5 performance is superior。

## 决策清单

| 条件 | 结果 | 证据 |
|---|---:|---|
| Projector algebra tests | PASS | 8/8；最大误差 `2.22044604925031e-16` |
| `w=1` 还原 M2 proposal | PASS | delta/theta/h 端点全部在数值容差内 |
| `w=0` 去除 parallel component | PASS | leakage `3.92523114670944e-16` |
| 中间权重 0.25/0.50/0.75 | PASS | parallel 精确缩放、perpendicular 保持 |
| h reconciliation / solve-back | PASS | residual `0`；solve-back `7.85046229341888e-17` |
| 使用 unweighted M2 raw proposal | PASS | M5 直接由 `J_star/h_star` 计算 `deltaRaw` |
| 不存在 double REW | PASS | helper 每周期一次；无 M4 tracker/weighted token |
| rate/projection 顺序未改变 | PASS | raw → operator → reconcile → rate → project |
| production M5 不读取 truth/counterfactual | PASS | forbidden token count 0 |
| Case05 smoke 与完整 instrumentation | PASS | 4 模式 × 165 cycles，660 行 |
| Case06 smoke 与完整 instrumentation | PASS | 4 模式 × 165 cycles，660 行 |
| GH/GC matched controls | PASS | parallel/perpendicular 配对测试通过 |
| 新增 tunable scalar | PASS | `0` |
| 冻结 source hashes | PASS | 6/6 before/after 均与 Step1 一致 |
| Update-level alignment | CHARACTERIZED | 分段统计已保存；无 angle PASS threshold |
| Projection-boundary logging | PASS | 字段、NaN 语义和顺序完整；本次激活次数 0 |

## 限制与停止点

- `POST_FAULT` 在 Case05/06 中不可用，因为两个既有案例均为持续故障。
- Simulink 的既有未连接测量端口和 algebraic-loop 警告仍存在；本阶段未修改冻结模型。
- smoke 只证明运行与 instrumentation 完整，不是性能实验。
- 按任务边界在 Step2 停止；未进入 Step3、Step4、全矩阵或 Monte Carlo。
