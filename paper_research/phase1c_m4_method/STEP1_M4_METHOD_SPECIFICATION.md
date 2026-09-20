# Phase 1C Step 1 — M4 Direction-Aware Fault-Preserving Adaptive Identification 方法规格

## 0. 文档状态与本轮边界

本文件是 Phase 1C Step 1 的方法规格，不是实现报告，也不是性能报告。本轮只冻结问题定义、候选架构、在线可观测量、数学骨架、参数预算和 Step 2 的最小日志/验证要求。

```text
FINAL FORMULA: NOT FROZEN
PARAMETER STATUS: NOT TUNED
IMPLEMENTATION STATUS: NOT STARTED
EXPERIMENT STATUS: NOT RUN
```

本轮严格遵守以下冻结边界：

- 不修改 `AI6109_MOA_AutoComp9.slx`；
- 不修改 Phase 1A 基线、算法注册表和工况注册表；
- 不修改 M0/M1/M2/M3 任何实现；
- 不修改 lambda、rate limit、projection 或现有 gate 参数；
- 不修改 Phase 1B Step 1–5 的正式结果、工作区、图表或报告；
- 不运行 MATLAB/Simulink，不运行新旧实验，不进入 Phase 1C Step 2；
- 不开发 M4 代码。

本轮唯一新增文件应为本文件。

## 1. 已读取的正式依据

### 1.1 Phase 1B 正式证据

1. `paper_research/phase1b_fault_absorption/PHASE1B_FAULT_ABSORPTION_REPORT.md`
2. `paper_research/phase1b_fault_absorption/STEP1_THEORY_AND_DATA_DEFINITION.md`
3. `paper_research/phase1b_fault_absorption/STEP2_BASELINE_MECHANISM.md`
4. `paper_research/phase1b_fault_absorption/STEP3_CASE06_VERIFICATION.md`
5. `paper_research/phase1b_fault_absorption/STEP4_CONTROLLED_FACTOR_EXPERIMENTS.md`
6. `paper_research/phase1b_fault_absorption/STEP5_CORRELATION_AND_EVIDENCE.md`

### 1.2 Phase 1A 基线、注册表与真实代码定义

1. `paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md`
2. `MATLAB一键实验/phase1a_algorithm_registry.m`
3. `MATLAB一键实验/phase1a_case_registry.m`
4. `MATLAB一键实验/patent_default_config.m`
5. `MATLAB一键实验/run_phase1a_algorithm.m`
6. `MATLAB一键实验/track_coupling_cvff_rls.m`
7. `MATLAB一键实验/coupling_regressor.m`
8. `MATLAB一键实验/initial_coupling_estimate.m`
9. `MATLAB一键实验/reconstruct_refs_from_b.m`

## 2. Phase 1B 结论压缩为 M4 设计约束

Phase 1B 已经证实的核心链条是：

```text
阻性故障残差 r_fault
→ 在当前回归几何中存在非零可吸收投影
→ M2 的递归参数更新沿近似 [+Cs1, -Cs2] 方向移动
→ 自适应容性补偿生成与故障阻性增量近同相的虚假补偿量
→ 阻性故障增幅被低估
```

正式证据包括：

- Case05 中 `eta_geom = 0.275451`；静态、递归和实际 M2 的 Cs 偏移方向与数量级闭合；
- Case05 中 M2 的故障因子约为 1.4011，而反事实递归约为 1.6011；
- Case05 虚假耦合补偿与故障阻性增量的 RMS 比约为 0.3333，基波相位差接近 0°；
- Case06 在真实漂移结束后仍复现同一故障吸收方向和数量级，说明该机理不依赖“恒定 Cs”这一单一工况；
- M3 的硬冻结能把故障保持显著拉回，但它通过完全停止递归实现，不能在故障期间继续追踪同时存在的真实 Cs 漂移；
- Step 4/5 显示 fault amplitude 改变时方向较稳定、`eta_geom` 基本稳定，但相位误差更主要改变正常估计偏差和残差背景，而非简单改变几何可吸收率；
- rate limit 和 projection 在既有正式条件中不是主导机理，lambda 对故障诱导偏差有次要但非零的瞬态贡献。

因此，M4 的目标不是再次证明 M2 会吸收故障，也不是简单把 M3 的二值门控改成一个平滑 sigmoid。M4 必须明确解决：

