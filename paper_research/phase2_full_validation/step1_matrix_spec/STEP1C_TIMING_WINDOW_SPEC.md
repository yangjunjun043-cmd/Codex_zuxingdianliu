# Phase 2 Step 1C — Overlap Timing and Window Freeze

## 1. Frozen timing construction

For rate multiplier `r`:

```text
drift_start = 0.80 s
drift_duration = 1.40 / r
drift_end = drift_start + drift_duration

fault_start = drift_start + 0.50 * drift_duration
ramp-up duration = 0.06 s
plateau duration = 0.34 s
ramp-down duration = 0.06 s
fault_end = fault_start + 0.46 s
```

因此 absolute fault timing 是 `DERIVED_FROM_RATE_TO_PRESERVE_NORMALIZED_ONSET`，不是 rate sweep 中的 held-fixed factor。Fault factor、ramp shape、total fault duration 与 total drift vector `D1=[+3,-2] pF` 保持不变。

## 2. Window mapping fractions

Case08 plateau `[1.56,1.90)` 长度 0.34 s 给出：

```text
W1 fractions = [3/17, 9/17)
W2 fractions = [9/17, 16/17)
```

它们映射到实际 simultaneous plateau：

```text
plateau_overlap_start = max(fault_start+0.06, drift_start)
plateau_overlap_end   = min(fault_start+0.40, drift_end)
```

W0 使用 Case08 在 `drift_start -> fault_start` 内的 fractions `[4/7,13/14)`。W3 在存在 `fault_end < drift_end` 时，使用 Case08 在 `fault_end -> drift_end` 内的 fractions `[1/12,11/12)`。W4 定义：

```text
W4_start = max(fault_end, drift_end) + 0.20 s
W4_end   = W4_start + 0.40 s
simulation_stop = max(4.00 s, W4_end + 0.20 s)
```

## 3. Frozen numerical schedule

| Item | 0.5x | 1.0x | 2.0x |
|---|---:|---:|---:|
| drift start | 0.8000000000 | 0.8000000000 | 0.8000000000 |
| drift end | 3.6000000000 | 2.2000000000 | 1.5000000000 |
| drift duration | 2.8000000000 | 1.4000000000 | 0.7000000000 |
| fault start | 2.2000000000 | 1.5000000000 | 1.1500000000 |
| ramp end / plateau start | 2.2600000000 | 1.5600000000 | 1.2100000000 |
| plateau end | 2.6000000000 | 1.9000000000 | 1.5500000000 |
| fault end | 2.6600000000 | 1.9600000000 | 1.6100000000 |
| simultaneous fault+drift | `[2.20,2.66)` | `[1.50,1.96)` | `[1.15,1.50)` |
| simultaneous plateau | `[2.26,2.60)` | `[1.56,1.90)` | `[1.21,1.50)` |
| W0 | `[1.60,2.10)` | `[1.20,1.45)` | `[1.00,1.125)` |
| W1 | `[2.32,2.44)` | `[1.62,1.74)` | `[1.2611764706,1.3635294118)` |
| W2 | `[2.44,2.58)` | `[1.74,1.88)` | `[1.3635294118,1.4829411765)` |
| W3 | `[2.7383333333,3.5216666667)` | `[1.98,2.18)` | `N/A_BY_DESIGN` |
| W4 | `[3.80,4.20)` | `[2.40,2.80)` | `[1.81,2.21)` |
| simulation stop | 4.40 | 4.00 | 4.00 |

Window-set IDs：`WINDOWSET_OV_R05`、`WINDOWSET_OV_R10`、`WINDOWSET_OV_R20`。

## 4. Special interpretation for 2x

2x condition has real simultaneous overlap `[1.15,1.50)` and simultaneous plateau `[1.21,1.50)`. Fault clears at 1.61 s, after drift ends at 1.50 s. Therefore:

```text
W3_ACTIVE_DRIFT = N/A_BY_DESIGN
```

This applies to every deterministic or MC overlap condition with rate 2x. It is not a numerical failure and does not justify deleting the condition.

## 5. Validation results

Automated arithmetic checks passed for all three rates:

- `drift_duration == 1.40/r`；
- total drift vector remains `[+3,-2] pF` for overlap core/MC；
- ramp-up and ramp-down remain 0.06 s；
- total fault duration remains 0.46 s；
- W1/W2 lie fully inside simultaneous plateau；
- 1x exactly reproduces Case07/08 timing and W0–W4；
- all times are nonnegative；
- W4 lies inside the simulation horizon。

```text
RATE_TIMING_DESIGN = PASS
```

