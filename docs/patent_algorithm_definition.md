# 相间耦合辨识与故障门控算法定义（现有代码版）

本文只整理当前 Phase 2 代码已经实现的算法，不增加新判据、传感器模型或参数。对应实现为：

- `coupling_regressor.m`
- `initial_coupling_estimate.m`
- `track_coupling_cvff_rls.m`
- `extract_resistive_current.m`
- `reconstruct_refs_from_b.m`
- `patent_default_config.m`

## 1. 输入量与输出量

输入量为采样时间 `t`、三相总泄漏电流 `ia/ib/ic`、B相电压 `ub`、三相自电容估计值 `self_pF=[Cself,A,Cself,B,Cself,C]`，以及频率、初始化窗口、遗忘因子、投影、变化率和门控参数。当前参考重构从理想 B 相电压提取基波和三次谐波，再按平衡三相假设形成 `dua/dub/duc`；本阶段没有电场传感器模型。

输出量包括逐样本相间耦合估计历史

\[
\hat{\boldsymbol c}(k)=[\hat C_{s1}(k),\hat C_{s2}(k)]^\mathsf T,
\]

逐工频周期的 `lambda`、阻性同相残差 `E_in`、正交残差 `E_quad`、门控标志 `gate`、基准残差 `base_in`，以及提取的三相阻性电流 `ir.A/ir.B/ir.C`。

## 2. 相间耦合与总泄漏电流模型

代码采用准静态电容关系 `i=C(t)du/dt`。令 `Cs1` 为 A-B 相间耦合电容，`Cs2` 为 B-C 相间耦合电容，则：

\[
\begin{aligned}
i_{A,\mathrm{coupling}}&=C_{s1}(\dot u_A-\dot u_B),\\
i_{B,\mathrm{coupling}}&=C_{s1}(\dot u_B-\dot u_A)+C_{s2}(\dot u_B-\dot u_C),\\
i_{C,\mathrm{coupling}}&=C_{s2}(\dot u_C-\dot u_B).
\end{aligned}
\]

总泄漏电流为：

\[
\begin{aligned}
i_A&=i_{A,R}+C_{\mathrm{self},A}\dot u_A+i_{A,\mathrm{coupling}},\\
i_B&=i_{B,R}+C_{\mathrm{self},B}\dot u_B+i_{B,\mathrm{coupling}},\\
i_C&=i_{C,R}+C_{\mathrm{self},C}\dot u_C+i_{C,\mathrm{coupling}}.
\end{aligned}
\]

`Cs1/Cs2` 在回归中以 pF 为数值单位，因此回归矩阵中显式乘以 `1e-12`。

## 3. Cs1/Cs2 三相联合回归

对一个包含 `n` 个样本的工频周期，先扣除已知自电容电流：

\[
\boldsymbol y=
\begin{bmatrix}
 i_A-C_{\mathrm{self},A}\dot u_A\\
 i_B-C_{\mathrm{self},B}\dot u_B\\
 i_C-C_{\mathrm{self},C}\dot u_C
\end{bmatrix}_{3n\times1}.
\]

令 `q=10^-12`，联合回归矩阵为：

\[
\boldsymbol X=q
\begin{bmatrix}
\dot u_A-\dot u_B & 0\\
\dot u_B-\dot u_A & \dot u_B-\dot u_C\\
0 & \dot u_C-\dot u_B
\end{bmatrix}_{3n\times2},
\qquad
\boldsymbol y=\boldsymbol X\boldsymbol c+\boldsymbol e.
\]

初始化窗口为 `0.10 s <= t < 0.70 s`，初值为：

\[
\boldsymbol c_0=(\boldsymbol X_0^\mathsf T\boldsymbol X_0+10^{-10}\boldsymbol I)^{-1}
\boldsymbol X_0^\mathsf T\boldsymbol y_0.
\]

## 4. 当前 CVFF-RLS 更新公式

算法以一个工频周期为更新块。采样率由 `1/median(diff(t))` 计算，每周期样本数为 `round(fs/f)`。初始化：

\[
\boldsymbol J_0=0.05\boldsymbol X_0^\mathsf T\boldsymbol X_0+10^{-8}\boldsymbol I,
\qquad
\boldsymbol h_0=\boldsymbol J_0\boldsymbol c_0.
\]

第 `m` 个周期：

\[
\boldsymbol R_m=\boldsymbol X_m^\mathsf T\boldsymbol X_m,
\qquad
\boldsymbol z_m=\boldsymbol X_m^\mathsf T\boldsymbol y_m.
\]

在未门控时执行信息形式的带遗忘更新：