> 在只使用在线可得量的前提下，连续地降低故障诱导更新，同时尽可能保留真实 Cs 漂移所需的更新通道。

## 3. M4 的必要功能与非目标

### 3.1 必要功能

M4 至少应满足：

1. **连续保护**：更新强度不再只有 0/1 两种状态；
2. **信息因果**：只使用当前或过去在线量，不使用真实 Cs、真实故障标签、未来样本或 counterfactual；
3. **状态一致**：若对更新降权，必须同步处理 RLS 信息状态，不能只缩放输出参数而让内部 `J/h` 继续吸收故障；
4. **保留物理安全边界**：现有 rate limit 与 projection 继续作为最终安全层，而不是被重新解释为 M4 的核心创新；
5. **可退化性**：保护权重为 1 时应退化到原 M2；保护权重为 0 时应接近 M3 的保持行为；
6. **可诊断性**：必须记录保护证据、原始更新、实际更新和方向诊断，允许区分“检测失败”和“保护律失败”；
7. **不承诺不可观测分离**：若真实漂移与故障诱导更新同方向，M4 必须报告不确定性，不能宣称仅凭当前量可无损分离。

### 3.2 本阶段非目标

- 不重新设计参考重构链路；
- 不重新调 lambda、rate limit、projection、M3 gate；
- 不引入神经网络、分类器或黑箱故障识别；
- 不扩展耦合参数维度；
- 不追求在所有漂移/故障组合中理论上完全可分；
- 不用 Case05/06 的真值方向作为在线先验硬编码进算法；
- 不在 Step 1 固定最终公式或数值阈值。

## 4. 现有 M2/M3 信号的真实代码定义

本节以 `track_coupling_cvff_rls.m` 的实际实现为准，而不是按变量名称推测物理含义。

### 4.1 每周期回归量与 innovation

每个完整工频周期构造：

\[
R_k=X_k^\mathsf{T}X_k,\qquad z_k=X_k^\mathsf{T}y_k.
\]

局部正则最小二乘估计为：

\[
\hat c_{\mathrm{LS},k}^{\mathrm{code}}=(R_k+10^{-10}I)^{-1}z_k.
\]

代码中实际存在的标量 innovation 为：

\[
\nu_k=\left\|\frac{\hat c_{\mathrm{LS},k}^{\mathrm{code}}-c_{k-1}}{[5,5]^\mathsf{T}}\right\|_2.
\]

Cs 数值单位沿代码约定为 pF。该量是“本周期局部 LS 与上一递归参数之差”的归一化范数，不是卡尔曼创新，也不是残差能量。

### 4.2 `lambda` 的真实定义

\[
\lambda_k=\lambda_{\max}-(\lambda_{\max}-\lambda_{\min})
\operatorname{clip}\!\left(\frac{\nu_k}{0.20},0,1\right).
\]

当前配置中 `lambda_min = 0.55`、`lambda_max = 0.995`。lambda 根据局部参数变化幅度改变遗忘速度；它不是故障证据，也不应在 M4-v0 中承担故障/漂移分类职责。

### 4.3 `E_in` 与 `E_quad` 的真实定义

在更新前参数 `c_{k-1}` 下先形成残差：

\[
e_k=y_k-X_kc_{k-1}.
\]

对 A/B/C 三相分别用基波和三次谐波的同相/正交基底拟合。对第 \(p\) 相：

\[
B_{\mathrm{in},p}=\begin{bmatrix}
\sin(\omega t+\phi_1+\theta_p) & \sin(3\omega t+\phi_3)
\end{bmatrix},
\]

\[
B_{\mathrm{quad},p}=\begin{bmatrix}
\cos(\omega t+\phi_1+\theta_p) & \cos(3\omega t+\phi_3)
\end{bmatrix},
\]

其中 \(\theta_A=+2\pi/3\)、\(\theta_B=0\)、\(\theta_C=-2\pi/3\)。代码求解：

\[
\beta_p=\begin{bmatrix}B_{\mathrm{in},p} & B_{\mathrm{quad},p} & \mathbf{1}\end{bmatrix}^{\dagger}e_{k,p}.
\]

随后计算每相拟合同相分量和正交分量的 RMS，并在三相上再做 RMS 聚合：

