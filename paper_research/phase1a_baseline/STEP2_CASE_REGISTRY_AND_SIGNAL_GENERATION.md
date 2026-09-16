# Phase 1A — Step 2：Unified Case Registry and Signal Generation

执行日期：2026-09-16  
执行范围：统一六个正式 case 与 AutoComp9 输入信号生成；仅执行纯 MATLAB 信号级测试，未调用 `sim`、未加载或运行 AutoComp9、未进入 algorithm mode。

## 1. Step 1 checkpoint

开始 Step 2 前，`git status --short --untracked-files=all` 仅包含 Step 1 已验收的六个新增文件，没有额外变更。随后按要求建立 checkpoint：

| 项目 | 值 |
|---|---|
| commit | `31885f11eebc3b5f2cb3d3414a02ff96fa179e89` |
| subject | `paper: freeze Phase 1A baseline scaffold` |
| timestamp | `2026-09-16T16:32:24+08:00` |

## 2. Step 2 修改文件

| 文件 | 动作 | 内容 |
|---|---|---|
| `MATLAB一键实验/generate_coupling_signals.m` | 修改 | 增加六个正式名 alias；迁移 smooth step/random drift；增加 fault only；Case05/06 共用 fault profile |
| `MATLAB一键实验/phase1a_case_registry.m` | 修改 | 冻结 Case05 seed=106，并更新 Case03/04/05 信号来源说明 |
| `MATLAB一键实验/tests/Phase1ACaseSignalTest.m` | 新增 | 七个 class-based 纯信号级测试，不调用 Simulink |
| `paper_research/phase1a_baseline/STEP2_CASE_REGISTRY_AND_SIGNAL_GENERATION.md` | 新增 | 本报告 |

未修改 AutoComp9、算法核心文件、Phase 2 入口或任何历史结果。

## 3. 六个正式 Case 定义、legacy mapping 与 seed

| 正式名称 | legacy 名称 | seed | 信号定义 | 历史结果 |
|---|---|---:|---|---|
| `Case01_static` | `static` | 101 | Cs1=10 pF，Cs2=10 pF，fault=1 | 有部分 AutoComp9/旧链证据 |
| `Case02_slow_drift` | `slow_drift` | 102 | 原 AutoComp9 slow drift，不变 | 有 AutoComp9 M0/M3 证据 |
| `Case03_smooth_step` | `smooth_step` | 103 | 旧 Phase 1 smooth step 公式原样迁移 | 有旧 MATLAB 合成链结果 |
| `Case04_random_drift` | `random_drift` | 104 | 旧 Phase 1 random drift 公式原样迁移 | 有旧 MATLAB 合成链结果 |
| `Case05_fault_only` | `fault_only` | 106 | Cs 固定；复用 Case06 fault profile | 无历史结果 |
| `Case06_drift_then_fault` | `fault_with_drift` | 105 | 原 AutoComp9 drift-then-fault，不变 | 有 AutoComp9 分散证据 |

`generate_coupling_signals` 先把正式名称归一到 legacy 名称，再进入唯一一套数学分支；没有复制六套公式，也没有删除或重命名 legacy scenario。

## 4. Case03 历史轨迹来源及迁移

来源：`MATLAB一键实验/synthesize_dynamic_case.m:21-23`。

原公式：

```matlab
s = smooth_step(t,1.45,1.65);
Cs1 = 10+5*s;
Cs2 = 10-4*s;
```

其中平滑函数保持为：

```matlab
x = min(max((t-t0)/(t1-t0),0),1);
y = x.^2.*(3-2*x);
```

迁移没有改变起止时间、幅值、边界裁剪、平滑函数、单位或向量方向。信号级验证确认：

- `t<=1.45 s`：Cs1=10 pF；
- `t>=1.65 s`：Cs1=15 pF、Cs2=6 pF；
- 正式名与 legacy 名三路输出最大差值均为 0。

## 5. Case04 历史轨迹来源及迁移

来源：`MATLAB一键实验/synthesize_dynamic_case.m:24-29`。迁移公式保持为：

```matlab
dt = median(diff(t));
s = smooth_step(t,0.5,1.0);
r = movmean(randn(size(t)),max(3,round(0.30/dt)));
r = (r-mean(r))/(std(r)+eps);
Cs1 = 10+s.*(1.5*sin(2*pi*0.25*t)+0.5*r);
Cs2 = 10+s.*(-1.2*sin(2*pi*0.20*t+0.7)+0.4*r);
```

正弦频率、相位、随机幅值、0.30 s moving-average、标准化、启用窗口和 `rng(seed)` 均未改变。使用正式 seed=104 连续生成两次：

```text
max(abs(Cs1_run1-Cs1_run2)) = 0
max(abs(Cs2_run1-Cs2_run2)) = 0
```

测试还用独立写出的旧公式逐样本比较，Cs1/Cs2 最大差值均为 0。

## 6. Case05 新增定义

Case05 是本轮唯一新增的物理工况，按指令冻结为：

```text
Cs1(t) = 10 pF
Cs2(t) = 10 pF
seed = 106
```

B 相故障不另写第二套数学定义，而是与 Case06 同时调用同一个局部 `fault_profile(t)`：

```matlab
faultScale = 1+0.6*smooth_step(t,3.0,3.06);
```

因此故障在 3.00–3.06 s 从 1.0 平滑过渡到 1.6。信号级范围验证为：

```text
Case05 Cs1 range = [10, 10] pF
Case05 Cs2 range = [10, 10] pF
Case05 fault range = [1, 1.6000000000000001]
```

Case05 仍保持 `historical_result_available=false`，其 registry 注释为：

```text
Phase 1A new deterministic seed; no historical Case05 result exists.
```

