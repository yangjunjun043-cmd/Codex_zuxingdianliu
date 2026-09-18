# Phase 1B-3 — Case06 External Verification

## 1. Scope and integrity

本步骤只运行 `Case06_drift_then_fault`，目标是检验 Step 2 在 Case05 建立的 fault absorption mechanism 能否迁移到“故障前已有真实 Cs 漂移”的工况。未进入 Phase 1B-4，未开发 M4，未调整 lambda、门控、故障幅值、评价窗口或 Case06 定义。

正式对象由冻结 registry / generator 读取：

- case：`Case06_drift_then_fault`
- legacy scenario：`fault_with_drift`
- seed：`105`
- Cs drift：`0.8–2.2 s`，Cs1 `+3 pF`、Cs2 `-2 pF`
- B 相 fault：`3.00–3.06 s`，factor `1.0 → 1.6`
- Phase 1A 窗口：pre `[2.60,2.90) s`，post `[3.40,3.80) s`

运行前元数据：

| 项目 | 值 |
|---|---|
| Git branch | `main` |
| Git commit | `91e1b3efc8d2bf637c3fa30865d44c7691330fe5` |
| Git status | DIRTY；包含此前阶段未跟踪产物和本步骤新增产物，未隐藏或清理 |
| AutoComp9 SHA-256 | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| Phase 1A baseline CSV SHA-256 | `E7BEB3ECFEDF521105B67198684752BB32AFAAEFD84ACA80822BA57FBD9D0AB3` |
| Phase 1A baseline workspace SHA-256 | `A90632B72479E7B6ADC4E410DB37542E9CA4985CA8381B6BAFC8F71C961E87B5` |
| Step 1 report SHA-256 | `02859DD0D35E35C18722B452DC7A5C9EE73B55CC6E7A26FC5566500F6E4B9041` |
| Step 2 report SHA-256 | `C98A2D9C53D6986EB4B9C202BEBC00DDD3A197B147615F68D5D073B652275CC1` |

Step 2 四个关键产物在运行前后哈希完全一致：

| Step 2 产物 | SHA-256 |
|---|---|
| `case05_key_metrics.csv` | `889FB69A32A17D5E55998C68DF99D11E02389A7C0631B4FCAFA05F368C62830A` |
| `case05_mechanism_summary.csv` | `F20A07ED08120951245A5F96342FBB1B051040C427154BD274779E8145E57A74` |
| `case05_mechanism_workspace.mat` | `AA585D987828728479BE4C521DFEFBD339120ECBD30C9E1DD9FAED216587A112` |
| `observation_blocks_case05.mat` | `1169CA3246FD790D09DC7B908C24AB55485E068A6AE9690D2FFBAA35A37CA32B` |

因此 AutoComp9、Phase 1A、Step 1、Step 2 均未被本步骤修改。

## 2. Instrumentation equivalence

本步骤直接复用 Step 2 的 `instrument_phase1b_vff_rls.m`，没有为 Case06 改写算法。与原始 `track_coupling_cvff_rls.m` 的 Case06 M2 逐周期比较结果如下：

| 字段 | 最大绝对差 |
|---|---:|
| Cs1 | 0 |
| Cs2 | 0 |
| lambda | 0 |
| E_in | 0 |
| E_quad | 0 |
| baseIn | 0 |
| gate | 0 |

重新生成的 time、Cs1/Cs2 truth、fault scale、三相真实阻性电流、M2 cHist/cycle/irB、M3 cHist/cycle/irB 与 Phase 1A frozen workspace 的最大绝对差均为 `0`。故障前 fault/counterfactual 两分支的参数轨迹最大差也为 `0 pF`。

结论：instrumentation replay 和 Phase 1A 回归均严格满足 `≤ 1e-12`。

## 3. Pre-fault true Cs drift tracking

漂移阶段 `[0.8,2.2] s` 的 M2 跟踪 RMSE：

| 参数 | RMSE (pF) |
|---|---:|
| Cs1 | 0.216861 |
| Cs2 | 0.159477 |

故障前稳定窗口 `[2.60,2.90) s`：

