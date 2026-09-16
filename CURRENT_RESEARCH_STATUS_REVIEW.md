# MOA 阻性电流研究项目现状回顾

审查日期：2026-09-16  
审查范围：当前工作区内的 MATLAB/Simulink 源文件、模型、已有结果、阶段报告、测试脚本、Git 历史及未提交工作区。  
审查原则：只读核查，不修改算法、不调参、不重新运行仿真实验。为确认 `.mat` 内容，仅执行了 MATLAB `whos -file`；未调用 `sim`，未生成或覆盖实验结果。本报告是本轮唯一新增的项目文件。

## 总体结论

项目已经完成专利主线所需的基础算法链和一组有效的核心证据：三相联合 Cs1/Cs2 回归、初始化最小二乘、创新量驱动的变遗忘因子 RLS、逐周期变化率限制、0～40 pF 物理范围投影、基于 `E_in/E_quad` 的硬冻结门控、阻性电流扣除、动态 Cs 的 Simulink 方程级实现，以及有门控/无门控消融。

历史 Case A 和 Case B 数值都能在现有 CSV、MAT、PNG 和报告中对应。特别是：

- 缓慢漂移：固定补偿 B 相基波误差 `8.958753%`，CVFF-RLS 为 `0.354786%`，Cs1/Cs2 RMSE 为 `0.157320/0.108514 pF`；
- 故障吸收消融：无门控 Cs1/Cs2 故障前后变化 `+5.006271/-4.977348 pF`，估计故障增幅 `1.402269`；有门控变化 `+0.561115/-0.616253 pF`，估计增幅 `1.582876`；真实增幅 `1.600000`。

但项目尚未形成计划中的统一“论文 Phase 1A baseline 框架”。M0、M2、M3 的底层能力已经分别存在，缺少统一 `algorithm_mode`、Case01/02/03 编排、统一结果对象和命名一致的基线报告。因此本报告将论文 Phase 1A 判定为：**部分完成**。

后续论文算法中的软门控、连续更新权重、方向感知参数更新、`P_X` 投影、`eta_abs`、基于 `E_in/E_quad` 的自适应遗忘因子均未实现。当前仍处于“专利算法证据已建立，论文统一 baseline 正在成形但未完成”的阶段。

## 1. 当前项目目录与关键文件

### 1.1 目录结构

| 路径 | 内容与定位 | 当前状态 |
|---|---|---|
| `MATLAB一键实验/` | 当前 MATLAB/Simulink 主工程，包含模型、算法、入口、测试和结果 | 在使用 |
| `MATLAB一键实验/results/` | 2026-08-06 的早期/原始专利结果，动态总电流由 MATLAB 合成 | 基线证据，保留，不应覆盖 |
| `MATLAB一键实验/results_phase1/` | Phase 1 正确性修复、扩展指标、30-seed SNR Monte Carlo 结果 | 在使用，专利阶段证据 |
| `MATLAB一键实验/results_phase2/` | 动态 Cs 进入 Simulink 后的结果、门控消融和模型布局验证 | 当前最重要的专利/论文 baseline 证据 |
| `MATLAB一键实验/results_phase2/gating_ablation/` | 有门控与无门控消融；同时保留旧命名和新命名两代结果 | 在使用；新一代文件未提交 |
| `MATLAB一键实验/results_phase2/model_layout_validation/` | AutoComp9 与布局整理后的 AutoComp10 数值一致性证据 | 已完成的模型整理验证 |
| `artifacts/phase0_baseline_run/` | AutoComp7、旧代码和 Phase 0 运行结果的隔离归档 | 历史基线，不参与当前调用 |
| `docs/` | Phase 0/1/2、门控消融和算法定义文档 | 在使用，但文档具有不同时间截面 |
| `MATLAB一键实验/tests/` | Phase 1 自动回归测试 | 在使用；没有 Phase 2/门控消融自动测试类 |
| `.agents/skills/` | 工具/代理技能依赖，不属于研究算法或实验产物 | 环境支持目录 |
| `.matlab_prefs/`、`MathWorks/`、`slprj/` | MATLAB 偏好和生成缓存 | 环境/缓存，不属于研究证据 |

未发现 `paper_research/`、`baseline/`、`phase1a/`、`Case01/Case02/Case03` 等独立论文目录。现有论文 baseline 相关材料实际分布在 `results_phase2/`、`run_gating_ablation.m` 和 `docs/gating_ablation_report.md` 中。

### 1.2 Simulink 模型

