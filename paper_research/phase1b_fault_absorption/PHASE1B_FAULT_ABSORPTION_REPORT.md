# Phase 1B — Final Fault Absorption Mechanism Report

完成日期：2026-09-18  
研究对象：AutoComp9 中无故障门控 VFF-RLS 对真实阻性故障的参数吸收机理  
正式状态：`PHASE 1B STATUS: COMPLETE`

本报告只整合 Phase 1B Step 1–5 和冻结 Phase 1A 中已经形成的正式证据。没有新增实验、运行 Simulink、修改模型、调整参数、增加工况、重新定义指标或开发 M4。

---

## 1. Executive conclusion

Phase 1B 已建立并闭合如下故障吸收机理：

```text
observed resistive-fault underestimation
        ↓
r_fault has a nonzero projection onto col(X)
        ↓
Delta c_LS,f predicts an equivalent +Cs1/-Cs2 fault bias
        ↓
ungated VFF-RLS recursively converges toward that false bias
        ↓
false Cs produces a false B-phase coupling compensation
        ↓
the compensation is nearly in phase with the fault fundamental
        ↓
part of the true resistive increment is incorrectly subtracted
        ↓
fault retention loss
```

Case05 给出完整因果闭环，Case06 在故障前已有真实 Cs 漂移的不同工作点上复现同一机理。两个单因素受控 sweep 进一步表明：故障方向不变时，`eta_geom` 基本恒定，但绝对投影、虚假参数偏差、错误补偿和故障增量损失随故障幅值增长；参考相位误差则主要通过 reference/model mismatch、正常估计偏差和补偿方向旋转恶化结果，而不是通过 `eta_geom` 大幅变化。

现有 hard gate 在 Case05/06 中显著抑制了故障诱导的虚假 Cs 更新并恢复了故障保持能力。这构成进入 M4 方法设计的充分机理依据，但不等于 M4 已被实现或验证。

---

## 2. Scope, frozen evidence and traceability

### 2.1 Evidence sources

| Evidence layer | Formal artifact | Role in this report |
|---|---|---|
| Theory and definitions | `STEP1_THEORY_AND_DATA_DEFINITION.md` | 冻结 X/y、`r_fault`、投影、LS、recursive replay、`E_in/E_quad` 定义 |
| Case05 mechanism | `STEP2_BASELINE_MECHANISM.md` and `step2/*` | 建立几何、参数偏差、错误补偿和 retention 的完整闭环 |
| Case06 verification | `STEP3_CASE06_VERIFICATION.md` and `step3/*` | 验证真实 Cs 漂移后机理仍成立 |
| Controlled factors | `STEP4_CONTROLLED_FACTOR_EXPERIMENTS.md` and `step4/*` | 分离 fault amplitude 与 reference phase error 的影响 |
| Correlation/evidence | `STEP5_CORRELATION_AND_EVIDENCE.md` and `step5/*` | 分层量化相关、预测误差和证据等级 |
| Hard-gate baseline | Phase 1A `baseline_summary.csv` | 提供冻结 M3 gate 和故障保持结果 |

### 2.2 Integrity

本报告生成前对 Phase 1B 目录中 82 个既有正式文件建立 SHA-256 清单；报告完成后逐项复核。最终报告是唯一新增文件，Step 1–5 代码、CSV、MAT、FIG、PNG 和正式报告均未改变。

### 2.3 Evidence terminology

本报告使用以下措辞等级：

- **directly verified**：由严格定义、数值闭合、双分支 replay 或同一数据上的反事实恢复直接验证；
- **strongly supported**：预测与动态结果高度一致，但二者不是数学同一量，仍存在递归历史等独立因素；
- **limited / conditional evidence**：只在当前确定性模型、有限工况或小样本 sweep 中成立；
- **not yet verified**：尚无正式实验或实现证据，不作性能声明。

---

## 3. Observed phenomenon

冻结 AutoComp9 中，M2 是启用 VFF、变化率限制和物理投影但关闭 fault gate 的 RLS。B 相真实阻性故障倍率为 `1.6000` 时：

| Case | Condition | M2 estimated factor | M2 retention error | M2 apparent Delta Cs1/Cs2 |
|---|---|---:|---:|---:|
| Case05 | constant true Cs, fault only | 1.401075 | -12.4328% | +4.9168 / -4.9570 pF |
| Case06 | true Cs drift, then fault | 1.402269 | -12.3582% | +5.0063 / -4.9773 pF |