\[
E_{\mathrm{in},k}=\sqrt{\frac{1}{3}\sum_p
\operatorname{RMS}^2(B_{\mathrm{in},p}\beta_{p,\mathrm{in}})},
\]

\[
E_{\mathrm{quad},k}=\sqrt{\frac{1}{3}\sum_p
\operatorname{RMS}^2(B_{\mathrm{quad},p}\beta_{p,\mathrm{quad}})}.
\]

两者单位均为 A，并包含基波与三次谐波拟合分量。`E_in` 不是“真实阻性电流”的直接测量，`E_quad` 也不是“纯容性模型误差”的唯一测量；参考误差、正常模型失配和谐波变化均可能污染它们。

### 4.4 `baseIn` 的真实定义

`baseIn` 单位为 A。它在首个有效在线周期初始化为当时的 `E_in`。在未门控且：

\[
E_{\mathrm{in},k}<1.08\,\mathrm{baseIn}_{k-1}
\]

时，代码更新：

\[
\mathrm{baseIn}_k=0.985\,\mathrm{baseIn}_{k-1}+0.015\,E_{\mathrm{in},k}.
\]

否则保持不变。M3 gate 激活期间，`baseIn` 同样冻结。它是缓慢更新的同相残差背景，不是无故障真值，也不应在故障污染后无条件继续学习。

### 4.5 M3 硬门控的真实定义

当前 M3 的故障判据为：

\[
t_k>1\ \mathrm{s},\quad
E_{\mathrm{in},k}>\mathrm{gate\_ratio}\,\mathrm{baseIn}_{k-1},\quad
E_{\mathrm{in},k}>\mathrm{gate\_quad\_ratio}\,E_{\mathrm{quad},k}.
\]

一旦触发，`J`、`h`、`c` 和 `baseIn` 在保持周期内全部冻结。这解释了 M3 的故障保持能力，也解释了它不能同时跟踪真实漂移。

### 4.6 现有代码中不存在的量

```text
local parameter innovation vector: NOT FORMALLY DEFINED
raw recursive parameter update vector: NOT FORMALLY DEFINED AS A LOGGED SIGNAL
online fault direction vector: NOT FORMALLY DEFINED
parallel/perpendicular update components: NOT FORMALLY DEFINED
continuous update weight: NOT FORMALLY DEFINED
```

为便于候选规格，本文只作候选定义，不视为已冻结公式：

\[
\delta c_{\mathrm{local},k}\triangleq
\hat c_{\mathrm{LS},k}^{\mathrm{code}}-c_{k-1},
\qquad
\delta c_{\mathrm{raw},k}\triangleq c_{\mathrm{M2,raw},k}-c_{k-1}.
\]

其中 `c_M2,raw` 是原 M2 信息更新后、rate limit 和 projection 前的参数候选。对当前信息形式 RLS，完整原始递归更新一般不等于简单的 \(Ke\)。若：

\[
A_k=\lambda_kJ_{k-1}+R_k+10^{-10}I,
\]

则：

\[
\delta c_{\mathrm{raw},k}=A_k^{-1}\left[
\lambda_k(h_{k-1}-J_{k-1}c_{k-1})+X_k^\mathsf{T}e_k-10^{-10}c_{k-1}
\right].
\]

Phase 1B 使用的 \(K r_{\mathrm{fault}}\) 是固定信息状态下的故障直接贡献诊断，不是在线递归总更新的完整表达式。

## 5. 在线可观测量与禁止使用量

| 量 | Step 2 是否在线可得 | 可作为 M4 输入 | 主要风险 |
|---|---:|---:|---|
| 当前周期 `X_k`, `y_k`, `R_k`, `z_k` | 是 | 是 | 受参考与模型失配影响 |
| `E_in`, `E_quad`, `baseIn` | 是 | 是 | 不是纯故障/纯漂移标签 |
| `lambda_k`、`J/h`、上一周期 `c` | 是 | 是 | 必须避免破坏 M2 端点等价性 |
| `delta c_local` | 可由现有量计算 | 是，先作诊断 | 混合真实漂移、噪声和故障投影 |
| `delta c_raw` | 可在 rate/projection 前取得 | 是 | 受历史信息状态影响 |
| 真实 `Cs1/Cs2` | 否 | 禁止 | 只能用于离线评价 |
| 真实 fault waveform / fault label | 否 | 禁止 | 只能用于离线评价 |
| counterfactual 参数轨迹 | 否 | 禁止 | 离线机理工具，不是在线信号 |
| 未来周期数据 | 否 | 禁止 | 违反因果性 |
| Phase 1B 预先计算的 `r_fault` 真值 | 否 | 禁止 | 依赖真值差分 |