| 文件 | 用途与实际结构 | 是否仍在使用 | 调用关系 | 阶段归属 |
|---|---|---|---|---|
| `MATLAB一键实验/AI6109_MOA_AutoComp7.slx` | 原始三相 MOA 基线；三个 MATLAB Function 内硬编码 `Vref=110e3/sqrt(3)`、`Iref=0.3e-3`、`alpha=6`；含静态耦合和 `iA/iB/iC_total` 输出 | 仅作不可破坏基线 | `scripts/build_or_patch_model.m` 的源模型；Phase 0 归档另有副本 | 专利基线 |
| `MATLAB一键实验/AI6109_MOA_AutoComp8.slx` | AutoComp7 的参数化副本；三个 MOA 函数使用 `Vref_moa/Iref_moa/alpha_moa` | Phase 1 在使用；`patent_default_config` 默认指向它 | `simulate_moa_base.m`、Phase 1 全量实验和参数化测试 | 专利 Phase 1 |
| `MATLAB一键实验/AI6109_MOA_AutoComp9.slx` | 动态 Cs 方程级模型；根级输入 Cs1、Cs2、B 相故障倍率和三相噪声；Simulink 直接输出总泄漏电流 | Phase 2 与门控消融的实际模型 | `simulate_phase2_case.m`、`run_phase2_simulink_dynamic.m`、`run_gating_ablation.m` | 专利 Phase 2；论文 baseline 证据 |
| `MATLAB一键实验/AI6109_MOA_AutoComp10.slx` | AutoComp9 的布局/子系统整理版；内部算法与方程未变 | 只用于布局验证，不是主要运行入口 | `validate_auto_comp10_layout.m` | 模型整理/展示 |
| `MATLAB一键实验/AI6109_MOA_AutoComp11.slx` | 当前内部 XML 仍包含与 AutoComp10 相同的动态 Cs、MOA、测量子系统和动态电流函数 | 仅被未跟踪的 `run_main.m` 使用；当前文件有未提交修改 | `run_main.m` | 后续统一运行入口试验，尚未形成正式阶段证据 |
| `artifacts/phase0_baseline_run/AI6109_MOA_AutoComp7.slx` | Phase 0 隔离副本 | 不参与当前调用 | 仅供历史复核 | 历史专利基线 |

当前模型 SHA-256：

| 模型 | SHA-256 |
|---|---|
| AutoComp7 | `7BBBB729FF91F457D8A9B221055B69123588E6EE28CAF93DE2613B3FF9974CD1` |
| AutoComp8 | `CC9C975E564940271D1E1C1454CBE7852C83897B668943E44CCB9111AECBA744` |
| AutoComp9 | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| AutoComp10 | `048E0A0CA23BE6008EAD134A229ED1B735B3A456F78673DFC9CE207D448B8CA2` |
| AutoComp11（当前未提交版本） | `89E1F63F5CC91EF35C8CA3110D97CADFF783B4B8C0CEEDCFE11DF3036D6433A9` |

### 1.3 核心 MATLAB 算法文件

| 文件 | 用途 | 当前调用关系 | 是否仍使用 | 阶段归属 |
|---|---|---|---|---|
| `patent_default_config.m` | 统一物理参数、算法阈值、随机种子和 Phase 1 输出目录 | 几乎所有入口的配置源；Phase 2 入口覆盖 `model/output_dir` | 是 | 专利核心；论文 baseline 共用 |
| `coupling_regressor.m` | 构造 Cs1/Cs2 的三相联合回归 `X,y`，扣除已知自电容 | 被初始化、NLMS、CVFF-RLS 和残差计算调用 | 是 | 专利核心 |
| `initial_coupling_estimate.m` | 在 0.10～0.70 s 窗口用正则化 LS 得到 `c0` | 固定补偿、NLMS、CVFF-RLS 的共同初值 | 是 | 专利核心 |
| `track_coupling_block_nlms.m` | 一周期块 NLMS 对比算法；含范围投影和尾部填充 | 仅 Phase 1 动态实验使用 | 是，作为对比 | 专利对比算法 |
| `track_coupling_cvff_rls.m` | 当前主算法：局部 LS 创新驱动 VFF、信息形式 RLS、变化率限制、范围投影、硬门控、残差记录 | Phase 1、Phase 2、消融和布局验证共同调用 | 是 | 专利核心；论文 M2/M3 基础 |
| `extract_resistive_current.m` | 用 Cself 和逐样本 Cs1/Cs2 扣除容性电流，输出 A/B/C 阻性电流 | 所有算法评价入口 | 是 | 专利核心 |
| `evaluate_case_metrics.m` | Cs MAE/MaxErr；阻性基波幅相、三次谐波幅相、波形 RMSE/NRMSE | Phase 1、Phase 2、布局验证 | 是 | 专利评价；论文 baseline 可复用 |
| `reconstruct_refs_from_b.m` | 对理想 B 相电压拟合基波和三次谐波，按平衡三相关系重构 A/B/C 及其导数 | Phase 1、Phase 2、消融均调用 | 是 | 当前核心限制所在 |
| `synthesize_dynamic_case.m` | 用 Simulink 电压/阻性真值在 MATLAB 合成动态 Cs、故障、总电流和噪声 | Phase 1 主数据链；Phase 2 仅作解析参考和噪声幅值参考 | 是，但不再是 Phase 2 算法输入 | 专利 Phase 1/单元参考 |
| `generate_coupling_signals.m` | 生成 Phase 2 的静态、慢漂移、故障倍率外部输入 | `simulate_phase2_case.m` | 是 | 专利 Phase 2 |
| `simulate_moa_base.m` | 运行 AutoComp8，读取三相电压和真实阻性电流；不读取动态总电流 | Phase 1 动态与鲁棒性入口 | 是 | 专利 Phase 1 |
| `simulate_phase2_case.m` | 向 AutoComp9 输入 Cs/故障/噪声，读取 Simulink 总电流和真值；同时生成 MATLAB 参考用于一致性/噪声构造 | Phase 2 和门控消融 | 是 | 专利 Phase 2；论文 baseline 证据 |