真实物理 Cs 在 Case05 中保持常数；Case06 的真实漂移发生于故障前，Cs1/Cs2 分别为 `+3/-2 pF`。因此故障后约 `+5/-5 pF` 的附加估计变化不能解释为真实耦合电容变化。

观测现象是：无门控自适应器把一部分真实阻性故障误解释为耦合参数变化，随后用该错误参数进行容性补偿，使估计阻性故障增量低于真值。

---

## 4. Mathematical mechanism

### 4.1 Actual observation model

每个工频周期的三相联合回归可写为：

\[
\boldsymbol y_k
=\boldsymbol X_k\boldsymbol c_{\mathrm{true},k}
+\boldsymbol b_k+\boldsymbol r_{f,k}+\boldsymbol n_k,
\]

其中：

- `c=[Cs1,Cs2]^T`，数值单位为 pF；
- `X` 为 `3000×2` 的 AB/BC 耦合回归矩阵，单位为 A/pF；
- `b` 包含正常阻性电流和确定性模型/参考残差；
- `r_fault` 是故障倍率单独引入的 observation-space 增量；
- `n` 为电流噪声。

当前 AutoComp9 的故障只乘在 B 相阻性支路，且不反馈改变电压、Cs truth 或噪声，因此：

\[
r_{f,B}(t)=\left(1-\frac{1}{g(t)}\right)i_{B,R}^{\mathrm{true}}(t),
\]

\[
\boldsymbol r_{f,k}=
\begin{bmatrix}
\boldsymbol 0\\
\boldsymbol r_{f,B}\\
\boldsymbol 0
\end{bmatrix}.
\]

该严格恢复避免了把全部 `y-X*c_est` 错称为真实故障。

### 4.2 Fault projection into the parameter model

故障对参数辨识通道的可进入部分由 `col(X)` 决定：

\[
\boldsymbol r_{\parallel}=Q_XQ_X^T\boldsymbol r_f,
\qquad
\boldsymbol r_{\perp}=\boldsymbol r_f-\boldsymbol r_{\parallel}.
\]

`r_parallel` 位于耦合模型列空间中，可以被某个 Cs 参数组合表达；`r_perp` 与该空间正交，不能通过当前两个 Cs 参数直接拟合。几何可吸收率定义为：

\[
\eta_{\mathrm{geom}}
=\frac{\|\boldsymbol r_{\parallel}\|_2^2}
{\|\boldsymbol r_f\|_2^2}.
\]

Case05/06 故障完全建立后的 `eta_geom=0.275451`，即约 27.55% 的完整三相 observation-space 故障能量位于当前 coupling model column space。该数值是几何可表达比例，不是 RLS 最终吸收比例，也不是 fault-retention error。

### 4.3 Static equivalent fault bias

在相同 X、正常残差和噪声下，fault/no-fault 静态 LS 解的差为：

\[
\Delta\boldsymbol c_{\mathrm{LS},f}
=\boldsymbol X^{+}\boldsymbol r_f
=\boldsymbol X\backslash\boldsymbol r_f.
\]

由于 `X*Delta c_LS,f=r_parallel`，该量给出当前 block 中故障可表达分量对应的 Cs 等效偏差。Case05/06 steady 值均为：

```text
Delta Cs1_LS,f = +4.886604 pF
Delta Cs2_LS,f = -4.886604 pF
```

因此约 `+4.9/-4.9 pF` 的方向和数量级在递归算法运行前，已经由 `r_fault` 与 `col(X)` 的几何关系决定。

### 4.4 From static bias to recursive false drift

M2 并不是逐 block 独立 LS。它递归更新 information state：

\[
J_k=\lambda_kJ_{k-1}+X_k^TX_k,
\qquad
h_k=\lambda_kh_{k-1}+X_k^Ty_k,
\]

再求解 raw 参数并执行变化率限制与 `[0,40] pF` 投影。故障同时改变 local LS innovation、`lambda`、`J/h` 和后续历史，因此 static `Delta c_LS,f` 不能被称为实际单周期更新。

