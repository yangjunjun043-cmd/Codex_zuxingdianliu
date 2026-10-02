# M5 Step5 Robustness / Monte-Carlo 决策报告

## 1. 正式状态

`STEP5 = STOP`。本报告严格执行 Step5A 冻结矩阵；未修改算法、方向、门控、约束、registry、seed、geometry、窗口或端点。

```text
STEP5_READY: PASS
PHYSICAL: 150 / 150
ALGORITHM_EVALUATIONS: 600 / 600
SIM_CALLS: 450 / 450
TRACKER_BRANCHES: 1200 / 1200
STEP5: STOP
STEP6_AUTHORIZED: NO — pending human review
```

## 2. Execution integrity

- 注册行：600/600；唯一 physical conditions：150/150；geometry pairs：50/50。
- 完整 evaluations：600/600；duplicates：0；simulation abort：0；metric missing：0。
- 实际 physical simulations：450；tracker branches：1200；runtime：37041.6 s。
- 四算法共享数据签名：PASS；三 geometry 标准化 noise draw 配对：PASS。
- Batch modes：`CLEAN_FAST_RESTART_BATCH|NOISY_F_CF_FAST_RESTART_BATCH`。

### 冻结哈希

| 对象 | 执行前 | 执行后 | 一致 |
|---|---|---|---|
| `source registry` | `8A498E19A455C13CAA7B5371BE2F933CA7B7637B893C656C92DA84D88D1938BE` | `8A498E19A455C13CAA7B5371BE2F933CA7B7637B893C656C92DA84D88D1938BE` | YES |
| `model` | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` | YES |
| `config` | `D9F3E6894F51C3D978421C9E1E93828A9205F418C77D01AC449B994A3D789726` | `D9F3E6894F51C3D978421C9E1E93828A9205F418C77D01AC449B994A3D789726` | YES |
| `tracker` | `8B580215A6268F4AC3BF27FB357DB6A4A01027DD2410C7FF59EA3C4B46DA4DDB` | `8B580215A6268F4AC3BF27FB357DB6A4A01027DD2410C7FF59EA3C4B46DA4DDB` | YES |
| `projector` | `47D2C12DB80F4BBFE7CE296841074DB6F3FF641CD769907666292E4398E06CA7` | `47D2C12DB80F4BBFE7CE296841074DB6F3FF641CD769907666292E4398E06CA7` | YES |
| `regressor` | `7582F66875A1099DF9656F9A89FE12D8FF6972C55D4A034736527A7DB00E03D5` | `7582F66875A1099DF9656F9A89FE12D8FF6972C55D4A034736527A7DB00E03D5` | YES |
| Step5 matrix | `3BC7206A20A01BF677522D56BAE9D7A497226162E386495763435733D38D5E66` | `3BC7206A20A01BF677522D56BAE9D7A497226162E386495763435733D38D5E66` | YES |

## 3. Geometry × weight 汇总

| Geometry | Weight | Valid N | Median Δperp (pF) | P10 | P25 | P75 | P90 | Fraction Δperp<0 | Median Δtotal | Median Δparallel |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| ORTHOGONAL | CONTINUOUS | 50/50 | 0.00472447528 | -0.0940520538 | -0.0539422561 | 0.141236933 | 0.255433691 | 0.340 | 0.0010743894 | -0.00630048264 |
| ORTHOGONAL | HARD | 50/50 | 0 | -0.276889505 | 0 | 0 | 0.682947523 | 0.100 | 0 | 0 |
| MIXED | CONTINUOUS | 50/50 | 0.00481367261 | -0.0191372403 | -0.0121436099 | 0.0412589679 | 0.240661589 | 0.300 | 0.00431619373 | -7.06788508e-05 |
| MIXED | HARD | 50/50 | 0 | -0.059318205 | 0 | 0 | 0.0911583497 | 0.140 | 0 | 0 |
| PARALLEL | CONTINUOUS | 50/50 | 0.00164071794 | -0.0136875886 | -0.00465111279 | 0.0215495229 | 0.180015633 | 0.320 | 0.00070980735 | 6.21835987e-07 |
| PARALLEL | HARD | 50/50 | 0 | -0.144469957 | 0 | 0 | 0.0471357446 | 0.120 | 0 | 0 |

## 4. Orthogonal continuous — primary

50/50 pairs finite。`median Delta_perp_cont = 0.00472447528 pF`，改善比例 `34.0%`。P10/P25/P75/P90 = -0.0940520538 / -0.0539422561 / 0.141236933 / 0.255433691 pF。Gate A = **FAIL**。

## 5. Orthogonal hard

50/50 pairs finite。`median Delta_perp_hard = 0 pF`，改善比例 `10.0%`。P10/P25/P75/P90 = -0.276889505 / 0 / 0 / 0.682947523 pF。Gate B = **DESCRIPTIVE_FAIL**；该 Gate 仅作机制描述。

## 6. Mixed

Continuous 的 median Δperp = 0.00481367261 pF，改善比例 30.0%，median Δtotal = 0.00431619373 pF。反向恶化比例为 56.0%；预注册 red flag NOT_TRIGGERED。Gate C = **PASS**。

## 7. Parallel validity boundary

全部 50 continuous pairs 与 50 hard pairs 已保留。Continuous median Δperp = 0.00164071794 pF，改善比例 32.0%。该 geometry 无 superiority threshold；Gate D = **RETAINED**。

## 8. Phase-error stratification

| Geometry | Weight | Phase error (deg) | N | Median Δperp | Fraction Δperp<0 |
|---|---|---:|---:|---:|---:|
| ORTHOGONAL | CONTINUOUS | 0 | 6 | 0.120756098 | 0.167 |
| ORTHOGONAL | CONTINUOUS | 0.33 | 8 | 0 | 0.375 |
| ORTHOGONAL | CONTINUOUS | 0.5 | 8 | 0.00397624864 | 0.250 |
| ORTHOGONAL | CONTINUOUS | 1 | 9 | -0.0396864879 | 0.556 |
| ORTHOGONAL | CONTINUOUS | 2 | 5 | 0 | 0.200 |
| ORTHOGONAL | CONTINUOUS | 3 | 14 | 0.0347695461 | 0.357 |
| ORTHOGONAL | HARD | 0 | 6 | 0.319155141 | 0.000 |
| ORTHOGONAL | HARD | 0.33 | 8 | 0 | 0.000 |
| ORTHOGONAL | HARD | 0.5 | 8 | 0 | 0.250 |
| ORTHOGONAL | HARD | 1 | 9 | 0 | 0.111 |
| ORTHOGONAL | HARD | 2 | 5 | 0 | 0.000 |
| ORTHOGONAL | HARD | 3 | 14 | 0 | 0.143 |
| MIXED | CONTINUOUS | 0 | 6 | 0.0313203126 | 0.333 |
| MIXED | CONTINUOUS | 0.33 | 8 | 0.0110824344 | 0.250 |
| MIXED | CONTINUOUS | 0.5 | 8 | 0.0101496481 | 0.250 |
| MIXED | CONTINUOUS | 1 | 9 | 0.00404898479 | 0.444 |
| MIXED | CONTINUOUS | 2 | 5 | 0 | 0.200 |
| MIXED | CONTINUOUS | 3 | 14 | 0.012811458 | 0.286 |
| MIXED | HARD | 0 | 6 | 0.0710267268 | 0.000 |
| MIXED | HARD | 0.33 | 8 | 0 | 0.000 |
| MIXED | HARD | 0.5 | 8 | 0 | 0.375 |
| MIXED | HARD | 1 | 9 | 0 | 0.111 |
| MIXED | HARD | 2 | 5 | 0 | 0.000 |
| MIXED | HARD | 3 | 14 | 0 | 0.214 |
| PARALLEL | CONTINUOUS | 0 | 6 | 0.00253348345 | 0.167 |
| PARALLEL | CONTINUOUS | 0.33 | 8 | 0.00536032835 | 0.000 |
| PARALLEL | CONTINUOUS | 0.5 | 8 | 0.0020099332 | 0.250 |
| PARALLEL | CONTINUOUS | 1 | 9 | 0.00196399023 | 0.444 |
| PARALLEL | CONTINUOUS | 2 | 5 | 0 | 0.400 |
| PARALLEL | CONTINUOUS | 3 | 14 | -0.0023255564 | 0.500 |
| PARALLEL | HARD | 0 | 6 | 0 | 0.167 |
| PARALLEL | HARD | 0.33 | 8 | 0 | 0.000 |
| PARALLEL | HARD | 0.5 | 8 | 0 | 0.125 |
| PARALLEL | HARD | 1 | 9 | 0 | 0.111 |
| PARALLEL | HARD | 2 | 5 | 0 | 0.000 |
| PARALLEL | HARD | 3 | 14 | 0 | 0.214 |

## 9. Projection / rate-limit boundary

| Geometry | Weight | Projection active | Rate active | Both inactive | Valid pre angles | Median pre angle | Median |pre→rate| | Median |rate→projection| |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| ORTHOGONAL | CONTINUOUS | 14/50 | 10/50 | 36/50 | 50/50 | 49.2036 | 6.39488e-14 | 0 |
| ORTHOGONAL | HARD | 12/50 | 10/50 | 38/50 | 50/50 | 70.5756 | 0 | 0 |
| MIXED | CONTINUOUS | 16/50 | 14/50 | 34/50 | 50/50 | 34.9204 | 1.39888e-13 | 0 |
| MIXED | HARD | 15/50 | 12/50 | 35/50 | 50/50 | 48.2171 | 2.66454e-15 | 0 |
| PARALLEL | CONTINUOUS | 16/50 | 15/50 | 34/50 | 50/50 | 36.1883 | 1.70974e-13 | 0 |
| PARALLEL | HARD | 16/50 | 14/50 | 34/50 | 50/50 | 46.9961 | 2.66454e-15 | 0 |

## 10. Negative results retained

- ORTHOGONAL/CONTINUOUS：Δperp>0 为 26/50；最大退化 0.472110935 pF，condition `M5_S5_O049_ORTHOGONAL`。
- ORTHOGONAL/HARD：Δperp>0 为 8/50；最大退化 1.57207504 pF，condition `M5_S5_O039_ORTHOGONAL`。
- MIXED/CONTINUOUS：Δperp>0 为 28/50；最大退化 2.04106897 pF，condition `M5_S5_O049_MIXED`。
- MIXED/HARD：Δperp>0 为 6/50；最大退化 1.4938557 pF，condition `M5_S5_O049_MIXED`。
- PARALLEL/CONTINUOUS：Δperp>0 为 26/50；最大退化 2.26515842 pF，condition `M5_S5_O049_PARALLEL`。
- PARALLEL/HARD：Δperp>0 为 7/50；最大退化 1.96970325 pF，condition `M5_S5_O049_PARALLEL`。

## 11. 科学问题回答

1. **Q1–Q2：** Orthogonal continuous 的稳定性由 50/50 raw pairs、median 0.00472447528 pF 和 34.0% 改善比例给出；按 Gate A 判为 FAIL。
2. **Q3：** Hard directionality 的 median 为 0 pF，改善比例 10.0%，描述性 Gate B 为 DESCRIPTIVE_FAIL。
3. **Q4：** Mixed continuous median Δperp 为 0.00481367261 pF，改善比例 30.0%；red flag NOT_TRIGGERED。
4. **Q5：** Parallel 100 个 matched pairs 全部保留，结果不用于 superiority Gate，符合 identifiability boundary 的预注册处理。
5. **Q6：** 第 8 节只按冻结 phase levels 报告，不新增分层；方向性 benefit 是否随 phase error 减弱以表中 median 和改善比例描述。
6. **Q7：** 第 9 节报告 projection/rate activation 及 pre→post angle rotation；near-zero angles 在原始结果中保持 NaN。
7. **Q8：** Step4 mechanism 在 Step5 中的支持状态由 Gate A、C、D、E 合并判定；Step5 = STOP。

## 12. Gates 与最终决定

| Gate | Result |
|---|---|
| Gate 0 execution integrity | PASS |
| Gate A Orthogonal continuous | FAIL |
| Gate B Orthogonal hard | DESCRIPTIVE_FAIL |
| Gate C Mixed | PASS |
| Gate D Parallel | RETAINED |
| Gate E method integrity | PASS |
| **STEP5** | **STOP** |

`STEP6_AUTHORIZED = NO — pending human review`。即使 Step5 为 GO，本轮也不会自动执行 Step6。
