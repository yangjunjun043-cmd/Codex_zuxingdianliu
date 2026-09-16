# 中文核心论文 Phase 1A 实现审计

审计日期：2026-09-16  
审计对象：`AI6109_MOA_AutoComp9.slx`、其 MATLAB 驱动链、M0/M2/M3 实现、六个目标 case 及既有结果。  
审计边界：本轮未启动 MATLAB/Simulink，未修改模型、算法、配置或历史结果；只进行了源文件、SLX 压缩包结构、CSV/MAT 生成语句、报告、Git 状态和文件元数据的只读核查。本文件是本轮唯一新增文件。

## 结论摘要

1. `AI6109_MOA_AutoComp9.slx` 当前由 `simulate_phase2_case.m` 直接调用；正式上层入口是 `run_phase2_simulink_dynamic.m` 和 `run_gating_ablation.m`。`scripts/build_phase2_model.m` 用于生成模型，不是实验入口。
2. M0、M2、M3 的底层数学实现均已存在，但尚无统一 `algorithm_mode`：
   - M0：初始化 LS 得到 `c0` 后整段冻结；
   - M2：`track_coupling_cvff_rls(..., false)`；
   - M3：`track_coupling_cvff_rls(..., true)`。
3. 当前 M2 不是“无约束裸 RLS”，而是保留 VFF、Cs 单周期变化率限制和 `[0,40] pF` 投影，仅关闭故障门控；M3 与 M2 的唯一算法开关差异是 `enableGate`。
4. `slow_drift` 与 `fault_with_drift`（即目标 `drift_then_fault`）已有可信 AutoComp9 历史证据，用户给出的全部关键数值均能精确对应现有 CSV。
5. 六个目标 case 尚未形成统一的 AutoComp9 × M0/M2/M3 结果集：Case03/04 仅有旧 MATLAB 合成链结果，Case05 完全缺失，Case01/02/06 的算法覆盖或输出 schema 不完整。
6. 可以建立纯调度型 `algorithm_mode={M0,M2,M3}`，无需修改现有数学公式、阈值或参数。关键是每个 case 只运行一次 AutoComp9，三种算法共享完全相同的 `data/ref/c0`。
7. Phase 1A 最小实现不需要修改 AutoComp9，也不需要修改 `track_coupling_cvff_rls.m`、`patent_default_config.m`、`initial_coupling_estimate.m` 或 `extract_resistive_current.m`。

## 1. 审计依据与版本状态

### 1.1 核心版本

| 对象 | 状态 |
|---|---|
| Git 分支 | `main`，跟踪 `origin/main` |
| 当前提交 | `622a1d3`（2026-08-17） |
| Phase 2 提交 | `6302c64`，tag=`phase2` |
| AutoComp9 SHA-256 | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| AutoComp9 工作区状态 | Git 未显示修改，当前模型与已提交版本一致 |

当前工作区已有的未提交内容包括 `run_gating_ablation.m`、`docs/gating_ablation_report.md`、AutoComp11 和新一代消融结果。本轮没有改动这些文件。当前 `run_gating_ablation.m` 的未提交版本比 Git 中版本保存了更完整的 M2/M3 时序证据，但移除了本次执行中的 M0 计算；旧版 `fault_retention.csv` 仍保留 M0 故障增幅。

### 1.2 证据等级

为避免把旧合成结果与 AutoComp9 结果混用，本报告采用以下区分：

| 等级 | 含义 |
|---|---|
| A | AutoComp9 直接输出 `iA/iB/iC_total`，可作为 Phase 1A 正式数值证据 |
| B | AutoComp8 提供电压/阻性真值，再由 `synthesize_dynamic_case.m` 在 MATLAB 中合成总电流；可复用场景定义和回归参考，但不应冒充 AutoComp9 结果 |
| C | 报告、图或汇总表；可用于交叉核对，但应追溯到 A/B 类源代码和数据 |

## 2. AutoComp9 当前由哪些脚本驱动

### 2.1 直接运行链

