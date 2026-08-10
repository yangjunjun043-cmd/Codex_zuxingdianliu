# AGENTS.md — MOA 阻性电流专利仿真实验工程

## 1. 项目目标

本工程用于验证一个面向金属氧化物避雷器（MOA）在线监测的发明专利方案。

当前推荐的专利主线不是“普通 LMS 自适应电容补偿”，也不是“差分电场探头本身”，而是：

> **基于相间耦合电容在线辨识、物理约束自适应跟踪及故障解耦门控的 MOA 阻性电流提取方法。**

建议核心技术链：

1. 由非接触电场参考获得工频相位/谐波参考；
2. 建立三相 MOA 总泄漏电流中的自电容与相间耦合电容模型；
3. 重点在线辨识随环境、安装位置和邻相场变化的相间耦合参数，而不是只辨识单个“MOA 等效电容”；
4. 使用带物理投影约束、变化率限制和变遗忘因子的 RLS/CVFF-RLS 跟踪耦合参数；
5. 使用阻性异常与容性参数变化的方向特征构造故障冻结/解耦门控，防止真实阻性故障被自适应器吸收到电容参数中；
6. 从总泄漏电流中扣除估计的容性与耦合分量，得到阻性电流；
7. 输出结果置信度/有效性标志，遇到电压严重不平衡、参考异常或模型失配时不得继续输出“高精度”结论。

## 2. 已知专利风险，禁止回退到这些宽泛表述

已有公开/授权方案已经覆盖或接近以下内容，工程中不要把它们单独包装成创新点：

- 电场探头/场探头 + 避雷器泄漏电流用于阻性电流监测；
- 非接触差分电场探头 + 三相干扰补偿/自适应补偿；
- 自适应噪声抵消 ANC + LMS/变步长 LMS 在线更新避雷器等效电容；
- 普通 FFT/谐波分解 + 容性电流补偿；
- 单纯“无 PT”获取阻性电流。

因此，后续实现和报告应突出以下差异：

- **相间耦合参数（Cs1/Cs2，后续可扩展为耦合电容矩阵）的在线辨识**；
- **多相联合回归，而不是单个等效电容的 LMS 更新**；
- **投影约束 + 变化率约束 + 变遗忘因子**；
- **阻性故障冻结/解耦门控，防止故障被参数估计吞掉**；
- **模型有效性判定/置信度输出**；
- 若进一步扩展，优先考虑 **具有物理结构约束的三相耦合电容矩阵辨识**，不要只换一个自适应算法名字。

## 3. 当前工程文件与角色

主要文件：

- `AI6109_MOA_AutoComp7.slx`：当前基准 Simulink 模型；
- `patent_default_config.m`：统一配置；
- `simulate_moa_base.m`：运行 Simulink，当前只读取三相电压和“真实阻性电流”；
- `synthesize_dynamic_case.m`：当前在 MATLAB 脚本中人工合成动态耦合总泄漏电流；
- `reconstruct_refs_from_b.m`：由 B 相电压重构 A/B/C 基波和三次谐波参考；
- `coupling_regressor.m`：构造 Cs1/Cs2 三相联合回归；
- `initial_coupling_estimate.m`：初始耦合参数估计；
- `track_coupling_block_nlms.m`：对比算法；
- `track_coupling_cvff_rls.m`：当前核心算法；
- `extract_resistive_current.m`：容性分量扣除并提取阻性电流；
- `evaluate_case_metrics.m`：评价指标；
- `run_patent_dynamic_experiments.m`：动态工况与故障门控；
- `run_patent_robustness_sweep.m`：鲁棒性扫描；
- `run_all_patent_experiments.m`：一键运行入口。

## 4. 不允许破坏基线

### 4.1 不直接覆盖原模型

禁止直接修改并覆盖：

- `AI6109_MOA_AutoComp7.slx`

如需修改 Simulink 模型：

1. 复制为 `AI6109_MOA_AutoComp8.slx` 或更高版本；
2. 优先通过 MATLAB 脚本使用 `load_system`、`add_block`、`set_param`、`add_line` 等接口修改；
3. 不要手工解压、编辑 XML、重新压缩 `.slx`；
4. 每次模型结构变化都新增或更新 `scripts/build_or_patch_model.m`，保证改动可复现。

### 4.2 不删除现有结果

现有 `results/` 作为基线证据保留。

新实验写入：