### 1.4 入口、构建和验证脚本

| 文件 | 用途与调用关系 | 当前状态 | 阶段归属 |
|---|---|---|---|
| `run_all_patent_experiments.m` | 顺序调用 Phase 1 动态实验和鲁棒性扫描 | 在使用；不包含 Phase 2 | 专利 Phase 1 |
| `run_patent_dynamic_experiments.m` | 运行 5 个场景，比较固定补偿、NLMS、带门控 CVFF-RLS，输出 XLSX/MAT/CSV/PNG | 在使用 | 专利 Phase 1 |
| `run_patent_robustness_sweep.m` | SNR 30-seed Monte Carlo；相位、三次谐波、负序扫描 | 在使用 | 专利 Phase 1 鲁棒性 |
| `run_phase1_validation.m` | 构建 AutoComp8、运行 Phase 1 全量实验、执行 tests | 在使用，但本轮未运行 | 专利 Phase 1 回归 |
| `run_phase2_simulink_dynamic.m` | AutoComp9 的静态一致性、慢漂移和故障+漂移实验 | 在使用 | 专利 Phase 2 |
| `run_gating_ablation.m` | 同一 AutoComp9 数据下比较 `enableGate=false/true` | 在使用；工作区版本有未提交修改 | 专利消融；论文 M2/M3 证据 |
| `run_main.m` | 检查 AutoComp11 接口并运行一次静态、零附加噪声仿真 | 未跟踪；未输出研究结果 | 后续统一入口试验 |
| `scripts/build_or_patch_model.m` | 从 AutoComp7 可复现构建 AutoComp8 | 在使用 | 专利 Phase 1 |
| `scripts/build_phase2_model.m` | 从 AutoComp8 构建 AutoComp9，加入动态总泄漏电流模块 | 在使用 | 专利 Phase 2 |
| `scripts/build_model_layout_auto_comp10.m` | 从 AutoComp9 生成布局整理版 AutoComp10 | 已完成布局用途 | 展示/模型整理 |
| `validate_auto_comp10_layout.m` | 复跑两个 Phase 2 工况，断言 AutoComp10 与 AutoComp9 数值不变 | 已有结果；本轮未运行 | 模型整理验证 |

`run_main.m` 文件头写“固定使用 AutoComp10”，实际第 9 行选择 `AI6109_MOA_AutoComp11`，说明该未提交入口的说明与实现不一致。

### 1.5 测试文件

| 文件 | 覆盖内容 | 状态 |
|---|---|---|
| `tests/baseline_expected.m` | Phase 0 B 相基波误差、故障增幅、负序敏感性和 AutoComp7 哈希 | 在使用 |
| `tests/BaselineRegressionTest.m` | 动态主指标、故障保持、负序结果回归 | 在使用 |
| `tests/EvaluateCaseMetricsTest.m` | 已知幅相误差、三次谐波误差、Monte Carlo seed 数量 | 在使用 |
| `tests/ModelParameterizationTest.m` | `Iref/Vref/alpha` 确实改变 AutoComp8 阻性电流 | 在使用 |
| `tests/MonteCarloDeterminismTest.m` | 相同 seed 的噪声和 Cs 估计完全一致 | 在使用 |
| `tests/TrackerTailTest.m` | NLMS/RLS 不足整周期尾部继承最后有效估计 | 在使用 |

现有报告记录 Phase 1 自动测试为 `11 passed / 0 failed / 0 incomplete`。本轮未重新运行测试。没有针对 AutoComp9 动态模型、门控消融数值或 AutoComp11 的 `matlab.unittest` 类。

### 1.6 报告、数据和图

| 文件/目录 | 内容 | 当前判断 |
|---|---|---|
| `docs/experiment_audit.md` | Phase 0 环境、AutoComp7 哈希和修改前基线 | 历史记录准确；其中“非 Git 工作区”只描述当时，不代表当前状态 |
| `docs/phase1_report.md` | 尾部修复、参数化、扩展指标、30-seed Monte Carlo 和测试结果 | 与 Phase 1 代码/结果一致；“未进入 Phase 2”是历史时间截面，当前已过时 |
| `docs/phase2_report.md` | AutoComp9 动态 Cs、静态一致性、慢漂移和故障结果 | 与 CSV 结果一致 |
| `docs/gating_ablation_report.md` | 无门控/有门控消融结果 | 与新 CSV 一致；当前文件有未提交修改 |
| `docs/patent_algorithm_definition.md` | 逐式整理当前 CVFF-RLS、残差、门控和参数 | 与现有代码基本一致；当前未跟踪 |
| `MATLAB一键实验/README.md` | Phase 1 使用和算法故事线 | 对 Phase 1 准确，但未纳入 Phase 2/消融/AutoComp9～11，已不完整 |
| `results_phase1/dynamic_experiment_workspace.mat` | `cfg/summary/faultSummary` | Phase 1 结构化结果 |
| `results_phase1/robustness_workspace.mat` | `cfg/result/snrSummary` | 30-seed 和敏感性结构化结果 |
| `results_phase2/phase2_workspace.mat` | `cfg/staticCheck/summary/faultFactors` | Phase 2 核心结果 |
| `results_phase2/gating_ablation/gating_ablation_results.mat` | 旧消融 `cfg/parameterChange/faultRetention/tracking` | 已提交的旧命名证据 |
| `results_phase2/gating_ablation/gating_ablation_evidence.mat` | 新消融完整时序、门控周期日志和汇总 | 当前最完整消融证据；未跟踪 |
| `results_phase1/*.xlsx` | 24 项动态指标和 26 项鲁棒性原始指标/统计 | 在使用 |
| `results_phase2/*.csv` | 静态一致性、Cs RMSE、B 相误差、故障保持 | 在使用 |
| `results_phase1/*.png`、`results_phase2/*.png` | 动态误差、门控、SNR、负序、Phase 2 跟踪与消融图 | 在使用；共检查到 28 个 PNG（含归档/旧结果重复） |