| 参数 | 初始 truth (pF) | pre truth (pF) | true drift (pF) | pre M2 estimate (pF) | pre estimation bias (pF) |
|---|---:|---:|---:|---:|---:|
| Cs1 | 10.000000 | 13.000000 | +3.000000 | 12.942173 | -0.057827 |
| Cs2 | 10.000000 | 8.000000 | -2.000000 | 8.056939 | +0.056939 |

M2 在故障开始前已经到达真实漂移后的工作点附近；故障前残差约为 `±0.057 pF`，远小于随后约 `±4.88 pF` 的 fault-induced false bias。因此后续故障吸收不能解释为未完成的真实漂移跟踪。

## 4. Strict Case06 r_fault construction

严格沿用 Step 1/2 定义：

```text
r_f,B(t) = (1 - 1/g(t)) * i_B,R,true(t)
r_f,k    = [0_A; r_f,B; 0_C]
y_counterfactual = y_fault - r_fault
```

每个周期：

- `size(X) = 3000×2`
- `size(r_fault) = 3000×1`
- 165 个观测周期全部对齐
- `max |(y_fault-y_counterfactual)-r_fault| = 2.1684e-19 A`

这里没有使用 `y-X*c_est` 冒充 fault truth。

## 5. X conditioning and eta_geom

| 指标 | Case06 |
|---|---:|
| rank(X), min/max | 2 / 2 |
| cond2(X), min/max/mean | 1.290994 / 1.290994 / 1.290994 |
| eta_geom, fault-ramp mean | 0.235467 |
| eta_geom, post-fault mean | 0.275451 |
| eta_geom, fault min/max | 0.173364 / 0.275451 |
| projection energy closure max relative error | 5.4981e-15 |
| projection fit max relative error | 3.2199e-15 |

Case05 与 Case06 的 post-fault `eta_geom` 差为 `-1.67e-16`，steady static LS bias 的差也在 `1.8e-15 pF` 量级。两个工况的电压/reference 与 fault waveform 相同，Cs truth 工作点不同，但 fault component 与 `col(X)` 的几何重合度未改变。

本工况支持的结论是：fault geometric absorbability 主要由 observation model / voltage geometry 决定；真实 Cs 漂移主要改变参数工作点和递归历史，并未改变 X 的列空间几何。

## 6. Static fault-induced parameter bias

`Delta c_LS,f = X \ r_fault` 的 Case06 结果：

| 时段 | Delta Cs1_LS,f (pF) | Delta Cs2_LS,f (pF) |
|---|---:|---:|
| first fault cycle | +0.395164 | -0.473056 |
| fault-ramp mean | +2.393390 | -2.493214 |
| steady post-fault mean | +4.886604 | -4.886604 |

方向始终为 `Cs1 > 0`、`Cs2 < 0`，steady 数量级约为 `±4.89 pF`。这里是 fault-induced equivalent bias，不是绝对 Cs 值。

## 7. Recursive fault/counterfactual replay

双分支在 fault onset 前完全共享并经历相同的真实 Cs drift；fault onset 后只在 `r_fault` 是否保留这一点上分离，且各自独立递归更新 `lambda/J/h/c/baseIn`。

Phase 1A 正式窗口结果：

| 参数 | Phase 1A actual M2 Delta Cs (pF) | counterfactual background Delta Cs (pF) | recursive fault-induced Delta Cs (pF) | fault-induced vs actual error (pF) | relative error |
|---|---:|---:|---:|---:|---:|
| Cs1 | +5.006271 | +0.117856 | +4.888415 | -0.117856 | -2.354% |
| Cs2 | -4.977348 | -0.095659 | -4.881689 | +0.095659 | +1.922% |

`background + fault-induced - actual` 的闭合误差对 Cs1/Cs2 均为 `0 pF`。逐周期 instrumented fault replay 与原 M2 的 update prediction 最大误差也为 `0 pF`。

因此正式 `+5.0063/-4.9773 pF` 中：

- fault-induced 部分占绝对变化的约 `97.65% / 98.08%`；
- counterfactual background / 正常估计残差只占约 `2.35% / 1.92%`。

