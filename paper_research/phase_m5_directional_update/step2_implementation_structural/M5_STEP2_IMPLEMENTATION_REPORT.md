# M5 Step2 实现与结构验证报告

## 1. 结论与边界

M5 Step2 的独立实现、结构单元测试、operator-matched 对照和 Case05/Case06 限定 smoke 均已完成。36 条 A–H 结构检查全部通过，17 个 `matlab.unittest` 测试全部通过，冻结源文件哈希全部保持不变。因此，本阶段结论为 **STEP2 = GO**。

该结论只表示实现满足预先规定的代数、状态一致性、调用链和日志结构，不表示 M5 的估计性能优于 M2/M3/M4，也不构成 Step3/Step4 或 Monte Carlo 结果。

## 2. 新建实现

- `MATLAB一键实验/m5_directional_update.m`：只实现固定方向 `d_f=[1;-1]/sqrt(2)`、投影分解及 directional/global operator，不含性能参数。
- `MATLAB一键实验/track_coupling_m5_directional_rls.m`：独立 M5 tracker，支持 `M5_DH`、`M5_FULL`、`GLOBAL_HARD_MATCHED` 和 `GLOBAL_CONTINUOUS_MATCHED`。
- `MATLAB一键实验/tests/M5DirectionalUpdateTest.m`：类式单元测试。
- `run_m5_step2_structural_checks.m`：生成 A–H 结构测试证据。
- `run_m5_step2_smoke.m`：只运行冻结定义的 Case05/Case06 并生成周期日志、摘要和哈希审计。

未修改冻结的 M2、M3、M4、`m4_fault_evidence.m`、`coupling_regressor.m`、dispatcher、正式 Simulink 模型、历史 registry 或历史 CSV。

## 3. 实现结构

每周期先由继承的 M2 信息状态计算：

```text
J_star = lambda*J_previous + R
h_star = lambda*h_previous + z
theta_M2_raw = (J_star + 1e-10*I) \ h_star
delta_raw = theta_M2_raw - theta_previous
```

`delta_raw` 是 M5 operator 的唯一更新输入。代码不调用冻结 M4 tracker，不读取 M4 已全局加权的 proposal；`m4_fault_evidence` 每周期只调用一次。

方向模式使用：

```text
delta_protected = P_perp*delta_raw + w*P_f*delta_raw
```

配对全局对照使用：

```text
delta_protected = w*delta_raw
```

其中 hard 模式复用 `w_hard=1-gate`，continuous 模式复用冻结证据函数输出的 `w_REW`。实现没有新增阈值、增益、下限、指数或其他可调标量；`forced_selected_weight` 仅为测试端点的显式 test-only 选项，不进入自然生产调用。

状态与约束顺序为：

```text
raw M2 proposal
→ directional/global operator
→ h=(J_star+1e-10*I)*theta_preconstraint
→ existing componentwise rate limit
→ existing [0,40] pF projection
→ final theta
```

投影后没有第二次方向修正。`baseIn` 使用 hard/REW 的同一 selected weight，候选式仍为继承的 `1.08 / 0.985 / 0.015` 语义。

## 4. 自动验证结果

| 验证项 | 结果 | 关键证据 |
|---|---:|---|
| MATLAB Code Analyzer | PASS | 5 个新增 `.m` 文件均为 0 issue |
| 类式单元测试 | PASS | 17/17 |
| A–H 结构检查 | PASS | 36/36 CSV 行 |
| Projector identities | PASS | 最大误差 `2.22044604925031e-16` |
| `w=1` endpoint | PASS | proposal 最大误差 `2.22044604925031e-16` |
| `w=0` endpoint | PASS | parallel leakage `3.92523114670944e-16` |
| `w=0.25/0.50/0.75` | PASS | 最大缩放/保持误差 `3.14018491736755e-16` |
| State reconciliation | PASS | residual `0`，solve-back `7.85046229341888e-17` |
| No double REW | PASS | evidence helper call count 1；M4 tracker call count 0 |
| Constraint order | PASS | 静态顺序及运行日志字段均通过 |
| 新增可调超参数 | PASS | `0` |
| 冻结哈希 | PASS | 6/6 |

集成 MATLAB 测试接口因无法附着本机 MATLAB 会话而未执行；同一测试类随后通过 R2023b `matlab.unittest` 批处理入口运行并全部通过。该接口问题不改变测试断言或测试结果。

## 5. 限定 smoke

只使用既有正式定义：

- `Case05_fault_only`，seed 106；
- `Case06_drift_then_fault`，seed 105。

两个案例的四种模式均正常运行，每个模式记录 165 个周期，每个案例输出 660 行周期日志。日志 schema 完整，solve-back 最大误差不超过 `3.97205464519564e-15`，reconciliation residual 为 `0`，分解最大误差不超过 `1.57009245868378e-16`。

Simulink 输出了既有的未连接 Current Measurement 端口和 algebraic-loop 警告；仿真没有因此失败。这些警告未被删除或隐藏，也未在本阶段修改模型。

本次两个案例都是持续故障，故 `POST_FAULT` 分段明确标记为不可用。本次 smoke 中 rate-limit 和 projection 的激活次数均为 0；相关前后角度、激活标志和 rotation 字段已记录，但不能据此评价约束激活时的统计表现。

## 6. 复现命令

```matlab
% 静态检查使用 checkcode，所有新文件 0 issue。

suite = matlab.unittest.TestSuite.fromFile( ...
    'MATLAB一键实验/tests/M5DirectionalUpdateTest.m');
results = matlab.unittest.TestRunner.withTextOutput.run(suite);
assertSuccess(results);

results = run_m5_step2_structural_checks();
assert(all(results.pass));

result = run_m5_step2_smoke();
assert(result.overall_pass);
```

## 7. 未进入的工作

本阶段未运行正式 M5 experiment matrix、性能阈值比较、Monte Carlo、Step3 preregistration 或 Step4 factorial performance experiment，也未对 smoke 结果调参。后续只有在人工检查 Step2 后才能进入下一阶段。