Phase 1B 使用完整 fault/counterfactual 双分支：故障前共享相同状态；故障后 fault branch 保留 `r_fault`，counterfactual branch 使用 `y_fault-r_fault`，且两个分支独立递归。二者参数差定义为 recursive fault-induced bias。

Case05 得到 `+4.886379/-4.885713 pF`，Case06 得到 `+4.888415/-4.881689 pF`。它们与 static LS 的方向和数量级一致。Step 5 的受控验证给出最大 RMSE `0.001339 pF`、最大相对误差 `0.6628%`、全部条件方向一致率 `100%`。因此 static LS 到 recursive false bias 的映射为 **strongly supported**，但不是把动态递归简化成静态 LS。

### 4.5 From false Cs to fault absorption

fault/counterfactual 参数差产生 B 相虚假耦合补偿：

\[
\Delta i_{\mathrm{coupling},B}
=\Delta C_{s1}(\dot u_B-\dot u_A)
+\Delta C_{s2}(\dot u_B-\dot u_C).
\]

Case05 中，该补偿的基波 RMS 为 `0.168850 mA`，是 `r_fault,B` 基波 `0.506607 mA` 的 `0.333295`，相位差仅 `0.00677°`；Case06 的比例为 `0.333228`、相位差 `0.06832°`。错误补偿与真实故障基波近同相，且在阻性电流提取时被扣除，因此约三分之一的故障增量被错误去除。

这解释了：

```text
true factor 1.6000
→ false coupling compensation removes about 0.2 increment
→ M2 factor about 1.401–1.402
```

对同一含故障总电流改用 counterfactual 参数轨迹后，Case05/06 分别恢复到 `1.601051/1.602647`。这是 false Cs 到 fault-retention loss 的直接因果闭环，而不只是相关关系。

---

## 5. Case05 causal closure

Case05 使用 seed `106`、SNR `30 dB`、恒定 Cs、B 相故障 `3.00–3.06 s` 从 `1.0` 增至 `1.6`。

| Mechanism quantity | Formal result |
|---|---:|
| `eta_geom`, ramp mean | 0.235467 |
| `eta_geom`, post mean | 0.275451 |
| static `Delta c_LS,f`, steady / pF | +4.886604 / -4.886604 |
| recursive fault-induced bias / pF | +4.886379 / -4.885713 |
| actual M2 Delta Cs / pF | +4.916774 / -4.956994 |
| counterfactual background Delta Cs / pF | +0.030394 / -0.071281 |
| M2 estimated factor | 1.401075 |
| counterfactual-parameter factor | 1.601051 |
| false-compensation/fault RMS ratio | 0.333295 |
| false-compensation phase difference | 0.00677° |

projection energy closure 最大误差为 `5.50e-15`，X 全部满列秩且 `cond2≈1.291`。因此约 `±4.89 pF` 不是病态矩阵放大、rate limit 分段或 physical projection 推挤造成的。

Case05 的完整闭环为：

```text
strict r_fault
→ 27.55% energy in col(X)
→ static +4.8866/-4.8866 pF
→ recursive +4.8864/-4.8857 pF
→ near-in-phase 0.16885 mA false compensation
→ M2 factor 1.4011
→ counterfactual recovery 1.6011
```

该链的每个中间量都由正式 observation blocks、递归 replay 或反事实提取直接验证。

---

## 6. Case06 cross-case verification

Case06 使用 seed `105`，故障前真实 Cs 在 `0.8–2.2 s` 漂移，之后施加与 Case05 相同的故障。三类变化严格分离：

| Quantity | Cs1 / pF | Cs2 / pF | Meaning |
|---|---:|---:|---|
| true Cs drift | +3.000000 | -2.000000 | 真实物理变化，发生于故障前 |
| pre-fault estimation residual | -0.057827 | +0.056939 | 漂移跟踪后的正常估计残差 |
| recursive fault-induced false bias | +4.888415 | -4.881689 | fault branch minus counterfactual branch |

故障前漂移跟踪 RMSE 为 `0.216861/0.159477 pF`，说明 M2 已到达新的真实工作点附近。故障后的 `±4.88 pF` 偏差远大于 pre-fault residual，不能归因于未完成的真实漂移跟踪。

