# Phase 1C — M4 Method Final Report

## 1. Research Question

Phase 1C asks whether the fault-absorption mechanism identified in Phase 1B can be mitigated without turning adaptive identification into a permanently frozen estimator. The target is a continuous, state-consistent reduction of fault-induced learning that preserves some true coupling-drift adaptation. It is not a claim of perfect fault/drift separation.

## 2. Frozen Inputs

- Phase 1A unified baseline, model, case registry, M0/M2/M3 definitions, reference reconstruction, sampling, seeds, noise, metrics, and evaluation windows are frozen.
- Phase 1B mechanism schema v1, recursive fault/counterfactual replay, fault retention, and false-compensation definitions are frozen.
- AutoComp9 is the formal model.
- M4 inherits all M2 parameters. Phase 1C introduced zero fitted or tuned parameter.
- Step 6 uses only Case02, Case05, Case07, and Case08.

## 3. Phase 1B Mechanistic Basis

Phase 1B established the following causal chain:

```text
r_fault
  -> projection onto col(X)
  -> false Delta Cs
  -> false coupling compensation
  -> resistive-fault retention loss
```

The key failure is not numerical divergence. Fault residual geometry overlaps the coupling-regressor subspace, so an unconstrained adaptive estimator can produce plausible, bounded Cs changes that compensate a real resistive fault. VFF, rate limits, and projection affect the path but do not by themselves prevent this biased learning.

## 4. M4 Method

The frozen method is:

```text
M4 — Residual-Evidence Weighted Adaptive Identification
REW-AI
paper_method_v1
```

M4 converts residual background excess and phase consistency into a scalar information-update weight `g`. It applies that same weight to both information states `J` and `h`, and to the eligible `baseIn` increment. The parameter estimate is always reconstructed from the updated information state. Direction quantities are recorded for diagnosis only.

## 5. Exact Mathematical Formulation

Residual evidence is

\[
r_b=E_{in}/(baseIn+\epsilon),\qquad
r_q=E_{in}/(E_{quad}+\epsilon),
\]

\[
e_b=\max(0,(r_b-1)/\max(gate\_ratio-1,\epsilon)),
\]

\[
p_q=clip(r_q/gate\_quad\_ratio,0,1),\quad
s=e_bp_q,\quad g=1/(1+s).
\]

With the inherited VFF `lambda_k`,

\[
J_k^*=\lambda_kJ_{k-1}+R_k,\qquad
h_k^*=\lambda_kh_{k-1}+z_k,
\]

\[
J_k=J_{k-1}+g_k(J_k^*-J_{k-1}),\qquad
h_k=h_{k-1}+g_k(h_k^*-h_{k-1}).
\]

The estimate is `c_raw=(J+1e-10 I)\h`, followed by the inherited 1.2 pF/cycle rate bound and `[0,40] pF` projection. The eligible `baseIn` candidate uses alpha 0.015 below the inherited 1.08 condition and is applied with the same `g`.

The complete formula and parameter table are frozen in `step6_ablation/PAPER_METHOD_V1_FREEZE.md`.

## 6. Implementation and State Consistency

Step 2 verified:

- `g=1` reproduces M2 exactly.
- `g=0` freezes `J`, `h`, `c`, and `baseIn` consistently.
- Intermediate `g` scales the information-state increments, not only the displayed parameter.
- Direction diagnostics cannot affect `g`, state updates, rate limiting, projection, or baseline updates.
- No c-only weighting path exists.

Step 6 repeated the strongest structural check on all formal streams. A_NO_WEIGHT equaled M2 sample-for-sample in Case02, Case05 F/CF, Case07 F/CF, and Case08 F/CF: 7/7 exact PASS.

## 7. Step 3 Normal Tracking Evidence

Across the frozen normal cases, M4 preserved normal behavior with limited degradation. On Case02:

- M2 Cs1/Cs2 RMSE: 0.157320/0.108514 pF.
- M4 Cs1/Cs2 RMSE: 0.160864/0.110566 pF.
- M2/M4 B resistive error: 0.354786%/0.364798%.
- M4 mean `g`: 0.975012; USR: 0.024988.
- M4 adds one 50 Hz cycle to Cs2 midpoint lag.

This supports “normal tracking preserved with minor degradation,” not “zero normal cost.” Normal drift can also produce high direction cosine; Case02's median local cosine is 0.9045.