```text
run_phase2_simulink_dynamic.m
  -> patent_default_config.m
  -> cfg.model = 'AI6109_MOA_AutoComp9'
  -> simulate_phase2_case.m
       -> generate_coupling_signals.m
       -> Simulink.SimulationInput(cfg.model)
       -> AI6109_MOA_AutoComp9.slx
  -> reconstruct_refs_from_b.m
  -> initial_coupling_estimate.m
  -> M0 / M3
  -> extract_resistive_current.m
  -> evaluate_case_metrics.m
```

```text
run_gating_ablation.m
  -> patent_default_config.m
  -> cfg.model = 'AI6109_MOA_AutoComp9'
  -> simulate_phase2_case.m（同一个 fault_with_drift 数据集）
  -> reconstruct_refs_from_b.m
  -> M2（enableGate=false）/ M3（enableGate=true）
  -> extract_resistive_current.m
  -> 故障前后参数变化、故障增幅、RMSE、门控周期
```

### 2.2 与 AutoComp9 有关但不是当前正式实验入口的脚本

| 文件 | 与 AutoComp9 的关系 | 是否直接驱动 AutoComp9 实验 |
|---|---|---|
| `scripts/build_phase2_model.m` | 从 AutoComp8 复制并构建 AutoComp9，加入 6 路根输入和 `DynamicLeakageCurrentModel` | 否，构建脚本 |
| `scripts/build_model_layout_auto_comp10.m` | 以 AutoComp9 为源生成只整理布局的 AutoComp10 | 否，消费 AutoComp9 作为源模型 |
| `validate_auto_comp10_layout.m` | 用 AutoComp9 历史 CSV 作为 before 基准，实际复跑对象是 AutoComp10 | 否 |
| `run_main.m` | 当前实际选择 AutoComp11，注释却写 AutoComp10 | 否，与 AutoComp9 Phase 1A 无关 |
| `patent_default_config.m` | 默认模型仍为 AutoComp8；Phase 2 两个入口显式覆盖为 AutoComp9 | 间接配置源 |

### 2.3 AutoComp9 已确认的接口和方程

SLX 压缩包 XML、构建脚本和运行脚本三者一致，根级外部输入为：

1. `Cs1_true_pF`
2. `Cs2_true_pF`
3. `B_fault_scale`
4. `noiseA_A`
5. `noiseB_A`
6. `noiseC_A`

模型直接输出 `iA_total/iB_total/iC_total`、三相阻性真值和 Cs 真值。动态总电流方程由 `scripts/build_phase2_model.m` 写入模型：

```text
iA = Cself*duA/dt + Cs1*(duA/dt-duB/dt) + iA_R + noiseA
iB = Cself*duB/dt + Cs1*(duB/dt-duA/dt)
     + Cs2*(duB/dt-duC/dt) + iB_R + noiseB
iC = Cself*duC/dt + Cs2*(duC/dt-duB/dt) + iC_R + noiseC
```

电压导数在模型内采用启动后切换到二阶后向差分。旧固定耦合支路以 `1e-18 F` 近似禁用，避免重复计入。B 相故障通过 `B_fault_scale*iB_R_raw` 注入。

## 3. M0、M2、M3 的实际实现位置

### 3.1 M0 — Fixed coupling compensation

M0 没有独立函数。当前实现散落在入口脚本：

- `run_phase2_simulink_dynamic.m:47-50`
- `run_patent_dynamic_experiments.m:16-17`
- Git 已提交版 `run_gating_ablation.m` 中曾包含同样逻辑，当前工作区版本已移除该分支。

实际公式为：

```matlab
c0 = initial_coupling_estimate(data,ref,cfg,self_pF);
fixedHist = repmat(c0(:).',numel(data.t),1);
```

因此当前 M0 的准确含义是：

> 在 `0.10–0.70 s` 初始窗口，用三相联合正则化 LS 估计 Cs1/Cs2；随后把这个估计值冻结到整个记录。

它不是直接把 `cfg.C1=cfg.C2=10 pF` 当作固定补偿值，也不是完全不经数据校准的标称补偿。