| Mechanism quantity | Case05 | Case06 |
|---|---:|---:|
| `eta_geom` post | 0.275451 | 0.275451 |
| static LS Cs1/Cs2 / pF | +4.8866 / -4.8866 | +4.8866 / -4.8866 |
| recursive fault bias / pF | +4.8864 / -4.8857 | +4.8884 / -4.8817 |
| false-compensation ratio | 0.333295 | 0.333228 |
| false-compensation phase | 0.00677° | 0.06832° |
| M2 factor | 1.401075 | 1.402269 |
| counterfactual recovery | 1.601051 | 1.602647 |

Case05/06 使用相同 voltage/reference geometry，因此不能验证任意几何；但它们具有不同 Cs truth 工作点和递归历史。几何、static bias、recursive fault bias、错误补偿和 retention loss 仍定量一致，直接支持同一 fault absorption mechanism 可跨这两个工作点迁移。

---

## 7. Controlled factor verification

### 7.1 Fault amplitude

固定相位误差 0°，扫描最终 fault factor `1.05–1.60`。`eta_geom_post` 六点均为 `0.275451415244565`，但：

| Relationship, n=6 | Pearson r | Spearman rho | Slope | R² |
|---|---:|---:|---:|---:|
| `F-1 → Delta Cs1_fault_induced` | 0.99999994 | 1 | 8.147435 pF | 0.99999987 |
| `F-1 → |Delta Cs2_fault_induced|` | 0.99999994 | 1 | 8.146079 pF | 0.99999987 |
| `F-1 → false-compensation RMS` | 0.99999994 | 1 | 0.281532 mA | 0.99999987 |
| `F-1 → lost increment` | 0.99999994 | 1 | 0.333433 | 0.99999987 |

recursive bias 从约 `±0.405 pF` 增至 `±4.886 pF`，false-compensation RMS 从 `0.013982 mA` 增至 `0.168850 mA`，lost increment 从 `0.015507` 增至 `0.198925`。

这说明 `eta_geom` 是方向/子空间确定的比例；当故障方向不变而幅值增加时，比例保持，绝对 `r_parallel`、`Delta c` 和被吞掉的故障增量仍会增加。

### 7.2 Static LS predictive accuracy

| Sweep | Parameter | RMSE / pF | Max relative error | Pearson r | Spearman rho | Direction agreement |
|---|---|---:|---:|---:|---:|---:|
| amplitude | Cs1 | 0.001256 | 0.6628% | 0.99999994 | 1 | 100% |
| amplitude | Cs2 | 0.001339 | 0.6354% | 0.99999994 | 1 | 100% |
| phase error | Cs1 | 0.000180 | 0.00460% | 1.00000000 | 1 | 100% |
| phase error | Cs2 | 0.000966 | 0.02111% | 1.00000000 | 1 | 100% |

最低幅值条件的实际 bias 仅约 `0.405 pF`，因此约 `0.0027 pF` 的最大绝对误差形成了 amplitude sweep 的最大相对误差。绝对误差仍很小。

### 7.3 Reference phase error

固定 fault factor 1.60，扫描参考相位误差 `0–3°`。正误差定义为重构参考相位超前；物理 fault waveform 未修改。

| Effect | 0° | 3° | Controlled relationship, n=6 |
|---|---:|---:|---|
| pre-fault Cs1 bias / pF | +0.0202 | -0.7948 | Pearson -0.9972, Spearman -1 |
| pre-fault Cs2 bias / pF | +0.0506 | -1.3701 | Pearson -0.9991, Spearman -1 |
| `eta_geom_post` | 0.275451 | 0.276055 | relative change +0.2191% |
| M2 retention error | -12.4328% | -21.0069% | Pearson -0.9939, Spearman -1 |
| counterfactual retention error | +0.0657% | -12.7846% | Pearson -0.9939, Spearman -1 |
| false-compensation phase | +0.0068° | -2.3796° | slope -0.7956°/°; Pearson -0.999998 |
| false-compensation RMS ratio | 0.333295 | 0.334309 | absolute change 0.001014 |

`eta_geom` 随 phase error 单调变化，Pearson 为 `0.9676`，但效应量只有 `0.2191%`。同期 counterfactual 参数路径自身恶化 `12.8503` 个百分点，且故障前已经产生明显 Cs bias。因此 phase-error degradation 主要反映 reference/model mismatch、正常参数估计偏差和补偿方向旋转，不能全部归因于 fault absorption。

