# 2.1 三相 MOA 泄漏电流及相间耦合模型

设 \(u_p(t)\) 和 \(i_p(t)\) 分别为第 \(p\) 相金属氧化物避雷器（metal oxide arrester，MOA）两端电压和测量泄漏电流，其中 \(p\in\{A,B,C\}\)。在本文采用的观测模型中，单相测量泄漏电流由阻性电流、自身电容电流、相间耦合电流和加性测量噪声组成，即

$$
i_p(t)=i_{R,p}(t)+i_{C,p}(t)+i_{\mathrm{coupling},p}(t)+n_p(t),
\tag{1}
$$

式中，\(i_{R,p}(t)\) 为 MOA 非线性电阻支路产生的阻性泄漏电流，\(i_{C,p}(t)\) 为自身电容电流，\(i_{\mathrm{coupling},p}(t)\) 为相邻相之间的等效电容耦合电流，\(n_p(t)\) 为电流测量通道中的加性噪声。该分解是后续从总泄漏电流中扣除容性分量并提取阻性分量的物理基础。[需文献支持]

以 \(C_{\mathrm{self},p}\) 表示第 \(p\) 相 MOA 本体等效电容与对地杂散电容之和。在当前模型中，\(C_{\mathrm{self},p}\) 在分析时段内保持不变，其产生的自身电容电流为

$$
\begin{aligned}
i_{C,A}(t)&=C_{\mathrm{self},A}\frac{\mathrm{d}u_A(t)}{\mathrm{d}t},\\
i_{C,B}(t)&=C_{\mathrm{self},B}\frac{\mathrm{d}u_B(t)}{\mathrm{d}t},\\
i_{C,C}(t)&=C_{\mathrm{self},C}\frac{\mathrm{d}u_C(t)}{\mathrm{d}t}.
\end{aligned}
\tag{2}
$$

为与各相物理含义相对应，式（2）保留了分相下标；冻结模型的具体实现采用三相相同的已知参数，即 \(C_{\mathrm{self},A}=C_{\mathrm{self},B}=C_{\mathrm{self},C}=C_{\mathrm{self}}\)，标称值为 \(400\ \mathrm{pF}\)。该值由 \(100\ \mathrm{pF}\) 对地杂散电容与 \(300\ \mathrm{pF}\) MOA 本体等效电容相加得到。本文物理公式中的电容单位均为 F；项目代码以 pF 存储相关参数时，通过乘以 \(10^{-12}\) 完成单位换算。

当前冻结拓扑仅考虑 A、B 相之间和 B、C 相之间的相邻相耦合。令 \(C_{s1}(t)\) 表示 AB 相间等效耦合电容，\(C_{s2}(t)\) 表示 BC 相间等效耦合电容，并按正式代码规定的电流正方向定义各相耦合分量：

