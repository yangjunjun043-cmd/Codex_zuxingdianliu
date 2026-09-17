# Phase 1A Step 6A — Case05 Compatibility Fix

执行日期：2026-09-17  
最终结论：`STEP6A_FAULT_ONLY_COMPATIBILITY_FIX = PASS`

## 1. Step 6 失败原因

Step 6 在 `Case05_fault_only` 处按规则停止。失败不是算法数值问题，而是已经冻结的
Phase 1A Case Registry 与旧 MATLAB synthetic reference/noise helper 之间缺少接口支持：

```text
Case05_fault_only
  -> legacy scenario = fault_only
  -> simulate_phase2_case
  -> synthesize_dynamic_case(...,"fault_only",...)
  -> Unknown scenario fault_only
```

`generate_coupling_signals.m` 已能产生 Case05，但修改前的
`synthesize_dynamic_case.m` 只有 `static`、`slow_drift`、`smooth_step`、
`random_drift` 和 `fault_with_drift` 五个分支。

## 2. 修改前调用链

```text
phase1a_case_registry
  -> Case05_fault_only / fault_only / seed 106
  -> simulate_phase2_case
     -> generate_coupling_signals                 % 成功
     -> zero-noise AutoComp9 run                  % Step 6 中成功
     -> synthesize_dynamic_case("fault_only")      % 修改前失败
     -> noise generation
     -> noisy AutoComp9 run
```

本轮没有再次调用该链路，也没有运行 AutoComp9。所有验收均为纯 MATLAB 函数测试。

## 3. 修改文件

| 文件 | 操作 | 内容 |
|---|---|---|
| `MATLAB一键实验/synthesize_dynamic_case.m` | 修改 | 增加 `fault_only` compatibility 分支，共 4 行 |
| `MATLAB一键实验/tests/Phase1AFaultOnlyCompatibilityTest.m` | 新增 | class-based 纯 MATLAB 专项测试 |
| `paper_research/phase1a_baseline/STEP6A_FAULT_ONLY_COMPATIBILITY_FIX.md` | 新增 | 本报告 |

未修改 `simulate_phase2_case.m`、`generate_coupling_signals.m`、Case Registry、
算法、Metrics、AutoComp9 或历史结果。

## 4. `fault_only` 新增实现

Cs switch 中新增空分支，使其保留函数已有的 10 pF 初始化值：

```matlab
case 'fault_only'
```

B 相阻性电流中新增：

```matlab
elseif strcmp(scenario, 'fault_only')
    sf = smooth_step(t, 3.0, 3.06);
    irB = irB .* (1 + 0.6*sf);
```

没有抽取或改写 `fault_with_drift` 原分支；其已有三行公式保持原样。新增 Case05
使用数学完全相同的 `smooth_step(t,3.0,3.06)` 和 `1+0.6*sf`。

## 5. Case05 冻结定义

| 字段 | 定义 | 实测 |
|---|---|---|
| 正式名称 | `Case05_fault_only` | 未修改 |
| legacy 名称 | `fault_only` | 未修改 |
| seed | 106 | 未修改 |
| Cs1 | 全程 10 pF | range `[10,10]` pF |
| Cs2 | 全程 10 pF | range `[10,10]` pF |
| 故障过渡 | 3.00–3.06 s | 通过 |
| 故障倍率 | 1.0 → 1.6 | range `[1,1.6000000000000001]` |

## 6. Case05 / Case06 fault profile 对照

测试使用完整时间向量 `0:2e-5:4.0 s`，令 synthetic base 的 B 相阻性电流为 1，
因此输出 `irB` 就是故障倍率向量。

```text
max(abs(Case05.irB-Case06.irB)) = 0
```

Case06 完整保护向量由 `[Cs1; Cs2; irB]` 构成。修改前后逐字节 SHA-256：

```text
before = E0DC3E1F196E8B5F7B2A85765304A5F747EFCE21CB3703AB6434843EE7F5A173
after  = E0DC3E1F196E8B5F7B2A85765304A5F747EFCE21CB3703AB6434843EE7F5A173
```

结论：Case06 的 Cs1、Cs2 和 fault profile 逐样本未改变。

## 7. Generate / Synthetic 两链 Case05 对照

比较：

```text
synthesize_dynamic_case(base,cfg,"fault_only",106)
generate_coupling_signals(t,"fault_only",106)
```

结果：

| 信号 | max abs difference |
|---|---:|
| Cs1 | 0 |
| Cs2 | 0 |
| fault profile | 0 |

因此 synthetic reference/noise 链表达的 Case05 与 Step 2 冻结 generator 完全一致。

## 8. Legacy scenario regression

新增参数化测试确认以下旧场景仍可正常返回有限的 `ia/ib/ic` 以及正确尺寸的
`Cs1/Cs2`：

