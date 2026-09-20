# Phase 2 Step 1A — Historical Audit & Variable Dictionary

## 1. Scope and status

本步骤只做 Phase 1A/1B/1C 正式资产的历史事实审计、变量字典、指标字典和可复用证据盘点。没有运行新的 Phase 2 仿真，没有执行 Monte-Carlo，没有进入 Step 1B，也没有修改模型、算法、Case、参数、评价窗口或历史结果。

审计基准：

- 正式模型：`AI6109_MOA_AutoComp9.slx`
- 正式生产算法：M0、M2、M3、M4
- M4：Residual-Evidence Weighted Adaptive Identification（REW-AI）
- M4 version：`paper_method_v1`
- formal validator：19/19 PASS
- historical regression：11/11 PASS
- Phase 1C freeze manifest：当前 9/9 SHA-256 匹配

本步骤新建的六个文件均位于 `paper_research/phase2_full_validation/step1_matrix_spec/`，它们是 Step 1 中间文件，不是 Phase 2 最终冻结矩阵。

## 2. Formal evidence reviewed

优先正式报告：

- `paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md`
- `paper_research/phase1b_fault_absorption/PHASE1B_FAULT_ABSORPTION_REPORT.md`
- `paper_research/phase1c_m4_method/PHASE1C_M4_METHOD_REPORT.md`
- `paper_research/phase1c_m4_method/STEP6_ABLATION_AND_FREEZE.md`
- `paper_research/phase1c_m4_method/step6_ablation/PAPER_METHOD_V1_FREEZE.md`

直接对应的正式事实来源包括：

- `phase1a_case_registry.m`、`generate_coupling_signals.m`、`run_phase1a_baseline.m`；
- `evaluate_phase1a_metrics.m`、`evaluate_case_metrics.m`；
- Phase 1B Step 2–5 runner、counterfactual replay、CSV、MAT 定义；
- Case07/08 specification、definition、signal builder、evaluator；
- Phase 1C Step3/4/5/5B/6 CSV 和 configuration snapshot；
- `build_phase2_model.m`、`simulate_phase2_case.m`、`reconstruct_refs_from_b.m`、`coupling_regressor.m`、`extract_resistive_current.m`。

旧 `results_phase1` 鲁棒性结果只作为 pre-unified historical evidence 盘点，未混入 Phase 1A/B/C 的正式性能结论。

## 3. Case inventory conclusion

Case01–Case08 均找到可追溯定义。完整字段见 `STEP1A_CASE_INVENTORY.csv`。

| Case | 正式角色 | 核心 truth | fault | 正式窗口 |
|---|---|---|---|---|
| Case01 | static healthy anchor | Cs `[10,10] pF` | 无 | global/steady |
| Case02 | slow drift anchor | `[10,10] -> [14,7] pF`, 1–3 s | 无 | global + Step3 phases |
| Case03 | smooth transition anchor | `[10,10] -> [15,6] pF`, 1.45–1.65 s | 无 | global + transition phases |
| Case04 | seeded random drift | sinusoidal + moving-average random path | 无 | global + random phases |
| Case05 | pure fault anchor | constant `[10,10] pF` | B factor 1.60, 3.00–3.06 s rise, then held | pre/post |
| Case06 | drift then fault | `[10,10] -> [13,8] pF`, 0.8–2.2 s | same persistent factor 1.60 | pre/post |
| Case07 | weak overlap | same `[+3,-2] pF` drift | temporary factor 1.30, 1.50–1.96 s | W0–W4 |
| Case08 | triggered overlap | same `[+3,-2] pF` drift | temporary factor 1.60, 1.50–1.96 s | W0–W4 + gate interval |

没有发现 Case09 或更高编号的正式冻结 Case。

## 4. Case05–Case08 focused recovery

### 4.1 Case05 — pure fault

- fault factor：1.60；`1.0` 表示无故障；
- B 相真实阻性电流在 3.00–3.06 s 以 cubic smoothstep 上升，之后保持到仿真结束；
- Cs truth：`[10,10] pF` 常数；
- seed：106；SNR：30 dB；reference phase error：0°；
- fault metric windows：pre `[2.60,2.90)`，post `[3.40,3.80)`；
- Phase 1A 有 M0/M2/M3，Phase 1C Step4 有 M2/M3/M4，Step6 有 M4 ablation；
- M2/M3/M4 正式结果可以直接作为冻结 anchor 复用。

### 4.2 Case06 — drift then fault