### 3.2 M2 — VFF-RLS without fault gate

当前唯一明确的 AutoComp9 M2 调用位于：

```matlab
% run_gating_ablation.m:16
noGate = track_coupling_cvff_rls(data,ref,cfg,self_pF,false);
```

M2 仍然包含：

- 初始三相联合 LS；
- 由局部 LS 参数创新驱动的变遗忘因子；
- 信息形式 `J/h` 递推；
- Cs1/Cs2 每周期 `±1.2 pF` 变化率限制；
- Cs1/Cs2 `[0,40] pF` 范围投影；
- `E_in/E_quad` 计算与周期日志。

关闭的只有 `isFault` 的生效条件，因此没有 `gateHold` 冻结。M2 尚未用于 AutoComp9 的 static、slow_drift、smooth_step、random_drift 或 fault_only 统一实验。

### 3.3 M3 — VFF-RLS with existing hard fault gate

当前 AutoComp9 M3 调用位于：

- `run_phase2_simulink_dynamic.m:49`
- `run_gating_ablation.m:17`

调用形式：

```matlab
gated = track_coupling_cvff_rls(data,ref,cfg,self_pF,true);
```

当前硬门控判据为：

```text
t_cycle_end > 1.0 s
E_in > 1.12 * baseIn
E_in > 1.20 * E_quad
```

触发后 `gateHold=max(gateHold,25)`。门控周期冻结 `J`、`h`、`c` 和 `baseIn`，但仍计算并记录局部 LS、`lambda`、`E_in`、`E_quad`。只在非门控周期且 `E_in < 1.08*baseIn` 时，以 `0.985/0.015` 慢速指数更新 `baseIn`。

### 3.4 三种模式的共同基础与唯一差异

| 项目 | M0 | M2 | M3 |
|---|---|---|---|
| 初始 LS `c0` | 是 | 是 | 是 |
| VFF-RLS 更新 | 否 | 是 | 是 |
| 变化率限制 | 不适用，参数冻结 | 是 | 是 |
| `[0,40] pF` 投影 | 初始 LS 后未再次投影 | 是 | 是 |
| `E_in/E_quad` | 否 | 计算但不门控 | 计算并用于硬门控 |
| 故障冻结 | 否 | 否 | 是 |

## 4. 六个目标 case 的历史数据与复用判断

### 4.1 总表

| 目标 case | 当前场景映射 | AutoComp9 生成器支持 | 现有 AutoComp9 证据 | 旧合成链证据 | 可直接复用 | Phase 1A 是否需运行 |
|---|---|---|---|---|---|---|
| `Case01_static` | `static` | 是 | 只有新旧总电流一致性 CSV；无统一 M0/M2/M3 指标或原始数据保存 | M0/NLMS/M3 trace、M3 cycle、XLSX 汇总 | 场景定义、静态一致性阈值、旧结果可作回归参考 | **需要** |
| `Case02_slow_drift` | `slow_drift` | 是 | M0/M3 汇总、M3 跟踪图；无 M2，无可重算的完整 raw case 保存 | M0/NLMS/M3 trace、M3 cycle、XLSX 汇总、PNG | 用户列出的四个关键数值可直接作为 AutoComp9 回归基准 | **需要**，补 M2 和统一 schema |
| `Case03_smooth_step` | `smooth_step` | 否 | 无 | M0/NLMS/M3 trace、M3 cycle、XLSX 汇总 | 轨迹公式、seed 约定和旧指标可复用；数值不能作为 AutoComp9 正式结果 | **必须** |
| `Case04_random_drift` | `random_drift` | 否 | 无 | M0/NLMS/M3 trace、M3 cycle、XLSX 汇总 | 随机轨迹公式、旧 seed 和旧指标可复用；数值不能作为 AutoComp9 正式结果 | **必须** |
| `Case05_fault_only` | 当前无映射 | 否 | 无 | 无 | 无历史结果可复用 | **必须** |
| `Case06_drift_then_fault` | 当前 `fault_with_drift` | 是，语义一致 | M0/M3 汇总与故障增幅；M2/M3 参数变化、RMSE、故障增幅、门控日志和时序 MAT | M0/NLMS/M3 trace、M3 cycle、XLSX 故障汇总、PNG | 全部指定历史数值可直接复用；可作为严格回归基准 | 为统一 schema **需要一次**；仅核实历史结论则不需要 |

