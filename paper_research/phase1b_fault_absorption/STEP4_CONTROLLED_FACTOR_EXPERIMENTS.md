# Phase 1B-4 — Controlled Factor Experiments

## 1. Scope and frozen boundary

本步骤只研究两个单因素：

- Experiment A：6 个 fault amplitude，reference phase error 固定为 `0°`；
- Experiment B：6 个 reference phase error，fault factor 固定为 `1.60`；
- `1.60 + 0°` 为共享基准，因此正式 unique conditions 为 11 个。

没有运行 6×6 全组合，没有增加 diagnostic condition，没有执行 M4、Monte Carlo、完整鲁棒性扫描或 Step 5 相关性分析。

运行基准保持不变：

| 项目 | 值 |
|---|---|
| case | `Case05_fault_only` |
| seed | 106 |
| SNR | 30 dB |
| Cs1/Cs2 truth | constant 10 pF / 10 pF |
| fault ramp | 3.00–3.06 s |
| pre/post windows | `[2.60,2.90)` / `[3.40,3.80)` s |
| Git branch | `main` |
| Git commit | `91e1b3efc8d2bf637c3fa30865d44c7691330fe5` |

AutoComp9、Phase 1A、Step 1/2/3、原始 M2/M3、lambda、rate limit、projection、gate 参数均未修改。运行前后对 16 个关键冻结文件执行 SHA-256 校验，包括模型、Phase 1A CSV/workspace、Step1–3 报告、Step2/3 summary/workspace/observation blocks，以及 tracker、dispatcher、reference reconstruction 和 default config。

关键冻结哈希：

| 文件 | SHA-256 |
|---|---|
| `AI6109_MOA_AutoComp9.slx` | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| Phase 1A baseline CSV | `E7BEB3ECFEDF521105B67198684752BB32AFAAEFD84ACA80822BA57FBD9D0AB3` |
| Step 1 report | `02859DD0D35E35C18722B452DC7A5C9EE73B55CC6E7A26FC5566500F6E4B9041` |
| Step 2 report | `C98A2D9C53D6986EB4B9C202BEBC00DDD3A197B147615F68D5D073B652275CC1` |
| Step 3 report | `983BB31BDB297C7DC8086C663D85A2ADA3ED62717E48274AB722051A0371844F` |
| original M2 tracker | `033135775D81BE4521AA76B8C6C2C8C3415988DA8870561722779DB0FC485D7E` |

## 2. Controlled input definitions

### 2.1 Fault amplitude

Phase 1A 没有任意终值 fault factor 的 cfg 参数。Step 4 独立 wrapper 继续使用 AutoComp9 的原六个 root inputs，并只把第三个输入定义为：

```text
g_F(t) = 1 + (F - 1) s(t; 3.00 s, 3.06 s)
```

其中 `s` 是与冻结 Case05 相同的 smooth-step。Cs1/Cs2、模型、seed、sampling、SNR 和其余输入不变。

每个幅值条件都重新运行 AutoComp9。随机数在每个条件使用同一 `seed+10000` 重置；三相噪声使用相同标准化随机序列，并按各条件理想信号 RMS 缩放到 30 dB。标准化 noise signature 最大差为 `7.99e-15`；所有条件的实际三相 SNR 分别为约 `29.9986 / 29.9877 / 30.0089 dB`。

### 2.2 Reference phase error

相位误差直接复用现有 `reconstruct_refs_from_b` 入口。对拟合得到的 B 相参考：

```text
phi1_used = phi1_fitted + deg2rad(delta)
phi3_used = phi3_fitted + 3*deg2rad(delta)
```

- `delta` 单位为 degree；
- 正号表示重构参考相位超前；
- A/C 基波仍相对 B 保持 `±120°`；
- 三次谐波继续为三相同相参考；
- 物理 fault waveform、Simulink data 和 noise 完全不变。

因此 phase sweep 只改变 reference / X / model mismatch，不用改变物理故障波形模拟相位误差。

## 3. Baseline reproduction

共享条件 `fault factor=1.60, phase error=0°` 首先与 Step 2 正式结果比较。最大差如下：