- `results_v2/`
- 或按阶段使用 `results_phase1/`、`results_phase2/`。

禁止为了让图“更好看”而覆盖原始结果。

## 5. 当前已经发现的关键问题

### P0 — 最高优先级：当前动态实验并没有真正使用 Simulink 的总泄漏电流

`simulate_moa_base.m` 只读取：

- `uA/uB/uC`
- `iA_R_true/iB_R_true/iC_R_true`

虽然 `.slx` 中存在：

- `iA_total`
- `iB_total`
- `iC_total`

但当前专利实验没有使用它们。

动态 Cs1/Cs2、噪声和总电流是在 `synthesize_dynamic_case.m` 中用代数公式重新合成的。

这意味着当前结果属于“MATLAB 合成数据上的算法验证”，不能表述成“完整 Simulink 物理模型验证”。

### P0 — 最高优先级：电场传感器尚未建模

当前 `reconstruct_refs_from_b.m` 直接使用真实 `data.ub`，这相当于已经拿到了理想 B 相电压。

尚未包含：

- 电场探头比例系数；
- 邻相场耦合；
- 探头安装偏差；
- 频率相关幅频/相频响应；
- 50 Hz 与 150 Hz 不同相移；
- 传感器噪声、偏置和漂移；
- 前端滤波及采样延迟。

后续必须使用“传感器输出信号”重构参考，禁止继续用 `ub` 真值冒充传感器测量值。

### P0 — 最高优先级：单 B 相参考无法在一般三相不平衡下唯一重构 A/C 相真实电压

当前代码默认：

- A/B/C 基波严格相差 ±120°；
- 三次谐波三相使用同相参考；
- 由一个 B 相标量信号推导另外两相。

现有结果已经显示严重问题：

- 负序 1% 时，B 相阻性基波误差约 11.2%；
- 负序 3% 时，B 相误差约 35.0%；
- 负序 5% 时，B 相误差约 62.0%。

这不是简单“调 RLS 参数”能解决的问题，而是参考可观测性/模型假设问题。

处理策略三选一，优先级从高到低：

1. 保留单参考方案，但加入“不平衡/模型失效检测”，失效时冻结参数并标记结果无效；
2. 将专利保护范围明确限定在满足一定三相平衡度的工况；
3. 若确需覆盖强不平衡，增加额外独立电场信息，不得假装单 B 相能够恢复任意三相电压。

### P0 — 指标存在尾部样本错误

`track_coupling_block_nlms.m` 和 `track_coupling_cvff_rls.m` 只按完整工频周期更新 `hist`。

仿真最后不足一个完整块的样本仍保留初始 `c0`，导致：

- `Cs1_MaxErr_pF`
- `Cs2_MaxErr_pF`

可能被最后一个未更新样本错误放大。

现有结果中多个动态工况的 CVFF-RLS 最大误差与固定补偿完全相同，就是明显信号。

修复方式：循环结束后，将最后一次有效 `c` 填充到剩余尾部样本。

### P1 — 配置文件与 Simulink 参数不一致

`simulate_moa_base.m` 向模型传入了若干变量，但当前 `.slx` 并未实际引用其中部分变量，例如：

- `SNR_i`
- `hf_ratio`
- `pulse_ratio`
- `IR_rms`
- `R_moa`
- `Rs_src`

当前 MATLAB Function 中 MOA 非线性模型还硬编码：

- `Vref = 110e3/sqrt(3)`
- `Iref = 0.3e-3`
- `alpha = 6`

因此以后改变 `cfg.IR_rms` 等参数时，可能以为模型变化了，实际上没有变化。

必须将所有有效物理参数统一到 `cfg` / model workspace，删除或明确标注无效参数。

### P1 — 自电容被当成完全已知常量

当前：

- `C0 = 100 pF`
- `C_moa = 300 pF`
- `Cself = 400 pF`

而算法只在线估计 Cs1/Cs2。

这是合理的第一版简化，但必须做模型失配实验：

- Cself ±1%
- ±2%
- ±5%
- 温漂/慢漂移

因为自电容产生的容性电流远大于阻性电流，几 pF 的误差就可能显著影响阻性电流结果。

不要一开始就把 Cself 也完全自由在线估计，否则容易出现不可辨识和“把真实阻性变化吸收进电容”的问题。

推荐：

- 启动阶段校准 Cself；
- 在线阶段以慢速、强约束方式修正；
- 故障门控触发时冻结 Cself 和耦合参数更新。