## 6. 候选 A — 残差证据连续加权

### 6.1 核心思想

用现有在线残差证据构造连续更新权重 \(g_k\in[g_{\min},1]\)。正常或可解释为容性变化时 \(g_k\to1\)；故障型同相残差显著时 \(g_k\) 下降，但不必直接降为零。

\[
s_{E,k}=\mathcal{S}\!\left(
\frac{E_{\mathrm{in},k}}{\mathrm{baseIn}_{k-1}+\epsilon},
\frac{E_{\mathrm{in},k}}{E_{\mathrm{quad},k}+\epsilon}
\right),
\]

\[
g_k=g_{\min}+(1-g_{\min})\,\mathcal{G}(s_{E,k};\kappa_E).
\]

其中 \(\mathcal{S}\) 是故障证据组合，\(\mathcal{G}\) 是单调下降、连续有界映射。

```text
FINAL FORMULA: NOT FROZEN
```

### 6.2 状态一致性要求

仅在最终参数上做 \(c_k=c_{k-1}+g_k\delta c_{\mathrm{raw},k}\)，而仍让 `J/h` 完整执行 M2 更新是不合格的，因为隐藏信息状态仍会吸收故障，故障结束后可能再次把偏差释放到参数中。

Step 2 更合适的候选骨架是对 M2 信息状态增量连续插值：

\[
J_k^{\mathrm{M2}}=\lambda_kJ_{k-1}+R_k,
\qquad h_k^{\mathrm{M2}}=\lambda_kh_{k-1}+z_k,
\]

\[
J_k=J_{k-1}+g_k(J_k^{\mathrm{M2}}-J_{k-1}),
\qquad
h_k=h_{k-1}+g_k(h_k^{\mathrm{M2}}-h_{k-1}),
\]

\[
c_{k,\mathrm{raw}}=(J_k+10^{-10}I)^{-1}h_k.
\]

再依次经过原有 rate limit 和 projection。这样 `g=1` 可退化为 M2，`g=0` 可保持信息状态和参数，接近 M3 的冻结端点。该信息插值是否是最终实现仍需 Step 2 用端点和恢复过程测试确认。

### 6.3 优点与局限

优点：全部使用在线量；新参数少；与 M2/M3 端点关系清楚；消除二值突变和固定 hold 依赖；故障期间仍可保留非零更新；容易做消融。

局限：所有参数方向统一缩放，不是真正方向分离；参考误差或模型失配可能误触发；弱故障仍可能被吸收；`g_min` 本身体现故障保持与漂移跟踪的折中。

## 7. 候选 B — innovation 方向一致性加权

### 7.1 核心思想

从 `delta c_local` 或 `delta c_raw` 的方向，判断当前更新是否与故障可疑方向一致。方向一致且残差证据强时降低更新权重；方向不一致时尽量保留。

\[
\rho_k=\frac{\delta c_k^\mathsf{T}d_{f,k}}
{(\|\delta c_k\|_2+\epsilon)(\|d_{f,k}\|_2+\epsilon)},
\qquad g_k=\mathcal{G}(s_{E,k},\rho_k).
\]

```text
FINAL FORMULA: NOT FROZEN
ONLINE FAULT-DIRECTION ESTIMATOR: NOT FORMALLY DEFINED
```

固定使用 Case05/06 的 `[+1,-1]` 方向会把特定模型和参考几何硬编码为先验，不满足一般性要求。可考虑但尚未验证的在线候选是，将拟合同相残差重新投影到参数空间：

\[
q_k=(R_k+\epsilon I)^{-1}X_k^\mathsf{T}e_{\mathrm{in},k},
\qquad d_{f,k}=q_k/(\|q_k\|_2+\epsilon).
\]

当前代码只输出聚合标量 `E_in`，并未正式输出同相残差样本向量，因此该方向估计器只能作为 Step 2 待验证诊断定义。

