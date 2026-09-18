# Phase 1B-1 — Theory & Data Definition

核对日期：2026-09-17  
阶段：Phase 1B — Fault Absorption Mechanism  
步骤：Step 1 — Theory & Data Definition  
边界：本步骤仅进行完整性、代码结构、数学定义和既有数据可用性审计。未调用 `sim`，未运行算法，未重跑 Phase 1A，未修改 AutoComp9 或 `paper_research/phase1a_baseline/`，未实现 M4。

---

## 1. Phase 1A integrity check

### 1.1 开始状态

| 项目 | 只读核对值 | 结论 |
|---|---|---|
| Git branch | `main` | 与冻结记录一致 |
| Git HEAD | `91e1b3efc8d2bf637c3fa30865d44c7691330fe5` | 与冻结记录一致 |
| HEAD subject | `paper: finalize Phase 1A baseline` | 与冻结记录一致 |
| AutoComp9 size | `203068 bytes` | 文件存在 |
| AutoComp9 SHA-256 | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` | PASS |
| `baseline_summary.csv` size | `5821 bytes` | 文件存在 |
| `baseline_summary.csv` SHA-256 | `E7BEB3ECFEDF521105B67198684752BB32AFAAEFD84ACA80822BA57FBD9D0AB3` | PASS |
| `baseline_workspace.mat` | `115337063 bytes` | 正式本地数据存在 |
| Phase 1A final report | 存在 | PASS |
| Step 7 regression report | 存在 | PASS |

开始时 `git status --short --untracked-files=all` 仅为：

```text
?? NEXT_SESSION_HANDOFF.md
?? paper_research/phase1a_baseline/baseline_workspace.mat
?? paper_research/phase1a_baseline/step5_smoke_workspace.mat
```

三项均与交接记录一致；没有已跟踪模型、源码或 Phase 1A 结果修改。Phase 1A 正式证据完整，可以进行 Phase 1B Step 1。

### 1.2 本步骤使用的证据

真实调用和公式以以下代码为准：

```text
run_phase1a_baseline.m
  -> simulate_phase2_case.m
     -> generate_coupling_signals.m
     -> AI6109_MOA_AutoComp9.slx
  -> reconstruct_refs_from_b.m
  -> run_phase1a_algorithm.m
     -> initial_coupling_estimate.m
     -> track_coupling_cvff_rls.m
        -> coupling_regressor.m
     -> extract_resistive_current.m