## 8. Step 4 Fault Preservation Evidence

For Case05 factor 1.60:

- M2 estimated factor 1.401075; retention error -12.432825%.
- M3 estimated factor 1.581137; retention error -1.178930%.
- M4 estimated factor 1.408580; retention error -11.963729%.
- M4 fault mean `g` 0.360837 and material latency 19.98 ms.
- M4 information suppression ISR is about 63.9% for J and h.
- M4 fault-bias norm is 3.75% below M2, but far above M3.

M4 responds earlier and reduces fault learning, but the pure-fault steady improvement is small. Continuous scalar weighting slows absorption without changing the biased equilibrium sufficiently.

## 9. Step 5 Weak Overlap Evidence

Case07 combines ongoing drift with a factor-1.30 fault. M3 never triggers and becomes identical to M2. M4 remains active below the hard threshold:

- overlap mean `g`: 0.545523;
- mean retention: M2/M3 0.664536, M4 0.698180;
- mean W1/W2 fault-bias RMS norm: M2/M3 3.477660 pF, M4 3.133961 pF;
- post-fault memory AUC: M2/M3 0.12178, M4 0.11742 pF·s.

This is the principal evidence for a continuous sub-threshold response. It also shows hard-gate threshold dependence.

## 10. Step 5B Triggered Overlap Evidence

Case08 changes only the fault factor to 1.60. M3 is active for all W1/W2 cycles. During its gate, M3 F-branch parameter movement is exactly zero despite true drift of approximately `[+1.307679,-0.871786] pF`.

M4 retains nonzero adaptation:

- M4 same-window mean `g` in the original Step 5B analysis: 0.360041 over W1/W2.
- M4 gate-interval F movement: `[+0.477525,+0.045154] pF`, norm 0.479655 pF.
- M4 CF drift movement: `[+1.396625,-0.889635] pF`, norm 1.655902 pF.
- M4 fault-induced movement: `[-0.919101,+0.934788] pF`, norm 1.310945 pF.
- mean retention: M2 0.666764, M3 0.967739, M4 0.745323.
- post-fault memory AUC: M2 0.19231, M3 0.25917, M4 0.16372 pF·s.

Thus M4 lies between full adaptation and hard freeze: it preserves more fault increment than M2 and more true-drift adaptation than frozen M3. Fault contamination remains significant, and Cs2 net movement has the wrong sign. `||Delta c_CF||/||Delta c_F||` is not used as a purity fraction because drift and fault vectors strongly cancel.

## 11. Ablation Study

Step 6 used three non-production variants:

1. A_NO_WEIGHT (`g=1`) proved that continuous weighting creates the M4/M2 difference.
2. A_BACKGROUND_ONLY (`p_q=1`) tested independent phase-consistency contribution.
3. A_FIXED_LAMBDA (`lambda=0.995`) tested the inherited VFF.

A_BACKGROUND_ONLY and A_FULL are identical in every formal metric. The current cases therefore do not demonstrate an independent phase-consistency contribution.

A_FIXED_LAMBDA sharply preserves faults but fails the normal task:

- Case02 Cs1/Cs2 RMSE: 1.454070/1.070934 pF; B error 4.475509%; lag 1.02/1.00 s.
- Case05 retention error: -1.091548%.
- Case07/08 mean retention: 0.970379/0.980388.
- Case07/08 memory AUC: 0.34204/0.46277 pF·s, much above A_FULL.

The fixed-lambda result is not a new candidate. It demonstrates that fault preservation can be obtained by slowing the estimator, at an unacceptable tracking and recovery cost.

## 12. Component Contribution

| Component | Case02 | Case05 | Case07 | Case08 | Final |
|---|---|---|---|---|---|
| Continuous weighting | LIMITED | SUPPORTED | SUPPORTED | SUPPORTED | SUPPORTED |
| Phase-consistency factor | NOT DEMONSTRATED | NOT DEMONSTRATED | NOT DEMONSTRATED | NOT DEMONSTRATED | NOT DEMONSTRATED |
| VFF | SUPPORTED | LIMITED | LIMITED | LIMITED | SUPPORTED |
| Hard-freeze comparison | NOT APPLICABLE | SUPPORTED | LIMITED | SUPPORTED | SUPPORTED |
| Direction diagnostic | NOT APPLICABLE | NOT DEMONSTRATED | NOT DEMONSTRATED | NOT DEMONSTRATED | NOT DEMONSTRATED |