## 8. True drift vs fault-induced false bias

三类变化已经分离：

| 类型 | Cs1 (pF) | Cs2 (pF) | 含义 |
|---|---:|---:|---|
| true Cs drift | +3.000000 | -2.000000 | 物理真实变化，发生在故障前 |
| pre-fault estimation residual | -0.057827 | +0.056939 | M2 在 drift 后工作点的正常残差 |
| fault-induced false bias | +4.888415 | -4.881689 | fault branch − counterfactual branch |

禁止的 `fault estimate - initial Cs` 没有被用作 fault-induced drift。Figure 2 显示：counterfactual 分支保持在真实漂移后的工作点附近，fault 分支在 3.0 s 后额外向 `+Cs1/-Cs2` 偏移。

## 9. Lambda / rate limit / projection / J-h analysis

### 9.1 Lambda

| 指标 | Case05 | Case06 |
|---|---:|---:|
| lambda, fault-ramp mean | 0.590783 | 0.629443 |
| Case06 counterfactual lambda, ramp mean | — | 0.934005 |
| lambda-neutral contribution mean | 2.718% | 3.301% |

Case06 的 lambda contribution 比 Case05 增加 `0.583` 个百分点，但仍仅约为 fault-induced bias 的 `3.30%`。真实漂移历史改变了 lambda 状态和工作点，VFF 对吸收程度有小幅影响；主因仍是 persistent fault/model-column overlap，而非 VFF 本身。

### 9.2 Rate limit and projection

| 指标 | Case05 | Case06 |
|---|---:|---:|
| rate-limit active, any parameter | 0 cycles | 0 cycles |
| projection active, total | 0 cycles | 0 cycles |

真实漂移后的参数位置没有使 rate limit 或 physical projection 参与本次故障吸收。

### 9.3 J/h state mismatch

| 时段 | Case06 relative mismatch |
|---|---:|
| pre-fault mean | 3.7821e-6 |
| fault-ramp mean | 6.9136e-6 |
| steady post mean | 4.8549e-6 |
| post-fault max | 1.4966e-5 |

Case05 ramp mean 为 `6.7856e-6`、post mean 为 `4.9842e-6`、post max 为 `1.4994e-5`。Case06 未出现显著增加，不能把 J/h constrained-state mismatch 视为主机理。

## 10. Fault retention recovery

对同一份真实 fault data，分别应用 fault branch 和 counterfactual branch 的参数轨迹：

| 指标 | 值 |
|---|---:|
| true fault factor | 1.600000 |
| M2 fault-branch factor | 1.402269 |
| M2 retention error | -12.3582% |
| counterfactual-parameter factor | 1.602647 |
| counterfactual retention error | +0.1655% |
| M3 auxiliary factor | 1.582876 |

去除 fault-induced false Cs trajectory 后，M2 从 `1.4023` 恢复到 `1.6026`，接近真值 `1.6000`。这构成 Case06 的闭环证据：即使故障前有真实 Cs drift，主要 fault-retention loss 仍由故障诱发虚假参数偏差造成。

## 11. False coupling compensation

在 `[3.40,3.80) s`，参数差严格使用 `fault branch - counterfactual branch`：

| 指标 | Case05 | Case06 |
|---|---:|---:|
| r_fault,B fundamental RMS | 0.506607 mA | 0.506607 mA |
| false coupling compensation fundamental RMS | 0.168850 mA | 0.168815 mA |
| amplitude ratio | 0.333295 | 0.333228 |
| phase difference | 0.00677° | 0.06832° |
| correlation | 0.909040 | 0.909039 |

Case06 的 false compensation 仍约占真实 fault 基波的三分之一，且几乎同相；与 Case05 的幅值比例差 `-0.0203%`，相关系数差 `-1.41e-6`。这是同一 fault absorption mechanism 的强外部验证。

## 12. E_in / E_quad timeline