项目内没有 `.fig` 文件。PNG 只保留了导出图，无法直接恢复 MATLAB Figure 对象。`gating_ablation/` 同时存在旧文件 `figure1_gating_ablation_cs.png`、`figure2_gating_ablation_current.png`、`fault_retention.csv`、`tracking_rmse.csv` 和新文件 `gating_ablation_comparison.png`、`fault_retention_summary.csv`、`tracking_rmse_summary.csv`；两代数值一致，新一代增加完整时序 MAT。

### 1.7 主要调用链

Phase 1：

```text
patent_default_config
  -> simulate_moa_base -> AutoComp8
  -> synthesize_dynamic_case
  -> reconstruct_refs_from_b
  -> initial_coupling_estimate -> coupling_regressor
  -> fixed / track_coupling_block_nlms / track_coupling_cvff_rls
  -> extract_resistive_current
  -> evaluate_case_metrics
  -> results_phase1 (XLSX/MAT/CSV/PNG)
```

Phase 2 与消融：

```text
patent_default_config（入口覆盖 model=AutoComp9）
  -> generate_coupling_signals
  -> simulate_phase2_case -> AutoComp9 -> iA/iB/iC_total
  -> reconstruct_refs_from_b
  -> fixed / track_coupling_cvff_rls(enableGate=false/true)
  -> extract_resistive_current
  -> evaluate_case_metrics / fault_factor / RMSE
  -> results_phase2 (CSV/MAT/PNG)
```

## 2. 已实现算法

| 算法/机制 | 代码事实 | 判定 |
|---|---|---|
| 固定相间耦合补偿 | 用初始化 LS 得到 `c0`，整段保持不变；见 Phase 1 和 Phase 2 入口 | 已实现 |
| 普通 LS | `initial_coupling_estimate` 有启动阶段正则化 LS；CVFF-RLS 每周期计算局部 `cls` | 已实现为初始化/内部量；未实现独立“普通 LS 跟踪方法” |
| NLMS | 一周期块更新，对比固定补偿和 CVFF-RLS | 已实现，仅 Phase 1 使用 |
| 固定遗忘因子 RLS | 没有独立函数、模式或实验 | **未实现，仅为后续计划/消融候选** |
| VFF-RLS | `lambda` 随局部 LS 参数创新变化，信息形式更新 `J/h` | 已实现 |
| VFF-RLS + 硬门控 | `enableGate=true` 时触发后完全冻结 `J/h/c/baseIn` | 已实现 |
| 无门控 VFF-RLS | 同一函数 `enableGate=false` | 已实现，并完成 Case B 消融 |
| 软门控/连续门控 | 未发现更新权重、连续门控函数或状态 | **未实现，仅为后续计划** |
| 方向感知更新 | `E_in/E_quad` 仅用于硬故障判据，没有按残差方向投影或重加权参数增量 | **未实现，仅为后续计划** |
| 基于 `E_in/E_quad` 调节遗忘因子 | 当前 `lambda` 只由 `norm((cls-c)./[5;5])` 决定 | **未实现，仅为后续计划** |
| Cs 变化率限制 | 每个参数每周期裁剪到 `±1.2 pF` | 已实现 |
| Cs 物理范围投影 | 每个参数独立裁剪到 `[0,40] pF` | 已实现；不是矩阵结构投影 |
| A-C 耦合/结构化耦合矩阵 | 回归只有 Cs1=AB、Cs2=BC 两列 | **未实现，仅为后续计划** |
| 结果有效性/置信度 | 没有 `result_valid/reference_quality/confidence` 输出 | **未实现，仅为后续计划** |

当前 `CVFF-RLS` 的“VFF”具体由参数创新驱动：

```text
cls = (R + 1e-10 I)^(-1) z
innovation = norm((cls-c)./[5;5])
lambda = 0.995 - (0.995-0.55)*clip(innovation/0.20,0,1)
```

`[5;5] pF` 和 `0.20` 仍是函数内硬编码值，不在 cfg 中。

## 3. 已完成仿真工况

### 3.1 Phase 1 MATLAB 合成数据链

实际运行并保存结果的场景：