VFF's support is specifically for tracking and recovery. It is not independently beneficial to steady fault preservation in the current cases.

## 13. M2/M3/M4 Mechanistic Comparison

| Evidence | M2 | M3 | M4 REW-AI |
|---|---|---|---|
| Normal drift tracking | Strong anchor | Same as M2 when gate off | Preserved with small suppression cost |
| Pure fault preservation | Strong absorption | Strong preservation | Slightly better than M2, much weaker than M3 |
| Weak overlap | Full learning | Threshold misses fault | Continuous sub-threshold action |
| Triggered overlap | Full learning | Full freeze | Nonzero weighted learning |
| Response continuity | `g=1` | Binary | Continuous |
| Threshold dependence | N/A | High | Lower, but evidence-scale dependent |
| Adaptation during fault | Full | Zero while gated | Nonzero and contaminated |
| Recovery | Moderate memory | Hold-induced memory | Lowest Case08 memory of the three |
| Main limitation | Fault absorption | Lost drift and missed weak faults | Biased fixed point remains |

No total score, ranking, or universal winner is assigned. M3 and M4 embody different mechanisms.

## 14. Failure Modes and Limitations

1. M4 steady fault preservation is markedly weaker than M3.
2. Scalar weighting slows but does not eliminate fault absorption.
3. Case08 fault-induced and drift-associated movements are the same order.
4. Case08 Cs2 net movement is in the wrong direction.
5. Direction evidence is not fault-specific.
6. M3 misses factor 1.30, confirming threshold dependence.
7. M4 has small unnecessary normal suppression.
8. The phase-consistency factor's independent contribution is not demonstrated.
9. Evidence is representative and single-seed; no Monte-Carlo or robustness claim is permitted.

The method must not be described as direction-aware separation, perfect fault/drift separation, elimination of fault absorption, universally superior to M3, optimal, or robust under all conditions.

## 15. Final Frozen Method

Only A_FULL is frozen as `paper_method_v1`. Formal name:

```text
M4 — Residual-Evidence Weighted Adaptive Identification (REW-AI)
```

```text
FORMULA STATUS: FROZEN
PARAMETER STATUS: FROZEN
SOURCE STATUS: FROZEN
M4 NEW FITTED/TUNED PARAMETERS: 0
```

A_NO_WEIGHT, A_BACKGROUND_ONLY, and A_FIXED_LAMBDA are permanently ablation-only and never become production algorithms. No new parameter optimization is authorized by this report.

## 16. Reproducibility

- MATLAB 23.2.0.2365128 (R2023b)
- Simulink 23.2
- Platform PCWIN64
- AutoComp9 SHA-256: `56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70`
- M4 source SHA-256: `A0504AD65B490F803AED454BF4D8CD2C6F724D0A96DF60502F7F32789521EEC1`
- Evidence helper SHA-256: `486FF017CE4491C84FBBF84D042EF661A5AFC5A8D255F0B88AC583304D593D15`
- Registry SHA-256: `0F9109EB48C90C33902DCEECD4E2FFAF4F8598516BEDF1EEE6E1E813F2AA3A63`
- Case07/Case08 specification SHA-256: `8D1A...20B1` / `F18D...F8580`
- Formal validator: 19/19 PASS
- Historical regression: 11/11 PASS
- A_NO_WEIGHT equivalence: 7/7 exact PASS
- Phase 1A, Phase 1B, and Step 1–5B protected files unchanged during formal execution.

Full hashes, tables, cycle diagnostics, and the MAT workspace are stored under `step6_ablation/`.

## 17. Readiness for Phase 2

Phase 1C provides a valid, bounded, frozen method and a mechanistically interpretable tradeoff. Phase 2 experiment design is permitted for:

- fault-amplitude levels;
- reference phase error;
- noise/SNR;
- different drift directions and rates;
- Monte-Carlo runs;
- statistical summaries.

No Phase 2 work was executed.

## 18. Phase 1C Final Status

```text
PHASE 1C STATUS:
COMPLETE

PHASE 2 READINESS:
YES
```

The final claim is deliberately bounded: REW-AI demonstrates a continuous, interpretable tradeoff between fault preservation and drift adaptation. It reduces fault-induced learning but remains contaminated by it.