### P1 — 现有谐波鲁棒性指标不充分

当前 `evaluate_case_metrics.m` 只评价阻性电流的 **基波 RMS 幅值误差**。

因此现有“三次谐波幅值鲁棒性很好”的图，只能说明“三次谐波变化时基波结果没有明显恶化”，不能证明：

- 阻性电流三次谐波提取准确；
- 总波形提取准确；
- 三次谐波相位准确。

必须新增：

- 基波幅值误差；
- 基波相位误差；
- 三次谐波幅值误差；
- 三次谐波相位误差；
- 总波形 NRMSE/RMSE；
- 峰值误差；
- 收敛时间；
- 参数稳态抖动；
- 故障增幅保持误差；
- 门控误触发率/漏触发率。

### P1 — 噪声实验只有单次随机实现

现有 SNR 结果并不单调，例如较低 SNR 有时反而误差更小。

原因之一是每个工况只看单个随机种子，随机误差与系统偏差混在一起。

必须改成 Monte Carlo：

- 每个噪声等级至少 30 个随机种子；
- 推荐 50 个；
- 输出 mean / std / median / P95；
- 图中使用均值 + 误差带或箱线图；
- 固定随机种子列表，保证可复现。

### P1 — MOA 本体模型过于理想

当前三相 MATLAB Function 都使用相同固定幂律：

`i = Iref * sign(v) * (abs(v)/Vref)^alpha`

需要增加模型失配：

- alpha = 4/5/6/7/8；
- 三相 alpha 不一致；
- Iref 不一致；
- 分段 V-I 曲线；
- 轻度老化、受潮、突变故障；
- 谐波背景下的非线性阻性波形。

不要只在与算法完全同源的理想模型上验证。

### P1 — 耦合模型过于简化

当前只有：

- A-B：Cs1
- B-C：Cs2

没有 A-C 相间耦合，也没有更一般的耦合矩阵失配。

下一阶段优先研究：

- 增加 CsAC；
- 或构造满足对称性/物理约束的三相耦合电容矩阵；
- 算法采用结构约束辨识，而不是无约束增加参数。

这也是更值得形成专利区别点的方向。

### P2 — 快速变化电容模型缺少 u*dC/dt 项

当前动态合成采用：

`iC = C(t) * du/dt`

只适合 C 在一个工频周期内近似不变的慢变化场景。

若研究机械移动、探头瞬时位移或非常快的环境变化，完整关系为：

`iC = C(t)*du/dt + u(t)*dC/dt`

要求：

- 慢漂移实验继续使用准静态模型；
- 另加 fast_change 场景，引入 `u*dC/dt`；
- 明确算法在哪个变化速率范围内有效。

## 6. 当前基线结果，修改前必须能复现

以下数值用于回归检查，不是最终专利指标。

CVFF-RLS 当前结果大致为：

- 固定耦合：B 相基波误差约 -0.030%；
- 缓慢漂移：B 相基波误差约 +0.325%；
- 平滑阶跃：B 相基波误差约 +0.144%；
- 随机波动：B 相基波误差约 -0.124%；
- 阻性故障+漂移：B 相基波误差约 -0.325%；
- 真实故障增幅 1.6 倍，CVFF-RLS 估计约 1.577 倍，保持误差约 -1.44%。

固定补偿在动态场景中明显更差：

- 缓慢漂移 B 相约 8.9%；
- 平滑阶跃 B 相约 14.1%；
- 故障+漂移 B 相约 6.75%。

这些结果说明“动态耦合在线跟踪”方向值得保留。

注意：修复尾部样本 bug 后，MaxErr 指标允许变化；FundErr 等主要指标不应无解释地大幅漂移。

## 7. 执行顺序 — 必须按阶段推进

### Phase 0 — 建立可复现基线

任务：

1. 检查 Git 工作区；
2. 不修改原始 `.slx`；
3. 运行当前 `run_all_patent_experiments`；
4. 将基线关键数值写入 `tests/baseline_expected.m` 或等效测试脚本；
5. 创建 `docs/experiment_audit.md`，记录 MATLAB 版本、工具箱、模型版本和基线结果。

通过条件：

- 一键运行成功；
- 基线结果与上述数值在合理容差内一致；
- 所有结果文件可重复生成。

### Phase 1 — 先修正确性，不改变专利算法结构

任务：