优点是更接近“故障诱导参数方向”的机理，可为候选 C 提供前置可观测性检查。局限是方向估计可能与故障吸收通道循环依赖；真实漂移也会产生同类方向；小更新时方向噪声大；参考误差同时污染残差和方向。

因此，候选 B 在 M4-v0 中只作诊断，不建议单独作为 Primary 控制架构。

## 8. 候选 C — 各向异性软投影

### 8.1 核心思想

把原始参数更新沿在线故障可疑方向和其正交补空间分解，仅连续抑制可疑方向：

\[
P_{f,k}=d_{f,k}d_{f,k}^\mathsf{T},
\]

\[
\delta c_{\parallel,k}=P_{f,k}\delta c_{\mathrm{raw},k},
\qquad
\delta c_{\perp,k}=(I-P_{f,k})\delta c_{\mathrm{raw},k},
\]

\[
c_k=c_{k-1}+\delta c_{\perp,k}+g_{\parallel,k}\delta c_{\parallel,k}.
\]

```text
FINAL FORMULA: NOT FROZEN
STATE-CONSISTENT INFORMATION-FORM REALIZATION: NOT FORMALLY DEFINED
```

若故障方向与真实漂移方向可分，该候选能比 A 保留更多有效漂移更新，并且最直接对应 Phase 1B 的故障可吸收方向。

### 8.2 当前关键证据缺口

Case06 的真实漂移为 \(\Delta c_{\mathrm{drift}}=[+3,-2]^\mathsf{T}\ \mathrm{pF}\)，而 Case05/06 的故障诱导方向近似为 \(d_f\propto[+1,-1]^\mathsf{T}\)。两者余弦相似度为：

\[
\frac{[3,-2]\cdot[1,-1]}{\sqrt{13}\sqrt{2}}
=\frac{5}{\sqrt{26}}\approx0.981.
\]

当前代表性真实漂移与故障方向几乎共线。Phase 1B Case06 是“漂移结束后发生故障”，并未正式测试二者同时存在。即使在线方向估计正确，各向异性投影也无法只凭方向保留共线真实漂移。

此外，若只投影参数输出而不投影/加权 `J/h` 信息增量，仍存在隐藏吸收。如何在信息形式 RLS 中实现严格状态一致的各向异性更新，当前没有冻结定义。

因此，候选 C 具有最强机理吸引力，但目前只能作为 Backup；应先通过 Step 2 的非控制诊断确认方向稳定性、可观测性和与真实漂移的可分程度。

## 9. 候选动作筛选矩阵

| 候选动作 | 结论 | 原因 |
|---|---|---|
| 残差证据连续加权 | **保留，Primary** | 最小、在线可观测、与 M2/M3 端点兼容、可状态一致实现 |
| innovation 方向加权 | **保留为诊断** | 有机理价值，但故障方向尚未正式定义，易与漂移混淆 |
| 各向异性软投影 | **保留，Backup** | 最接近方向保护目标，但共线不可辨识和信息状态实现风险最大 |
| 修改 lambda 作为故障保护核心 | **拒绝** | lambda 已承担遗忘速度调节，混入故障分类会破坏 Phase 1B 归因 |
| 依赖 rate limit/projection 保护故障 | **拒绝为核心，保留安全层** | 正式条件中不是主导；限制幅度不等于识别来源 |
| 只把 M3 阈值改成 sigmoid | **拒绝为完整 M4** | 若 `J/h` 仍完整更新则隐藏吸收未解决，也没有方向诊断 |
| 多阈值、多状态机、多 hold 时间 | **拒绝 M4-v0** | 参数过多，容易针对 Case05/06 调参 |
| 固定 `[+1,-1]` 方向硬编码 | **拒绝** | 过拟合当前回归几何，缺少在线一般性 |

## 10. 四类工况下的预期行为

### 10.1 无漂移、无故障

- `E_in/baseIn` 接近背景，候选 A 的 `g` 应接近 1，M4 退化到 M2；
- 微小更新下的方向诊断不得触发控制；
- 不应增加稳态偏差或参数抖动。

### 10.2 仅真实 Cs 漂移

- 若漂移主要体现为 `E_quad` 或局部参数变化，而 `E_in` 未异常增强，A 应保持较高 `g`；
- B/C 必须验证漂移方向是否会被误判；
- `lambda` 继续负责跟踪速度，M4 不替代其作用；
- 若参考误差使漂移同时引起高 `E_in`，M4 可能过度保护，该失败工况必须保留。