### 4.2 Case01_static

现有 AutoComp9 文件 `results_phase2/static_consistency.csv` 只检查 Simulink 总电流与旧 MATLAB 合成电流的波形差异：

| 相 | 波形 RMSE / A | 最大绝对误差 / A |
|---|---:|---:|
| A | `2.6832930e-7` | `5.4488457e-7` |
| B | `2.7194416e-7` | `5.5323886e-7` |
| C | `2.6832932e-7` | `5.4486729e-7` |

这证明 AutoComp9 固定 Cs 链路基本一致，但不是 M0/M2/M3 的正式基线结果。`results_phase1/static_trace.csv` 和 `static_rls_cycle.csv` 属于 B 级旧合成链，只能复用为回归参考。

### 4.3 Case02_slow_drift

AutoComp9 已有 A 级证据：

- `results_phase2/phase2_key_metrics.csv`
- `results_phase2/figure1_dynamic_coupling_tracking.png`
- `results_phase2/phase2_workspace.mat` 中的汇总表
- `docs/phase2_report.md`

但 `phase2_workspace.mat` 的生成语句只保存 `cfg/staticCheck/summary/faultFactors`，没有保存 `slow.data`、M0/M3 时序或 M2 结果。因此现有数值可直接引用和作为回归断言，不能直接拼成统一三算法完整结果。

### 4.4 Case03_smooth_step 与 Case04_random_drift

二者已在 `synthesize_dynamic_case.m` 和 Phase 1 结果中实际运行，但 `generate_coupling_signals.m` 不支持这两个字符串，AutoComp9 无对应结果。

可复用内容：

- `smooth_step`：`1.45–1.65 s`，Cs1 `10→15 pF`，Cs2 `10→6 pF`；
- `random_drift`：`0.5–1.0 s` 启用，低频正弦叠加 0.30 s 移动平均随机项；
- 现有 trace/cycle、XLSX 指标和固定 seed 可作回归参考。

不可直接复用为正式结论的是旧链路数值，因为其总电流由 MATLAB 合成，而非 AutoComp9 输出。

### 4.5 Case05_fault_only

代码、文件名和报告中均未发现 `fault_only`。这是唯一完全没有历史场景、结果或生成分支的目标 case。

Phase 1A 实现时需要先明确场景定义。最小且与 Case06 可比的定义建议是：Cs1/Cs2 全程保持 `10/10 pF`，B 相故障仍在 `3.00–3.06 s` 从 1.0 平滑升至 1.6，评价窗口沿用 `2.60–2.90 s` 与 `3.40–3.80 s`。这只是后续实现建议，不是当前已存在代码或结果。

### 4.6 Case06_drift_then_fault

目标名称与当前 `fault_with_drift` 的物理顺序一致：Cs 漂移在 `0.8–2.2 s` 完成，故障在 `3.0–3.06 s` 发生，因此可以只做命名映射，不需要改变轨迹公式。

现有 A 级证据最完整：

- `results_phase2/phase2_key_metrics.csv`：M0/M3 B 相误差与 M3 Cs RMSE；
- `results_phase2/fault_retention.csv`：M0/M3 故障增幅；
- `results_phase2/gating_ablation/cs_parameter_change.csv`：M2/M3 参数变化；
- `results_phase2/gating_ablation/fault_retention_summary.csv`：M2/M3 故障增幅；
- `results_phase2/gating_ablation/tracking_rmse_summary.csv`：M2/M3 Cs RMSE；
- `results_phase2/gating_ablation/gating_ablation_evidence.mat`：M2/M3 时序和门控周期日志；
- 旧版 `gating_ablation/fault_retention.csv`：同一数据下 M0/M2/M3 故障增幅。