---

## 8. Roles of VFF, constraints and information state

### 8.1 VFF lambda

故障提高 local LS innovation，使 lambda 在 ramp 期下降，从而加快瞬态跟随：

| Quantity | Case05 | Case06 |
|---|---:|---:|
| fault-branch lambda, ramp mean | 0.590783 | 0.629443 |
| counterfactual lambda, ramp mean | 0.880154 | 0.934005 |
| lambda-neutral estimated final contribution | about 2.7% | about 3.3% |

lambda 对故障初始跟随明显，但对最终 `±4.9 pF` 偏差的增量仅占几个百分点。主机理仍是持续 `r_fault` 与 `col(X)` 重合，以及递归信息状态向对应等效偏差收敛。

### 8.2 Rate limit

Case05、Case06 和 Step 4 全部正式条件中 rate limit 激活周期均为 0。Case05 raw 最大更新小于 `1.2 pF/cycle`。所以虚假 Cs 确实经过多个周期递归形成，但不是由 rate limiter 强制分段累积。

### 8.3 Physical projection

全部正式条件中 `[0,40] pF` 投影激活周期均为 0。当前 fault absorption 不是参数撞到物理边界后的投影效应。

### 8.4 J/h mismatch

信息状态不会在 rate/projection 后回写，因此理论上存在 `h≠Jc`。Case05/06 的归一化 mismatch 为 `10^-6–10^-5` 量级，post 最大约 `1.5e-5`；rate/projection 又未触发。该 mismatch 存在，但没有证据表明它是当前 `±4.9 pF` 主偏差来源。

---

## 9. E_in/E_quad and hard gate

### 9.1 Why E_in/E_quad contains fault evidence

每周期 residual `e=y-X*c_before` 被投影到参考电压同相的 sine 子空间和近似正交的 cosine 子空间，分别形成 `E_in` 与 `E_quad`。在当前参考约定下，阻性故障更接近同相分量，而容性/耦合误差通常更接近导数方向，因此故障出现时 `E_in` 相对历史 baseline 和 `E_quad` 上升。

Case05：

```text
E_in    pre/ramp/post = 0.9271 / 1.0346 / 1.1261 mA
E_quad  pre/ramp/post = 0.01235 / 0.01598 / 0.11969 mA
```

Case06 给出相近时序。Case05 的双阈值条件在 50 个含故障周期中的 48 个成立，与 M3 的 48 个实际 gate cycles 一致。

必须区分代码角色：M2 计算并记录 `E_in/E_quad`，但它们不进入 M2 的 J/h/c 更新；只有启用 gate 的 M3 才使用它们冻结状态。因此：

```text
E_in/E_quad = fault evidence / gate diagnostic
E_in/E_quad ≠ direct M2 update signal
```

当前证据不足以把它们宣称为一般不平衡、传感器误差和模型失配下的纯阻性/容性正交分离。

### 9.2 Why the existing hard gate works

M3 与 M2 使用相同 VFF-RLS 和约束，区别仅为启用现有 hard gate。gate 有效时冻结 `J/h/c/baseIn`，阻止大部分故障分量进入参数递归状态：

```text
fault evidence triggers gate
→ J/h/c adaptation freezes
→ most fault-induced false Cs update is prevented
→ false coupling compensation is much smaller
→ more true resistive increment is retained
```

| Case | M2 factor | M3 factor | M2 retention error | M3 retention error | First gate | Gate duration |
|---|---:|---:|---:|---:|---:|---:|
| Case05 | 1.401075 | 1.581137 | -12.4328% | -1.17893% | 3.05998 s | 48 cycles / 0.96 s |
| Case06 | 1.402269 | 1.582876 | -12.3582% | -1.07022% | 3.05998 s | 48 cycles / 0.96 s |

M3 并未达到 counterfactual 的 `1.6011/1.6026`，因为 gate 在故障 ramp 结束附近才首次触发，触发前已有少量参数更新，并且正常模型/噪声误差仍存在。现有数据支持“hard gate 防止大部分 fault-induced false update”，不支持“完全消除所有误差”。

### 9.3 Hard-gate limitations

基于现有实现和证据，可以确认以下研究动机：