- `static`：固定 Cs1/Cs2；
- `slow_drift`：1.0～3.0 s 平滑变化，Cs1 10→14 pF，Cs2 10→7 pF；
- `smooth_step`：1.45～1.65 s 平滑阶跃，Cs1 10→15 pF，Cs2 10→6 pF；
- `random_drift`：低频正弦叠加平滑随机变化；
- `fault_with_drift`：0.8～2.2 s 耦合漂移，3.0～3.06 s B 相阻性电流平滑升至 1.6 倍；
- SNR：无噪声、40、30、20 dB，每级 30 seeds；
- 参考相位误差：0、0.33、0.5、1、2、3°；
- 三次谐波幅值比：0.5%、2%、5%、8%、10%；
- 三次谐波相位：0、1、3、5、10°；
- 负序电压：0、1%、3%、5%。

### 3.2 Phase 2 Simulink 动态总电流链

实际运行并保存结果的场景：

- 固定 Cs 的 Simulink 与 MATLAB 解析一致性；
- `slow_drift` 在线辨识与固定补偿对比；
- `fault_with_drift` 在线辨识、固定补偿和故障增幅保持；
- 同一故障数据上的无门控/有门控消融；
- AutoComp9 与布局整理版 AutoComp10 的结果一致性。

### 3.3 Case A：缓慢相间耦合漂移

已完成全部要求：Cs1/Cs2 真值随时间变化、在线跟踪、固定补偿对比、Cs1/Cs2 RMSE、B 相阻性电流基波误差。现有 `phase2_key_metrics.csv` 与 `docs/phase2_report.md` 精确对应历史数值：

| 指标 | 现有结果 |
|---|---:|
| Cs1 RMSE | `0.1573202519 pF` |
| Cs2 RMSE | `0.1085135880 pF` |
| 固定补偿 B 相基波误差 | `8.9587533463%` |
| CVFF-RLS B 相基波误差 | `0.3547858576%` |

图 `results_phase2/figure1_dynamic_coupling_tracking.png` 显示 Cs1 10→14 pF、Cs2 10→7 pF 的真值和在线估计，和 CSV 一致。

### 3.4 Case B：耦合漂移后施加阻性故障

代码和结果确认：

- 耦合漂移在 `0.8～2.2 s` 完成；故障发生前真值已稳定为 Cs1=`13 pF`、Cs2=`8 pF`；
- B 相阻性故障从 `3.00 s` 开始，在 `3.06 s` 平滑达到正常值的 `1.6` 倍；
- 消融使用同一 AutoComp9 数据、同一 seed=`105`、同一初值和同一算法参数，唯一变量为 `enableGate`；
- 真实故障增幅为 `1.59999999999967`。

| 指标 | 无门控 | 有门控 |
|---|---:|---:|
| Cs1 故障前后估计变化 | `+5.0062709272 pF` | `+0.5611149292 pF` |
| Cs2 故障前后估计变化 | `-4.9773479465 pF` | `-0.6162526311 pF` |
| Cs1 全窗口 RMSE | `2.6151618174 pF` | `0.3152578523 pF` |
| Cs2 全窗口 RMSE | `2.5998580359 pF` | `0.3280663929 pF` |
| 估计故障增幅 | `1.4022686971` | `1.5828764863` |
| 故障保持误差 | `-12.3582064311%` | `-1.0702196067%` |

门控后并非完全零变化。周期日志显示故障斜坡早期在判据越阈值前先执行过一次更新，约在 3.04 s 将 Cs1/Cs2 推到约 `13.555/7.378 pF`；约在 3.06 s 开始触发冻结。该现象解释了有门控情况下仍有约 `+0.56/-0.62 pF` 的故障前后变化。

## 4. 已得到的关键数值结果

### 4.1 Phase 0/Phase 1 基线

Phase 1 尾部填充修复没有改变主要 B 相基波结果：

| 场景 | CVFF-RLS B 相基波误差 |
|---|---:|
| 固定耦合 | `-0.029800%` |
| 缓慢漂移 | `+0.32467%` |
| 平滑阶跃 | `+0.14364%` |
| 随机波动 | `-0.12368%` |
| 阻性故障+漂移 | `-0.32494%` |

Phase 1 故障增幅为真值 `1.6000`、估计 `1.5770095`、保持误差 `-1.43691%`。Phase 2 改用 Simulink 总电流后对应估计为 `1.5828765`、保持误差 `-1.07022%`。

### 4.2 静态一致性

AutoComp9 固定 Cs 时，Simulink 总电流与旧 MATLAB 合成链的波形 RMSE 为：A `2.6833e-7 A`、B `2.7194e-7 A`、C `2.6833e-7 A`；最大绝对误差均约 `5.5e-7 A`。现有断言阈值为 RMSE `<2e-6 A` 且最大误差 `<5e-6 A`。

### 4.3 鲁棒性结果边界

- SNR Monte Carlo 已完成 4 个等级 × 30 seeds；无噪声/40/30/20 dB 的 `|B_FundErr|` 均值分别约 `0.50475/0.49027/0.40967/0.18465%`。均值随噪声增强反而下降，报告已正确标记为噪声与系统偏差抵消，不能解释成低 SNR 更优。
- 单 B 相参考在负序下显著失效：1%/3%/5% 负序时 B 相基波误差约 `11.193%/35.030%/61.991%`。
- 三次谐波幅值和相位扫描已运行，但当前参考与模型仍来自同一理想电压链，不能替代真实电场传感器验证。

## 5. 已完成的消融实验

当前明确完成的算法消融只有故障门控开关：

