# M5 Step1 — GO/NO-GO decision

## Decision

```text
STEP1_DECISION: CONDITIONAL GO
DIRECTION_SOURCE_CASE: CASE A
DIRECTION_SOURCE_LABEL: MODEL_DERIVED
M5_CANDIDATE_DIRECTION: [0.7071067811865476, -0.7071067811865476]^T
NEW_TUNABLE_HYPERPARAMETERS: 0
UPDATE_LEVEL_ALIGNMENT: PARTIALLY VERIFIED
M5_IMPLEMENTATION_THIS_STEP: NO
NEW_SIMULATION_THIS_STEP: NO
```

## Basis for proceeding

1. The frozen `[Cs1,Cs2]=[CsAB,CsBC]` regressor gives the nominal B-phase fault projection direction `[1,-1]` analytically. The direction no longer depends on an empirical-first argument.
2. The model-derived direction differs from the Phase1B empirical SVD direction by only `0.5856097745 deg`; Phase1B is validation evidence, not a calibration input.
3. Frozen Case05/06 update logs support the same energy-weighted raw-update subspace. The leading axes of direct `K r_fault`, raw branch separation, and fault-induced raw increment difference are within `0.016-0.691 deg` of the model direction and explain `99.79%-99.999%` of their respective vector energy.
4. The exact insertion point is identifiable: use the unweighted M2 `deltaM2Raw`, then apply directional protection before the inherited rate limit and projection.
5. Both proposed variants reuse existing scalars only: `w_hard=1-gate` for M5-DH and the frozen M4 `update_weight` for M5-Full.

## Conditions attached to GO

Step2 may begin only if all of the following are treated as structural acceptance tests rather than optional diagnostics:

1. **New tracker only.** Do not modify frozen M2, M3, M4, the M4 evidence helper, model, registry definitions, thresholds, or historical results.
2. **Correct raw input.** Apply M5 to the unweighted M2 raw increment. Do not apply it after M4's globally weighted `delta_c_raw`, and do not multiply the result by REW a second time.
3. **Information-state reconciliation.** After directional protection, set `h=(J*+1e-10 I)theta_dir` while retaining `J*`. A displayed-parameter-only patch is not acceptable because it leaves rejected fault information in `h`.
4. **Existing safety-layer order.** Apply the inherited componentwise rate limit and box projection after M5. Accept and log any downstream rotation; do not add a second direction correction.
5. **Update-level instrumentation.** Log the exact total `Delta theta_raw`, its parallel/perpendicular components, the protected increment, reconciled information state, and post-constraint increment on every cycle.
6. **No new scalar tuning.** No angle threshold, cosine threshold, gain floor, exponent, hysteresis term, post-projection correction, or direction calibration is permitted.
7. **Fixed nominal direction.** Do not feed injected phase-error truth, true fault current, counterfactual data, future data, or the Phase1B empirical vector into the online controller.
8. **Boundary retention.** Preserve near-zero, projection-active, phase-error, drift/fault-collinear, and failed cases in later evaluation.

## Why the decision is conditional rather than unconditional

The energy-weighted update subspace is supported, but the exact cycle-by-cycle total raw increment is not uniformly aligned with `d_f`. In the frozen replay, late-fault raw increment differences become small, reverse sign, or mix with background tracking. Projector-based protection is sign-invariant, yet small-vector direction remains ill-conditioned. Step2 must expose this behavior at the actual control point.

The state-consistent anisotropic formula passed an in-memory algebra check, including the `w=0`/`w=1` endpoints and solve-back reconciliation. No M5 tracker has been implemented, compiled, or tested against the frozen production path. Its code-level equality and mismatch invariants must be demonstrated before any M5 experiment or performance claim.

## Rejection triggers for Step2

Step2 becomes **NO-GO** if any of the following occurs:

- parameter order or regressor signs differ from this audit;
- `w=1` does not reproduce the unprotected M2 proposal exactly;
- `w=0` fails to preserve `P_perp Delta theta_raw` or fails to remove `P_f Delta theta_raw`;
- the reconciled `h` retains a nonzero residual relative to `(J*+1e-10 I)theta_dir` beyond numerical roundoff;
- M5 changes the frozen M2/M3/M4 hashes or uses truth/counterfactual inputs online;
- REW is applied globally before the directional operator or applied twice;
- rate limiting/projection is moved ahead of M5 or followed by an unapproved direction correction;
- implementation requires a new fitted scalar to pass structural tests.

## Stop statement

This decision authorizes only a separately reviewed Step2 implementation and structural test pass. It does not authorize M5 performance experiments, Phase2 reruns, model changes, or claims that M5 separates fault from true drift.