- **binary update/freeze**：更新权重只有 0 或 1，无法按故障证据强弱连续调节；
- **threshold dependence**：触发依赖 `1.12*baseIn`、`1.20*E_quad` 和 hold 周期；当前没有阈值敏感性或 Monte-Carlo 证据；
- **onset delay**：Case05/06 首次触发为 `3.05998 s`，故障 ramp 为 `3.00–3.06 s`，触发前可能已有吸收；
- **drift/fault direction separation is incomplete**：现有门控依赖 residual evidence，不能连续量化某个更新方向属于真实耦合漂移还是故障投影；
- **reference validity dependence**：phase-error sweep 表明参考失配可产生明显 normal bias，而现有 hard gate 尚未在完整参考误差、不平衡和模型失配矩阵下验证。

这些局限只构成 M4 的研究需求，不代表 M4 已解决它们。

---

## 10. Formal position and limits of eta_geom

### 10.1 What eta_geom explains

`eta_geom` 解释的是：在给定 observation model、reference construction 和参数化 X 下，故障向量能量有多少比例可由 coupling-parameter column space 表达。它能够：

- 判断故障波形是否存在被 Cs 模型解释的几何通道；
- 量化 `r_parallel/r_perp` 的能量分解；
- 为 static `Delta c_LS,f` 提供几何基础；
- 比较相同定义下不同 fault/reference geometry 的可表达程度。

### 10.2 What eta_geom cannot explain alone

它不能单独预测：

- fault 的绝对幅值和绝对 `Delta c`；
- normal/pre-fault estimation bias；
- reference/model mismatch 的直接误差；
- recursive state history、收敛时间和 counterfactual background；
- VFF lambda response；
- rate/projection 是否参与；
- 最终 fault-retention error 的全部来源。

amplitude sweep 中 `eta_geom` 恒定而 lost increment 增长，是“比例不等于绝对量”的直接证据；phase sweep 中 eta 仅变化 `0.2191%` 而 counterfactual retention 恶化 `12.8503 pp`，是“geometry 不等于全部 estimation error”的直接证据。

因此：

> `eta_geom` is a geometry descriptor, not a universal fault-retention predictor.

---

## 11. Evidence chain and strength

| Mechanism link | Evidence level | Formal evidence | Main boundary |
|---|---|---|---|
| `r_fault → projection onto col(X)` | directly verified | strict fault construction；projection closure `≤5.50e-15` | 依赖当前 X/reference model |
| `projection → Delta c_LS,f` | directly verified | `X*Delta c_LS,f=r_parallel` 数值闭合 | 仅为静态 blockwise 等效量 |
| `Delta c_LS,f → recursive false Cs bias` | strongly supported | 最大 RMSE `0.001339 pF`，最大相对误差 `0.6628%`，方向 100% | 动态历史和 lambda 仍独立存在 |
| `recursive false Cs → false compensation` | directly verified | Case05/06 trajectory difference 映射到约 1/3 fault RMS | 冻结 B 相提取方程 |
| `false compensation → lost increment` | directly verified | counterfactual factor 恢复至 `1.6011/1.6026` | 确定性仿真闭环 |
| Case05 → Case06 transfer | directly verified for these two cases | geometry、bias、compensation、retention 定量一致 | 相同 voltage/reference geometry |
| amplitude scaling | strongly supported | n=6，Pearson 约 0.99999994，Spearman 1 | controlled exploratory evidence |
| phase-error decomposition | limited / conditional evidence | n=6；normal bias 和 counterfactual degradation 显著 | 只扫描 0–3° 正相位误差 |
| hard-gate effectiveness | limited / conditional evidence | Case05/06 M3 factor 约 1.58，48 gate cycles | 两个确定性工况；无阈值鲁棒性 |
| future M4 performance | not yet verified | M4 未实现、未运行 | 只能提出设计要求 |

---

## 12. Answers to Q1–Q14

### Q1 — 为什么无门控 VFF-RLS 会产生虚假 Cs 变化？

因为实际 observation `y` 同时含真实耦合分量和阻性故障分量。只要 `r_fault` 对 `col(X)` 的投影非零，最小二乘意义下就存在一个 Cs 参数偏差可降低故障残差。M2 没有区分“真实 Cs 变化”和“可由 Cs 模型表达的故障分量”，所以递归信息状态会向该等效参数偏差收敛。

### Q2 — 故障的哪部分进入参数辨识通道？