```text
M2-like：track_coupling_cvff_rls(..., enableGate=false)
M3-like：track_coupling_cvff_rls(..., enableGate=true)
```

该消融证明：在当前模型和单一故障场景下，阻性故障会被无门控 VFF-RLS 通过约 `+5/-5 pF` 的虚假 Cs 调整部分吸收；硬门控将虚假变化压缩到约 `+0.56/-0.62 pF`，并把故障增幅保持误差由 `-12.36%` 改善到 `-1.07%`。

尚未完成以下系统消融：固定遗忘因子 RLS、RLS+投影、RLS+VFF、RLS+变化率、软门控、方向感知更新、`P_X` 投影、不同门限/保持周期敏感性。固定补偿与 CVFF-RLS 的对比存在，但不等价于完整的算法组件消融矩阵。

## 6. 当前故障门控逻辑

### 6.1 `E_in` 与 `E_quad`

每个工频周期先用当前旧参数 `c` 形成三相联合残差：

```text
e = y - X*c
```

对每相残差分别以以下基函数联合最小二乘拟合：

```text
Bin = [sin(ωt + phi1 + phase_p), sin(3ωt + phi3)]
Bq  = [cos(ωt + phi1 + phase_p), cos(3ωt + phi3)]
B   = [Bin, Bq, 1]
coef = B \ ep
```

A/B/C 基波相位偏移为 `+2π/3、0、-2π/3`，三次谐波三相同相。每相分别计算 `Bin*coef(1:2)` 和 `Bq*coef(3:4)` 的 RMS，再对三相作均方根合成得到 `E_in` 和 `E_quad`。

### 6.2 `baseIn` 与故障判据

- 第一个在线更新周期用当前 `E_in` 初始化 `baseIn`；
- 仅当周期末时间 `>1.0 s` 且 `enableGate=true` 时允许判故障；
- 当前实际判据仍是：

```text
E_in > 1.12 * baseIn
且
E_in > 1.20 * E_quad
```

- 仅在非门控周期且 `E_in < 1.08*baseIn` 时慢速更新：

```text
baseIn = 0.985*baseIn + 0.015*E_in
```

因此 `baseIn` 是条件更新的慢速指数基线，不会在大残差期间快速追随故障。

### 6.3 `gateHold`、冻结状态和解除

- 触发时：`gateHold=max(gateHold,25)`；基础保持量是 25 个工频周期，即 50 Hz 下约 0.5 s；
- 只要 `gateHold>0`，当前周期 `gate=1` 并将计数减一；
- 门控周期完全跳过 `J`、`h`、`c` 和 `baseIn` 更新；
- `lambda`、局部 LS 和残差仍会被计算并记录，但不写入参数状态；
- 若故障条件持续成立，每周期都会把 `gateHold` 重新抬到至少 25，因此实际冻结可长于 25 周期；现有故障工况从约 3.06 s 一直持续到仿真结束，累计记录 48 个门控周期；
- 解除条件没有独立的低阈值滞回逻辑：只有当故障判据不再成立，且此前保持计数递减到 0，才恢复正常更新。

### 6.4 更新顺序

实际顺序是：构造 `R/z` → 计算局部 LS/创新量/`lambda` → 用旧 `c` 计算 `E_in/E_quad` → 判故障并更新 `gateHold` → 若门控则冻结 → 否则更新 `J/h`、求 `cNew`、执行变化率限制和范围投影、条件更新 `baseIn`。

确认的参数值：

| 参数 | 当前代码值 |
|---|---:|
| `gate_ratio` | `1.12` |
| `gate_quad_ratio` | `1.20` |
| `gate_hold_cycles` | `25` |
| `rate_limit_pF_per_cycle` | `1.2 pF/cycle` |
| `coupling_bounds_pF` | `[0,40] pF` |
| `lambda_min/lambda_max` | `0.55/0.995` |

## 7. 当前模型假设

| 项目 | 状态 | 代码依据与边界 |
|---|---|---|
| 使用理想 B 相电压 | **已实现且仍在使用** | 所有算法入口把 `data.ub` 直接传给 `reconstruct_refs_from_b`；没有电场探头输出 |
| 由平衡三相关系重构 A/B/C | **已实现且仍在使用** | A/C 基波固定为 B 相 `±120°`，三次谐波三相同相 |
| 三相自身电容固定约 400 pF | **已实现且仍在使用** | `C0=100 pF`、`C_moa=300 pF`，算法三相均固定使用 `Cself=400 pF` |
| 只考虑 A-B、B-C 耦合 | **已实现且仍在使用** | 回归和总电流只有 Cs1/Cs2 |
| A-C 弱耦合 | **未实现** | 无 CsAC 参数、支路或失配项 |
| 电流传感器/总电流噪声 | **部分实现** | Phase 1 和 Phase 2 均可加独立白噪声，默认 30 dB |
| 电场传感器噪声、增益、偏置、漂移 | **未实现** | 没有 `eB_meas` 或传感器模型 |
| 相位误差 | **部分实现** | 有统一 `phase_error_deg` 扫描；150 Hz 相位被设为基波相差的 3 倍，不能独立配置 50/150 Hz 响应 |
| 三相电压不平衡 | **部分实现** | 模型可施加 `Vneg_pu` 并已扫描，但算法无有效性门控，结果显示严重失效 |
| 三次谐波 | **已实现** | 电源、参考拟合、残差分解和评价均含 150 Hz；只覆盖三次谐波 |
| 自身电容参数误差/漂移 | **未实现** | 真值和算法都使用同一固定 Cself；没有 ±1/2/5% 失配实验 |
| 动态 Cs 在 Simulink 中 | **已实现** | AutoComp9～11 的方程级模块直接生成总泄漏电流 |
| `u*dC/dt` 快变项 | **未实现** | 当前仅 `C(t)*du/dt`，适用于准静态慢变化 |
| MOA 参数可配置 | **已实现** | AutoComp8～11 使用 `Vref/Iref/alpha` 参数 |
| 多种 MOA 非线性曲线/三相失配 | **未充分实现** | 参数化存在，但没有 alpha/Iref 三相不一致、分段曲线或老化扫描 |
| 结果有效性/置信度 | **未实现** | 负序严重时仍会计算结果，没有 `valid=false` |