其不足是证据分散在两套入口和两代输出命名中，新时序 MAT 又没有保存 M0 时序、总电流和完整参考。因此历史结论无需重跑即可确认，但正式统一 Phase 1A 数据包仍应在未来通过新入口运行一次。

## 5. 指定历史数值核实

### 5.1 Slow drift

来源：`results_phase2/phase2_key_metrics.csv`。

| 指标 | 指定近似值 | 现有精确值 | 核实 |
|---|---:|---:|---|
| M0 Fixed B fundamental error | `8.958753%` | `8.9587533463069%` | 一致 |
| M3 B fundamental error | `0.354786%` | `0.354785857594943%` | 一致 |
| M3 Cs1 RMSE | `0.157320 pF` | `0.157320251866564 pF` | 一致 |
| M3 Cs2 RMSE | `0.108514 pF` | `0.108513587962671 pF` | 一致 |

### 5.2 Drift then fault

来源：`results_phase2/fault_retention.csv`、`gating_ablation/cs_parameter_change.csv` 和 `gating_ablation/fault_retention_summary.csv`。

| 指标 | 指定近似值 | 现有精确值 | 核实 |
|---|---:|---:|---|
| true fault factor | `1.600000` | `1.59999999999967` | 一致 |
| M2 Cs1 change | `+5.006271 pF` | `+5.00627092717497 pF` | 一致 |
| M2 Cs2 change | `-4.977348 pF` | `-4.97734794650682 pF` | 一致 |
| M2 estimated fault factor | `1.402269` | `1.40226869710244` | 一致 |
| M3 Cs1 change | `+0.561115 pF` | `+0.561114929229058 pF` | 一致 |
| M3 Cs2 change | `-0.616253 pF` | `-0.616252631092842 pF` | 一致 |
| M3 estimated fault factor | `1.582876` | `1.58287648629316` | 一致 |

这些数值均来自 AutoComp9 同一 `scenario='fault_with_drift'`、`seed=105` 数据。M2/M3 的唯一开关差异为 `enableGate=false/true`。

## 6. 当前硬编码参数审计

### 6.1 已集中在 cfg 的参数

下列值虽是固定默认值，但已在 `patent_default_config.m` 中统一管理，Phase 1A 不需要改动：

| 参数 | 当前值 |
|---|---:|
| 仿真时长 / 步长 | `4.0 s` / `2e-5 s` |
| 基频 | `50 Hz` |
| 自电容 | `C0=100 pF`、`C_moa=300 pF`、合计 `400 pF` |
| 电流 SNR | `30 dB` |
| 初始窗口 | `0.10–0.70 s` |
| 评价起点 | `0.80 s` |
| `lambda_min/max` | `0.55/0.995` |
| Cs 范围 | `[0,40] pF` |
| Cs 变化率 | `1.2 pF/cycle` |
| 门控比值 | `1.12`、`1.20` |
| 门控保持 | `25 cycles` |

### 6.2 仍散落在脚本/函数中的硬编码值