`r_parallel=Q_XQ_X^T r_fault` 能进入；`r_perp` 不能由当前 Cs 参数直接表达。`eta_geom` 给出两者的能量比例。Case05/06 post-fault eta 为 `0.275451`。

### Q3 — 为什么 Case05 出现约 +4.9/-4.9 pF？

Case05 的 `X\r_fault` 在 steady 窗口为 `+4.886604/-4.886604 pF`；完整递归双分支得到 `+4.886379/-4.885713 pF`。该方向和数量级由故障投影几何决定，递归算法随后实际形成该虚假漂移。

### Q4 — static Delta c_LS,f 的预测能力多强？

全部受控正式条件方向一致率 `100%`。最大 RMSE `0.001339 pF`，最大相对误差 `0.6628%`；两个 sweep 的 Pearson 接近 1、Spearman 为 1。它强力预测最终 fault-induced bias 的方向和数量级，但不预测递归时序。

### Q5 — 虚假 Cs 为什么吞掉真实故障？

false Cs 生成虚假 coupling compensation；Case05/06 该补偿约为 fault fundamental RMS 的三分之一，并与其近同相。提取阻性电流时错误补偿被扣除，从而把真实阻性增量的一部分同时扣除，M2 factor 从真值 1.6 降至约 1.401–1.402。

### Q6 — Case05 和 Case06 是否支持同一机理？

是。Case06 已把 `+3/-2 pF` true drift、约 `-0.058/+0.057 pF` pre-fault residual 和 `+4.888/-4.882 pF` fault-induced bias 分离。尽管工作点和递归历史不同，geometry、static bias、false compensation 和 retention 与 Case05 高度一致。

### Q7 — fault amplitude 有什么影响？

在故障方向不变的 amplitude sweep 中，`eta_geom` 恒定；但 `r_parallel` 的绝对幅值、`Delta Cs`、false-compensation RMS 和 lost increment 均近似按 `F-1` 线性增长。

### Q8 — reference phase error 有什么影响？

0–3° 扫描中 eta 仅相对变化 `0.2191%`，但故障前 Cs bias 达到 `-0.7948/-1.3701 pF`，counterfactual retention 恶化 `12.8503 pp`，false-compensation phase 旋转至 `-2.3796°`。因此新增恶化主要来自 reference/model mismatch 和 normal estimation bias，不能全部归为 fault absorption。

### Q9 — lambda、rate limit、projection 和 J/h mismatch 的作用？

lambda 在 fault ramp 降低并加快跟踪，但最终贡献约 2.7–3.3%，不是主因；rate limit 和 projection 在全部正式工况中均未触发；J/h mismatch 存在但只有 `10^-6–10^-5` 量级，当前不是主机理。

### Q10 — E_in/E_quad 为什么帮助识别故障？

它们分别描述 residual 在参考同相和近似正交子空间中的周期 RMS。当前阻性故障使同相 evidence 相对 baseline 和正交分量增大，因此可触发 M3。它们是 fault evidence/gate diagnostic，不是 M2 的直接 update signal，也尚未被证明为普适物理分离量。

### Q11 — eta_geom 能解释什么、不能解释什么？

它解释 fault waveform 与 coupling model column space 的几何可表达程度；不能单独解释绝对故障量、正常估计偏差、reference mismatch、递归历史、lambda 或最终 retention。

### Q12 — 为什么 hard gate 有效？

gate 冻结 J/h/c，使故障 evidence 不再持续写入参数状态，从而防止大部分 false Cs 和后续 false compensation。Case05/06 的 M3 factor 分别为 `1.5811/1.5829`，明显优于 M2 的 `1.4011/1.4023`。

### Q13 — hard gate 有哪些局限？

它是 binary freeze/update，依赖固定阈值和 hold 时间，存在 onset delay，不能连续区分真实 drift direction 与 fault direction；对参考误差、不平衡、噪声和模型失配的阈值鲁棒性尚未完成正式验证。

### Q14 — 是否具备进入 M4 设计的依据？

是。Phase 1B 已明确识别需要抑制的 fault-induced parameter channel、可计算的几何/LS 预测量、可用的 residual evidence、现有 hard gate 的有效性及局限。依据足以进入方法设计，但 M4 的结构、性能和鲁棒性均为 **not yet verified**。