1. 修复 NLMS/RLS 尾部 `hist` 填充；
2. 清理无效 cfg 参数，统一模型参数来源；
3. 将 MATLAB Function 的 `Vref/Iref/alpha` 参数化；
4. 扩充评价指标；
5. 增加 Monte Carlo 噪声实验；
6. 将 README 重命名为正常的 `README.md`；
7. 增加自动化测试。

通过条件：

- 无尾部异常 MaxErr；
- 参数修改确实传递到模型；
- 同一随机种子结果完全可重复；
- 新指标输出完整。

### Phase 2 — 把动态耦合真正放进 Simulink

目标：不再依赖 `synthesize_dynamic_case.m` 直接“造总电流”作为主要证据。

任务：

1. 创建 `AI6109_MOA_AutoComp8.slx`；
2. 在 Simulink 中实现动态 Cs1/Cs2；
3. 优先使用受控电流源实现：
   - `iAB = Cs1(t)*(duA/dt-duB/dt)`
   - `iBC = Cs2(t)*(duB/dt-duC/dt)`
4. 可选增加快速变化项 `u*dC/dt`；
5. 从模型直接输出 `iA_total/iB_total/iC_total`；
6. `simulate_moa_base` / 新仿真入口读取真实总泄漏电流；
7. 保留旧合成方法作为单元测试/算法快速测试，不再作为最终专利主证据。

通过条件：

- 静态 Cs 时 Simulink 总电流与解析式一致；
- 动态 Cs 时参数真值与算法估计能直接对比；
- 改变 Cs 轨迹无需在后处理阶段重构总电流。

### Phase 3 — 建立真实的电场参考链路

任务：

1. 新增 `simulate_field_sensor.m` 或 Simulink 传感器子系统；
2. 输入真实三相电压，输出探头测量信号 `eB_meas`；
3. 至少包含：
   - 主相比例；
   - A/C 邻相耦合；
   - 增益漂移；
   - 50/150 Hz 独立相位误差；
   - 噪声；
   - DC offset；
4. `reconstruct_refs_from_b` 改为只允许使用 `eB_meas`，禁止读取 `data.ub` 真值；
5. 新增相位/谐波估计模块，可采用最小二乘、正交解调或 PLL，但要报告其误差；
6. 添加 reference_quality / valid flag。

通过条件：

- 代码路径中不存在“算法直接使用真实 ub”作为测量输入；
- 传感器误差可通过 cfg 扫描；
- 50 Hz 与 150 Hz 相位误差可分别配置。

### Phase 4 — 处理三相不平衡的科学边界

不要通过调参伪装解决不可观测问题。

任务：

1. 证明/验证单 B 相参考在负序存在时的误差；
2. 实现 residual-based validity gate；
3. 定义可接受不平衡区间；
4. 超出区间时：
   - 冻结 Cs 更新；
   - 输出 result_valid=false；
   - 保留最近可信结果或仅报告全电流；
5. 若要增加额外电场信息，作为独立分支实验，不覆盖单传感器基线。

通过条件：

- 严重不平衡时系统不会继续宣称高精度；
- 有明确的检测率、误报率和阈值敏感性分析。

### Phase 5 — 强化专利核心：相间耦合结构辨识

优先尝试：

1. 从 Cs1/Cs2 扩展至 CsAB/CsBC/CsAC；
2. 或扩展为具有对称性和非负约束的耦合电容矩阵；
3. 比较：
   - 固定补偿；
   - NLMS；
   - 普通 RLS；
   - RLS + 投影；
   - RLS + 变遗忘因子；
   - RLS + 投影 + VFF；
   - 完整 CVFF-RLS + 故障门控；
4. 做消融实验，不允许只展示最终算法。

重点证明：

- 跟踪速度；
- 稳态误差；
- 参数不发散；
- 故障发生时不把阻性变化误识别为电容变化；
- 环境变化时又能及时更新耦合参数。

### Phase 6 — 专利证据实验

至少覆盖：

- 固定耦合；
- 慢漂移；
- 平滑阶跃；
- 随机漂移；
- 阻性故障 + 耦合漂移；
- 自电容失配；
- 传感器增益误差；
- 50 Hz 相位误差；
- 150 Hz 相位误差；
- 0.5% / 2% / 5% / 8% / 10% 三次谐波；
- 负序不平衡；
- 20/30/40 dB SNR + 无噪声；
- 参数突变；
- 多种 MOA 非线性曲线；
- Monte Carlo 随机参数组合。

