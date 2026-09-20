# `paper_method_v1` Freeze Record

## Identity

- Formal name: **M4 — Residual-Evidence Weighted Adaptive Identification**
- Acronym: **REW-AI**
- Implementation lineage: M4-v0
- Production variant: A_FULL only
- Freeze version: `paper_method_v1`
- Direction role: diagnostic only; no direction quantity enters the control law.

## Exact Formula

For cycle k:

\[
r_{b,k}=\frac{E_{in,k}}{baseIn_{k-1}+\epsilon},\qquad
r_{q,k}=\frac{E_{in,k}}{E_{quad,k}+\epsilon}
\]

\[
e_{b,k}=\max\left(0,\frac{r_{b,k}-1}
{\max(gate\_ratio-1,\epsilon)}\right)
\]

\[
p_{q,k}=\operatorname{clip}\left(
\frac{r_{q,k}}{gate\_quad\_ratio},0,1\right),\qquad
s_k=e_{b,k}p_{q,k},\qquad g_k=\frac{1}{1+s_k}
\]

The inherited VFF is

\[
\nu_k=\left\|(c_{LS,k}-c_{k-1})/[5,5]^T\right\|_2,
\]

\[
\lambda_k=\lambda_{max}-(\lambda_{max}-\lambda_{min})
\operatorname{clip}(\nu_k/0.20,0,1).
\]

The unweighted information candidate and weighted state-consistent update are

\[
J_k^*=\lambda_kJ_{k-1}+R_k,\qquad
h_k^*=\lambda_kh_{k-1}+z_k,
\]

\[
J_k=J_{k-1}+g_k(J_k^*-J_{k-1}),\qquad
h_k=h_{k-1}+g_k(h_k^*-h_{k-1}),
\]

\[
c_k^{raw}=(J_k+10^{-10}I)^{-1}h_k.
\]

The existing per-cycle rate limit and `[0,40] pF` projection are then applied to `c_k`. If `E_in,k < 1.08 baseIn_k-1`,

\[
baseIn_k^*=0.985baseIn_{k-1}+0.015E_{in,k};
\]

otherwise `baseIn_k^*=baseIn_k-1`. The state-consistent baseline update is

\[
baseIn_k=baseIn_{k-1}+g_k(baseIn_k^*-baseIn_{k-1}).
\]

## Parameter Status

| Parameter | Value | Origin | Tuned in Phase 1C? |
|---|---:|---|---|
| gate_ratio | 1.12 | inherited cfg | No |
| gate_quad_ratio | 1.20 | inherited cfg | No |
| lambda_min | 0.55 | inherited cfg | No |
| lambda_max | 0.995 | inherited cfg | No |
| innovation scale | 0.20 | inherited M2/M4 source | No |
| baseIn alpha | 0.015 | frozen M4 source | No |
| baseIn condition | 1.08 | frozen M4 source | No |
| regularization | 1e-10 | frozen M4 source | No |
| rate limit | 1.2 pF/cycle | inherited cfg | No |
| projection bounds | [0, 40] pF | inherited cfg | No |

`M4 new fitted/tuned parameters = 0`.

## Reproducibility Identity

| Role | SHA-256 |
|---|---|
| M4 source | `A0504AD65B490F803AED454BF4D8CD2C6F724D0A96DF60502F7F32789521EEC1` |
| Evidence helper | `486FF017CE4491C84FBBF84D042EF661A5AFC5A8D255F0B88AC583304D593D15` |
| Algorithm registry | `0F9109EB48C90C33902DCEECD4E2FFAF4F8598516BEDF1EEE6E1E813F2AA3A63` |
| Configuration | `D9F3E6894F51C3D978421C9E1E93828A9205F418C77D01AC449B994A3D789726` |
| AutoComp9 model | `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70` |
| Case07 specification | `8D1A8154960A58BF3E853F471B1112E68EA8029370247B51FCCD5F40359A20B1` |
| Case08 specification | `F18DCF91BA8AFCC11FF9D382D85B91138EEC90296EF785B6C1412181B26F8580` |
| Step 6 definition | `501C8FAC641ABD5BF75653FFD5FB357415E96FC0FEFB6E5CD41DC4B1FA241081` |

- MATLAB: 23.2.0.2365128 (R2023b)
- Simulink: 23.2
- Platform: PCWIN64
- Formal validator: 19/19 PASS
- Historical regression: 11/11 PASS

## Freeze Declaration

```text
FORMULA STATUS:
FROZEN

PARAMETER STATUS:
FROZEN

SOURCE STATUS:
FROZEN
```

The three ablation variants never become production or final algorithms.