| 指标 | pre-fault mean (mA) | fault-ramp mean (mA) | steady post mean (mA) |
|---|---:|---:|---:|
| E_in | 0.926439 | 1.028024 | 1.125326 |
| E_quad | 0.011118 | 0.013888 | 0.118446 |
| baseIn | 0.929001 | 0.928816 | 0.928816 |

Case05 的 E_in 为 `0.927120 / 1.034603 / 1.126072 mA`，E_quad 为 `0.012353 / 0.015978 / 0.119688 mA`。Case06 已在故障前吸收了真实 Cs drift，因此 fault onset 时仍出现与 Case05 相近的故障证据时间线。

按冻结代码含义，E_in/E_quad 是 fault evidence / gate diagnostics，不是 M2 的直接参数更新驱动。

## 13. Case05 vs Case06 quantitative comparison

完整 18 项比较保存在 `step3/case05_case06_comparison.csv`。核心项如下：

| Metric | Case05 | Case06 | Difference | Relative difference |
|---|---:|---:|---:|---:|
| eta_geom post mean | 0.275451 | 0.275451 | -1.67e-16 | -6.05e-14% |
| steady static LS Cs1 (pF) | +4.886604 | +4.886604 | +1.78e-15 | +3.64e-14% |
| steady static LS Cs2 (pF) | -4.886604 | -4.886604 | -8.88e-16 | -1.82e-14% |
| recursive fault-induced Cs1 (pF) | +4.886379 | +4.888415 | +0.002036 | +0.0417% |
| recursive fault-induced Cs2 (pF) | -4.885713 | -4.881689 | +0.004024 | +0.0824% |
| actual M2 Delta Cs1 (pF) | +4.916774 | +5.006271 | +0.089497 | +1.820% |
| actual M2 Delta Cs2 (pF) | -4.956994 | -4.977348 | -0.020353 | -0.411% |
| M2 fault factor | 1.401075 | 1.402269 | +0.001194 | +0.0852% |
| M2 retention error | -12.4328% | -12.3582% | +0.0746 pp | +0.600% |
| lambda contribution mean | 2.718% | 3.301% | +0.583 pp | +21.46% |
| false-compensation ratio | 0.333295 | 0.333228 | -6.76e-5 | -0.0203% |
| false-compensation correlation | 0.909040 | 0.909039 | -1.41e-6 | -0.000155% |

Case06 actual M2 Delta Cs 相对 Case05 略有差异，来源主要是 counterfactual background / pre-fault recursive history，而 fault-induced incremental bias、geometry、false compensation 和 retention loss 基本一致。

## 14. Mechanism transferability — Q1 to Q12

**Q1：故障前真实 Cs drift 是否被正常跟踪？**

是。漂移阶段 RMSE 为 `0.2169/0.1595 pF`，pre 稳定窗口 bias 仅 `-0.0578/+0.0569 pF`。

**Q2：故障后是否仍出现 +Cs1/-Cs2 false bias？**

是。fault-induced bias 为 `+4.8884/-4.8817 pF`。

**Q3：true drift 与 fault-induced bias 各是多少？**

true drift 为 `+3/-2 pF`；pre residual 为 `-0.0578/+0.0569 pF`；fault-induced false bias 为 `+4.8884/-4.8817 pF`，三者已独立列出。

**Q4：Case06 eta_geom 是否与 Case05 接近？**

不仅接近，而且在数值精度内相同；post mean 差 `1.67e-16`。

**Q5：static Delta c_LS,f 是否预测方向和数量级？**

是。steady 预测 `+4.8866/-4.8866 pF`，与递归 fault-induced `+4.8884/-4.8817 pF` 同方向、同数量级。

**Q6：双分支 replay 是否解释正式 +5.0063/-4.9773 pF 的主要部分？**

是。fault-induced 部分解释约 `97.65%/98.08%`；剩余为 `+0.1179/-0.0957 pF` 的 counterfactual background。

**Q7：lambda、rate limit、projection、J/h mismatch 是否显著改变？**

lambda contribution 从 `2.72%` 小幅升至 `3.30%`，仍属次要；rate/projection 均为 0；J/h mismatch 与 Case05 同量级。

**Q8：counterfactual Cs trajectory 是否恢复 fault factor？**