### 10.3 仅阻性故障

- `E_in` 相对 `baseIn` 增强且相对 `E_quad` 占优时，A 连续降低信息更新；
- 原始与实际更新之差应可量化为“被保护的更新”；
- `g_min>0` 允许少量残余吸收，需评价保持与恢复速度折中；
- B/C 的方向量只在能量和条件数充分时有解释意义。

### 10.4 真实 Cs 漂移与阻性故障同时存在

- A 只能统一降权，能保留部分跟踪，但不能区分共线贡献；
- C 只在贡献方向可分时有优势；若共线，真实漂移必然一起被压制；
- 当前证据不能证明该工况可由单周期 `X/y/E` 唯一分解；
- Step 2 必须保留此诊断性反例，即使结果不利。

## 11. 候选比较

| 维度 | A 残差连续加权 | B 方向一致性加权 | C 各向异性软投影 |
|---|---|---|---|
| 现有在线量可实现性 | 高 | 中 | 中低 |
| 与 Phase 1B 机理对应 | 中高 | 高 | 最高 |
| 状态一致实现难度 | 低至中 | 中 | 高 |
| 新参数数量 | 最少 | 中 | 中至多 |
| 可解释性 | 高 | 中高 | 高，但依赖方向有效性 |
| 参考误差敏感性 | 中高 | 高 | 高 |
| 同时漂移+故障潜力 | 折中保留 | 未知 | 仅在方向可分时最好 |
| 共线漂移风险 | 统一变慢 | 误判 | 直接压制真实漂移 |
| 过拟合 Case05/06 风险 | 低至中 | 高 | 高 |
| 适合作为 M4-v0 | **是** | 否，先诊断 | 否，作为 Backup |

## 12. 推荐架构

### 12.1 Primary：A — 状态一致的残差证据连续加权

推荐 M4-v0 暂定名：

> **Residual-Evidence Weighted Information Update（残差证据加权的信息状态更新）**

选择理由：

1. 直接消除 M3 二值冻结，并保留故障期间非零跟踪；
2. `E_in/E_quad/baseIn` 已在现有代码中定义和验证；
3. 可用信息状态插值保证 `g=1` 与 M2、`g=0` 与保持端点一致；
4. 不假装已解决当前证据尚不支持的方向可辨识问题；
5. 新参数少，容易做因果归因和失败分析；
6. 可同时记录方向诊断，为是否升级到 C 提供正式数据。

该选择基于证据成熟度和实现可证性，不预设 A 的最终性能一定优于 C。

### 12.2 Backup：C — 各向异性软投影

候选 C 只有在 Step 2 诊断满足以下条件后才允许进入后续实现：

- 在线故障可疑方向在 Case05/06 和相位误差条件下稳定；
- 方向不依赖真值或 counterfactual；
- 正常漂移与故障方向在目标工况中具有足够可分性；
- 能给出 `J/h` 的状态一致各向异性更新；
- 对低能量、病态 `R` 和方向翻转有明确降级策略。

候选 B 不单独实现，作为 C 的诊断组件。

## 13. Primary M4 数学骨架

以下仅为 Step 2 架构候选，不是最终公式。

### 13.1 残差证据与权重

\[
r_{b,k}=\frac{E_{\mathrm{in},k}}{\mathrm{baseIn}_{k-1}+\epsilon},
\qquad
r_{q,k}=\frac{E_{\mathrm{in},k}}{E_{\mathrm{quad},k}+\epsilon}.
\]

故障证据应对 `r_b` 和“同相相对正交占优”单调不减，在背景附近连续，不使用 Case05 故障因子或真值幅值，并可由日志重算。

可选骨架：

\[
s_{E,k}=\mathcal{S}(r_{b,k},r_{q,k}),
\]

\[
g_k=g_{\min}+(1-g_{\min})
\left[1-\sigma\!\left(\frac{s_{E,k}-1}{\kappa_E}\right)\right].
\]

其中 \(\sigma\) 可为平滑饱和函数；`1` 仅表示证据归一化后的参考中心，不表示阈值已冻结。

### 13.2 信息状态更新

\[
J_k^{*}=\lambda_kJ_{k-1}+R_k,
\qquad h_k^{*}=\lambda_kh_{k-1}+z_k,
\]