- drift：0.80–2.20 s cubic smoothstep；
- total drift vector：`[+3,-2] pF`，L2=`sqrt(13)=3.605551275 pF`；
- 平均向量率：`[+2.142857,-1.428571] pF/s`，L2=`2.575393768 pF/s`；
- fault：与 Case05 相同，factor 1.60，3.00–3.06 s 上升并保持；
- metric windows：pre `[2.60,2.90)`，post `[3.40,3.80)`；
- Phase 1A/1B/1C 的 M0/M2/M3/M4 证据均可追溯。

### 4.3 Case07 — weak overlap

- drift：0.80–2.20 s，`[+3,-2] pF`；
- temporary B fault：factor 1.30；
- onset 1.50 s；ramp-up 1.50–1.56 s；plateau 1.56–1.90 s；ramp-down 1.90–1.96 s；
- W0 `[1.20,1.45)`；W1 `[1.62,1.74)`；W2 `[1.74,1.88)`；W3 `[1.98,2.18)`；W4 `[2.40,2.80)`；
- M3 hard gate 正式记录为未触发：W1/W2 overlap active ratio=0；M3 与 M2 相同；
- M4 W1/W2 combined mean `g=0.5455229423`；
- Phase 1C 报告用于方向诊断的 W0-end 到 W2-end true movement 为约 `[+1.2619,-0.8413] pF`。

### 4.4 Case08 — triggered overlap

Case08 相对 Case07 唯一物理改变是 factor `1.30 -> 1.60`。其余模型、seed、noise replay、Cs truth、fault timing、reference 和 W0–W4 全部相同。

正式结果：

- M3 W1 gate active ratio：1；
- M3 W2 gate active ratio：1；
- M3 W1/W2 combined active ratio：1；
- M4 W1/W2 mean `g=0.3600409602`；
- exact M3 gate interval：`[1.55998,2.39998] s`；
- 该 interval 的 true Cs movement：`[+1.307678974,-0.871785983] pF`；
- M4 同 interval F movement：`[+0.477524546,+0.045153713] pF`；
- M4 CF movement：`[+1.396625413,-0.889634734] pF`；
- 两者差：`[-0.919100867,+0.934788447] pF`。

Case08 temporary fault active window相对 true drift window `[0.80,2.20] s` 的 normalized position：

```text
normalized start = (1.50 - 0.80) / (2.20 - 0.80)
                 = 0.5000000000

normalized end   = (1.96 - 0.80) / (2.20 - 0.80)
                 = 0.8285714286
```

补充位置：ramp-up end 为 `0.5428571429`，plateau end 为 `0.7857142857`。这些值仅为对冻结 Case08 的真实换算，没有修改 Case08。

## 5. Nominal drift vectors

项目不存在一个适用于所有 case 的唯一 nominal vector：

| Context | Delta Cs vector / pF | L2 / pF |
|---|---:|---:|
| Case02 normal slow drift | `[+4,-3]` | 5.000000 |
| Case03 transition | `[+5,-4]` | 6.403124 |
| Case06/07/08 drift family | `[+3,-2]` | 3.605551 |

若 Phase 2 所称 nominal drift 指 overlap family，则正式值是 `[+3,-2] pF`。Case04 没有单一 terminal vector。

## 6. Variable findings

完整字典见 `STEP1A_VARIABLE_DICTIONARY.csv`。

### 6.1 Reference phase error

Phase 1B 的正式定义是：

```text
phi1_used = phi1_fitted + deg2rad(delta)
phi3_used = phi3_fitted + 3*deg2rad(delta)
```

- 单位：degree；
- 正号：重构参考超前；
- 只修改 reconstructed reference、X 和补偿模型；
- 不修改 Simulink physical voltage、fault waveform 或 noise；
- A/C fundamental 仍相对 B 为 ±120°；
- third harmonic 仍为三相同相；
- 它是 coherent time-shift definition，不是独立 50/150 Hz 传感器相位响应。

正式 phase-error values 为：`0, 0.33, 0.5, 1, 2, 3 deg`。因此题示的 0.33°、0.5°、1°、2°、3°全部有 Phase 1B 正式历史依据。

术语关系：

- `reference phase error`：上述精确定义；
- Phase 1B phase sweep 中的 `phase mismatch`：指上述注入造成的 mismatch；
- `reference/model mismatch`：更宽泛的上位概念，并非一个单独冻结变量，不能与 phase error 普遍视为同义。

### 6.2 Noise / SNR

正式 current-noise path：

```text
noise = rms(ideal total leakage current) / 10^(SNR_dB/20) * randn
```