---

## 13. Research boundaries

本阶段结论必须在以下边界内使用：

1. 当前证据来自 `AI6109_MOA_AutoComp9.slx` 仿真，不是硬件实验；
2. Case05/06 是确定性工况，不是随机总体样本；
3. Step 4 两个 sweep 各 `n=6`，相关结果属于 controlled exploratory evidence；
4. 尚无 Monte-Carlo；
5. 尚无完整噪声、三相不平衡、MOA 模型失配、自电容失配和耦合矩阵失配鲁棒性研究；
6. 尚无硬件、现场数据或传感器链路实验；
7. 当前参考仍基于理想 B 相电压重构，phase sweep 只是受控参考误差注入；
8. `eta_geom` 依赖当前 AB/BC 两列 observation model、参考构造和故障定义；
9. Case05/06 共享 voltage/reference geometry，只验证了不同 Cs 工作点/历史下的迁移；
10. phase-error degradation 同时包含 reference/model mismatch 和 normal bias，不能简单归因于 fault absorption；
11. hard-gate evidence 仅来自 Case05/06，尚无阈值敏感性、误报率和漏报率正式统计；
12. M4 尚未设计、实现或验证。

这些限制约束外推范围，但不否定本阶段在当前模型和正式工况中已经闭合的故障吸收机理。

---

## 14. Implications for future M4 design

Phase 1B 支持将以下内容作为下一阶段的设计要求，而不是既成性能声明：

- 利用 `r_fault/col(X)` 机理，显式限制故障证据沿可吸收参数方向进入更新；
- 在保留真实慢速 Cs drift 跟踪能力的同时，降低阻性故障方向的参数更新权重；
- 从 hard binary gate 研究连续、可解释的 update weighting 或 fault/drift decoupling；
- 将 `E_in/E_quad` 作为 evidence 输入，而不是未经验证的纯物理分量；
- 同时考虑 reference-quality/model-validity，避免把参考失配当成 fault absorption；
- 保留 projection/rate/VFF 消融，使 M4 的增益可以归因；
- 在正式宣称鲁棒性前完成 Monte-Carlo、噪声、不平衡、模型失配和阈值敏感性验证。

本报告不选择 M4 的具体公式，也不声称上述目标已经实现。

---

## 15. Final mechanism statement

在当前三相 AB/BC 耦合回归模型中，真实 B 相阻性故障所形成的 observation-space 增量并不完全独立于耦合参数模型。其落入回归矩阵列空间 `col(X)` 的分量可以被等效表示为 Cs 参数变化；相应的静态故障诱导偏差 `Delta c_LS,f=X\r_fault` 能准确预测无门控 VFF-RLS 最终形成的虚假 `+Cs1/-Cs2` 偏差方向和数量级。递归更新形成的错误 Cs 随后产生与真实阻性故障基波近同相的虚假耦合补偿，使部分真实阻性电流增量在容性扣除过程中被错误消除，从而形成 fault absorption。Case05 的完整反事实闭环、Case06 在真实 Cs 漂移工作点上的复现，以及故障幅值与参考相位误差的受控实验共同支持该机理；其中 `eta_geom` 只描述几何可表达比例，不能单独预测全部 fault-retention error。

---

## 16. Final acceptance

| ID | Requirement | Result |
|---|---|---|
| A | Step 1–5 frozen artifacts unchanged | PASS，报告生成前后 82 个既有文件 SHA-256 一致 |
| B | all major conclusions traceable | PASS，均追溯到正式报告/CSV/MAT |
| C | mathematical mechanism complete | PASS，X/y、projection、LS、recursive、compensation、retention 完整 |
| D | Case05 causal closure | PASS，counterfactual recovery 1.6011 |
| E | Case06 verification | PASS，不同 Cs 工作点上 recovery 1.6026 |
| F | controlled factor evidence | PASS，两个独立 n=6 sweep |
| G | statistical boundaries stated | PASS，明确 controlled exploratory evidence |
| H | eta_geom limitations stated | PASS |
| I | M4 not implemented | PASS |
| J | remaining limitations stated | PASS |

```text
PHASE 1B STATUS:
COMPLETE
```

```text
READY FOR NEXT PHASE:
M4 method design
```

Phase 1B 在此结束。不自动进入下一阶段，不开发 M4。