| 位置 | 硬编码内容 | Phase 1A 处理建议 |
|---|---|---|
| `generate_coupling_signals.m` | 初值 `10/10 pF`；slow drift 的 `1.0–3.0 s`、`+4/-3 pF`；Case06 的 `0.8–2.2 s`、`+3/-2 pF`、`3.0–3.06 s`、`+60%` | 保持现值，只扩展 case 映射；不得调参 |
| `synthesize_dynamic_case.m` | smooth step 和 random drift 的全部轨迹常数 | 逐字迁移到 AutoComp9 信号生成分支，不重新设计 |
| `run_phase2_simulink_dynamic.m` | seeds `101/102/105`；故障窗口 `2.60–2.90 s`、`3.40–3.80 s`；故障标称 `1.6`；静态一致性阈值 `2e-6/5e-6 A` | 新入口显式复用，不改变 |
| `run_gating_ablation.m` | `scenario='fault_with_drift'`、seed `105`、同一故障窗口、故障起点 `3.0 s` | 作为 Case06 回归常量保持 |
| `simulate_phase2_case.m` | 噪声 seed 偏移 `+10000`；旧耦合支路禁用值 `1e-18 F` | 保持 |
| `initial_coupling_estimate.m` | LS 正则项 `1e-10 I` | 保持 |
| `track_coupling_cvff_rls.m` | `J0=0.05 X0'X0+1e-8I`、求解正则 `1e-10I`、创新归一化 `[5;5] pF`、饱和尺度 `0.20`、判故障启用时刻 `1.0 s` | 算法内部常数，Phase 1A 不迁移、不修改 |
| `track_coupling_cvff_rls.m` | `baseIn` 更新条件 `1.08`，指数系数 `0.985/0.015` | 保持 |
| `track_coupling_cvff_rls.m` | 残差只拟合 1/3 次谐波；A/B/C 基波相位固定 `+120/0/-120°`；三次谐波同相 | 保持当前数学模型 |
| `scripts/build_phase2_model.m` / AutoComp9 | 二阶后向差分、只给 B 相施加故障、只有 AB/BC 耦合 | 模型禁止修改 |
| `patent_default_config.m` | 默认 `cfg.model=AutoComp8`、默认输出 `results_phase1` | Phase 1A 新入口局部覆盖 AutoComp9 和新输出目录即可，无需改默认配置 |

另一个需明确记录的点是：`generate_coupling_signals.m` 把 Cs 基值直接写成 `10 pF`，没有读取 `cfg.C1/cfg.C2`。Phase 1A 为保持历史结果不应顺手重构这一点。

## 7. 统一 algorithm_mode 是否能做到不改公式和参数

**可以。** 推荐把它实现成薄调度层，而不是改写现有算法：

```text
输入：algorithm_mode, data, ref, cfg, self_pF, c0

M0:
  cHist = repeat(c0)

M2:
  tracker = track_coupling_cvff_rls(data,ref,cfg,self_pF,false)
  cHist = tracker.hist

M3:
  tracker = track_coupling_cvff_rls(data,ref,cfg,self_pF,true)
  cHist = tracker.hist

共同后处理：
  ir = extract_resistive_current(data,ref,self_pF,cHist)
```

为保证严格公平，正确调度顺序应是：

1. 每个 case 只调用一次 `simulate_phase2_case`；
2. 从同一 `data.ub` 只构造一次 `ref`；
3. 从同一 `data/ref` 只计算一次 `c0`；
4. M0/M2/M3 共享这份 `data/ref/c0`；
5. 三种算法统一进入同一评价函数和同一窗口。

这样不会改变：

- AutoComp9 方程；
- VFF 计算；
- RLS 信息矩阵更新；
- 变化率和投影约束；
- `E_in/E_quad`；
- 门控门限、保持周期或基线更新；
- 任何历史 case 的轨迹、seed、噪声和评价窗口。

需要注意：当前 `track_coupling_cvff_rls` 内部会自行再次计算 `c0`。统一调度层可以接受这个现状，不必为了“只算一次”而改核心函数；只要 M0、M2、M3 使用同一数据和 cfg，得到的初始化仍完全一致。Phase 1A 不应借统一入口之机重构函数签名。

## 8. 哪些 case 必须重新运行

### 8.1 仅为确认历史结论

- Case02 和 Case06：**不需要重新运行**。指定关键数值已有 AutoComp9 CSV 直接支持。
- Case01：已有静态链路一致性证据，但没有三算法结果；不能据此宣称统一 baseline 已完成。
- Case03/04/05：没有 AutoComp9 正式结果，无法只靠旧文件完成论文表格。

### 8.2 为形成正式统一 Phase 1A 数据集

六个 case 都应通过未来统一入口各运行一次，但原因不同：

