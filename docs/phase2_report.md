# 精简版 Phase 2 报告

## 结论

本阶段已将动态相间耦合电容 `Cs1(t)`、`Cs2(t)` 搬入 `AI6109_MOA_AutoComp9.slx`。CVFF-RLS 的输入电流来自 AutoComp9 输出的 `iA_total/iB_total/iC_total`，不再由 MATLAB 后处理重新合成。AutoComp7 与 AutoComp8 的 SHA-256 均未改变。

## ① 动态 Cs 是否真正进入 Simulink

是。AutoComp9 增加根级输入 `Cs1_true_pF`、`Cs2_true_pF` 和前馈模块 `DynamicLeakageCurrentModel`。模型按下式直接计算总泄漏电流：

```text
iA = Cself*duA/dt + Cs1*(duA/dt-duB/dt) + iA_R
iB = Cself*duB/dt + Cs1*(duB/dt-duA/dt) + Cs2*(duB/dt-duC/dt) + iB_R
iC = Cself*duC/dt + Cs2*(duC/dt-duB/dt) + iC_R
```

`Cs1_true`、`Cs2_true` 同时由模型导出作为真值。电压导数使用二阶因果后向差分；它不需要未来样本，适合在线仿真。旧固定耦合支路在 AutoComp9 中近似开路，避免重复计入。这里属于 Simulink 方程级动态物理模型，不是 Simscape 可变电容器件模型。

## ② Simulink 与原 MATLAB 合成是否基本一致

固定 `Cs1=Cs2=10 pF`、30 dB 电流噪声且使用同一噪声序列时：

| 相别 | 波形 RMSE / A | 最大绝对误差 / A |
|---|---:|---:|
| A | 2.6833e-7 | 5.4488e-7 |
| B | 2.7194e-7 | 5.5324e-7 |
| C | 2.6833e-7 | 5.4487e-7 |

结果达到“基本一致”。差异来自原 MATLAB `gradient` 的中心差分与模型二阶因果后向差分。固定检查仅排除仿真最后一个样本，因为 `gradient` 在该终止端点退化为一阶单边差分；动态算法输入和原评价窗口 `t>=0.8 s` 均未修改。

## ③ 动态耦合下是否优于固定补偿

是。在缓慢耦合漂移场景中：

| 指标 | 结果 |
|---|---:|
| Cs1 RMSE | 0.15732 pF |
| Cs2 RMSE | 0.10851 pF |
| 固定补偿 B 相基波误差 | 8.95875% |
| CVFF-RLS B 相基波误差 | 0.35479% |

对应曲线见 `results_phase2/figure1_dynamic_coupling_tracking.png`。

## ④ 阻性故障是否被吸收到 Cs 参数中

本次结果表明门控机制有效。故障后共有 48 个工频周期被门控冻结；真实故障增幅为 1.6000，CVFF-RLS 提取结果为 1.58288，保持误差为 -1.07022%。固定补偿估计增幅仅为 1.55107。故障发生后 Cs 估计没有出现与 60% 阻性突变同量级的错误跳变。

对应波形见 `results_phase2/figure2_fault_resistive_current.png`。

## ⑤ 两个实验的关键数值

| 场景 | Cs1 RMSE / pF | Cs2 RMSE / pF | 固定补偿 B 基波误差 / % | CVFF-RLS B 基波误差 / % |
|---|---:|---:|---:|---:|
| 缓慢耦合漂移 | 0.15732 | 0.10851 | 8.95875 | 0.35479 |
| 阻性故障+耦合漂移 | 0.31526 | 0.32807 | 6.78184 | -0.31016 |

故障场景：真实增幅 `1.6000`，CVFF-RLS 估计 `1.58288`，保持误差 `-1.07022%`。

## ⑥ 是否支撑专利核心技术效果

可以支撑以下受限结论：在当前平衡三相、理想 B 相电压参考、已知自电容和既定 CsAB/CsBC 模型下，在线辨识显著降低了相间耦合缓慢变化对阻性电流提取的影响；故障门控在阻性突变时冻结更新，避免主要故障增量被耦合参数估计吸收。

尚不能据此扩展到电场传感器误差、负序不平衡、自电容失配或一般耦合矩阵。原模型的一个代数环仍存在；本阶段没有为消除它而改变原物理结构。旧耦合支路的三个 Current Measurement 输出因公共总电流输出已切换到新方程块而产生未连接警告，但不参与新链路计算。

## 文件与复现命令

- 构建脚本：`MATLAB一键实验/scripts/build_phase2_model.m`
- 仿真入口：`MATLAB一键实验/run_phase2_simulink_dynamic.m`
- 结果目录：`MATLAB一键实验/results_phase2/`

```powershell
matlab -batch "addpath('scripts'); build_phase2_model"
matlab -batch "results=run_phase2_simulink_dynamic"
```

模型哈希：

| 模型 | SHA-256 |
|---|---|
| AutoComp7 | `7BBBB729FF91F457D8A9B221055B69123588E6EE28CAF93DE2613B3FF9974CD1` |
| AutoComp8 | `CC9C975E564940271D1E1C1454CBE7852C83897B668943E44CCB9111AECBA744` |
| AutoComp9 | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