- A/B/C 分别生成 Gaussian white noise；
- 加在 AutoComp9 总泄漏电流输出链的三个 noise external inputs；
- 不加在 voltage/reference、true resistive current 或 Cs truth；
- SNR 针对每相 ideal total leakage current 的 RMS；
- case seed 的正式噪声偏移为 `seed+10000`；
- 同一 case 内各算法共享完全相同 data；Case07/08 的 F/CF 共享完全相同三相 noise vectors。

Phase 1A-C 的正式运行点是 30 dB。`SNR=Inf` 在 Case07/08 noise replay 中用作差分恢复 clean run，不是正式性能 level。旧 pre-unified Phase1 曾执行 `Inf/40/30/20 dB × 30 seeds`，但不能当作 paper_method_v1 的正式 robustness 结果。

### 6.3 Third harmonic

- `h3_ratio`：第三谐波电压幅值/基波幅值；正式默认 0.05；
- `phi3_deg`：物理第三谐波相位；正式默认 0°；
- 两者均传给 AutoComp9；
- reference reconstruction 联合拟合 50/150 Hz；
- 当前三相 third harmonic reference 同相，因此公共三次谐波在 AB/BC derivative differences 中理论上抵消，但仍进入 self-capacitance subtraction 和 residual evidence。

接口存在，但 Phase 1A-C 没有 M4 harmonic robustness sweep。旧历史 range 只能列为 `PARTIAL_REUSE`。

### 6.4 Negative sequence

`Vneg_pu` 的正式配置含义是负序电压标幺比，默认 0，且传入 AutoComp9。正式 Phase 1A-C 没有 negative-sequence sweep。旧历史 scan 为 0/1%/3%/5%，已揭示单 B 相参考的可观测性边界。

本次读取到的正式源码/报告没有给出 AutoComp9 内部负序相位序列的精确数学式，因此内部 convention 标记 `UNRESOLVED`，不根据变量名补写。

### 6.5 Cself

- truth：AutoComp9 `Cself_pF=(C0+C_moa)*1e12=400 pF`；
- algorithm assumption：`selfPF=[400,400,400] pF`；
- algorithm 不在线估计 Cself。

低层函数上两者可以分开传值，但所有正式 runner 都从同一 cfg 同时生成 truth 与 assumption。因此当前没有冻结的 independent mismatch condition。要做 Phase 2 Cself mismatch，Step 1B 必须先冻结双变量传递和符号约定。

### 6.6 CsAC

AutoComp9 formal equation只有 AB/BC：

```text
iA = Cself*duA + Cs1*(duA-duB) + ...
iB = Cself*duB + Cs1*(duB-duA) + Cs2*(duB-duC) + ...
iC = Cself*duC + Cs2*(duC-duB) + ...
```

Estimator 也只有两列 `Cs1=AB`、`Cs2=BC`。当前没有 CsAC truth port、current term或独立注入接口。因此不能在现有正式路径中无修改地独立注入 CsAC。AutoComp9 本身不得修改。

## 7. Evaluation-window inventory

| Family | Window | Formal use |
|---|---|---|
| global | `[0.80,4.00]` | Phase1A Cs RMSE、B fundamental error |
| fault pre | `[2.60,2.90)` | Case05/06 baseline |
| fault post | `[3.40,3.80)` | Case05/06 steady fault |
| W0 | `[1.20,1.45)` | pre-fault active drift |
| W1 | `[1.62,1.74)` | overlap early |
| W2 | `[1.74,1.88)` | overlap late |
| W3 | `[1.98,2.18)` | post-fault active drift |
| W4 | `[2.40,2.80)` | post-drift recovery |
| Case08 gate interval | `[1.55998,2.39998]` endpoint sampling convention | triggered hard-gate movement |

所有窗口必须保持算法间相同；跨 family 的同名指标必须保留 window metadata。

## 8. Counterfactual audit

### 8.1 Phase 1B M2 replay

Phase 1B 严格构造 `r_fault`，然后：

- F branch 使用 `y_fault`；
- CF branch 使用 `y_fault-r_fault`；
- fault 前共享状态；
- fault 后各自递归，不逐周期重置；
- 只删除 B 相 fault observation component，保留 X、正常残差、noise 和真实 Cs path。

M2 没有 protection schedule，因此这里的 recursive F-CF difference 是当前冻结定义下的 fault-induced recursive effect。

### 8.2 Phase 1C matched F/CF

Case07/08 使用两套 matched data：