| case | 原因 |
|---|---|
| Case01 | 缺 M0/M2/M3 统一算法结果和完整 case 保存 |
| Case02 | 缺 M2，现有 MAT 仅保存汇总，无法从原始 AutoComp9 数据离线补齐 |
| Case03 | AutoComp9 生成器不支持，只有旧合成链结果 |
| Case04 | AutoComp9 生成器不支持，只有旧合成链结果 |
| Case05 | 场景和结果均不存在 |
| Case06 | 历史数值齐全但分散，当前时序 MAT 缺 M0 和完整原始数据；统一 schema 需一次确定性重跑 |

这里的“运行一次”是每个 case 运行一次 AutoComp9，再在同一数据上执行三种 MATLAB 算法，不是每个算法各运行一次 Simulink。Case02/06 的现有数值应作为严格回归阈值，任何差异都必须先解释，不能为对齐论文图表而调参。

## 9. Phase 1A 最小修改文件清单

以下是后续实现阶段的最小、可审计方案；本轮未执行这些修改。

| 文件 | 动作 | 最小职责 |
|---|---|---|
| `MATLAB一键实验/generate_coupling_signals.m` | 修改 | 保留现有三个分支原样；增加 Case01–Case06 名称映射，逐字复用 `smooth_step/random_drift` 旧轨迹，并新增经过确认的 `fault_only` 轨迹 |
| `MATLAB一键实验/run_phase1a_algorithm.m` | 新增 | 只做 `algorithm_mode={M0,M2,M3}` 调度和统一返回结构；不复制算法公式 |
| `MATLAB一键实验/evaluate_phase1a_metrics.m` | 新增 | 在现有 `evaluate_case_metrics` 基础上统一追加 Cs RMSE、故障增幅、故障前后 Cs 变化、保持误差、首门控时刻和门控周期；沿用原窗口 |
| `MATLAB一键实验/run_phase1a_baseline.m` | 新增 | 六 case 编排；每 case 一次 AutoComp9；三模式共用数据；保存统一 MAT/CSV/PNG |
| `MATLAB一键实验/tests/Phase1ABaselineTest.m` | 新增 | 校验 case registry、模式映射、共享数据、Case02/06 历史数值和输出 schema |

如果只追求“能跑”，算法调度和评价可以写成 `run_phase1a_baseline.m` 的局部函数，从而少两个文件；但这会把调度、评价和 I/O 混在一个脚本中，不利于审计。上表的五个文件是兼顾最小改动与可维护性的建议下限。

### 9.1 明确不应修改的文件

- `AI6109_MOA_AutoComp9.slx`
- `track_coupling_cvff_rls.m`
- `initial_coupling_estimate.m`
- `coupling_regressor.m`
- `extract_resistive_current.m`
- `reconstruct_refs_from_b.m`
- `patent_default_config.m`（新入口局部覆盖 model/output 即可）
- `results/`、`results_phase1/`、`results_phase2/` 内任何历史证据

未来结果应写入独立目录，例如 `results_phase1a/`，不得覆盖 Phase 2 证据。

## 10. Phase 1A 实施前的冻结结论

| 审计项 | 结论 |
|---|---|
| AutoComp9 正式基线模型 | 可用，文件未修改，哈希已确认 |
| M0 | 已实现，但逻辑散落；含初始 LS 校准后冻结 |
| M2 | 已实现，仅在 Case06 消融中实际运行 |
| M3 | 已实现，在 Phase 2 slow drift、Case06 和消融中实际运行 |
| 统一 `algorithm_mode` | 尚不存在；可由薄调度层实现且不改数学公式 |
| 六 case AutoComp9 覆盖 | 不完整 |
| Case02 历史关键值 | 已精确核实，可作回归基准 |
| Case06 历史关键值 | 已精确核实，可作回归基准 |
| Case05 | 尚未定义、尚未运行 |
| M4 / 软门控 | 本轮未创建，当前也不存在 |

最终判断：Phase 1A 的下一步应是“统一调度、补齐 case、统一输出”，不是修改算法、调参或创建 M4。完成上述最小实现并用历史 Case02/06 数值做回归验证后，才可以把 Phase 1A 标记为完成。