| scenario | 结果 |
|---|---|
| `static` | PASS |
| `slow_drift` | PASS |
| `smooth_step` | PASS |
| `random_drift` | PASS |
| `fault_with_drift` | PASS |

Git diff 进一步确认旧 scenario 的 switch 公式均未修改，Case06 的独立冻结公式测试和
修改前后向量哈希也均通过。

## 9. 单元测试结果

测试文件：

```text
MATLAB一键实验/tests/Phase1AFaultOnlyCompatibilityTest.m
```

运行范围仅为 `runtests`；没有调用 `sim`、`simulate_phase2_case` 或任何实验 runner。

```text
12 Passed, 0 Failed, 0 Incomplete
duration = 0.90418 s
```

覆盖内容：

- `fault_only` 可正常返回；
- Cs1 恒定 10 pF；
- Cs2 恒定 10 pF；
- 故障前为 1、3.06 s 后为 1.6；
- Case05/06 fault profile 严格相等；
- Case05 synthetic/generator 三路严格相等；
- 旧五个 scenario 均可生成；
- Case06 与冻结数学公式逐样本严格相等。

## 10. Code Analyzer

| 文件 | issues |
|---|---:|
| `synthesize_dynamic_case.m` | 0 |
| `tests/Phase1AFaultOnlyCompatibilityTest.m` | 0 |

## 11. 为什么允许本轮修改

本修复没有修改算法、阈值、参数、评价窗口或实验真值。Case05 的物理定义已在 Step 2
冻结；本轮只是为 legacy synthetic reference/noise helper 增加缺失的 `fault_only`
接口，使它能够表达同一冻结 Case。新增代码没有改变 Case06 历史分支。

## 12. A–M 验收表

| ID | 验收项 | 结果 | 依据 |
|---|---|---|---|
| A | `synthesize_dynamic_case` 支持 `fault_only` | **PASS** | 调用正常返回 |
| B | Case05 Cs1 全程 10 pF | **PASS** | range `[10,10]`；逐样本测试 |
| C | Case05 Cs2 全程 10 pF | **PASS** | range `[10,10]`；逐样本测试 |
| D | Case05/06 fault profile 完全一致 | **PASS** | max abs diff = 0 |
| E | Case05 与 generator 定义一致 | **PASS** | Cs1/Cs2/fault 三路差值均为 0 |
| F | 旧五个 scenario 仍正常 | **PASS** | 五组参数化测试通过 |
| G | Case06 原数学定义未改变 | **PASS** | 原代码未改；前后 SHA 相同 |
| H | 未修改 AutoComp9 | **PASS** | SHA 仍为冻结值 |
| I | 未修改 `simulate_phase2_case` | **PASS** | Git diff 无该文件 |
| J | 未修改算法核心 | **PASS** | Git diff 无算法文件 |
| K | 未修改 Metrics | **PASS** | Git diff 无 Metrics 文件 |
| L | 未修改历史结果 | **PASS** | 三个历史结果目录 status 为空 |
| M | 未重新运行完整 Step 6 | **PASS** | CSV/MAT 均不存在；仅纯 MATLAB 测试 |

AutoComp9 SHA-256：

```text
56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70
```

## 13. Git 检查

### `git diff --stat`

```text
 MATLAB一键实验/synthesize_dynamic_case.m | 4 ++++
 1 file changed, 4 insertions(+)
```

新测试和本报告为未跟踪文件，因此不出现在 `git diff --stat`。

### `git diff --check`

```text
(no whitespace errors)
```

Git 同时给出工作区 LF 将来可能转换为 CRLF 的提示；这不是 `diff --check` 错误。

### `git status --short --untracked-files=all`

```text
 M "MATLAB一键实验/synthesize_dynamic_case.m"
?? "MATLAB一键实验/run_phase1a_baseline.m"
?? "MATLAB一键实验/tests/Phase1AFaultOnlyCompatibilityTest.m"
?? "MATLAB一键实验/validate_phase1a_baseline.m"
?? paper_research/phase1a_baseline/STEP6A_FAULT_ONLY_COMPATIBILITY_FIX.md
?? paper_research/phase1a_baseline/STEP6_FORMAL_BASELINE_RUN.md
?? paper_research/phase1a_baseline/step5_smoke_workspace.mat
```

其中 `run_phase1a_baseline.m`、`validate_phase1a_baseline.m`、Step 6 失败报告及
`step5_smoke_workspace.mat` 均为本轮开始前已有文件，本轮未修改。

## 14. 停止点

```text
STEP6A_FAULT_ONLY_COMPATIBILITY_FIX = PASS
```

本轮没有重新运行完整 Step 6，没有生成 `baseline_summary.csv` 或
`baseline_workspace.mat`，也没有进入 Step 7 或 Phase 1B。等待人工验收。