| 对象 | 最大绝对差 |
|---|---:|
| Simulink data | 1.73e-18 |
| fault scale | 2.22e-16 |
| reconstructed reference | 0 |
| original M2 hist/cycle | 1.78e-15 |
| instrumented fault history | 1.78e-15 |
| instrumented counterfactual history | 0 |
| key mechanism metrics | 4.44e-15 |

正式复现值：

- `eta_geom post = 0.275451415244565`
- recursive fault-induced `Delta Cs = +4.886379 / -4.885713 pF`
- M2 fault factor `= 1.40107479735928`

全部小于 `1e-12`，故 Step 2 基准复现通过后才继续其他条件。

## 4. Experiment A — fault amplitude

### 4.1 Formal results

| Final factor | eta post | LS Cs1/Cs2 (pF) | Recursive fault-induced Cs1/Cs2 (pF) | M2 factor | Retention error | False-comp ratio | lambda ramp |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1.05 | 0.275451 | +0.4072 / -0.4072 | +0.4045 / -0.4046 | 1.03449 | -1.4768% | 0.33118 | 0.78733 |
| 1.10 | 0.275451 | +0.8144 / -0.8144 | +0.8135 / -0.8134 | 1.06776 | -2.9310% | 0.33294 | 0.67679 |
| 1.20 | 0.275451 | +1.6289 / -1.6289 | +1.6282 / -1.6282 | 1.13441 | -5.4656% | 0.33320 | 0.63964 |
| 1.30 | 0.275451 | +2.4433 / -2.4433 | +2.4426 / -2.4424 | 1.20108 | -7.6089% | 0.33322 | 0.62920 |
| 1.40 | 0.275451 | +3.2577 / -3.2577 | +3.2571 / -3.2567 | 1.26775 | -9.4462% | 0.33325 | 0.61724 |
| 1.60 | 0.275451 | +4.8866 / -4.8866 | +4.8864 / -4.8857 | 1.40107 | -12.4328% | 0.33330 | 0.59078 |

### 4.2 Geometry

在六个幅值条件中：

- post-fault `eta_geom` range 仅为 `1.11e-16`；
- fault-ramp `eta_geom` range 仅为 `4.44e-16`；
- 所有 X 均为 rank 2，condition number 保持不变。

因此在本实验中 `r_fault = alpha r0`，其方向和 X 不变，`eta_geom` 对故障幅值严格不敏感。该结果来自数据，不是预设约束。

### 4.3 False parameter bias

用 excess amplitude `F-1` 归一化：

- `Delta Cs1_fault_induced/(F-1) = 8.1326 ± 0.0207 pF`
- `|Delta Cs2_fault_induced|/(F-1) = 8.1324 ± 0.0196 pF`

虚假 Cs 漂移与故障增幅呈稳定的近线性关系，方向在全部条件中均为 `+Cs1/-Cs2`。最小幅值条件受固定噪声和有限递归量影响相对更明显，但方向与数量级仍保持。

### 4.4 Fault retention

虽然 `eta_geom` 不变，M2 retention error 从 `-1.48%` 单调恶化到 `-12.43%`。这说明 geometric absorbability 描述可被模型列空间表示的能量比例，但实际被递归吸收的绝对故障能量随 fault amplitude 增长，从而造成更大的 fault-retention loss。

False compensation RMS 随 fault RMS 一起增长，其比值在 `0.3312–0.3333` 间基本稳定；相位差接近 `0°`，相关系数约 `0.909`。

lambda ramp mean 从 `0.7873` 降至 `0.5908`，说明 VFF 对更大创新量作出更强响应；但 lambda-neutral contribution 仍约为 `2.1–2.7%`，没有改变 overlap 是主机理的判断。

## 5. Experiment B — reference phase error

### 5.1 Formal results