## 7. Case05/Case06 fault profile 一致性

Case05 和 Case06 通过同一 `fault_profile` 函数构造故障。使用完整 `0:2e-5:4 s` 时间向量比较：

```text
max(abs(Case05.fault_scale-Case06.fault_scale)) = 0
```

两者唯一的物理差异是 Case05 的 Cs1/Cs2 固定，而 Case06 继续使用原有 `0.8–2.2 s`、`+3/-2 pF` 耦合漂移。

## 8. Case01/02/06 legacy regression

旧分支的数值公式与 checkpoint 对照如下：

| legacy case | checkpoint 数学定义 | Step 2 状态 | 正式名/legacy 最大差值 |
|---|---|---|---:|
| `static` | 10/10 pF，fault=1 | 未改变 | 0 |
| `slow_drift` | smooth step 1.0–3.0 s；Cs1=10+4s，Cs2=10-3s | 未改变 | 0 |
| `fault_with_drift` | smooth step 0.8–2.2 s；Cs1=10+3s，Cs2=10-2s；fault 3.0–3.06 s 至 1.6 | 数学等价；fault 表达式抽取为共享函数 | 0 |

明确结论：

```text
Case01 legacy behavior changed? NO
Case02 legacy behavior changed? NO
Case06 legacy behavior changed? NO
```

Case06 的故障表达式虽从分支内移到 `fault_profile`，实际调用的 `smooth_step(t,3.0,3.06)` 和系数 `1+0.6*...` 完全相同；完整时间向量逐样本测试通过。

## 9. 信号级测试结果

测试文件：`MATLAB一键实验/tests/Phase1ACaseSignalTest.m`。

运行方式仅包含 `checkcode` 和 `runtests`。MATLAB MCP 无法附着现有会话后，改用允许的命令行 `matlab -batch`；命令中没有 `sim`、模型名或任何实验入口。

Code Analyzer：

| 文件 | issue 数 |
|---|---:|
| `generate_coupling_signals.m` | 0 |
| `phase1a_case_registry.m` | 0 |
| `tests/Phase1ACaseSignalTest.m` | 0 |

单元测试：

```text
7 passed / 0 failed / 0 incomplete
```

| 测试 | 结果 |
|---|---|
| Registry mappings and seeds | PASS |
| Static legacy and alias | PASS |
| Slow drift legacy and alias | PASS |
| Smooth step migration | PASS |
| Random drift migration and determinism | PASS |
| Fault-with-drift legacy and alias | PASS |
| Fault-only definition and shared profile | PASS |

六组正式名与 legacy 名的 Cs1、Cs2、fault 三路最大差值均为 0。测试采用完整 `duration=4.0 s`、`dt=2e-5 s` 时间向量。

## 10. Step 2 验收 A–N

| 编号 | 验收项 | 结果 | 依据 |
|---|---|---|---|
| A | 六个正式 Case 均存在唯一映射 | **PASS** | registry 与 alias 测试均为 6 条唯一映射 |
| B | Case01 static 旧轨迹未改变 | **PASS** | 显式公式和逐样本比较通过 |
| C | Case02 slow_drift 旧轨迹未改变 | **PASS** | 显式旧公式和逐样本比较通过 |
| D | Case06 fault_with_drift 旧轨迹未改变 | **PASS** | 原漂移公式及共享故障公式逐样本通过 |
| E | Case03 smooth_step 原样迁移 | **PASS** | 与 `synthesize_dynamic_case.m` 旧公式逐样本相等 |
| F | Case04 random_drift 原样迁移 | **PASS** | 与旧随机公式逐样本相等 |
| G | Case04 seed=104 可确定复现 | **PASS** | 两次 Cs1/Cs2 最大差值均为 0 |
| H | Case05 fault_only 已建立 | **PASS** | legacy/formal 两个名称均可生成 |
| I | Case05 seed=106 已冻结 | **PASS** | registry 和单元测试均确认 106 |
| J | Case05 与 Case06 使用相同 fault profile | **PASS** | 共用函数，逐样本最大差值为 0 |
| K | Case05 Cs1/Cs2 全程固定 | **PASS** | 两者范围均为 `[10,10] pF` |
| L | 没有运行正式 AutoComp9 仿真 | **PASS** | 只运行纯函数 `checkcode/runtests` 和差值打印 |
| M | 没有修改算法核心文件 | **PASS** | 受保护文件 diff 为空 |
| N | 没有修改历史结果 | **PASS** | 三个历史结果目录 diff 为空 |

## 11. Git 检查

最终 `git diff --stat` 与 `git status --short` 见下方；本轮没有创建 Step 2 checkpoint，也没有进入 Step 3。

执行：

```text
git diff --stat
```

结果：

```text
 .../generate_coupling_signals.m" | 31 +++++++++++++++++++++-
 .../phase1a_case_registry.m"     | 16 +++++------
 2 files changed, 38 insertions(+), 9 deletions(-)
```

`git diff --stat` 不统计两个未跟踪的新文件。执行：

```text
git status --short
```

结果：

```text
 M "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/generate_coupling_signals.m"
 M "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/phase1a_case_registry.m"
?? "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/tests/Phase1ACaseSignalTest.m"
?? paper_research/phase1a_baseline/STEP2_CASE_REGISTRY_AND_SIGNAL_GENERATION.md
```

Git 的 `MATLAB\344...` 是中文目录 `MATLAB一键实验/` 的转义显示。`git diff --check` 无错误；只有 Git 提示未来可能把 LF 转为 CRLF。

## 12. 停止点

Phase 1A Step 2 已完成。当前只具备统一 case 名称和输入信号生成能力；尚未实现 `algorithm_mode`、正式指标计算或六工况运行。