```

同时用 `scripts/build_phase2_model.m` 与冻结 SLX 内的 `DynamicLeakageCurrentModel` 脚本交叉核对故障注入和总电流方程。SLX 内实际存在：

```matlab
iA_R_true = -iA_R_raw;
iB_R_true = -B_fault_scale*iB_R_raw;
iC_R_true = -iC_R_raw;
```

只读打开 `baseline_workspace.mat`，核对根变量、Case05/06 字段、算法字段和 cycle table 字段。该操作没有调用模型或算法。

---

## 2. Actual regression model

### 2.1 参数向量

`coupling_regressor.m` 使用的参数为：

\[
\boldsymbol c=
\begin{bmatrix}
C_{s1}\\
C_{s2}
\end{bmatrix},
\]

其中数值单位是 **pF**，不是 F。`C_{s1}` 对应 A-B 相间耦合，`C_{s2}` 对应 B-C 相间耦合。

### 2.2 参考信号预处理

`reconstruct_refs_from_b.m` 只使用理想 B 相电压 `data.ub`。在初始化窗口
`0.10 <= t < 0.70 s` 内，以

```matlab
H = [sin(w*t), cos(w*t), sin(3*w*t), cos(3*w*t), 1];
beta = H \ ub;
```

拟合 B 相基波、三次谐波和直流项。然后按基波平衡三相关系构造 A/B/C 电压参考，并解析计算 `ref.dua/ref.dub/ref.duc`。三次谐波在三相中使用同相参考。

因此进入回归的导数不是 AutoComp9 内部二阶后向差分的原始三相电压导数，而是由初始化窗口拟合得到的解析参考导数。两者的差异属于回归残差/模型失配。

### 2.3 实际 X 和 y

对任意索引块 `idx`，令 `n=numel(idx)`、`q=1e-12 F/pF`，并记
`d_A=ref.dua(idx)`、`d_B=ref.dub(idx)`、`d_C=ref.duc(idx)`。代码构造：

\[
\boldsymbol X=q
\begin{bmatrix}
d_A-d_B & 0\\
d_B-d_A & d_B-d_C\\
0 & d_C-d_B
\end{bmatrix}_{3n\times2},
\]

\[
\boldsymbol y=
\begin{bmatrix}
i_A-C_{\mathrm{self},A}d_A\\
i_B-C_{\mathrm{self},B}d_B\\
i_C-C_{\mathrm{self},C}d_C
\end{bmatrix}_{3n\times1}.
\]

代码中的三相排列不是逐时刻交织，而是：

```text
rows 1:n         = A 相的全部 n 个样本
rows n+1:2n      = B 相的全部 n 个样本
rows 2n+1:3n     = C 相的全部 n 个样本
```

两列的物理含义为：

| X 列 | A 相块 | B 相块 | C 相块 | 物理含义 |
|---|---|---|---|---|
| 第 1 列 | `q(dA-dB)` | `q(dB-dA)` | 0 | A-B 耦合电容每 1 pF 对三相电流的贡献 |
| 第 2 列 | 0 | `q(dB-dC)` | `q(dC-dB)` | B-C 耦合电容每 1 pF 对三相电流的贡献 |

`d` 的单位是 V/s，乘 `q` 后 X 的单位是 A/pF；`c` 的数值单位是 pF，因此 `X*c` 的单位是 A。`y` 也以 A 为单位。

### 2.4 每周期实际维度

冻结配置为 `Ts=2e-5 s`、`f=50 Hz`。代码计算：

```matlab
fs = 1/median(diff(t));
Nc = round(fs/cfg.f);
```

因此当前数据中：

```text
fs = 50000 Hz
Nc = 1000 samples/phase/cycle
Xk = 3000 × 2
yk = 3000 × 1
```

在线更新确实按一个完整工频周期 block 进行。正式 Case05/06 各有 165 个更新块，cycle 末时刻从 `0.71998 s` 到 `3.99998 s`。最后 `t=4.0 s` 的不足整周期尾样本由最终参数填充，不构成新的 RLS 更新块。

初始化窗口包含 30000 个单相样本，因此 `X0` 为 `90000 × 2`。

### 2.5 谐波、缩放和进入 RLS 前的处理

1. `ref.du*` 来自基波和三次谐波拟合后的解析导数。
2. 因当前三次谐波参考在 A/B/C 三相同相，`dA-dB`、`dB-dC` 中公共三次谐波理论上抵消；但三次谐波仍参与自电容扣除和后续残差拟合。
3. 自电容先按 `self_pF*1e-12.*du` 从原始总电流中扣除。
4. X 显式乘 `1e-12`，使 Cs 参数以 pF 进入算法。
5. y 未做去均值、标准化、滤波或幅值归一化。
6. X 也未做列标准化；只有 VFF innovation 使用 `[5;5] pF` 做参数尺度归一化。
7. AutoComp9 生成总电流时使用实际电压的二阶后向差分，而辨识使用解析重构导数；该差异没有在进入 RLS 前被消除。

因此更完整的实际观测关系应写为：

\[
\boldsymbol y_k
=\boldsymbol X_k\boldsymbol c_{\mathrm{true},k}
+\boldsymbol b_k+\boldsymbol r_{f,k}+\boldsymbol n_k,
\]

其中 `b_k` 至少包含正常阻性电流、模型内导数与重构导数差异、参考重构误差及其他确定性模型失配；`r_f,k` 仅表示由故障倍率引入的**增量故障分量**；`n_k` 为电流噪声。不能把全部 `y-X*c_est` 都称为真实故障分量。

---

## 3. Static LS fault-bias definition

### 3.1 静态几何层

在同一个 X、相同正常残差和相同噪声实现下，比较 fault 与 no-fault counterfactual：

\[
\boldsymbol y_f=\boldsymbol X\boldsymbol c_{\mathrm{true}}+
\boldsymbol b+\boldsymbol r_f+\boldsymbol n,
\]

\[
\boldsymbol y_0=\boldsymbol X\boldsymbol c_{\mathrm{true}}+
\boldsymbol b+\boldsymbol n.
\]

普通最小二乘解的差为：

\[
\Delta\boldsymbol c_{\mathrm{LS},f}
=\hat{\boldsymbol c}_{f}-\hat{\boldsymbol c}_{0}
=\boldsymbol X^{+}\boldsymbol r_f.
\]

当 X 满列秩时：

\[
\Delta\boldsymbol c_{\mathrm{LS},f}
=(\boldsymbol X^\mathsf T\boldsymbol X)^{-1}
\boldsymbol X^\mathsf T\boldsymbol r_f.
\]

本报告冻结其名称为：

```text
static fault-induced equivalent parameter bias
静态故障诱导等效参数偏差
```

它回答的是：“如果只在当前 block 上进行无约束静态 LS，故障分量在 Cs 参数空间中等效对应多大的偏差？”它不等于 M2 的最终 Cs 漂移，也不包含历史信息、VFF、变化率限制或物理投影。

### 3.2 数值实现要求

Step 2 禁止显式计算 `(X'*X)^(-1)`。对当前 `3000×2` 的高矩阵，优先：

```matlab
delta_c_LS_f = X \ r_fault;
```

并用 economy SVD 记录：

```text
rank_X
sigma_max_X
sigma_min_X
cond2_X = sigma_max_X/sigma_min_X
```

SVD 秩容差冻结为：

\[
\mathrm{tol}_{\mathrm{rank}}=
\max(\mathrm{size}(X))\,\epsilon(\sigma_{\max}).
\]

若 X 不满列秩，则使用保留奇异值对应的最小范数解；只有明确记录容差时才允许 `pinv(X,tol)`。不得静默接受病态矩阵。

注意：tracker 内用于 VFF 的局部估计是
`(X'*X+1e-10*I)\(X'*y)`，它是代码现状中的正则化 normal-equation 解，不是本节定义的稳定普通 LS 几何量。两者必须分别记录。

---

## 4. Geometric fault projection

令故障可表达子空间为：

\[
\mathcal S_X=\mathrm{col}(\boldsymbol X).
\]

对 X 作 economy SVD：

\[
\boldsymbol X=\boldsymbol U\boldsymbol\Sigma\boldsymbol V^\mathsf T,
\]

根据上一节秩容差保留 `r=rank(X)` 个左奇异向量，令
`Q_X=U(:,1:r)`。定义：

\[
\boldsymbol r_{\parallel}=\boldsymbol Q_X\boldsymbol Q_X^\mathsf T\boldsymbol r_f,
\qquad
\boldsymbol r_{\perp}=\boldsymbol r_f-\boldsymbol r_{\parallel}.
\]

冻结指标：

\[
\eta_{\mathrm{geom}}=
\frac{\|\boldsymbol r_{\parallel}\|_2^2}
{\|\boldsymbol r_f\|_2^2}.
\]

名称冻结为：

```text
geometric fault absorbability
几何故障可吸收率
```

定义域和退化规则：

- 当 `||r_f||_2>0` 时，理论范围为 `[0,1]`；仅允许浮点舍入导致极小越界，保存前可在 `1e-12` 容差内夹紧。
- 当 `||r_f||_2=0` 时，`eta_geom=NaN`，不能写 0，因为该 block 没有可定义的故障方向。
- `eta_geom` 只描述故障向量与 coupling model column space 的几何重合，不等于实际 RLS 吸收比例。

正交能量闭合验证：

\[
\epsilon_{\mathrm{closure}}=
\frac{\left|\|r_f\|_2^2-
(\|r_{\parallel}\|_2^2+\|r_{\perp}\|_2^2)\right|}
{\max(\|r_f\|_2^2,\epsilon)}.
\]

Step 2 接受阈值冻结为 `epsilon_closure <= 1e-10`。同时验证
`X*delta_c_LS_f` 与 `r_parallel` 在数值容差内一致。

---

## 5. Actual dynamic VFF-RLS mechanism

### 5.1 状态初始化

`track_coupling_cvff_rls.m` 先重新调用 `initial_coupling_estimate` 得到 `c0`，随后：

\[
\boldsymbol J_0=0.05\boldsymbol X_0^\mathsf T\boldsymbol X_0+10^{-8}\boldsymbol I,
\qquad
\boldsymbol h_0=\boldsymbol J_0\boldsymbol c_0.
\]

代码保存的是 information state `J/h`，不是标准协方差矩阵 P。

### 5.2 每周期真实顺序

对第 k 个工频周期：

1. 构造 `Xk,yk`；
2. 计算 `Rk=Xk'*Xk`、`zk=Xk'*yk`；
3. 计算正则化局部参数 `cLS,k=(Rk+1e-10 I)\zk`；
4. 用当前受约束参数 `c_{k-1}` 计算 innovation；
5. 由 innovation 计算 `lambda_k`；
6. 用更新前参数 `c_{k-1}` 计算 `E_in/E_quad`；
7. 更新/续期 gate 状态；
8. 若 gate 有效，冻结 `J/h/c/baseIn`；
9. 若 gate 无效，更新 `J/h`，求 unconstrained `cNew`，再依次执行变化率限制和物理投影；
10. 仅在非门控且 `E_in<1.08*baseIn` 时更新 `baseIn`；
11. 将更新后的 c 保持到该周期全部样本。

### 5.3 VFF

\[
\boldsymbol c_{\mathrm{LS},k}^{\mathrm{code}}
=(\boldsymbol R_k+10^{-10}\boldsymbol I)^{-1}\boldsymbol z_k,
\]

\[
\nu_k=\left\|
\frac{\boldsymbol c_{\mathrm{LS},k}^{\mathrm{code}}-
\boldsymbol c_{k-1}}{[5,5]^\mathsf T}
\right\|_2,
\]

\[
\lambda_k=\lambda_{\max}-(\lambda_{\max}-\lambda_{\min})
\operatorname{clip}(\nu_k/0.20,0,1).
\]

`[5;5] pF` 和 `0.20` 是函数内历史常量。故障会先改变 y 和局部 LS，从而可能改变 `nu` 和 `lambda`；因此不能把 lambda 当作与故障无关的固定增益。

### 5.4 非门控更新

若 gate 无效：

\[
\boldsymbol J_k^-=\lambda_k\boldsymbol J_{k-1}+\boldsymbol R_k,
\qquad
\boldsymbol h_k^-=\lambda_k\boldsymbol h_{k-1}+\boldsymbol z_k,
\]

\[
\boldsymbol c_k^{\mathrm{raw}}
=(\boldsymbol J_k^-+10^{-10}\boldsymbol I)^{-1}\boldsymbol h_k^-.
\]

然后：

\[
\Delta\boldsymbol c_k^{\mathrm{rate}}
=\operatorname{clip}(\boldsymbol c_k^{\mathrm{raw}}-
\boldsymbol c_{k-1},-1.2,1.2),
\]

\[
\boldsymbol c_k^{\mathrm{rate}}
=\boldsymbol c_{k-1}+\Delta\boldsymbol c_k^{\mathrm{rate}},
\]

\[
\boldsymbol c_k=\operatorname{clip}
(\boldsymbol c_k^{\mathrm{rate}},0,40).
\]

这里两个 clip 均逐参数执行。J/h 不会因变化率限制或投影而回写修正，所以一般不能假设 `h_{k-1}=J_{k-1}c_{k-1}`。令

\[
\boldsymbol A_k=\lambda_k\boldsymbol J_{k-1}+
\boldsymbol R_k+10^{-10}\boldsymbol I,
\]

则实际 unconstrained 增量的精确表达为：

\[
\Delta\boldsymbol c_k^{\mathrm{raw}}
=\boldsymbol A_k^{-1}
\left[
\lambda_k(\boldsymbol h_{k-1}-\boldsymbol J_{k-1}\boldsymbol c_{k-1})
+\boldsymbol X_k^\mathsf T\boldsymbol e_k
-10^{-10}\boldsymbol c_{k-1}
\right],
\]

其中 `e_k=yk-Xk*c_{k-1}`。该式比直接套用标准 covariance-form RLS 增益更符合现有代码。

### 5.5 故障到单周期更新的映射

若固定同一个历史状态和同一个 lambda，并写
`yk=y0,k+r_f,k`，则故障的直接 unconstrained 贡献为：

\[
\Delta\boldsymbol c_{\mathrm{RLS},f,k}^{\mathrm{direct}}
=\boldsymbol K_k\boldsymbol r_{f,k},
\]

\[
\boldsymbol K_k=
(\lambda_k\boldsymbol J_{k-1}+\boldsymbol R_k+10^{-10}\boldsymbol I)^{-1}
\boldsymbol X_k^\mathsf T.
\]

这只是 **fixed-lambda direct term**。完整的 fault/counterfactual 差异必须分别计算：

\[
\boldsymbol c_{k,f}^{\mathrm{raw}}=
\boldsymbol A_{k,f}^{-1}
(\lambda_{k,f}\boldsymbol h_{k-1}+\boldsymbol z_{k,0}+
\boldsymbol X_k^\mathsf T\boldsymbol r_{f,k}),
\]

\[
\boldsymbol c_{k,0}^{\mathrm{raw}}=
\boldsymbol A_{k,0}^{-1}
(\lambda_{k,0}\boldsymbol h_{k-1}+\boldsymbol z_{k,0}),
\]

因为 `lambda_f` 与 `lambda_0` 可能不同。之后还必须对两个分支分别执行 rate limit 和 physical projection。该映射是分段非线性的，不能压缩成全局固定 K。

若 M3 gate 有效，则代码的实际更新为：

```text
delta_c_actual = [0;0]
Jk = Jk-1
hk = hk-1
ck = ck-1
```

此时 lambda 仍被计算和记录，但未用于 J/h 更新。

---

## 6. Delta c definitions — mandatory distinction

| 名称 | 定义 | 包含历史状态 | 包含 VFF | 包含 rate/projection | 含义 |
|---|---|---:|---:|---:|---|
| `Delta c_LS,f` | `X\r_fault` | 否 | 否 | 否 | 静态故障诱导等效参数偏差 |
| `Delta c_RLS,f,direct` | `Kk*r_fault`，lambda 固定 | 是 | 使用给定 lambda | 否 | 当前历史状态下的直接 unconstrained fault term |
| `Delta c_RLS,f,cf` | fault 与 counterfactual 两分支完整差 | 是 | 两分支各自计算 | 可分别给出 raw/final | 包含 fault 对 lambda 的影响 |
| `Delta c_RLS,pred` | 用实际 X/y/J/h 按代码顺序 replay 后的 `c_projected-c_before` | 是 | 是 | 是 | 对实际单周期 M2/M3 更新的预测 |
| `Delta c_actual` | tracker 实际 `c_after-c_before` | 是 | 是 | 是 | 用于验证 instrumentation 与原实现一致 |

上述名称在 mechanism schema v1 中冻结。不得用 `Delta c_LS,f` 代替 M2 实际参数漂移，也不得把 fixed-lambda `K*r_fault` 描述成完整动态结果。

---

## 7. Strict r_fault definition

### 7.1 AutoComp9 中的故障位置

冻结模型和构建脚本一致：

\[
i_{B,R}^{\mathrm{true}}=-g(t)i_{B,R}^{\mathrm{raw}},
\qquad g(t)=\texttt{B\_fault\_scale}.
\]

无故障但其他条件完全相同时：

\[
i_{B,R}^{0}=-i_{B,R}^{\mathrm{raw}}
=\frac{i_{B,R}^{\mathrm{true}}}{g(t)}.
\]

因此 B 相严格增量故障分量为：

\[
r_{f,B}(t)=i_{B,R}^{\mathrm{true}}-i_{B,R}^{0}
=\left(1-\frac1{g(t)}\right)i_{B,R}^{\mathrm{true}}
=(g(t)-1)i_{B,R}^{0}.
\]

当前故障倍率始终 `g>=1`，不存在除零。故障倍率只进入 `DynamicLeakageCurrentModel` 的 B 相阻性电流支路；没有反馈改变电压、Cs truth 或噪声生成。因此对于当前 AutoComp9，以上恢复是严格的，不需要把 `y-X*c_est` 冒充故障真值，也不需要第二次 no-fault Simulink 运行。

### 7.2 observation-space 向量

对与 `coupling_regressor` 相同的周期 `idx`，严格定义：

\[
\boldsymbol r_{f,k}=
\begin{bmatrix}
\boldsymbol 0_n\\
\boldsymbol r_{f,B}(idx)\\
\boldsymbol 0_n
\end{bmatrix}\in\mathbb R^{3n}.
\]

其排列、长度和单位与 y 完全一致。Case05/06 的 `fault_scale` 和 `irB_true` 已保存在正式 workspace，因此 `r_fault` 本身可从冻结数据严格导出；但 X/y 未保存，所以当前 workspace 单独不足以计算投影。

### 7.3 未来模型的退化条件

若以后故障会反馈影响电压、原始阻性波形、Cs、噪声或网络状态，则上述除法恢复不再成立。此时必须采用 fault/no-fault paired run，并保证除 fault profile 外以下内容完全一致：模型哈希、配置、Cs truth、电压、采样、seed、噪声 realization、相位误差和 SNR。定义应为：

\[
\boldsymbol r_f=\boldsymbol y_{fault}-\boldsymbol y_{counterfactual},
\]

且两者必须在同一个 `coupling_regressor` observation space 中构造。

---

## 8. E_in / E_quad definition

### 8.1 输入和周期层级

`track_coupling_cvff_rls.m` 的局部函数 `residual_components` 在每个完整工频周期调用。输入为当前周期 `data/ref/idx`、**更新前**参数 c、self_pF 和 f。先重新构造同一个 X/y：

\[
\boldsymbol e_k=\boldsymbol y_k-\boldsymbol X_k\boldsymbol c_{k-1}.
\]

然后按 A/B/C 三个连续块拆分，每相 n=1000 个样本。

### 8.2 每相拟合

对相 p，基波相位偏移为 A `+2pi/3`、B `0`、C `-2pi/3`。定义：

\[
B_{in,p}=
\begin{bmatrix}
\sin(\omega t+\phi_1+\theta_p)&
\sin(3\omega t+\phi_3)
\end{bmatrix},
\]

\[
B_{q,p}=
\begin{bmatrix}
\cos(\omega t+\phi_1+\theta_p)&
\cos(3\omega t+\phi_3)
\end{bmatrix}.
\]

代码联合求解：

```matlab
B = [Bin, Bq, ones(n,1)];
coef = B \ ep;
```

然后：

\[
E_{in,p}=\operatorname{RMS}(B_{in,p}\,coef_{1:2}),
\qquad
E_{quad,p}=\operatorname{RMS}(B_{q,p}\,coef_{3:4}).
\]

三相合成：

\[
E_{in}=\sqrt{\frac{E_{in,A}^2+E_{in,B}^2+E_{in,C}^2}{3}},
\qquad
E_{quad}=\sqrt{\frac{E_{quad,A}^2+E_{quad,B}^2+E_{quad,C}^2}{3}}.
\]

二者单位均为 A。没有额外滤波、能量归一化或按总电流幅值归一化；只有每周期的 1/3 次谐波加直流联合 LS 拟合。

### 8.3 baseline 和 gate

- 第一个在线周期用其 `E_in` 初始化 `baseIn`。
- 只有 `enableGate=true`、周期末时刻 `>1.0 s`，且同时满足
  `E_in > 1.12*baseIn` 与 `E_in > 1.20*E_quad` 时才触发故障。
- `1.12` 作用于相对历史 in-phase baseline；`1.20` 作用于同相/正交方向比较。
- 触发后 `gateHold=max(gateHold,25)`；持续触发可续期。
- gate 有效时冻结 J/h/c/baseIn。
- 非门控且 `E_in<1.08*baseIn` 时，
  `baseIn=0.985*baseIn+0.015*E_in`。
- M2 仍计算并记录这些量，但 `enableGate=false`，所以它们不冻结更新。

### 8.4 可支持的物理解释边界

在当前参考约定下，MOA 阻性电流变化通常更接近电压同相的 sine 子空间，而自电容/耦合电容误差通常更接近导数对应的 cosine 子空间，因此 `E_in` 相对 `E_quad` 和历史 baseline 上升，具有对阻性故障敏感的数学结构。

但是，当前残差还混有非线性 MOA 谐波、有限窗联合拟合串扰、理想 B 相参考假设、模型内 BDF 导数与解析导数差异以及噪声。现有代码和 Phase 1A 数据不足以证明 `E_in/E_quad` 在一般不平衡、传感器误差或模型失配下仍是纯粹的“阻性/容性”正交分解。对此结论为：

```text
current evidence insufficient for a universal physical-separation claim
```

---

## 9. Case05 / Case06 data availability audit

正式 MAT 的 Case05/06 均有 `200001` 个时域样本；M2/M3 各有 `165×8` cycle table，字段为：

```text
time_s, Cs1_pF, Cs2_pF, lambda, E_in, E_quad, gate, base_in
```

逐项结论：

| 所需量 | 状态 | 现有位置或原因 |
|---|---|---|
| X | **not available** | 未保存 `data.ua/ub/uc`、ref 或 X |
| y | **not available** | 未保存三相总电流 `data.ia/ib/ic` |
| truth Cs1/Cs2 | **available** | `caseData.<case>.Cs1_true/Cs2_true` |
| estimated Cs1/Cs2 | **available** | `algorithmResults.<case>.<mode>.cHist`；M2/M3 cycle 亦有周期后值 |
| true resistive current A/B/C | **available** | `irA_true/irB_true/irC_true` |
| estimated resistive current B | **available** | 每个 mode 的 `irB` |
| estimated resistive current A/C | **not available** | `minimal_algorithm_result` 只保存 B 相 |
| fault profile | **available** | `fault_scale` |
| strict r_fault | **derivable** | 由 `fault_scale` 和 `irB_true` 按第 7 节公式恢复 |
| lambda | **available for M2/M3** | cycle table |
| innovation | **not available** | tracker 未写入 cycle table |
| E_in/E_quad | **available for M2/M3** | cycle table |
| baseIn/gate | **available for M2/M3** | cycle table |
| R/z | **not available** | tracker 未记录 |
| J/h state | **not available** | tracker 未记录 |
| cNew/rate-limited/projected 中间量 | **not available** | tracker 只保存最终 c |
| actual cycle delta c | **derivable** | 对相邻 cycle Cs 值作差；首周期需由 `cHist` 推出 c0 |
| c0 | **derivable** | `cHist` 在线更新前的常值段 |
| voltage/reference derivatives | **not available** | 未保存 data.ub 或 ref |
| total current/noise realization | **not available** | 精简 workspace 未保存 data.ia/ib/ic/noise |
| eta_geom/r_parallel/r_perp | **not available** | r_fault 可导出，但缺 X |
| matrix rank/singular values/condition | **not available** | 缺 X |

结论：冻结 workspace 足以确认故障真值、参数漂移、故障保持、lambda 和现有门控时序，但不足以独立完成 Step 2 的投影与动态状态重放。不得修改 Phase 1A workspace；必须在 Phase 1B 新目录中建立独立 instrumentation。

---

## 10. Phase 1B mechanism schema v1 — FROZEN

本节冻结：

```text
schema_name    = Phase 1B mechanism schema
schema_version = v1
row_granularity = one case × one algorithm × one complete fundamental cycle
```

### 10.1 Cycle summary table

#### Identity and timing

| 字段 | 单位/类型 | 定义 |
|---|---|---|
| `schema_version` | string | 固定 `phase1b_mechanism_v1` |
| `case_name` | string | `Case05_fault_only` 或 `Case06_drift_then_fault` |
| `algorithm_mode` | string | Step 2 首先记录 `M2/M3` |
| `cycle_index` | integer | 从 1 开始的在线完整周期编号 |
| `time_start_s` | s | block 首样本时间 |
| `time_end_s` | s | block 末样本时间 |
| `sample_start_index` | integer | 对应 full data 的 MATLAB 1-based index |
| `sample_end_index` | integer | 对应 full data 的 MATLAB 1-based index |
| `n_samples` | integer | 当前冻结配置应为 1000 |

#### Truth and parameter state

| 字段 | 单位 | 定义 |
|---|---|---|
| `fault_factor_true` | 1 | block 内 `mean(fault_scale)`；为保留斜坡信息同时记录 start/end |
| `fault_factor_start` | 1 | block 首样本倍率 |
| `fault_factor_end` | 1 | block 末样本倍率 |
| `Cs1_true_pF` / `Cs2_true_pF` | pF | block truth 的均值 |
| `Cs1_est_before_pF` / `Cs2_est_before_pF` | pF | 更新前 c |
| `Cs1_est_pF` / `Cs2_est_pF` | pF | 更新/门控后的 c |

#### Geometry

| 字段 | 单位 | 定义 |
|---|---|---|
| `rank_X` | 1 | SVD 数值秩 |
| `sigma_max_X_A_per_pF` | A/pF | 最大奇异值 |
| `sigma_min_X_A_per_pF` | A/pF | 最小保留奇异值 |
| `cond2_X` | 1 | 2-范数条件数 |
| `r_fault_norm_A` | A | `norm(r_fault,2)`；向量 2-范数 |
| `r_parallel_norm_A` | A | `norm(r_parallel,2)` |
| `r_perp_norm_A` | A | `norm(r_perp,2)` |
| `eta_geom` | 1 | 几何故障可吸收率；无故障 block 为 NaN |
| `projection_energy_closure_relerr` | 1 | 第 4 节能量闭合相对误差 |
| `delta_Cs1_LS_pred_pF` / `delta_Cs2_LS_pred_pF` | pF | `X\r_fault` |

#### Code-local LS and VFF

| 字段 | 单位 | 定义 |
|---|---|---|
| `cLS1_code_pF` / `cLS2_code_pF` | pF | tracker 的正则化 local LS |
| `innovation` | 1 | `[5;5] pF` 归一化后的 2-范数 |
| `lambda` | 1 | 实际 VFF lambda |

#### Information state and sufficient statistics

| 字段 | 单位 | 定义 |
|---|---|---|
| `R11/R12/R22` | A²/pF² | `X'*X` 的独立元素 |
| `z1/z2` | A²/pF | `X'*y` |
| `J11/J12/J22_before` | A²/pF² | 更新前 J |
| `h1/h2_before` | A²/pF | 更新前 h |
| `J11/J12/J22_after` | A²/pF² | gate/更新后的 J |
| `h1/h2_after` | A²/pF | gate/更新后的 h |

#### Dynamic prediction and actual update

| 字段 | 单位 | 定义 |
|---|---|---|
| `delta_Cs1_RLS_direct_raw_pF` / `delta_Cs2_RLS_direct_raw_pF` | pF | fixed-lambda `K*r_fault` |
| `delta_Cs1_RLS_fault_cf_raw_pF` / `delta_Cs2_RLS_fault_cf_raw_pF` | pF | fault/counterfactual raw 差，lambda 各自计算 |
| `Cs1_raw_pF` / `Cs2_raw_pF` | pF | 实际 observed branch 的 unconstrained `cNew` |
| `Cs1_rate_limited_pF` / `Cs2_rate_limited_pF` | pF | rate limit 后、投影前 |
| `Cs1_projected_pF` / `Cs2_projected_pF` | pF | 物理投影后预测值 |
| `delta_Cs1_RLS_pred_pF` / `delta_Cs2_RLS_pred_pF` | pF | `c_projected-c_before`；gate 时为 0 |
| `delta_Cs1_actual_pF` / `delta_Cs2_actual_pF` | pF | 原 tracker 的 `c_after-c_before` |
| `prediction_error_Cs1_pF` / `prediction_error_Cs2_pF` | pF | predicted minus actual；等价性验收用 |
| `rate_limit_active_Cs1/Cs2` | logical | 对应参数是否触发 ±1.2 pF/cycle |
| `projection_active_Cs1/Cs2` | logical | 是否触发 `[0,40] pF` 投影 |

#### Residual and gate

| 字段 | 单位 | 定义 |
|---|---|---|
| `E_in_A` | A | 现有代码的三相同相残差 RMS |
| `E_quad_A` | A | 现有代码的三相正交残差 RMS |
| `base_in_A` | A | 当前周期记录的 baseline |
| `gate_trigger_condition` | logical | 本周期原始双阈值判据是否成立 |
| `gate_active` | logical | 本周期是否实际冻结 |
| `gate_hold_before` / `gate_hold_after` | cycles | 保持计数状态 |

保留 `fault_factor_start/end` 是因为 3.00–3.06 s 为平滑斜坡，仅用一个倍率会丢失 block 内变化；保留 J/h/R/z 是因为没有这些状态就不能从真实代码验证动态预测；保留 raw/rate/projected 三阶段是因为现有更新是非线性的。

### 10.2 Observation block companion store

单个 cycle table 不应重复保存 3000 行原始向量。Step 2 必须另存同版本 MAT companion：

```text
observationBlocks.<case>.<algorithm>(k).idx
observationBlocks.<case>.<algorithm>(k).X
observationBlocks.<case>.<algorithm>(k).y_fault
observationBlocks.<case>.<algorithm>(k).y_counterfactual
observationBlocks.<case>.<algorithm>(k).r_fault
```

其中必须验证：

```text
size(X)              = [3*n_samples, 2]
size(y_fault)        = [3*n_samples, 1]
size(y_counterfactual)= [3*n_samples, 1]
size(r_fault)        = [3*n_samples, 1]
y_fault - y_counterfactual == r_fault  (within floating tolerance)
```

cycle summary 与 companion store 共同构成 **Phase 1B mechanism schema v1**。后续如需新增字段必须提升 schema version，不得静默改变本节字段语义。

---

## 11. Step 2 instrumentation requirements

Step 2 应独立实现，禁止修改 AutoComp9、Phase 1A runner、Phase 1A workspace 或现有 tracker。最低要求：

1. 新建 Phase 1B wrapper，只运行 Case05/06；不重跑六工况 baseline。
2. wrapper 使用冻结 AutoComp9 哈希、冻结 cfg、Case registry seeds 和现有 `simulate_phase2_case` 获得完整 data；输出只写入 `paper_research/phase1b_fault_absorption/`。
3. 从同一 `data/ref` 构造 X/y，禁止从绘图或 CSV 反推。
4. 使用保存的 `fault_scale` 和 `irB_true` 构造严格 `r_fault`；再定义 `data.ib_counterfactual=data.ib-r_fault_B`。A/C、电压、Cs、noise realization 均保持同一份数据，因此无需第二次 Simulink counterfactual run。
5. 新建独立 instrumented tracker/replay，不改 `track_coupling_cvff_rls.m`。逐周期记录 schema v1 中的 c/J/h/R/z/local LS/innovation/lambda/raw/rate/projected/gate 状态。
6. instrumented 输出必须与原 M2/M3 的 `cHist` 和现有 8 字段 cycle table 对齐；建议最大绝对差阈值 `<=1e-12`（pF 或相应字段量纲下），否则 Step 2 不得使用其机理结果。
7. 用 SVD/QR 计算投影和条件数，不显式求逆。
8. Case05 用于隔离纯故障；Case06 用于验证漂移后的同一故障。两者必须使用相同定义和 schema。
9. 保存运行时 Git commit、model SHA、CSV SHA、cfg、seed、MATLAB/Simulink 版本和 instrumentation 源码哈希。
10. 不修改、覆盖或重新保存 `baseline_workspace.mat`。

如果将来发现 current AutoComp9 的代数 counterfactual 与显式 no-fault run 不一致，再增加一次严格 paired-run 交叉验证；在当前无反馈结构下它不是 Step 2 的必需条件。

---

## 12. Fault-amplitude hypothesis

若

\[
\boldsymbol r_f=\alpha\boldsymbol r_0
\]

且 X 的列空间不变，则：

\[
\eta_{\mathrm{geom}}(\alpha\boldsymbol r_0)
=\eta_{\mathrm{geom}}(\boldsymbol r_0),\qquad \alpha\ne0.
\]

因此后续不得预设“故障幅度增加必然导致 eta_geom 增加”。冻结的待验证假设为：

```text
eta_geom may remain approximately constant,
while |Delta c_LS,f|, dynamic parameter drift,
and/or fault-retention loss increase with fault amplitude.
```

实际动态算法仍可能因 lambda 饱和、rate limit、projection、gate 和历史状态呈现非线性。若 X 或归一化后的故障波形方向随幅值变化，eta_geom 也可变化，但必须由 X/故障方向变化解释，不能只按幅值大小解释。

---

## 13. Unresolved questions

1. Case05/06 的实际 X 条件数、数值秩和 eta_geom 尚未计算；正式 workspace 缺 X，必须留到 Step 2。
2. fixed-lambda direct term 与 lambda-change counterfactual term 各占多大比例尚无数据。
3. M2 的 rate limit 是否在故障斜坡各周期触发、J/h 与受约束 c 的不一致积累到什么程度，尚需 instrumentation。
4. `E_in/E_quad` 对当前工况有效，但在负序、传感器误差、自电容失配和一般谐波条件下的方向解释尚无证据。
5. 当前 tracker 的 local LS 使用 normal equations 和固定 `1e-10 I`；其数值影响需通过 SVD 条件数对照，但本步骤不修改算法。
6. 当前 fault absorption 仍只针对 A-B/B-C 两参数模型；不能外推至 CsAC 或一般耦合矩阵。

这些问题不阻塞 Step 1 的定义冻结，但必须由 Step 2/3 的独立数据和验证回答。

---

## 14. Step 1 acceptance

| 验收项 | 结果 |
|---|---|
| Phase 1A Git/模型/CSV 完整性 | PASS |
| 真实 X/y/c、维度、单位和排列已从代码确认 | PASS |
| 静态 LS fault-bias 定义及稳定数值方法 | PASS |
| 几何投影、eta_geom、能量闭合与退化规则 | PASS |
| 真实 VFF-RLS 更新顺序和非线性约束推导 | PASS |
| Delta c_LS 与动态 Delta c_RLS 明确区分 | PASS |
| r_fault 从 AutoComp9 真值链严格定义 | PASS |
| E_in/E_quad、baseline 和 gate 路径确认 | PASS |
| Case05/06 workspace 可用性逐项核对 | PASS |
| Phase 1B mechanism schema v1 冻结 | PASS |
| Step 2 instrumentation 边界和验收要求 | PASS |
| 未运行仿真、未修改 Phase 1A、未实现 M4 | PASS |

```text
STEP1_THEORY_AND_DATA_DEFINITION: PASS
```

建议仅在人工审查本报告和 mechanism schema v1 后进入 Step 2。本步骤在此停止，不自动执行 Step 2。
