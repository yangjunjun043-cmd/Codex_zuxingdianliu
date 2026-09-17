# Phase 1A — Step 3：Unified M0/M2/M3 Algorithm Dispatcher

执行日期：2026-09-16  
执行范围：建立 M0/M2/M3 统一薄调度层和纯 MATLAB 函数级测试；未加载或运行 AutoComp9，未调用 `sim`，未进入指标计算或 Step 4。

## 1. Step 2 checkpoint

开始 Step 3 前，`git status --short --untracked-files=all` 只包含已人工验收的 Step 2 四项变更。按要求建立 checkpoint：

| 项目 | 值 |
|---|---|
| commit | `fe0821f73e0c2470e9f48432b3f8a12f86ed7a70` |
| subject | `paper: unify Phase 1A case signals` |
| timestamp | `2026-09-16T16:57:39+08:00` |
| files | `generate_coupling_signals.m`、`phase1a_case_registry.m`、`Phase1ACaseSignalTest.m`、Step 2 报告 |

## 2. 新增/修改文件

| 文件 | 动作 | 职责 |
|---|---|---|
| `MATLAB一键实验/run_phase1a_algorithm.m` | 新增 | 根据 `algorithm_mode` 调用既有 M0/M2/M3，并统一调用阻性电流提取函数 |
| `MATLAB一键实验/tests/Phase1AAlgorithmDispatcherTest.m` | 新增 | Registry、三模式映射、统一返回结构、薄调度和非法模式测试 |
| `paper_research/phase1a_baseline/STEP3_ALGORITHM_DISPATCHER.md` | 新增 | 本报告 |

现有 `phase1a_algorithm_registry.m` 已与实际调度完全一致，因此未修改。算法核心、模型、Phase 2 历史入口和历史结果均未修改。

## 3. Dispatcher 接口与职责

正式接口：

```matlab
result = run_phase1a_algorithm(algorithm_mode,data,ref,cfg,self_pF)
```

职责仅有三项：

1. 校验并规范化 `algorithm_mode`；
2. 直接调度现有 M0/M2/M3；
3. 将选定的 `cHist` 统一交给 `extract_resistive_current`。

该函数不生成 case，不运行 Simulink，不评价指标，不写文件，不绘图，不改变输入数据、参考、配置、seed 或参数。

## 4. M0 调用路径

```text
M0
  -> initial_coupling_estimate(data,ref,cfg,self_pF)
  -> repmat(c0(:).',numel(data.t),1)
  -> extract_resistive_current(data,ref,self_pF,cHist)
```

M0 仍是“初始化联合 LS 后全程冻结”，没有改成标称 `10/10 pF`，也没有复制 LS 数学公式。`tracker` 返回真实空结构 `struct()`，没有伪造跟踪数据。

## 5. M2 调用路径

```text
M2
  -> track_coupling_cvff_rls(data,ref,cfg,self_pF,false)
  -> cHist = tracker.hist
  -> extract_resistive_current(data,ref,self_pF,cHist)
```

M2 仅关闭既有 fault gate；现有 VFF、信息形式 RLS、Cs 变化率限制、物理范围投影和 cycle log 原样保留。完整 tracker 结构未被裁剪。

## 6. M3 调用路径

```text
M3
  -> track_coupling_cvff_rls(data,ref,cfg,self_pF,true)
  -> cHist = tracker.hist
  -> extract_resistive_current(data,ref,self_pF,cHist)
```

M3 直接启用现有 hard fault gate；未修改门限、保持周期、基线更新或任何算法参数。完整 tracker 结构未被裁剪。

## 7. 统一返回结构

三种模式均返回下列字段：

| 字段 | 内容 |
|---|---|
| `algorithm_mode` | 规范化后的 `M0`、`M2` 或 `M3` |
| `algorithm_name` | 从 `phase1a_algorithm_registry` 读取的正式名称 |
| `c0` | 现有 `initial_coupling_estimate` 得到的初值 |
| `cHist` | M0 的冻结历史，或 M2/M3 的 `tracker.hist` |
| `ir` | 统一调用 `extract_resistive_current` 的输出 |
| `tracker` | M0 为空结构；M2/M3 保留现有 tracker 及 cycle log |

当前 tracker 内部仍按历史实现自行计算初始化。Dispatcher 为统一结果记录另外调用一次现有初始化函数，没有修改 tracker 函数签名或核心实现。

## 8. 阻性电流统一提取路径

Dispatcher 中只有一处阻性电流提取调用：

```matlab
ir = extract_resistive_current(data,ref,self_pF,cHist);
```

M0/M2/M3 不再分别维护阻性电流扣除代码。测试以静态源码检查确认该调用在 dispatcher 中恰好出现一次。

## 9. 非法 mode 处理

非字符/字符串、非标量、missing、空字符串，以及未在启用 registry 中唯一匹配的模式，统一抛出：