\[
J_k=J_{k-1}+g_k(J_k^{*}-J_{k-1}),
\qquad
h_k=h_{k-1}+g_k(h_k^{*}-h_{k-1}),
\]

\[
c_{k,\mathrm{raw}}=(J_k+10^{-10}I)^{-1}h_k.
\]

之后保持原 M2 顺序：

```text
raw candidate
→ existing rate limit
→ existing [0, 40] pF projection
→ c_k
```

### 13.3 `baseIn` 更新原则

`baseIn` 不能在强故障证据下快速追随 `E_in`，否则保护会自行解除。Step 2 至少比较以下不增加新参数的原则：沿用现有 `E_in < 1.08*baseIn` 条件；当 `g` 明显低于 1 时保持 `baseIn`；只使用历史和当前信息。

```text
BASELINE UPDATE LOGIC: NOT FROZEN
```

### 13.4 端点要求

- `g=1`：逐周期 `J/h/c/lambda/rate/projection` 与 M2 在数值容差内一致；
- `g=0`：`J/h/c` 保持，不得暗中更新；
- `0<g<1`：实际信息增量介于保持与 M2 端点之间，并可由日志重建；
- 保护解除后，不出现由隐藏 `J/h` 吸收造成的参数突跳。

```text
FINAL FORMULA: NOT FROZEN
```

## 14. 最少新增参数

Primary M4-v0 建议最多新增两个可调参数：

1. `m4_evidence_transition`（\(\kappa_E\)）  
   单位：无量纲。含义：从正常证据到强保护之间的连续过渡宽度。应依据正常背景分布或预先声明的工程容差设定，不得用 Case05/06 最终保持结果反向调优。

2. `m4_min_update_weight`（\(g_{\min}\)）  
   单位：无量纲，范围 `[0,1]`。含义：强故障证据下仍保留的最小信息更新比例，明确体现故障保持与同时漂移跟踪的折中。

`epsilon`、正则项 `1e-10` 和现有 `baseIn` 更新系数视为数值/既有结构量，不新增为调优自由度。M4-v0 不新增方向阈值、方向 hold、第二组 gate ratio 或额外 lambda 参数。

Backup C 若进入未来实现，才可能需要方向置信度阈值或平滑参数；Step 1 不给出数值。

## 15. 主要理论风险与失败模式

### 15.1 最大风险：漂移与故障方向不可辨识

最严重风险不是阈值选错，而是可辨识性：真实 Cs 漂移与故障可吸收投影可能共线。Case06 `[+3,-2]` 与 `[+1,-1]` 的余弦约 0.981，已给出直接警告。

二者同时出现且只观察 `X/y/残差/递归状态` 时，任何方向抑制都可能同时抑制真实漂移。M4 可以管理折中、降低吸收、输出置信度，但当前不能宣称无损分离。

### 15.2 其他失败模式

- **参考相位误差**：可提高正常 `E_in`、改变偏差和方向，导致长期误保护；
- **慢变或小幅故障**：可能不产生显著证据，却持续被参数吸收；
- **背景污染**：`baseIn` 若在故障期上升，保护会过早解除；若冻结过久，恢复期又可能误判；
- **病态回归/低能量**：方向余弦不可靠，必须带条件数、范数与有效标志；
- **多谐波聚合**：当前 `E_in/E_quad` 同时含基波与三次谐波，正常谐波变化可能驱动保护；
- **信息状态不一致**：只处理 `c` 而不处理 `J/h` 会造成延迟释放的隐藏偏差。

## 16. Step 2 实现与日志要求

### 16.1 实现隔离

Step 2 若获批准，应新建独立 M4 tracker 和独立结果目录；不修改 M2/M3 文件、不修改 Simulink、不改 Phase 1A/1B 正式结果；注册为独立算法项。

### 16.2 每周期必须记录

现有量：

```text
time_s
Cs1
Cs2
lambda
E_in
E_quad
base_in
rate_limit_active
projection_active
```

M4 新增最小量：

```text
evidence_ratio_base
evidence_ratio_quad
fault_evidence_score
update_weight
delta_c_local_1/2
delta_c_raw_1/2
delta_c_applied_1/2
delta_c_suppressed_1/2
J_increment_norm_raw
J_increment_norm_applied
h_increment_norm_raw
h_increment_norm_applied
m4_evidence_valid
```