\[
\boldsymbol J_m=\lambda_m\boldsymbol J_{m-1}+\boldsymbol R_m,
\qquad
\boldsymbol h_m=\lambda_m\boldsymbol h_{m-1}+\boldsymbol z_m,
\]

\[
\boldsymbol c_m^*=(\boldsymbol J_m+10^{-10}\boldsymbol I)^{-1}\boldsymbol h_m.
\]

随后依次执行变化率限制和物理投影。对每个参数：

\[
\Delta c_i=\operatorname{clip}(c_{m,i}^*-c_{m-1,i},-1.2,1.2)\ \mathrm{pF/cycle},
\]

\[
c_{m,i}=\operatorname{clip}(c_{m-1,i}+\Delta c_i,0,40)\ \mathrm{pF}.
\]

这里的“物理约束”是两个参数分别进行的非负区间投影；当前代码没有耦合矩阵对称性等额外约束。

## 5. 变遗忘因子逻辑

每周期先计算无约束局部最小二乘估计：

\[
\boldsymbol c_{\mathrm{LS},m}=(\boldsymbol R_m+10^{-10}\boldsymbol I)^{-1}\boldsymbol z_m.
\]

代码定义归一化创新量：

\[
\eta_m=\left\|\frac{\boldsymbol c_{\mathrm{LS},m}-\boldsymbol c_{m-1}}
{[5,5]^\mathsf T}\right\|_2.
\]

遗忘因子为：

\[
\lambda_m=\lambda_{\max}-(\lambda_{\max}-\lambda_{\min})
\operatorname{clip}\left(\frac{\eta_m}{0.20},0,1\right),
\]

当前 `lambda_min=0.55`、`lambda_max=0.995`。创新较小时接近 `0.995`，创新达到或超过 `0.20` 时取 `0.55`。`5 pF` 和 `0.20` 当前为函数内硬编码值。

## 6. 故障残差、判据与门控状态

按当前参数估计计算周期残差：

\[
\boldsymbol e_m=\boldsymbol y_m-\boldsymbol X_m\boldsymbol c_{m-1}.
\]

对 A/B/C 三相分别拟合同相基波、同相三次谐波、正交基波、正交三次谐波和直流项。相位偏移为 A 相 `+2π/3`、B 相 `0`、C 相 `-2π/3`；三次谐波三相使用同相参考。每相得到同相重构残差 RMS `E_in,p` 和正交重构残差 RMS `E_quad,p`，再按三相均方根合成：

\[
E_{\mathrm{in}}=\sqrt{\frac{1}{3}\sum_p E_{\mathrm{in},p}^2},
\qquad
E_{\mathrm{quad}}=\sqrt{\frac{1}{3}\sum_p E_{\mathrm{quad},p}^2}.
\]

第一次进入在线周期时，以该周期 `E_in` 初始化 `baseIn`。仅当门控功能开启、周期末时间大于 `1.0 s`，且同时满足下列条件时判为故障：

\[
E_{\mathrm{in}}>1.12\,\mathrm{baseIn},
\qquad
E_{\mathrm{in}}>1.20\,E_{\mathrm{quad}}.
\]

触发后：

\[
\mathrm{gateHold}=\max(\mathrm{gateHold},25).
\]

只要 `gateHold>0`，本周期 `gate=1`，计数减一，并完全跳过 `J`、`h`、`c` 和 `baseIn` 更新。因此当前实现是“冻结 Cs 更新”，不是降低增益或仅限制更新。若故障判据连续成立，会反复把保持计数恢复到至少 25 周期，实际门控持续时间可长于 25 周期；本次消融工况中故障后累计门控 48 个周期。

恢复条件是：`gateHold` 已减至零，且当前周期没有重新触发故障。恢复后按正常 CVFF-RLS、变化率限制和投影逻辑更新。仅在非门控周期且

\[
E_{\mathrm{in}}<1.08\,\mathrm{baseIn}
\]

时更新基准：

\[
\mathrm{baseIn}\leftarrow0.985\,\mathrm{baseIn}+0.015E_{\mathrm{in}}.
\]

## 7. 阻性电流输出

使用逐样本保持的 `Cs1/Cs2` 估计扣除自电容和相间耦合电流：

\[
\begin{aligned}
\hat i_{A,R}&=i_A-C_{\mathrm{self},A}\dot u_A-hat C_{s1}(\dot u_A-\dot u_B),\\
\hat i_{B,R}&=i_B-C_{\mathrm{self},B}\dot u_B-hat C_{s1}(\dot u_B-\dot u_A)-\hat C_{s2}(\dot u_B-\dot u_C),\\
\hat i_{C,R}&=i_C-C_{\mathrm{self},C}\dot u_C-hat C_{s2}(\dot u_C-\dot u_B).
\end{aligned}
\]