## 8. 已实现但尚未充分验证的功能

1. AutoComp9～11 的动态 Cs 是方程级 Simulink 实现，已做固定 Cs 一致性，但不是 Simscape 可变电容物理器件模型。
2. AutoComp10 只验证了布局整理后两个场景数值不变。AutoComp11 没有对应构建脚本、正式报告或结果回归，且当前二进制模型有未提交修改。
3. `evaluate_case_metrics` 已支持三相基波/三次谐波幅相和波形 RMSE/NRMSE，但 Phase 2 汇总只输出 Cs RMSE 和 B 相基波误差，没有系统输出全部扩展指标。
4. Monte Carlo 已具备固定 seed 和统计表，但仅对 SNR 运行 30 seeds；耦合、传感器、MOA 参数和故障参数尚未联合随机化。
5. 门控消融只覆盖一个 60% B 相故障、一个噪声等级和一个 seed。没有检测率、误触发率、漏触发率或阈值敏感性。
6. 负序和相位误差扫描证明了边界，却尚未形成运行时有效性判定。
7. 变化率限制和范围投影已实现，但没有单独消融，无法分别量化其技术效果。

## 9. 原计划但尚未实现的内容

以下内容在当前代码中没有实现，不能当作已完成算法：

- 真实电场传感器链 `eB_meas`，包括邻相场耦合、增益漂移、DC 偏置、噪声、前端延迟、50/150 Hz 独立相位响应；
- `reference_quality`、`result_valid`、置信度输出和不平衡/模型失配冻结；
- CsAC 或物理结构约束的三相耦合电容矩阵；
- Cself 启动校准、慢速强约束在线修正和 Cself 失配扫描；
- 快速变化时的 `u*dC/dt`；
- 固定遗忘因子 RLS 和完整组件消融矩阵；
- 软门控、连续更新权重、`g_m`；
- 方向感知/故障保持型更新、残差方向投影；
- `projection matrix`、`P_X`、`eta_abs`；
- 由 `E_in/E_quad` 直接调节 `lambda`；
- 一般化故障吸收机理的解析推导、阈值检测率/误报率分析；
- 低压硬件实验或现场数据验证；
- 最终论文正文、统一图表编号和投稿格式。

## 10. Phase 1A 完成情况

### 10.1 逐项核查

| Phase 1A 项目 | 现有实现 | 判定 |
|---|---|---|
| M0 固定补偿 | 初始化 LS 后全程固定；Phase 1/2 均有 | 已有 |
| M2 无门控 VFF-RLS | `enableGate=false`，消融脚本实际运行 | 已有 |
| M3 硬门控 VFF-RLS | `enableGate=true`，Phase 1/2 和消融实际运行 | 已有 |
| 统一 `algorithm_mode` | 没有；仅固定逻辑散落在入口，RLS 用布尔 `enableGate` | 缺失 |
| Case01/Case02/Case03 | 没有这些名称或统一 case registry；只有场景字符串 | 缺失 |
| 自动 Cs1/Cs2 RMSE | Phase 2 和消融已计算 | 已有 |
| 阻性电流误差 | Phase 1 完整指标；Phase 2 汇总 B 相基波误差 | 已有 |
| 故障增幅 | 已自动计算 | 已有 |
| 故障保持误差 | 已自动计算 | 已有 |
| 门控时间 | 记录门控周期数 48；未单独输出秒数/首触发/解除时刻 | 部分已有 |
| 自动保存 MAT | Phase 1、Phase 2、消融均有 | 已有 |
| 自动输出 PNG | Phase 1、Phase 2、消融均有 | 已有 |
| 自动汇总指标 | XLSX/CSV 均有，但没有统一跨 case/跨 algorithm 的一张论文 baseline 总表 | 部分已有 |

项目中不存在 `PHASE1A_BASELINE_REPORT.md`。`docs/phase1_report.md` 是专利工程的 Phase 1 正确性报告，不是论文 Phase 1A 统一 baseline 报告。

### 10.2 判定

**Phase 1A：部分完成。**

依据是：M0/M2/M3 和核心 Case A/Case B 指标证据已经存在，门控消融也已完成；但缺少计划中的统一算法选择、Case01/02/03 组织、单一 baseline 入口、统一结果 schema 和 Phase 1A 专门报告。不能仅因底层能力存在就把统一 baseline 框架判为完成。