$$
\begin{aligned}
i_{AB,A}(t)&=C_{s1}(t)\left[\frac{\mathrm{d}u_A(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}\right],\\
i_{AB,B}(t)&=C_{s1}(t)\left[\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_A(t)}{\mathrm{d}t}\right],\\
i_{BC,B}(t)&=C_{s2}(t)\left[\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_C(t)}{\mathrm{d}t}\right],\\
i_{BC,C}(t)&=C_{s2}(t)\left[\frac{\mathrm{d}u_C(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}\right].
\end{aligned}
\tag{3}
$$

式（3）中，同一耦合支路在其连接的两相上形成方向相反的电流分量。A 相只与 AB 支路相连，C 相只与 BC 支路相连；B 相同时位于两条耦合支路的端点，因此其测量电流同时包含 \(C_{s1}\) 和 \(C_{s2}\) 对应的差分电压导数项。由式（1）—式（3），三相测量泄漏电流写为

$$
\begin{aligned}
i_A(t)={}&i_{R,A}(t)
+C_{\mathrm{self},A}\frac{\mathrm{d}u_A(t)}{\mathrm{d}t}
+C_{s1}(t)\left[\frac{\mathrm{d}u_A(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}\right]
+n_A(t),\\
i_B(t)={}&i_{R,B}(t)
+C_{\mathrm{self},B}\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}
+C_{s1}(t)\left[\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_A(t)}{\mathrm{d}t}\right]
+C_{s2}(t)\left[\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_C(t)}{\mathrm{d}t}\right]
+n_B(t),\\
i_C(t)={}&i_{R,C}(t)
+C_{\mathrm{self},C}\frac{\mathrm{d}u_C(t)}{\mathrm{d}t}
+C_{s2}(t)\left[\frac{\mathrm{d}u_C(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}\right]
+n_C(t).
\end{aligned}
\tag{4}
$$

式（4）采用准静态电容关系。其含义是，\(C_{s1}(t)\) 和 \(C_{s2}(t)\) 相对于工频周期缓慢变化，耦合电流按 \(C_s(t)\,\mathrm{d}(u_p-u_q)/\mathrm{d}t\) 计算；当前模型未计入快速电容变化时可能出现的 \((u_p-u_q)\,\mathrm{d}C_s/\mathrm{d}t\) 项。因此，本文后续结论限定于该准静态 AB/BC 两参数模型，不将式（4）扩展解释为一般三相完整电容耦合矩阵。

依据式（4），若采用 \(\widehat C_{s1}(t)\) 和 \(\widehat C_{s2}(t)\) 补偿 B 相耦合电流，则阻性电流的提取结果可表示为

$$
\begin{aligned}
\widehat i_{R,B}(t)={}&i_B(t)
-C_{\mathrm{self},B}\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}\\
&-\widehat C_{s1}(t)\left[\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_A(t)}{\mathrm{d}t}\right]
-\widehat C_{s2}(t)\left[\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_C(t)}{\mathrm{d}t}\right].
\end{aligned}
\tag{5}
$$

在自身电容参数准确的条件下，式（5）与真实阻性电流之间的差为

$$
\begin{aligned}
\widehat i_{R,B}(t)-i_{R,B}(t)={}&
\left[C_{s1}(t)-\widehat C_{s1}(t)\right]
\left[\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_A(t)}{\mathrm{d}t}\right]\\
&+\left[C_{s2}(t)-\widehat C_{s2}(t)\right]
\left[\frac{\mathrm{d}u_B(t)}{\mathrm{d}t}-\frac{\mathrm{d}u_C(t)}{\mathrm{d}t}\right]
+n_B(t).
\end{aligned}
\tag{6}
$$

式（6）表明，当实际相间耦合参数发生变化而补偿参数仍保持初始值时，参数失配会以差分电压导数为权重残留在阻性电流提取结果中；B 相误差还会叠加两条耦合支路的失配贡献。安装几何、电场边界及环境状态变化可能引起等效相间耦合参数偏移或缓慢漂移。[需文献支持] 因而，仅采用固定 \(C_{s1}\) 和 \(C_{s2}\) 难以持续保持耦合补偿与实际状态一致，后续需要根据三相观测对这两个参数进行在线辨识。

需要强调的是，当前在线辨识参数集合仅包含 \(C_{s1}\) 和 \(C_{s2}\)。\(C_{\mathrm{self},p}\) 在正式算法中作为已知模型参数参与容性电流扣除，AC 相间耦合电容未进入当前模型，也未进入在线辨识参数集合。上述三相方程由此构成两个耦合参数的共同观测基础，下一节将在保持式（3）符号方向不变的前提下，将其整理为三相联合回归模型。

## 人工审核清单

### 公式与代码对应关系