- F：drift/reference/noise + temporary fault；
- CF：完全相同但 `fault_scale=1`；
- 每个算法分别在 F/CF 上完整运行。

对 M3/M4，fault 还会改变 gate/`g`，从而改变 drift learning。故 `c_F-c_CF` 同时混合：

1. direct fault-related parameter effect；
2. fault-triggered protection caused drift-learning reduction。

Step5B 已明确 optional protection-schedule replay 未执行。因此正式审计结论是：

```text
CAUSAL_CONFOUNDING_REMAINS
```

本步骤不修复，也不创建新算法。Step 1B 可据此决定是否预注册 Protection-Schedule Counterfactual Replay。

## 9. Candidate-axis audit

| Axis | 现有接口 | Phase 1 正式证据 | 候选范围依据 | 主要混杂 | Step 1B freeze |
|---|---|---|---|---|---|
| Fault amplitude | 有 | Phase1B M2 single-seed sweep | 1.05–1.60 有正式依据 | noise RMS rescale；无 M3/M4 full sweep | 需要 |
| Noise/SNR | 有 | 正式仅 30 dB | Inf/40/30/20 仅旧历史 | realization pairing、绝对 noise level | 需要 |
| Reference phase error | 有 | 0–3° 正式 M2 sweep | 全部候选值有依据 | normal bias + X/compensation rotation | 定义可复用，矩阵仍需冻结 |
| Third harmonic | 有 | 正式仅 5%/0° | 扫描范围仅旧历史 | ideal voltage/reference共源 | 需要 |
| Negative sequence | 有 | 无 Phase1A-C sweep | 0/1/3/5% 仅旧历史 | 单 B 相不可观测；无 validity gate | 需要 |
| Cself mismatch | 低层可分、runner 未分 | 无 | 无正式 range | truth/assumption易被一起改 | 需要 |
| CsAC weak coupling | 无正式 port | 无 | 无正式 range | 会改变模型结构/证据来源 | 需要 |
| Drift rate | case code可改 | 多 case 非单因素 | 无正式 controlled levels | rate 与 total delta/direction/timing | 需要 |
| Overlap fault factor | 有 Case07/08 | 1.30/1.60 两点 | 两个 frozen anchors | factor改变 protection schedule | 需要 |
| Drift direction | case code可改 | 三个固定方向 + random | 无 controlled rotation | magnitude/rate/timing共同变化 | 需要 |
| Monte-Carlo | seed机制有 | paper_method_v1 无 MC | 旧 SNR 30 seeds precedent | truth seed/noise seed角色不同 | 需要 |

## 10. Variable-confounding checklist

| Risk | Audit finding |
|---|---|
| A. drift rate 改变是否同时改变 total Delta Cs | 当前跨 case 比较会；必须在后续 one-factor design 中固定 total vector |
| B. reference phase error 是否同时改变其他 mismatch | 它只改 reference，但同时改变 X、自电容扣除残差与补偿方向；不是纯 fault geometry axis |
| C. Cself truth/algorithm 是否一起改 | 现有 runner 是；必须拆分后才能研究 mismatch |
| D. noise 是否对所有算法相同 | Phase1A 同 case 是；Case07/08 F/CF 也是；未来 MC 必须保持 paired data |
| E. fault factor 是否改变 timing/ramp | Phase1B wrapper 不改变 timing/ramp；Case07/08 两点也只改 factor |
| F. drift direction 是否同时改变 magnitude | 现有 Case02/03/06 family 是；不能据此归因 direction |
| G. 算法 evaluation window 是否一致 | 每个正式 condition 内一致；不同 case family 的窗口不同 |
| H. 算法是否共享同一 condition data | Phase1A 是；Case07/08每个 branch内是；Phase1B amplitude/phase只正式运行 M2 |

## 11. Reusable evidence conclusion

详细分类见 `STEP1A_REUSABLE_EVIDENCE.csv`。

### EXACT_REUSE

以下冻结 anchor 在其原有 condition、algorithm version、metric definition 和 window 内无需重跑：

- Case01–Case06 的 Phase1A baseline rows；
- Case01–Case04 的 Phase1C M4 normal-tracking rows；
- Case05/06 的 Phase1C M2/M3/M4 fault-preservation rows；
- Case07/08 的 Phase1C overlap rows；
- Step6 对 Case02/05/07/08 的正式 ablation/freeze evidence。

如果 Phase 2 Step1D 改变 metric schema 或要求缺失算法，这些 anchor 只能转为 `PARTIAL_REUSE`，不能静默重命名字段。

### PARTIAL_REUSE