## 8. 当前关键参数与建议保护表达

下表中的“建议保护范围”是按现有代码功能关系给出的权利要求表达边界，不是参数扫描得到的性能保证范围。

| 参数/逻辑 | 当前值 | 建议保护表达 |
|---|---:|---|
| 采样时间 | 20 μs | 能够覆盖目标工频及谐波的预设采样时间 |
| 工频 | 50 Hz | 待监测交流系统的基频 |
| 算法使用的自电容 | 三相均为 400 pF | 预先标定或预设的各相自电容 |
| 工频更新块 | 1 周期，50 Hz | 一个或多个工频周期的分块更新 |
| 初始化窗口 | 0.10–0.70 s | 预设正常运行初始化区间 |
| 指标窗口起点 | 0.80 s | 初始化结束后的预设评价区间；不属于在线更新公式 |
| `lambda_min` | 0.55 | `0 < lambda_min <= lambda_max <= 1` |
| `lambda_max` | 0.995 | 同上，创新增大时遗忘因子减小 |
| 创新参数尺度 | 每个 Cs 为 5 pF | 正的参数归一化尺度，可按装置耦合量级设定 |
| 创新饱和尺度 | 0.20 | 正阈值；达到阈值时取最小遗忘因子 |
| Cs 投影边界 | 0–40 pF | 非负且不超过预设物理上限 |
| 单周期变化率 | ±1.2 pF/cycle | 绝对变化量不超过预设正上限 |
| 故障相对门限 | 1.12×`baseIn` | 大于 1 的同相残差相对阈值 |
| 方向判别门限 | 1.20×`E_quad` | 大于 1 的同相/正交残差方向阈值 |
| 启用故障检测时间 | 周期末 `>1.0 s` | 初始化完成后的预设保护时间 |
| 门控保持 | 25 周期 | 至少一个周期的预设保持计数；持续触发可续期 |
| 基准更新条件 | `E_in<1.08 baseIn` | 仅在非故障、残差接近基准时慢速更新 |
| 基准平滑 | 0.985/0.015 | 旧基准与新残差的凸组合，权重和为 1 |

当前数值范围只在既有 Phase 2 工况中得到验证，不能据此宣称适用于负序、自电容失配、电场传感器误差或一般耦合矩阵。

## 9. 专利方法步骤 S1～S12

**S1**：采集同步的三相总泄漏电流 `iA/iB/iC`、B 相电压 `uB` 及采样时间。Simulink 数据中同时保存 `uA/uB/uC`，但当前算法的 `reconstruct_refs_from_b` 实际只读取理想 `uB` 并重构三相参考。

**S2**：在初始化窗口内对 B 相电压作基波、三次谐波最小二乘拟合，获得幅值与相位，并依据平衡三相关系形成 `uA/uB/uC` 及 `duA/dt、duB/dt、duC/dt` 参考。

**S3**：从三相总泄漏电流中扣除预设自电容电流，形成联合回归观测向量 `y`。

**S4**：依据 A-B 耦合和 B-C 耦合的电流方向构造三相联合回归矩阵 `X`，待辨识参数为 `Cs1/Cs2`。

**S5**：在初始化窗口计算 `Cs1/Cs2` 初值，并初始化信息矩阵 `J`、信息向量 `h` 和同相残差基准 `baseIn`。

**S6**：对每个工频周期计算 `R=X'X`、`z=X'y`、局部最小二乘参数以及归一化创新量，据此确定变遗忘因子。

**S7**：按当前参数计算三相残差，将残差分解为与阻性参考同相的分量和与容性参考正交的分量，得到 `E_in` 与 `E_quad`。

**S8（正常/耦合变化状态）**：当故障判据不成立且保持计数为零时，允许更新 `J/h` 和 `Cs1/Cs2`；对更新量执行单周期变化率限制，再将参数投影到物理范围。残差接近正常基准时慢速更新 `baseIn`。

**S9（阻性故障状态）**：当 `E_in` 同时超过相对基准阈值和相对正交残差方向阈值时，设置门控保持计数。

**S10**：门控有效期间冻结 `J/h/Cs1/Cs2/baseIn` 更新，使阻性突变不能通过耦合参数的虚假调整被吸收；持续满足故障判据时续期保持计数。

**S11**：保持计数归零且故障判据不再成立后，恢复正常 CVFF-RLS、变化率限制、物理投影和基准慢速更新。

**S12**：用逐样本保持的 `Cs1/Cs2` 估计计算并扣除自电容及相间耦合电流，输出三相阻性电流估计和参数/门控状态记录。
