# 避雷器专利完整仿真实验包

## 一键运行

1. 用 MATLAB 打开本文件夹。
2. 确认已安装 Simulink 与 Simscape Electrical / Specialized Power Systems。
3. 在命令窗口执行：

```matlab
run_all_patent_experiments
```

Phase 1 结果自动写入 `results_phase1` 文件夹；原始 `results` 作为基线证据保留。

`AI6109_MOA_AutoComp7.slx` 是只读基线模型。若需要重新生成 Phase 1 的参数化模型，执行：

```matlab
addpath scripts
build_or_patch_model
```

该脚本由 AutoComp7 构建 `AI6109_MOA_AutoComp8.slx`，只参数化三个 MOA MATLAB Function 的 `Vref_moa`、`Iref_moa` 和 `alpha_moa`。

## 实验故事线

1. **固定耦合基准**：证明用户原有 Simulink 电源、MOA 非线性支路和正交参考能够正确工作。
2. **缓慢漂移**：模拟安装距离、温湿度和邻相场分布缓慢变化导致的 `Cs1、Cs2` 漂移，比较固定补偿、NLMS和CVFF-RLS。
3. **平滑阶跃**：模拟位置变化或现场工况切换，验证收敛速度和稳态误差。
4. **随机波动**：验证连续小扰动下的稳定性。
5. **阻性故障与漂移**：B相阻性电流提高60%，验证参数更新门控不会把真实故障错误吸收到耦合电容估计中。
6. **鲁棒性扫描**：覆盖 30 个固定随机种子的噪声 Monte Carlo、相位误差、三次谐波幅值/相位以及负序电压不平衡。

## 采用的算法

核心算法为“带投影约束、变遗忘因子和故障冻结门控的递推最小二乘法（CVFF-RLS）”。只在线跟踪 `Cs1、Cs2`，MOA本体电容在启动阶段作为校准参数固定。这样比同时估计五个电容参数更稳定，也更符合专利中“聚焦相间耦合动态电容”的叙述。

## 重要说明

动态耦合支路采用准静态关系 `i=C(t)·du/dt`，即认为耦合电容在一个工频周期内近似不变。该假设适用于温湿度、安装位置、邻相场分布等慢变化场景。若要研究机械瞬时位移造成的极快变化，应进一步加入 `u·dC/dt` 项。
