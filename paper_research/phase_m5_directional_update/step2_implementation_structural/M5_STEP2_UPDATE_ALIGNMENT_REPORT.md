# M5 Step2 更新级方向表征

## 1. 表征口径

本报告分析的是每周期 exact total `delta_raw = theta_M2_raw-theta_previous`，不是 local-LS 方向，也不是经过 M4 全局权重后的更新。方向分解固定为：

```text
delta_parallel = P_f*delta_raw
delta_perp = P_perp*delta_raw
parallel_energy_fraction = ||delta_parallel||^2 /
    (||delta_parallel||^2 + ||delta_perp||^2 + eps)
```

向量范数接近机器零时角度写为 `NaN`；方向反转周期通过 signed projection 单独保留。Step2 不设置 angle performance threshold，最终状态为 **UPDATE_LEVEL_ALIGNMENT = CHARACTERIZED**。

## 2. M5-Full 描述统计

| Case | Segment | cycles | mean parallel norm | mean perp norm | parallel energy fraction | mean selected weight | negative signed projection cycles |
|---|---|---:|---:|---:|---:|---:|---:|
| Case05 | PRE_FAULT | 115 | 0.019006 | 0.014127 | 0.601098 | 0.993788 | 61 |
| Case05 | FAULT_ACTIVE | 20 | 0.905204 | 0.074850 | 0.993249 | 0.388318 | 0 |
| Case05 | LATE_FAULT | 30 | 0.047292 | 0.024227 | 0.849248 | 0.361285 | 6 |
| Case06 | PRE_FAULT | 115 | 0.044538 | 0.021880 | 0.811647 | 0.989610 | 31 |
| Case06 | FAULT_ACTIVE | 20 | 0.890211 | 0.052565 | 0.996461 | 0.392988 | 0 |
| Case06 | LATE_FAULT | 30 | 0.046029 | 0.020450 | 0.851701 | 0.362647 | 6 |

Case05 全程 parallel energy fraction 为 `0.990529`，Case06 为 `0.991769`。这些全程值受到 fault-active 大幅更新的能量主导，不能替代分段结果。pre-fault 中仍存在明显的 perpendicular 成分和方向反转，说明 exact raw increment 并非逐周期恒定沿 `d_f`；数据没有被筛除或重标。

两个案例的 165 个周期均具有有效角度，near-zero raw cycle 为 0。两个案例都是持续故障，因此 `POST_FAULT` 为 unavailable，而不是用 late-fault 数据代替。

## 3. 约束边界记录

周期日志同时记录：

- `protected_angle_to_df_deg`；
- `post_rate_angle_to_df_deg`；
- `post_projection_angle_to_df_deg`；
- `rate_rotation_deg` 和 `projection_rotation_deg`；
- `rate_limit_active` 和 `projection_active`。

本次 Case05/06 的四种模式中，rate-limit 与 projection 激活次数均为 0，因此观察到的 projection rotation 为 0，global hard 在零更新区间的角度为 `NaN`。这验证了日志和 NaN 语义，但没有覆盖“约束真实激活”时的经验旋转分布。代码静态顺序已验证为 operator → reconciliation → rate → projection，projection 后无方向修正。

## 4. 解释边界

这些数据支持“所选故障阶段的 raw update 能量多数位于模型导出的 differential direction”这一描述性观察，同时也明确显示混合追踪周期和反向周期。它们不证明全工况 fully aligned，也不证明 directional operator 带来性能提升。
