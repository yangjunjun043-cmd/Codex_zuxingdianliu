# M5 Step1 — M2/M3/M4 update-path audit

## 1. Audit boundary

This is a read-only code and frozen-log audit. No tracker, model, registry, threshold, experiment, or frozen result was modified. No Simulink or experiment run was performed.

The MATLAB Code Analyzer was run on the five primary source files listed below. It reported zero issues for each file. This check is static analysis only and is not a simulation or performance validation.

A separate in-memory MATLAB algebra check verified the projector identities, the `w=0` and `w=1` endpoints, and the information-vector reconciliation formula. The maximum solve-back error was `7.850462293418876e-17`. This was a formula check with synthetic matrices; it did not execute a tracker or simulation.

## 2. Sources and integrity

| Role | File | Current SHA-256 | Frozen comparison |
|---|---|---|---|
| regressor | `MATLAB一键实验/coupling_regressor.m` | `7582F66875A1099DF9656F9A89FE12D8FF6972C55D4A034736527A7DB00E03D5` | read-only anchor |
| M2/M3 tracker | `MATLAB一键实验/track_coupling_cvff_rls.m` | `033135775D81BE4521AA76B8C6C2C8C3415988DA8870561722779DB0FC485D7E` | unchanged during this audit |
| M4 tracker | `MATLAB一键实验/track_coupling_m4_weighted_rls.m` | `A0504AD65B490F803AED454BF4D8CD2C6F724D0A96DF60502F7F32789521EEC1` | exact match to `paper_method_v1` freeze record |
| M4 evidence | `MATLAB一键实验/m4_fault_evidence.m` | `486FF017CE4491C84FBBF84D042EF661A5AFC5A8D255F0B88AC583304D593D15` | exact match to freeze record |
| dispatcher | `MATLAB一键实验/run_phase1a_algorithm.m` | `5C623E150C179E8F86823C02D5B22760C4FBD4EEA496C7FE3B2CF1154814AD16` | unchanged during this audit |

## 3. Parameter ordering and physical signs

`coupling_regressor.m:7-10` fixes the columns as `[Cs1, Cs2] = [CsAB, CsBC]`:

| Phase rows | column 1: Cs1 | column 2: Cs2 |
|---|---:|---:|
| A | `dua-dub` | 0 |
| B | `dub-dua` | `dub-duc` |
| C | 0 | `duc-dub` |

All regressor entries are multiplied by `1e-12`, so the numerical parameters are pF. `coupling_regressor.m:11-13` subtracts the self-capacitance currents from the measured phase currents before estimation.

The reference reconstruction in `reconstruct_refs_from_b.m:16-21` enforces balanced fundamental shifts of `+120/0/-120 deg` and a common third harmonic. The common third-harmonic derivative cancels from both coupling-regressor difference columns.

## 4. M2 update chain

The actual M2 path is `track_coupling_cvff_rls(..., enableGate=false)`.

| Order | Code location | Operation |
|---:|---|---|
| 1 | lines 16-17 | build `X,y`; compute `R=X'X`, `z=X'y` |
| 2 | lines 18-20 | local LS, normalized innovation, VFF `lambda` |
| 3 | lines 21-23 | pre-update residual decomposition and fault-condition evaluation |
| 4 | lines 29-30 | update `J=lambda*J+R`, `h=lambda*h+z`; solve unconstrained `cNew` |
| 5 | lines 31-32 | componentwise rate-limit `cNew-c` and update `c` |
| 6 | line 33 | box projection to configured coupling bounds |
| 7 | line 34 | conditionally update `baseIn` |
| 8 | lines 36-45 | save final cycle parameter/history |

The production M2 tracker does not retain a named `deltaRaw`, but the exact raw increment is

\[
\Delta c_{raw}=(J_{new}+10^{-10}I)^{-1}h_{new}-c_{previous}.
\]

The Phase1B instrumented replay records this quantity before rate limiting and projection.