方向只作诊断时还需记录：

```text
fault_direction_candidate_1/2
direction_candidate_valid
innovation_direction_cosine
delta_c_parallel_1/2
delta_c_perpendicular_1/2
R_condition_number
```

方向尚未定义或无效时应输出无效标志和 NaN，不得用零向量伪装有效。

### 16.3 Step 2 最小结构验证

1. `g≡1` 与 M2 周期级等价；
2. `g≡0` 与保持端点等价；
3. 固定 `g=0.5` 时信息增量可重建；
4. rate limit/projection 顺序与 M2 一致；
5. `baseIn` 不被强故障残差快速污染；
6. 所有决策量可从在线日志重算；
7. 删除真值 Cs、故障标签和 counterfactual 后仍可运行；
8. 方向诊断在低范数或病态 `R` 时正确标无效；
9. 同时漂移+故障工况必须保留，即使结果不利；
10. M2/M3 回归结果保持不变。

## 17. 本规格必须回答的问题

### Q1. M4 的直接设计目标是什么？

把 M3 的硬冻结改为连续、状态一致的故障保护，在故障证据增强时减少 M2 的参数吸收，同时尽可能保留真实 Cs 跟踪能力。

### Q2. 为什么不能只把 M3 判据换成 sigmoid？

若只缩放输出参数而 `J/h` 完整更新，内部仍吸收故障；单一平滑阈值也没有解决证据解释、端点等价和同时漂移问题。

### Q3. `E_in/E_quad/baseIn/lambda` 分别是什么？

`E_in/E_quad` 是三相残差在基波与三次谐波同相/正交基底上的拟合 RMS 聚合；`baseIn` 是有条件慢更新的同相残差背景；`lambda` 是由局部 LS 参数变化范数驱动的遗忘因子。它们都不是真实故障标签。

### Q4. 当前是否已有可直接用于方向控制的 innovation 向量？

没有。标量 innovation 已有，但局部参数创新向量、原始递归更新向量和在线故障方向均 `NOT FORMALLY DEFINED`，需要 Step 2 显式定义和记录。

### Q5. 三个候选中推荐哪个？

Primary 为 A：状态一致的残差证据连续加权。B 先作方向诊断；C 为条件性 Backup。

### Q6. 为什么不直接选择各向异性投影？

在线故障方向尚未验证，信息状态实现尚未定义，而且 Case06 漂移与故障方向余弦约 0.981，存在严重共线不可辨识风险。

### Q7. Primary 最少需要几个新参数？

最多两个：`m4_evidence_transition` 和 `m4_min_update_weight`。本步不赋数值、不调参。

### Q8. M4 如何保证不偷用真值？

控制律只允许当前/历史 `X/y/R/z`、`E_in/E_quad/baseIn`、`lambda/J/h/c` 及其因果派生量。真实 Cs、故障标签、`r_fault` 真值、未来数据和 counterfactual 只用于离线评价。

### Q9. 最大理论风险是什么？

真实漂移与故障诱导更新共线，仅凭当前观测无法无损分离。必须量化并报告该边界，不能通过调参隐藏。

### Q10. Step 2 最关键的成功判据是什么？

先证明状态更新正确、端点可复现、保护动作可从日志重建、没有真值泄漏，并用同时漂移+故障条件检验真实边界；不是立即宣称全面优于所有算法。

## 18. Step 1 验收结论

- Phase 1B 总报告及 Step 1–5 已读取；
- Phase 1A 基线、注册表及 M2/M3 真实实现已读取；
- `E_in/E_quad/baseIn/lambda` 的代码定义已澄清；
- 缺失方向量已标记为 `NOT FORMALLY DEFINED`；
- 已比较 3 个最小可解释候选并选择 Primary/Backup；
- 已给出未冻结数学骨架、两参数预算、四类工况、失败模式及 Step 2 日志/测试要求；
- 未运行实验，未实现 M4，未修改历史正式资产。

```text
STEP 1 STATUS:
PASS

RECOMMENDED M4 FOR STEP 2:
Candidate A — Residual-Evidence Weighted Information Update

FORMULA STATUS:
NOT FROZEN

PARAMETER STATUS:
NOT TUNED
```