- 式（1）的总电流分解对应 `MATLAB一键实验/scripts/build_phase2_model.m` 第 93—97 行；其中阻性电流、三类容性项和加性噪声在三相总电流表达式中相加。
- 式（2）的自身电容项对应 `MATLAB一键实验/scripts/build_phase2_model.m` 第 94—97 行，以及 `MATLAB一键实验/coupling_regressor.m` 第 11—13 行的已知自身电容扣除；\(C_{\mathrm{self}}=400\ \mathrm{pF}\) 的配置来源为 `MATLAB一键实验/patent_default_config.m` 第 11—13 行。
- 式（3）的 AB/BC 耦合方向对应 `MATLAB一键实验/coupling_regressor.m` 第 7—10 行；同一方向也见 `MATLAB一键实验/scripts/build_phase2_model.m` 第 95—97 行和 `MATLAB一键实验/extract_resistive_current.m` 第 4—6 行。
- 式（4）的三相完整表达式对应 `MATLAB一键实验/scripts/build_phase2_model.m` 第 93—97 行；历史解析构造中的同式实现位于 `MATLAB一键实验/synthesize_dynamic_case.m` 第 47—54 行。
- 式（5）对应 `MATLAB一键实验/extract_resistive_current.m` 第 4—7 行，其中先计算自身及耦合电容电流，再由总电流扣除。
- 式（6）由式（4）和式（5）直接相减得到；其耦合误差方向与 `MATLAB一键实验/coupling_regressor.m` 第 8—9 行的 B 相两列回归量一致。

### 当前存在的不确定点

- 正文使用分相符号 \(C_{\mathrm{self},A}\)、\(C_{\mathrm{self},B}\)、\(C_{\mathrm{self},C}\) 以保持物理定义清楚；冻结 AutoComp9 实现实际使用一个公共参数 `Cself_pF`，三相取相同标称值。终稿表格需继续区分“分相一般记号”和“冻结实现中的相等约束”。
- `patent_default_config.m` 第 5 行仍将默认模型字段初始化为 AutoComp8，而 Phase 1A 正式运行入口会将其覆盖为冻结的 AutoComp9。该差异不改变本节方程，但终稿应以 AutoComp9 为正式模型来源。
- 当前准静态模型未包含 \((u_p-u_q)\,\mathrm{d}C_s/\mathrm{d}t\) 项，尚不能据此讨论快速机械位移或快速电容突变。
- 式（1）中的 \(n_p(t)\) 按正式模型限定为加性电流噪声；参考电压误差、未建模耦合和其他模型失配不在本符号中合并处理。

### 需要外部文献支持的句子

- “该分解是后续从总泄漏电流中扣除容性分量并提取阻性分量的物理基础。”
- “安装几何、电场边界及环境状态变化可能引起等效相间耦合参数偏移或缓慢漂移。”

### 属于模型假设而非一般事实的内容

- 仅保留 AB、BC 两条相邻相耦合支路，不建立 AC 支路或一般三相耦合电容矩阵。
- \(C_{\mathrm{self}}\) 在在线阶段已知且不随时间变化，冻结实现中三相取相同的 \(400\ \mathrm{pF}\)。
- \(C_{s1}(t)\) 和 \(C_{s2}(t)\) 满足准静态变化条件，忽略电压乘以电容变化率的附加电流项。
- 测量噪声以加性电流项进入三相观测。
- 当前在线辨识参数只有 \(C_{s1}\) 和 \(C_{s2}\)，未辨识 \(C_{\mathrm{self}}\) 或 AC 耦合参数。

### 与正式回归代码的一致性结论

- 未发现正文与 `coupling_regressor.m` 的符号方向不一致。A 相使用 \(\mathrm{d}u_A/\mathrm{d}t-\mathrm{d}u_B/\mathrm{d}t\)，B 相依次使用 \(\mathrm{d}u_B/\mathrm{d}t-\mathrm{d}u_A/\mathrm{d}t\) 和 \(\mathrm{d}u_B/\mathrm{d}t-\mathrm{d}u_C/\mathrm{d}t\)，C 相使用 \(\mathrm{d}u_C/\mathrm{d}t-\mathrm{d}u_B/\mathrm{d}t\)。
- `coupling_regressor.m` 以两列矩阵表示 \(C_{s1}\) 和 \(C_{s2}\)，并在构造观测量时扣除已知自身电容项；正文采用相同的两参数边界。