## 11. 后续论文算法检索结果

对 `.m`、`.md`、`.csv` 文本进行了关键词核查：

| 关键词/概念 | 结果 |
|---|---|
| soft gate / continuous gate | 未发现实现 |
| update weight / `g_m` | 未发现实现 |
| direction-aware / fault-preserving | 未发现实现 |
| residual direction | 未发现参数更新实现；只有 `E_in/E_quad` 的硬判据 |
| adaptive lambda based on `E_in/E_quad` | 未实现；当前 lambda 基于局部 LS 参数创新 |
| fault absorption | 没有以该英文关键词命名的模块；消融结果已实证该现象 |
| projection matrix / `P_X` | 未发现实现 |
| `eta_abs` | 未发现实现 |

结论：**尚未进入 M4 方向感知软门控等后续论文算法阶段。** 当前所做的“方向”仅指硬门控判据比较同相残差与正交残差，不等于方向感知参数更新。

## 12. Git 状态与阶段时间线

当前分支为 `main`，跟踪 `origin/main`。最近提交：

| 提交 | 日期 | 说明 | 实际研究内容 |
|---|---|---|---|
| `d2fc182` | 2026-08-10 | 完成阶段一实验 | Phase 0/1、AutoComp7/8、算法、测试、Phase 1 结果与报告 |
| `6302c64`（tag `phase2`） | 2026-08-11 | 完成阶段二实验 | AutoComp9、动态 Cs Simulink、Phase 2 结果和报告 |
| `0938aea`（tag `phase3`） | 2026-08-12 | 完成阶段三实验 | AutoComp10/11、布局验证和第一版门控消融；不是 AGENTS 规划中的“电场传感器 Phase 3” |
| `622a1d3` | 2026-08-17 | 忽略 MATLAB 和 Simulink 缓存文件 | 清理版本控制中的生成缓存 |

当前工作区已有且本轮未触碰的变更：

- 已修改：`AI6109_MOA_AutoComp11.slx`、`run_gating_ablation.m`、`docs/gating_ablation_report.md`；
- 未跟踪：新一代门控消融 CSV/PNG/MAT、`run_main.m`、`docs/patent_algorithm_definition.md`；
- 本报告新增后，`CURRENT_RESEARCH_STATUS_REVIEW.md` 也为未跟踪文件。

现有未提交变更形成一套内部一致的新门控消融证据，但尚未进入 Git 历史。AutoComp11 是二进制文件，Git 只能显示整体变化；当前 XML 可确认核心动态电流方程仍存在，但没有脚本或报告说明这次未提交修改的具体意图。

## 13. 当前论文研究实际阶段

当前不是“尚未开始”，也不是“统一 baseline 已完成”。更准确的位置是：

> 专利核心算法和 Phase 2 证据已经形成；论文 baseline 所需的 M0/M2/M3 与核心混合事件消融已分别完成，但尚未统一为 Phase 1A 框架，尚未开始 M4 方向感知软门控。

现有成果足以支持论文的研究动机和 baseline 预实验：动态耦合会造成固定补偿误差，无门控自适应会吸收阻性故障，硬门控能显著缓解该问题。现有证据还不足以支持传感器误差、不平衡运行、一般耦合矩阵和现场适用性的广泛结论。

## 14. 下一步最合理的工作

本轮不执行开发。人工确认后，最合理的下一步不是立即做新算法，而是先完成论文 Phase 1A 的“统一而不改算法”整理：

1. 明确选定正式 baseline 模型（建议先固定 AutoComp9 或经验证的 AutoComp10，不直接以未说明变更的 AutoComp11 为基线）；
2. 建立只做调度的统一 `algorithm_mode={M0,M2,M3}`，底层算法公式保持不变；
3. 把现有场景映射为 Case01/Case02/Case03，并明确哪一个是慢漂移、哪一个是故障吸收混合事件；
4. 统一输出 Cs RMSE、B 相误差、故障增幅、保持误差、首触发时刻、门控周期/秒数和结果文件路径；
5. 用现有证据生成 `PHASE1A_BASELINE_REPORT.md`，避免重复跑大规模实验；只有缺少的统一字段才做最小补充运行；
6. Phase 1A 经人工验收后，再进入 M4 软门控/方向感知算法设计。

## 状态简表

| 项目状态 | 当前判定 |
|---|---|
| 专利基础模型 | 已完成（受当前理想化假设限制） |
| Cs在线辨识 | 已完成（Cs1/Cs2） |
| VFF-RLS | 已完成 |
| E_in/E_quad残差分解 | 已完成 |
| 故障硬门控 | 已完成 |
| 门控消融实验 | 已完成（单一核心工况） |
| Baseline统一框架 | 部分完成 |
| 混合事件实验 | 部分完成（漂移后 B 相故障） |
| 鲁棒性实验 | 部分完成 |
| Monte-Carlo | 部分完成（仅 SNR，30 seeds） |
| 故障吸收机理分析 | 部分完成（实证消融，缺少一般化解析/统计） |
| M4方向感知软门控 | 未完成 |
| 低压实验验证 | 未完成 |
| 论文正文 | 未完成 |
