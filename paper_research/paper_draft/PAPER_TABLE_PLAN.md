# 论文表格规划

## 0. 总体原则

正文暂定 5 张表。表格只承载需要精确查阅的定义、参数、工况与限定性结论；趋势和分布优先用图。若投稿版面受限，Table 3 的完整矩阵移入补充材料，正文仅保留精简版。

路径约定：缩写路径 `phase1a_baseline/`、`phase1b_fault_absorption/`、`phase1c_m4_method/`、`phase2_full_validation/` 均相对于项目目录 `paper_research/`。

## Table 1 三相 MOA、coupling model 与算法主要参数

- **Scientific purpose：** 给出复现实验和理解方程所需的物理、采样、回归、VFF、约束、M3 与 M4 参数，不把 case-specific truth 与 algorithm parameter 混为一类。
- **Planned columns：** 类别；参数/符号；冻结值；单位；物理/算法含义；来源；是否在 Phase 1C 调整。
- **Core rows：** `f=50 Hz`、`dt=2e-5 s`、`Cself_algorithm=400 pF`、初始 `Cs1/Cs2=10/10 pF`、`lambda_min/max=0.55/0.995`、rate limit `1.2 pF/cycle`、projection `[0,40] pF`、`gate_ratio=1.12`、`gate_quad_ratio=1.20`、`gate_hold_cycles=25`、baseIn alpha `0.015`、baseIn condition `1.08`、regularization `1e-10`。
- **Source files：** `paper_research/phase1c_m4_method/step6_ablation/tables/parameter_table.csv`；`step6_ablation/PAPER_METHOD_V1_FREEZE.md`；`paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md`；`MATLAB一键实验/patent_default_config.m`。
- **Expected claim：** M4 继承 M2/M3 既有参数，Phase 1C 新 fitted/tuned parameters=0；方法差异来自信息状态更新机制。
- **Caution：** 不把固定 case definition 写成“最优参数”；不暗示 Cself truth 永远等于 400 pF；只列正文真正使用的参数，完整内部常量可放补充材料。
- **Hardware supplement：** 后续实验参数另设表，不与仿真参数混写。

## Table 2 M0/M2/M3/M4 方法结构与作用机制

- **Scientific purpose：** 客观比较四种方法的更新方式、保护机制、已验证作用和已知失败模式，不给总分或“最好”标签。
- **Planned columns：** 方法；参数更新；fault protection；fault 下 adaptation；正常 tracking；weak-fault behavior；强故障 behavior；主要限制；正式证据。
- **Planned content：**
  - M0：初始化后固定；无 fault absorption，但动态 coupling tracking 弱；
  - M2：持续 VFF-RLS；tracking 强；易 fault absorption；
  - M3：hard gate；触发后保护强；可能 weak-fault miss 与 hard-freeze drift loss；
  - M4/REW-AI：`0<g<=1` 连续 information-state weighting；相对 M2 减少部分吸收并保留非零更新；强故障保护通常弱于触发后的 M3，仍有 residual contamination。
- **Source files：** `paper_research/phase1a_baseline/PHASE1A_BASELINE_REPORT.md`；`paper_research/phase1c_m4_method/PHASE1C_M4_METHOD_REPORT.md`；`step6_ablation/tables/phase1c_method_summary.csv`；`phase2_full_validation/step7_final_analysis/PHASE2_FINAL_ANALYSIS.md`。
- **Expected claim：** M3 与 M4 是不同 protection–adaptation trade-offs，不是线性升级或全面替代关系。
- **Caution：** 禁止出现综合评分、星级、winner、best/optimal；`direction diagnostic` 不列为 M4 control feature；phase-consistency contribution 标记“独立贡献未证明”。
- **Hardware supplement：** 可在实验完成后增加“硬件趋势是否复现”一列，但当前留空或不设置该列。

## Table 3 Deterministic experimental matrix

- **Scientific purpose：** 让读者快速看到 representative cases、Phase 2 deterministic factors、overlap/replay 与 sensitivity 的覆盖范围和复用关系。
- **Planned columns：** 证据层；family/case；水平或范围；anchor；算法；主要指标；物理条件数；正式 source；解释限制。
- **Core rows：**
  - Phase 1A Case01–06；
  - Phase 1C Case07 weak overlap、Case08 triggered overlap；
  - fault factor 1.05–1.60（fault-only / drift-then-fault）；
  - SNR `Inf/40/30/20 dB`；
  - reference phase `0/0.33/0.5/1/2/3°`；
  - third harmonic `0.5/2/5/8/10%`；
  - negative sequence `0/1/3/5%`；
  - Cself `-10%…+10%`；CsAC `0…3 pF`；
  - overlap rate `0.5/1/2×`、factor `1.10/1.30/1.60`、direction D1/D2/D3；
  - Case08 F/N/P/A；
  - registered sensitivity low/nominal/high。