```text
Phase1A:UnknownAlgorithmMode
```

参数化单元测试确认 `M1`、`M4`、`UNKNOWN` 和空字符串均被明确拒绝，没有静默回退。

## 10. 单元测试结果

测试文件：`MATLAB一键实验/tests/Phase1AAlgorithmDispatcherTest.m`。

MATLAB 连接器无法附着到已有会话，因此沿用 Step 2 的回退方式，通过 `matlab -batch` 只运行 `checkcode` 和该测试文件。没有调用 `sim`、模型名或任何实验入口。

用于返回结构检查的数据是测试内存中构造的短时、确定性三相函数级样本，不读取或写入历史结果，也不启动 Simulink。

最终结果：

```text
9 passed / 0 failed / 0 incomplete
```

| 测试内容 | 结果 |
|---|---|
| Registry 仅含启用的 M0/M2/M3 | PASS |
| M0 调用现有初始化并冻结 `cHist` | PASS |
| M2 返回现有 tracker、hist 和 cycle log | PASS |
| M3 返回现有 tracker、hist 和 cycle log | PASS |
| 三种模式返回统一结构并生成 A/B/C 阻性电流 | PASS |
| M2/M3 源码映射精确使用 `false/true` | PASS |
| Dispatcher 不含 VFF/RLS/门控/限幅/投影数学公式 | PASS |
| M1/M4/UNKNOWN/空字符串均报指定错误 | PASS |

首次执行中薄调度静态规则把变量名 `match =` 误识别为独立的 `h =` 更新，导致 1 个测试误报；收紧正则词边界后重跑全部通过。调度实现本身未因该误报改变。

## 11. Code Analyzer 结果

| 文件 | issue 数 |
|---|---:|
| `run_phase1a_algorithm.m` | 0 |
| `tests/Phase1AAlgorithmDispatcherTest.m` | 0 |

## 12. Step 3 验收 A–N

| 编号 | 验收项 | 结果 | 依据 |
|---|---|---|---|
| A | 建立统一 `run_phase1a_algorithm.m` | **PASS** | 新增单一职责函数 |
| B | 只支持 M0/M2/M3 | **PASS** | registry 唯一匹配和测试确认 |
| C | M0 与历史实现一致 | **PASS** | 直接初始化 LS 后 `repmat` 冻结 |
| D | M2 精确调用现有函数并传入 `false` | **PASS** | 源码静态检查与函数级测试 |
| E | M3 精确调用现有函数并传入 `true` | **PASS** | 源码静态检查与函数级测试 |
| F | M0/M2/M3 共用 `extract_resistive_current` | **PASS** | dispatcher 仅一处统一调用 |
| G | 没有复制 VFF/RLS/门控数学公式 | **PASS** | 禁止公式标记静态检查通过 |
| H | 非法 mode 会报错 | **PASS** | 四组非法输入均得到指定 error ID |
| I | 没有修改算法核心文件 | **PASS** | 最终 Git 核查无受保护文件 diff |
| J | 没有修改 AutoComp9 | **PASS** | SHA-256 仍为 `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| K | 没有修改 Phase 2 历史入口 | **PASS** | `run_phase2_simulink_dynamic.m`、`run_gating_ablation.m` 无 diff |
| L | 没有修改历史结果 | **PASS** | `results/`、`results_phase1/`、`results_phase2/` 无 diff |
| M | 没有运行正式六工况 | **PASS** | 只执行 checkcode 和纯函数测试 |
| N | 没有创建 M1/M4/软门控/P_X/eta_abs | **PASS** | 仅非法输入测试提及保留编号；无实现或模式注册 |

## 13. Git 检查

执行：

```text
git diff --stat
```

结果：无输出。原因是 Step 3 只新增三个未跟踪文件，没有修改已跟踪文件。

执行：

```text
git status --short --untracked-files=all
```

结果：

```text
?? "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/run_phase1a_algorithm.m"
?? "MATLAB\344\270\200\351\224\256\345\256\236\351\252\214/tests/Phase1AAlgorithmDispatcherTest.m"
?? paper_research/phase1a_baseline/STEP3_ALGORITHM_DISPATCHER.md
```

Git 的 `MATLAB\344...` 是中文目录 `MATLAB一键实验/` 的转义显示。

## 14. 人工快速核对

```text
M0 dispatch path: initial_coupling_estimate -> frozen cHist -> extract_resistive_current
M2 dispatch path: track_coupling_cvff_rls(...,false) -> tracker.hist -> extract_resistive_current
M3 dispatch path: track_coupling_cvff_rls(...,true) -> tracker.hist -> extract_resistive_current
```

## 15. 停止点

Phase 1A Step 3 已完成。当前只建立统一算法调用层；没有实现指标计算，没有生成 baseline CSV/MAT/图，没有运行正式 AutoComp9 六工况，也没有进入 Step 4。