最终生成：

- `results_final/summary.xlsx`
- `results_final/figures/*.png`
- `docs/patent_evidence_matrix.md`
- `docs/final_experiment_report.md`

## 8. 专利证据矩阵必须包含

`docs/patent_evidence_matrix.md` 至少用表格回答：

| 拟保护技术特征 | 对应代码 | 对应实验 | 指标 | 是否通过 | 图/表文件 |
|---|---|---|---|---|---|
| 相间耦合在线辨识 | ... | ... | Cs MAE | ... | ... |
| 变遗忘因子 | ... | ... | 收敛时间 | ... | ... |
| 投影/变化率约束 | ... | ... | 发散率/越界率 | ... | ... |
| 故障冻结门控 | ... | ... | 故障保持误差 | ... | ... |
| 模型有效性判定 | ... | ... | 检测率/误报率 | ... | ... |
| 电场参考链路 | ... | ... | 相位误差 | ... | ... |

禁止只写“效果更好”，必须有定量数据。

## 9. 编码规则

- 保持 MATLAB 代码简单、可读；
- 一个函数做一件事；
- 不要把所有逻辑塞进单个超长脚本；
- 所有重要阈值必须进入 cfg，不允许散落 magic number；
- 每个 cfg 参数写中文注释、单位和物理含义；
- 随机实验必须显式记录 seed；
- 保存结果时同时保存 cfg；
- 图、表名称要包含场景和算法；
- 不允许只为了“跑出漂亮结果”修改真值或评价窗口；
- 修改评价窗口必须解释原因并在报告中记录；
- 不得删除失败工况，失败结果也要保留。

## 10. MATLAB / Simulink 执行规则

优先使用命令行批处理，以便 Codex 自动回归：

```bash
matlab -batch "run_all_patent_experiments"
```

新阶段建议提供独立入口，例如：

```bash
matlab -batch "run_phase1_validation"
matlab -batch "run_phase2_simulink_dynamic"
matlab -batch "run_phase3_field_reference"
matlab -batch "run_final_patent_experiments"
```

每次执行后：

1. 检查 MATLAB 是否有 error；
2. 检查结果文件是否生成；
3. 自动读取关键 CSV/表格做回归判断；
4. 再进入下一阶段。

不要在一个 Codex 任务中同时重写模型、算法、指标和绘图，必须分阶段提交。

## 11. Git 提交建议

建议每个阶段独立提交：

- `baseline: reproduce current patent experiments`
- `fix: correct tracker tail history and metrics`
- `refactor: unify simulation parameters`
- `model: add dynamic coupling currents in simulink`
- `model: add electric-field sensor measurement chain`
- `algo: add reference validity gate`
- `algo: extend constrained coupling identification`
- `test: add monte carlo and model mismatch sweeps`
- `docs: generate patent evidence matrix`

不要把数十个不相关修改混成一次提交。

## 12. Codex 每轮任务的输出格式

每轮完成后必须汇报：

1. 修改了哪些文件；
2. 为什么修改；
3. 运行了哪些 MATLAB 命令；
4. 哪些实验通过/失败；
5. 关键数值变化；
6. 是否影响原基线；
7. 下一步建议；
8. 若有未解决问题，明确列出，不允许静默跳过。

## 13. 第一轮任务 — 现在立即执行

只做 Phase 0 + Phase 1，不进入模型大改。

具体任务：

1. 运行现有一键实验并记录基线；
2. 修复 NLMS/CVFF-RLS 尾部 `hist` 未填充问题；
3. 检查 `patent_default_config.m` 中传给 Simulink 但未使用的参数；
4. 将三个 MATLAB Function 中硬编码的 `Vref/Iref/alpha` 参数化；
5. 保证修改 `cfg` 后模型参数真实变化；
6. 扩展 `evaluate_case_metrics.m`：加入基波相位、三次谐波幅值/相位、波形 RMSE；
7. 将 SNR 实验改成至少 30 seeds 的 Monte Carlo；
8. 新增自动回归脚本；
9. 不修改 `AI6109_MOA_AutoComp7.slx` 原文件，若确实要改模型则复制为 AutoComp8；
10. 生成 `docs/phase1_report.md`，包含修改前后对比。

第一轮结束后停止，不自动继续 Phase 2。等待人工检查 Phase 1 结果后再继续。
