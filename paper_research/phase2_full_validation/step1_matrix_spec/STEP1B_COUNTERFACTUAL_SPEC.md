# Phase 2 Step 1B — Protection-Schedule Counterfactual Specification

## 1. Frozen decision

```text
COUNTERFACTUAL_CAUSAL_REPLAY = INCLUDE
ROLE = Phase 2 causal addendum
ANCHOR = frozen Case08
PRIMARY ALGORITHMS = M3, M4
FROZEN CORE MODIFICATION = FORBIDDEN
```

M2 可作为无 protection 的机制参照，但不是 protection-schedule replay 主对象；M0 不适用。本 addendum 处理 Phase 1C 的已知混杂：M3/M4 的 `c_F-c_CF` 同时含 direct fault-related effect 和由 fault-triggered protection 造成的真实 drift learning reduction。

## 2. Four trajectories

所有轨迹必须共享 Case08 的 true Cs drift、reference、noise、initial state、time axis 和 evaluation windows；区别只允许来自下表冻结的 fault 与 schedule 操作。

| Trajectory | Fault observation | M3 schedule | M4 schedule | Lambda schedule |
|---|---|---|---|---|
| F — Fault Actual | frozen Case08 fault | natural fault `gate(t)` | natural fault `g(t)` | natural fault lambda |
| N — No-Fault Natural | deleted | natural no-fault gate | natural no-fault g | natural no-fault lambda |
| P — Protection-Schedule Replay | deleted | replay F `gate(t)` | replay F `g(t)` | natural no-fault lambda |
| A — Full Adaptation-Schedule Replay | deleted | replay F `gate(t)` | replay F `g(t)` | replay F `lambda(t)` |

如果后续代码审计发现另有直接改变 RLS 信息写入强度的 time-varying schedule，不得自动加入 A；必须标记 `ADDITIONAL_SCHEDULE_UNRESOLVED` 并等待人工审核。

## 3. Frozen decomposition

对同一已声明 interval 的参数 movement `Delta_c`：

```text
Delta_c_F - Delta_c_N
= (Delta_c_F - Delta_c_A)
+ (Delta_c_A - Delta_c_P)
+ (Delta_c_P - Delta_c_N)
```

操作性解释冻结为：

- `F-A`：matched adaptation schedule 下 remaining direct fault-related contamination；
- `A-P`：fault-triggered VFF / adaptation-schedule contribution；
- `P-N`：protection-induced true-drift learning reduction。

这是 operational counterfactual decomposition，不是 perfect causal identification。报告必须同时保留 Cs1/Cs2 signed components 和 L2 norm，不得只报告 norm。

## 4. Implementation discipline

未来实现只允许：

1. 独立 Phase 2 replay wrapper；或
2. 冻结 state-transition 的只读复制 replay implementation。

不得修改 M3/M4 frozen source、`paper_method_v1`、gate/VFF/rate limit/projection，也不得为 replay 重调数值容差。

## 5. REPLAY_EQUIVALENCE_GATE

正式使用反事实结论前必须完成以下等价性回归：

1. 使用与 frozen run 相同的输入、初始状态和记录 schedule；
2. 以 natural schedule replay 路径复现对应原 frozen trajectory；
3. 比较完整 `c(t)`，并比较 gate/g、lambda、最终参数和所有拟用于论文的 derived metric；
4. 所有差异必须处于项目已有 numerical tolerance 内；Step 1C/实现阶段只能引用已有容差，不得因 replay 失败放宽；
5. 保存 comparison artifact、tolerance provenance 和 validator result。

若任一主对象未通过：

```text
COUNTERFACTUAL_REPLAY = BLOCKED
```

不得用近似 replay 撰写因果结论。

## 6. Registered outputs

M3/M4 分别保存 F/N/P/A 的：

- trajectory provenance 和 schedule source；
- Cs1/Cs2 start/end 与 signed movement；
- movement L2 norm；
- F-A、A-P、P-N、F-N 的 signed vector 与 norm；
- M3 `gate(t)`、M4 `g(t)`、两算法 `lambda(t)`；
- equivalence-gate pass/fail 与 validator artifact path。

Case08 的 F/N 冻结证据可复用；P/A 是未来新增 replay trajectories。本步骤不实现、不运行。

## 7. Stop status

```text
SPECIFICATION FROZEN: YES
REPLAY IMPLEMENTED: NO
REPLAY EXECUTED: NO
FROZEN SOURCE MODIFIED: NO
```