| Error (deg) | eta post | Pre bias Cs1/Cs2 (pF) | Recursive fault-induced Cs1/Cs2 (pF) | M2 factor | M2 retention error | CF-param retention error | False-comp phase |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 0.275451 | +0.0202 / +0.0506 | +4.8864 / -4.8857 | 1.40107 | -12.4328% | +0.0657% | +0.0068° |
| 0.33 | 0.275459 | -0.0467 / -0.0829 | +4.8571 / -4.9149 | 1.37940 | -13.7875% | -1.9653% | -0.2569° |
| 0.50 | 0.275468 | -0.0833 / -0.1539 | +4.8419 / -4.9298 | 1.36912 | -14.4298% | -2.9282% | -0.3927° |
| 1.00 | 0.275519 | -0.1998 / -0.3714 | +4.7971 / -4.9735 | 1.34188 | -16.1324% | -5.4801% | -0.7920° |
| 2.00 | 0.275720 | -0.4715 / -0.8449 | +4.7063 / -5.0598 | 1.29789 | -18.8818% | -9.6006% | -1.5882° |
| 3.00 | 0.276055 | -0.7948 / -1.3701 | +4.6140 / -5.1446 | 1.26389 | -21.0069% | -12.7846% | -2.3796° |

### 5.2 Geometry versus model mismatch

从 `0°` 到 `3°`：

- post `eta_geom` 仅增加 `0.219%`；
- ramp `eta_geom` 仅增加 `0.507%`；
- fault-induced Cs1 减少 `5.57%`；
- `|fault-induced Cs2|` 增加 `5.30%`。

因此 reference phase error 对 fault/column geometric overlap 的影响很小，但它使两参数方向出现可解释的不对称旋转。

更重要的是，故障前 M2 estimation bias 从约 `+0.020/+0.051 pF` 发展到 `-0.795/-1.370 pF`。即使使用 counterfactual parameter trajectory，retention error 也从 `+0.066%` 恶化到 `-12.785%`。这证明本 sweep 中相位误差的主要影响是 reference/model mismatch 与正常参数估计偏差，而不是 eta_geom 大幅改变。

动态递归过程仍有次级影响：fault-induced Cs1/Cs2 随误差出现约 `±5%` 的不对称变化，但 lambda ramp 仅从 `0.59078` 变为 `0.58815`，lambda contribution 仍约 `2.7%`。false compensation amplitude ratio 仅从 `0.33330` 增至 `0.33431`，其相位却随 reference error 旋转到 `-2.38°`。

## 6. Static LS versus recursive bias

全部 11 个正式条件中：

- `Delta c_LS,f` 始终预测 `+Cs1/-Cs2`；
- LS 与 recursive fault-induced bias 的最大绝对相对误差为 `0.663%`；
- 最大值出现在最弱故障 `1.05`，原因是目标偏差最小，固定噪声/有限递归残差占比更高；
- phase sweep 的 LS 相对误差不超过约 `0.022%`。

因此 `Delta c_LS,f` 在全部正式工况中都正确预测 fault-induced bias 的方向和数量级，并且通常达到远优于 1% 的一致性。

## 7. Constraints, recursion and numerical validity

| 检查 | 结果 |
|---|---:|
| formal unique conditions | 11 |
| amplitude sweep members | 6 |
| phase sweep members | 6（含共享基准） |
| instrumentation replay max | 0 |
| recursive update replay max | 0 pF |
| pre-fault branch difference max | 0 pF |
| counterfactual identity max | 2.1684e-19 A |
| projection energy closure max | 6.5454e-15 |
| normalized noise signature max difference | 7.9936e-15 |
| maximum rate-limit active cycles | 0 |
| maximum projection active cycles | 0 |

所有条件均保留，没有删除结果或调参。Rate limit 和 physical projection 在本实验范围内均未参与。

## 8. Answers to the required questions

### Q1. Fault amplitude 改变时 eta_geom 是否基本不变？

是。post/ramp range 分别只有 `1.11e-16/4.44e-16`，在数值精度内恒定。

### Q2. Fault-induced Delta Cs 是否随故障幅值呈稳定关系？

是。它与 `F-1` 近似成比例，归一化斜率约为 `+8.133/-8.132 pF per unit excess factor`。

### Q3. Fault retention loss 如何随故障幅值变化？

随幅值单调恶化：retention error 从 `-1.48%` 增至 `-12.43%`。几何比例不变，但被错误补偿扣除的绝对故障分量增大。

### Q4. Reference phase error 是否改变 eta_geom？

只小幅改变。3° 时 post eta 相对 0° 增加 `0.219%`，不足以解释 retention error 从 `-12.43%` 到 `-21.01%` 的变化。

