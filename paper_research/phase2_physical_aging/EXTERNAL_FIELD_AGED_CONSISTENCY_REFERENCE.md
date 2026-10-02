# External field-aged consistency reference

```text
REFERENCE_ROLE = EXTERNAL_FIELD_AGED_CONSISTENCY_REFERENCE
PARAMETER_DONOR = NO
FU_2024_PARAMETER_MIXING = PROHIBITED
```

## 文献信息

Masume Khodsuz and Mohammad Mirzaie, “Evaluation of ultraviolet ageing, pollution and varistor degradation effects on harmonic contents of surge arrester leakage current,” *IET Science, Measurement & Technology*, vol. 9, pp. 979–986, 2015. DOI: [10.1049/iet-smt.2014.0372](https://doi.org/10.1049/iet-smt.2014.0372).

核对来源：[Wiley Online Library 原文页面](https://ietresearch.onlinelibrary.wiley.com/doi/10.1049/iet-smt.2014.0372)，访问日期 2026-09-28。

## 可使用的独立一致性证据

该文献第 5 节说明，实验所用 aged varistor 取自一台已在电力系统运行 15 年的避雷器。Figure 9 给出 virgin/aged varistor 的 V–I characteristic，作者报告 aged characteristic 相对 virgin 发生明显变化。该 aged varistor 被分别放置在由 7 片阀片组成的 active column 的首部、中部和末部。

Table 8 给出的阻性电流谐波为：

| 状态/位置 | `ir1` (A) | `ir3` (A) | `ir5` (A) |
|---|---:|---:|---:|
| Virgin clean arrester | `2.14e-5` | `5.103e-7` | `4.315e-6` |
| Aged varistor：首部 | `3.85e-5` | `2.051e-6` | `1.489e-6` |
| Aged varistor：中部 | `3.80e-5` | `1.762e-6` | `1.728e-6` |
| Aged varistor：末部 | `3.784e-5` | `1.102e-6` | `2.519e-6` |

三个 aged-varistor 位置均表现为 `ir1` 增大、`ir3` 增大而 `ir5` 降低。该证据支持的边界结论是：长期运行退化阀片在避雷器实验重构条件下可引起阻性电流谐波的非同比例变化，因此物理老化验证不应仅检查总幅值或采用常数倍率模型。

## 禁止用途

本文件不提供 `alpha_a`、`Uref_a`、`Iref_a` 或 Fu 2024 Figure 1 的数字化点。Khodsuz & Mirzaie 的样品、老化历史、整柱结构和测量条件与 Fu 2024 的 Sample B 不同，因此：

- 不得把 Table 8 谐波数值与 Fu 2024 的 `E1mA`、`alpha`、`IL` 拼接成模型参数；
- 不得用 Table 8 反推本工程的 aged power-law 参数；
- 不得以 M0/M2/M3/M4 的表现选择其中某个位置或倍率；
- 该文献只用于验证“真实退化应允许波形/谐波结构变化”这一独立方向性要求。