- **Source files：** `paper_research/phase2_full_validation/step1_matrix_spec/phase2_condition_registry.csv`；`paper_research/phase2_full_validation/step1_matrix_spec/STEP1_PHASE2_MATRIX_SPECIFICATION.md`；各 Step 2B-2 至 Step 5 结果 CSV。
- **Expected claim：** Phase 2 按预注册矩阵验证 robustness/generalization，不调 M4；失败工况与边界全部保留。
- **Caution：** 204 total physical/stochastic conditions 不等于 deterministic count；839 registry records 不等于 839 new simulations；negative sequence 标注 `CONFIGURED_VALIDITY_BOUNDARY_ONLY`。
- **Hardware supplement：** 否；低压 Experiment A/B/C 单独描述，不要求复制本矩阵。
- **版面策略：** 正文若过密，只保留 factor family 与 range；完整 case/condition IDs 移入补充材料。

## Table 4 Monte-Carlo cohort definitions 与 uncertainty ranges

- **Scientific purpose：** 说明 H/F/O cohort 的科学角色、随机因素、固定因素、样本量和主要统计指标，使 Fig.8 的配对分布可解释。
- **Planned columns：** cohort；scientific role；随机变量；固定/排除变量；N physical conditions；algorithms；primary metrics；统计摘要；解释边界。
- **Core rows：**
  - H：SNR、reference phase、drift rate、Cself mismatch；健康/漂移；
  - F：SNR、reference phase、fault factor、Cself mismatch；persistent fault；
  - O：SNR、reference phase、fault factor、drift rate、Cself mismatch；overlap。
- **Required statistics in table：** 每组 N=50；总 150 conditions/600 evaluations；H M4 USR mean/P95；F M3 trigger/miss count 与 M4 对 M2 配对改善计数；O M4 对 M2/M3 配对计数、reverse movement count 与 AUC；0 numerical failures。
- **Source files：** `paper_research/phase2_full_validation/step1_matrix_spec/STEP1C_MC_REGISTRY_SPEC.md`；`paper_research/phase2_full_validation/step1_matrix_spec/phase2_condition_registry.csv`；`paper_research/phase2_full_validation/step6_monte_carlo_full/step6_monte_carlo_full_results.csv`；`paper_research/phase2_full_validation/step6_monte_carlo_full/STEP6_MONTE_CARLO_FULL.md`。
- **Expected claim：** MC 为 Phase 1 representative conclusions 提供同一冻结仿真框架内的统计外部验证，不形成总体算法排名。
- **Caution：** 不写“external experimental validation”；fault onset、initial Cs、drift amplitude、negative sequence 与 CsAC 不在 primary MC，必须在表中列为 excluded/fixed；improvement counts 不称胜率。
- **Hardware supplement：** 无需硬件复刻 Monte-Carlo；实验章节另给少量代表性重复与不确定度。

## Table 5 主要结论、适用范围与 limitation summary

- **Scientific purpose：** 把正文允许陈述的结论与边界并列，防止摘要、讨论和结论超出数据支持。
- **Planned columns：** claim；evidence strength；关键数值；适用条件；allowed wording；主要 limitation；需硬件验证；关联 Figure/Section。
- **Core rows：** fault absorption mechanism；M3 threshold/weak miss；M3 hard-freeze drift loss；M4 continuous weighting；M4 相对 M2 的部分改善；M3/M4 trade-off；reference phase boundary；Cself/CsAC mismatch；negative sequence unresolved；counterfactual cancellation；MC H/F/O；低压实验缺口。
- **Source files：** `paper_research/phase2_full_validation/step7_final_analysis/PAPER_RESULT_MAP.csv`；本阶段 `paper_research/paper_draft/PAPER_EVIDENCE_MAPPING.md`。
- **Expected claim：** 正文贡献与限制具有一一对应的正式证据来源和措辞边界。
- **Caution：** Table 5 不重复 Table 2 的结构比较；它服务于 claim discipline。`STRONG` 也只表示冻结证据体系内强支持，不表示现场普适性。
- **Hardware supplement：** 是；Experiment A/B/C 完成后更新“需硬件验证”状态，但不得改写既有仿真负结果。

## 6. 表间去重与删减规则

| 若出现冲突 | 保留 | 移动/删除 |
|---|---|---|
| Table 1 与方法公式重复 | Table 1 保留数值与来源 | 公式留正文 3.5 |
| Table 2 与 Fig.1 重复 | Fig.1 讲因果和状态流，Table 2 讲结构差异与限制 | 删除表中流程图式长句 |
| Table 3 与 Fig.3/5/7 重复 | Table 3 只给覆盖范围 | 数值趋势留图 |
| Table 4 与 Fig.8 重复 | Table 4 给 cohort design，Fig.8 给 distribution | 不在 Table 4 堆全部分位数 |
| Table 5 与 Evidence Mapping 重复 | Table 5 只给正文精简版 | 完整 allowed/forbidden wording 留 `PAPER_EVIDENCE_MAPPING.md` |

## 7. 推荐正文优先级

1. 必留：Table 1、Table 2、Table 4、Table 5。
2. 可压缩或转补充材料：Table 3。
3. 不建议新增“所有算法所有工况数值总表”；完整数据已由正式 CSV 与补充材料承担。