### Q5. 相位误差主要影响什么？

主要影响 reference/model mismatch 和正常估计偏差。证据是 pre-fault bias 显著增长，且 counterfactual-parameter retention 本身从近零误差恶化到 `-12.78%`。几何改变很小；动态 recursive false bias 的不对称变化属于次级影响。

### Q6. Delta c_LS,f 是否始终预测方向/数量级？

是。11 条件方向全部正确，总体最大相对误差 `0.663%`。

### Q7. 是否出现 rate limit / projection 参与？

没有。全部条件两者均为 0 cycles。

### Q8. 哪些关系值得进入 Step 5？

建议按两个 sweep 分层，而不是把 11 行直接混合：

1. `F-1` 与 static LS bias、recursive fault-induced bias、false-compensation RMS、absolute fault-factor loss；
2. static `Delta c_LS,f` 与 recursive fault-induced `Delta c`，并计算 prediction RMSE；
3. phase error 与 pre-fault Cs bias、M2 retention error、counterfactual retention error、false-compensation phase；
4. phase error 与 eta_geom 的弱关系，用于证明 geometry 不是主要中介；
5. `eta_geom` 与 retention loss 必须按因子分层解释：amplitude sweep 中 eta 恒定而 loss 变化，直接混合相关可能产生误导。

Step 5 可报告 Pearson、Spearman 和 prediction RMSE，但每个 sweep 只有 6 点，应标明属于受控探索性证据。

## 9. Outputs

正式输出位于 `paper_research/phase1b_fault_absorption/step4/`：

- `controlled_factor_summary.csv`：11 条件汇总；
- `controlled_factor_cycles.csv`：1815 个 cycle-level records，保留 mechanism schema v1 和 condition metadata；
- `controlled_factor_validation.csv`：逐条件递归/投影一致性；
- `controlled_factor_noise_consistency.csv`：SNR 与 noise realization 一致性；
- `controlled_factor_workspace.mat`：完整 summary、cycle detail、validation、运行元数据和 reference phase convention；
- `figures/`：4 张正式图，各有 PNG/FIG。

新增 Step4 代码：

- `simulate_step4_fault_amplitude.m`
- `evaluate_step4_condition.m`
- `generate_phase1b_step4_figures.m`
- `run_phase1b_step4_controlled_factors.m`

运行命令：

```matlab
addpath(fullfile(pwd,'paper_research','phase1b_fault_absorption','step4'));
run_phase1b_step4_controlled_factors;
```

四个新增脚本运行前 `checkcode=0`。仿真保留 AutoComp9 已知的代数环和未连接 Current Measurement 端口警告；没有 MATLAB/Simulink error。

## 10. Limitations

- 本步骤是单 seed、两个单因素 sweep，不是统计鲁棒性或 Monte Carlo 结论。
- 每个 sweep 只有 6 点，Step 5 的相关系数需要结合机制和散点图解释，不能只看 p-value。
- phase error 同时影响 fundamental 与 third harmonic，采用的是工程现有的相干时间偏移定义；没有分别扫描 50/150 Hz 独立相移。
- 本步骤没有改变 fault timing、故障方向或电压不平衡，因此不覆盖其他 X geometry。

## 11. Acceptance

| 条件 | 结果 | 证据 |
|---|---|---|
| A. previous phases unchanged | PASS | 16-file frozen manifest 前后哈希一致 |
| B. baseline condition reproduced | PASS | max difference `4.44e-15` |
| C. 6 amplitude conditions complete | PASS | 6/6 retained |
| D. 6 phase-error conditions complete | PASS | 6/6，含共享基准 |
| E. 11 unique formal conditions retained | PASS | unique count = 11 |
| F. mechanism metrics calculated | PASS | summary + 1815 cycle rows |
| G. fault/counterfactual valid | PASS | replay 0；identity/closure passed |
| H. no cherry-picking or tuning | PASS | registry exactly matched；无额外/删除条件 |
| I. CSV/MAT/figures/report complete | PASS | 所有正式产物存在 |

```text
STEP4_CONTROLLED_FACTOR_EXPERIMENTS: PASS
```

ready for Phase 1B-5 Correlation & Mechanism Evidence