是，从 `1.4023` 恢复到 `1.6026`，真值为 `1.6000`。

**Q9：false coupling compensation 是否仍与 fault 基波近同相？**

是。幅值比 `0.33323`、相位差 `0.0683°`、相关系数 `0.90904`。

**Q10：Case05/Case06 是否支持同一 fault absorption mechanism？**

是。geometry、static bias、recursive fault-induced bias、false compensation 和 fault-retention loss 均定量一致。

**Q11：真实 Cs drift 改变 absorbability，还是只改变工作点/历史？**

本次数据支持后者：X/r_fault geometry 没有改变，主要变化体现在 pre-fault 参数工作点、lambda/J/h 历史和小量 counterfactual background。

**Q12：是否支持进入 Phase 1B-4？**

是。Case06 已完成独立外部验证；可进入受控因素实验，但本步骤没有执行 Phase 1B-4。

## 15. Limitations

- 这是第二个确定性工况的 external verification，不等同于 Monte Carlo 或完整鲁棒性证明。
- Case05/Case06 使用相同 voltage/reference geometry 与 fault waveform，所以可以检验 Cs 工作点/历史的影响，但不能检验不同电压几何、故障相位或幅值。
- counterfactual-parameter factor 的 `+0.1655%` 残差表明正常估计残差、模型残差和谐波残差仍存在，不能宣称完全无误差。
- Simulink 运行保留了既有未连接 Current Measurement 端口与代数环警告；没有 error，正式回归和哈希均通过。本步骤未为消除警告修改 AutoComp9。

## 16. Outputs and commands

新增代码：

- `step3/run_phase1b_step3_case06.m`
- `step3/generate_phase1b_step3_figures.m`

正式结果：

- `step3/case06_mechanism_summary.csv`：165 周期，Phase 1B mechanism schema v1
- `step3/case06_key_metrics.csv`
- `step3/case06_mechanism_workspace.mat`
- `step3/observation_blocks_case06.mat`
- `step3/case05_case06_comparison.csv`
- `step3/figures/figure1...figure6`：每张均保存 `.png` 和 `.fig`

运行命令：

```matlab
addpath(fullfile(pwd,'paper_research','phase1b_fault_absorption','step3'));
run_phase1b_step3_case06;
```

图形调整只重新加载已有 `case06_mechanism_workspace.mat`，没有重跑仿真。两个新增 `.m` 文件最终 `checkcode` 为 0 issues。

## 17. Step 3 acceptance

| 条件 | 结果 | 证据 |
|---|---|---|
| A. Phase1A integrity | PASS | frozen hashes unchanged；formal replay all zero |
| B. Step2 artifacts unchanged | PASS | report 与四个关键产物哈希前后一致 |
| C. instrumentation replay | PASS | 所有要求字段 max diff = 0 |
| D. pre-fault drift separated | PASS | true drift、pre residual、fault bias 独立量化 |
| E. strict r_fault | PASS | 3000×2 / 3000×1；identity 2.17e-19 A |
| F. eta_geom | PASS | ramp/post/range 与投影闭合完整 |
| G. static Delta c_LS,f | PASS | first/ramp/steady 均已计算 |
| H. recursive dual replay | PASS | fault/counterfactual/lambda-neutral 全部完成 |
| I. fault-induced bias separated | PASS | `+4.8884/-4.8817 pF` |
| J. retention loss linked to false bias | PASS | M2 1.4023；几何与错误补偿闭环 |
| K. counterfactual recovery | PASS | 恢复到 1.6026，真值 1.6000 |
| L. Case05/06 comparison | PASS | 18 项正式 comparison CSV |
| M. lambda/rate/projection/J-h | PASS | 3.30%；0/0 cycles；mismatch 同量级 |
| N. figures/results saved | PASS | 6 对图 + CSV/MAT 全部存在 |
| O. no forbidden modification | PASS | AutoComp9/Phase1A/Step1/Step2 哈希不变；未执行禁项 |

```text
STEP3_CASE06_VERIFICATION: PASS
```

ready for Phase 1B-4 Controlled Factor Experiments