- Phase1B fault-amplitude与 phase-error sweep：正式，但只有 M2 mechanism schema、single seed；
- 旧 SNR/harmonic/negative-sequence sweep：有范围和 failure-boundary价值，但不是 Phase1A-C unified M0/M2/M3/M4 evidence；
- drift-rate/direction：有多个历史 case，但不是 controlled one-factor sweep；
- overlap factor：只有 1.30/1.60 两点。

### RERUN_REQUIRED

- paper_method_v1 的 multi-SNR/Monte-Carlo；
- M4 harmonic/negative-sequence robustness；
- Cself mismatch；
- CsAC mismatch；
- controlled drift-rate/direction；
- 需要统一 Phase2 schema 的新条件。

### UNRESOLVED

- protection-schedule counterfactual replay；
- negative-sequence内部相位 convention；
- Phase2 最终 axis/level/统计/threshold；
- 新指标定义。

## 12. Required final answers

1. **是否修改任何 frozen source？** 否。只新增 Step1A 六个中间文件。
2. **是否运行新的 Phase 2 仿真？** 否。没有调用 `sim`。只进行文件读取、哈希核对；一次只读模型参数定位失败，未产生结果。
3. **Case01–Case08 是否全部找到正式定义？** 是。Case01–06 来自 Phase1A registry/generator；Case07/08 有独立冻结 specification/definition。
4. **Case05–08 是否完整恢复？** 是，fault、drift、seed、noise、reference、窗口和正式输出均恢复；Case05/06 为 persistent fault，Case07/08 为 temporary fault。
5. **nominal Cs drift vector 是多少？** overlap/Case06 family 为 `[+3,-2] pF`，L2 3.605551 pF；Case02 anchor 为 `[+4,-3] pF`，L2 5 pF。不存在全项目唯一 nominal vector。
6. **Case08 normalized fault/drift position？** start=`0.5`，end=`0.8285714286`，按 onset 1.50 s 到 clear 1.96 s 相对 drift 0.80–2.20 s 计算。
7. **reference_phase_error 正式定义？** 只推进重构参考：50 Hz `+delta`，150 Hz `+3delta`，正号为 reference lead；不改 physical data/noise/fault。
8. **Phase 1 正式 phase-error values？** `0,0.33,0.5,1,2,3 deg`。
9. **noise/SNR 当前如何定义？** 每相 total leakage current 的 additive white Gaussian noise，sigma=`rms(ideal total current)/10^(SNR/20)`；正式 nominal 30 dB；固定 seed offset +10000。
10. **harmonic 是否已有可靠接口？** 参数入口可靠，正式 nominal 为 5%/0°；没有 Phase1A-C 的 M4 harmonic robustness sweep。
11. **negative sequence 是否已有可靠接口？** `Vneg_pu` 参数入口存在，算法无 validity gate；内部精确序分量相位 convention 在正式文本中未解析，标记 `UNRESOLVED`。
12. **Cself truth/algorithm assumption 是否可独立控制？** 低层函数上可以分开，但正式 runner 未分开，尚无冻结独立控制 schema。
13. **CsAC 是否可在不修改 AutoComp9 下独立注入？** 现有正式接口不可以；无 port/term/estimator column。
14. **counterfactual 是否仍有 causal confounding？** 是。Phase1C M3/M4 的 F-CF 差包含 protection-schedule-mediated learning difference；`CAUSAL_CONFOUNDING_REMAINS`。
15. **哪些 Phase 1 条件可以 EXACT_REUSE？** Case01–08 各自冻结 anchor及 Step6 ablation，在其原 schema/window内可以；跨 Phase2 新 schema 是否 exact 需 Step1D确认。
16. **有哪些 UNRESOLVED？** 见 `STEP1A_UNRESOLVED_ITEMS.md`，核心包括负序内部 convention、Cself split schema、CsAC path、controlled rate/direction、counterfactual schedule replay和新指标。
17. **是否发现候选值缺少历史/代码依据？** 是。Cself mismatch levels、CsAC levels、controlled drift-rate/direction levels、Monte-Carlo联合分布均无正式范围；SNR/harmonic/negative-sequence候选范围只有旧 pre-unified历史依据，不是 Phase1A-C完整算法证据。Phase-error候选值全部有正式依据。

## 13. Step 1A stop condition

```text
STEP 1A STATUS: COMPLETE
NEW PHASE 2 SIMULATION: NO
FROZEN SOURCE MODIFIED: NO
STEP 1B STARTED: NO
```

本步骤在此停止，等待人工验收。