The M2 implementation updates `J/h` before applying the rate limit and box projection to `c`. It does not reconcile `h` after those constraints. Consequently, a nonzero `h-Jc` mismatch is an existing behavior, not an M5 invention.

## 5. M3 hard-gate chain

M3 is the same function with `enableGate=true`.

The trigger at line 23 is

```text
t_end > 1.0 s
AND E_in > gate_ratio * baseIn
AND E_in > gate_quad_ratio * E_quad
```

At lines 24-28, a trigger loads the existing hold counter and `gate=1` remains active while the counter is positive. During an active gate, lines 29-34 are skipped. Therefore `J`, `h`, `c`, and `baseIn` are all frozen. The history stores the held `c`.

The code convention is important for M5-DH:

\[
w_{hard}=1-gate.
\]

The unmodified M3 code does not form an unconstrained raw proposal on gated cycles. A later M5-DH implementation must move the common M2 proposal calculation ahead of the directional decision in a new M5 tracker; it must not modify the frozen M3 file.

## 6. M4 REW chain

The frozen M4 path is `track_coupling_m4_weighted_rls.m`.

### 6.1 Evidence

Lines 56-65 compute the pre-update residual evidence and call `m4_fault_evidence.m`. The helper uses the inherited `gate_ratio` and `gate_quad_ratio` only as scales:

\[
r_b=E_{in}/(baseIn+\epsilon),\quad
r_q=E_{in}/(E_{quad}+\epsilon),
\]

\[
e_b=\max(0,(r_b-1)/(gate\_ratio-1)),\quad
p_q=\operatorname{clip}(r_q/gate\_quad\_ratio,0,1),
\]

\[
g=1/(1+e_bp_q).
\]

No direction quantity enters this weight. For invalid evidence, the helper sets the natural weight to 1. The `forcedUpdateWeight` branch is a structural-test hook; the production dispatcher does not supply it.

### 6.2 Unweighted proposal and global information weighting

Lines 67-72 first form the unweighted M2 proposal:

\[
J^*=\lambda J+R,\quad h^*=\lambda h+z,
\quad c_{M2,raw}=(J^*+10^{-10}I)^{-1}h^*.
\]

`deltaM2Raw=cM2Raw-cPrevious` is the unprotected raw increment needed by M5.

Lines 74-89 then apply `g` to the complete information-state increments:

\[
J=J_{previous}+g(J^*-J_{previous}),\quad
h=h_{previous}+g(h^*-h_{previous}),
\]

and solve a second candidate `cRaw`. Thus M4 is globally weighted in information space. It is not equivalent to multiplying the final parameter increment by `g`, and it does not preserve the orthogonal parameter component exactly.

### 6.3 Constraints and baseline state

Lines 91-105 apply the existing rate limit and projection after the weighted information solve and log information/rate/projection suppression separately. Lines 110-123 apply the same `g` to the eligible `baseIn` increment. Lines 126-129 compute direction diagnostics only; the frozen M4 report and source state that they never control `g`, `J`, `h`, `c`, or `baseIn`.

## 7. Required M5 branch point

The M5 branch point is M4's `deltaM2Raw`, before lines 74-86 perform global REW interpolation:

```text
J*, h*, c_M2_raw, deltaM2Raw
              |
              +--> M5 directional operator
                       |
                       +--> information-vector reconciliation
                                |
                                +--> existing rate limit
                                         |
                                         +--> existing box projection
```

Two tempting placements are rejected:

1. **After M4 `deltaRaw`:** the perpendicular component has already been globally suppressed by weighted `J/h` and cannot satisfy the M5 formula.
2. **Only on displayed `c`:** leaving `h=h*` stores the rejected fault-direction response in the hidden information state.

The minimum later implementation must therefore use the unweighted M2 raw proposal and reconcile `h` to the directionally protected pre-constraint parameter. The exact formula is fixed in `M5_STEP1_METHOD_SPEC.md`.

## 8. Frozen update-level direction evidence

### 8.1 Available logs

The following frozen files contain cycle-level pre-projection quantities:

- `phase1b_fault_absorption/step2/case05_mechanism_summary.csv`;
- `phase1b_fault_absorption/step3/case06_mechanism_summary.csv`.

`instrument_phase1b_vff_rls.m:131-183` mirrors the M2 update, records `cRaw`, rate-limited and projected candidates, and stores both fault and counterfactual branches. For the 50 cycles with `fault_factor_true>1` in each case, the audit reconstructed:

\[
\Delta c_{raw,F}=c_{raw,F}-c_{before,F},
\]

\[
\Delta c_{raw,CF}=c_{raw,CF}-c_{before,CF},
\]

\[
\Delta c_{raw,fault}=\Delta c_{raw,F}-\Delta c_{raw,CF}.
\]

It also read the logged direct term `K r_fault` and the pre-projection raw candidate separation `c_raw,F-c_raw,CF`.

### 8.2 Subspace results

The rank-one SVD results below use the unoriented axis because `P_f=d_fd_f^T` is sign-invariant.

| Case and quantity | leading direction angle to `[1,-1]` | directional energy |
|---|---:|---:|
| Case05 static LS fault projection | 0.018255 deg | 0.999992965 |
| Case06 static LS fault projection | 0.018255 deg | 0.999992965 |
| Case05 direct `K r_fault` | 0.025060 deg | 0.999992562 |
| Case06 direct `K r_fault` | 0.025725 deg | 0.999992385 |
| Case05 raw candidate separation | 0.061210 deg | 0.999987469 |
| Case06 raw candidate separation | 0.057090 deg | 0.999978877 |
| Case05 fault-induced raw increment difference | 0.016367 deg | 0.997912426 |
| Case06 fault-induced raw increment difference | 0.690739 deg | 0.998409187 |

These energy-weighted axes support the same differential subspace at the raw-update level.

### 8.3 Cyclewise limitation

Cyclewise angles are less stable after the fault and counterfactual branches approach their biased trajectories. The fault-induced raw increment difference has projector-relevant median/P90 axial angles of `33.735/75.275 deg` in Case05 and `19.476/71.595 deg` in Case06. The total fault-branch raw increment is also mixed with normal tracking and history. Small late-cycle differences can reverse sign or be dominated by background increments even though the energy-weighted leading subspace remains differential.

The raw candidate separation is much more stable: its median/P90 axial angles are `0.0156/0.3917 deg` for Case05 and `0.0541/0.7000 deg` for Case06. That quantity is a pre-projection branch-state separation, not the exact per-cycle M5 control input.

The formal conclusion is therefore:

```text
UPDATE_LEVEL_ALIGNMENT:
PARTIALLY VERIFIED

VERIFIED:
energy-weighted raw fault subspace and pre-projection branch separation

NOT YET VERIFIED:
uniform cycle-by-cycle alignment of the exact total Delta theta_raw used by M5
```

This distinction is a Step2 instrumentation requirement, not a reason to replace the model-derived direction with the empirical Phase1B vector.

## 9. Projection ordering

The existing order is raw solve, componentwise rate limit, then box projection. M5 must be inserted before both constraints. If either constraint activates, the final applied update can rotate away from `d_f`; Step0 already observed this boundary in projection-active Phase2 records.

No secondary direction correction is permitted after projection. Step2 must log pre-protection, post-protection, post-rate, and post-projection directions so that the physical-boundary rotation remains visible.

## 10. Audit conclusion

The existing code supplies a unique unprotected M2 raw proposal and reusable M3/M4 evidence scalars. The nominal fault-sensitive axis is derivable from the frozen regressor. A parameter-only M5 patch would be inconsistent with the stored information vector, while composing M5 after M4's global weighting would violate the intended perpendicular pass-through. The state-reconciled branch specified for M5 is therefore a condition of proceeding.
