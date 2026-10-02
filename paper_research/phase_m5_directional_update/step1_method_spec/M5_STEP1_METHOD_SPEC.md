# M5 Step1 — Directional-update method specification

## 1. Status and scope

This document fixes the mathematical object, direction source, update order, and minimum state-consistent realization for a later M5 implementation. It does not implement M5 and does not report M5 performance.

```text
M5 IMPLEMENTATION: NOT STARTED
NEW SIMULATION: NOT RUN
FROZEN M2/M3/M4 SOURCE MODIFICATION: NONE
DIRECTION SOURCE CASE: CASE A
DIRECTION SOURCE LABEL: MODEL_DERIVED
STEP1 DECISION: CONDITIONAL GO
```

The candidate is limited to the existing two-parameter AB/BC coupling model. It does not claim that fault and physical coupling drift are identifiable when both occupy the same parameter-space direction.

## 2. Frozen parameter and regression definitions

The parameter order is

\[
\theta=\begin{bmatrix}C_{s1}\\C_{s2}\end{bmatrix}
=\begin{bmatrix}C_{AB}\\C_{BC}\end{bmatrix}\quad[\mathrm{pF}].
\]

For one cycle, define

\[
a=\dot u_A-\dot u_B,\qquad b=\dot u_B-\dot u_C,
\qquad q=10^{-12}\ \mathrm{F/pF}.
\]

The frozen regressor is

\[
X=q\begin{bmatrix}
a&0\\
-a&b\\
0&-b
\end{bmatrix},
\]

where each displayed entry denotes a cycle-length column vector. The observation is the three-phase total current after subtracting the configured self-capacitance currents:

\[
y=\begin{bmatrix}
i_A-C_{self,A}\dot u_A\\
i_B-C_{self,B}\dot u_B\\
i_C-C_{self,C}\dot u_C
\end{bmatrix}.
\]

At the beginning of cycle \(k\), before any information or parameter update,

\[
e_k=y_k-X_k\theta_{k-1}.
\]

`E_in` and `E_quad` are RMS aggregates of the fitted in-phase and quadrature components of this pre-update residual. They are evidence measures, not direct measurements of pure fault current or pure capacitance error.

## 3. Existing raw RLS proposal

The local least-squares candidate and VFF are retained exactly:

\[
\theta_{LS,k}=(R_k+10^{-10}I)^{-1}z_k,
\quad R_k=X_k^TX_k,\quad z_k=X_k^Ty_k,
\]

\[
\nu_k=\left\|(\theta_{LS,k}-\theta_{k-1})/[5,5]^T\right\|_2,
\]

\[
\lambda_k=\lambda_{max}-(\lambda_{max}-\lambda_{min})
\operatorname{clip}(\nu_k/0.20,0,1).
\]

The unprotected M2 information proposal is

\[
J_k^*=\lambda_kJ_{k-1}+R_k,\qquad
h_k^*=\lambda_kh_{k-1}+z_k,
\]

\[
\theta_{M2,raw,k}=(J_k^*+10^{-10}I)^{-1}h_k^*,
\]

\[
\boxed{\Delta\theta_{raw,k}=\theta_{M2,raw,k}-\theta_{k-1}}.
\]

This boxed quantity is the only authorized input to the M5 directional operator. In the M4 logger it corresponds to `delta_c_m2_raw`, not `delta_c_raw`. The latter has already undergone M4's global information-state weighting and would suppress the perpendicular component before M5 can preserve it.

## 4. Model-derived fault-sensitive direction

### 4.1 Nominal derivation

For the reconstructed balanced fundamental,

\[
\dot u_B=D\cos\tau,\quad
\dot u_A=D\cos(\tau+2\pi/3),\quad
\dot u_C=D\cos(\tau-2\pi/3).
\]

The common third-harmonic derivative cancels in both \(a\) and \(b\). Over a complete cycle,

\[
X^TX\ \propto\
\begin{bmatrix}
3&3/4\\
3/4&3
\end{bmatrix}.
\]

A B-phase-only resistive fault increment has regression-space form

\[
r_f=\begin{bmatrix}0&r_B&0\end{bmatrix}^T.
\]

Only the fundamental component of \(r_B\) projects onto the fundamental-only coupling regressor. For a nominal in-phase resistive fundamental, \(r_B=F\sin\tau\),

\[
X^Tr_f\ \propto\
\begin{bmatrix}1\\-1\end{bmatrix}.
\]

Because `[1,-1]^T` is an eigenvector of the displayed normal matrix,

\[
(X^TX)^{-1}X^Tr_f\ \parallel\
\begin{bmatrix}1\\-1\end{bmatrix}.
\]

The selected M5 direction is therefore

\[
\boxed{
d_f=d_0=\frac{1}{\sqrt2}
\begin{bmatrix}1\\-1\end{bmatrix}
=\begin{bmatrix}
0.7071067811865476\\
-0.7071067811865476
\end{bmatrix}.}
\]

Its sign is only a reporting convention. The projector is unchanged if `d_f` is replaced by `-d_f`.

### 4.2 Operating-point rotation under reference phase error

If the reconstructed reference is displaced from the true resistive-current phase by \(\delta\), the same model gives

\[
\Delta\theta_f(\delta)\ \propto\
\frac{\sqrt3}{9}\cos\delta
\begin{bmatrix}1\\-1\end{bmatrix}
-\frac15\sin\delta
\begin{bmatrix}1\\1\end{bmatrix}.
\]

Thus the nominal direction is exact at \(\delta=0\), while phase mismatch adds a common-mode component. The angle from the differential axis is

\[
\alpha(\delta)=\arctan\left(\frac{3\sqrt3}{5}|\tan\delta|\right).
\]

The injected phase-error truth used in a simulation is not an online observable and must not be supplied to M5. Step2 therefore uses the fixed nominal `d_0`; the formula above defines an applicability boundary, not an operating-point correction input.

### 4.3 Source classification and empirical comparison

The direction is classified as **CASE A / MODEL_DERIVED** because its numerical value follows from the frozen parameter order, regressor signs, balanced reference reconstruction, and B-only fault support. It is not fitted to Phase1B or Phase2.

The Phase1B empirical SVD direction is

\[
d_{emp}=\begin{bmatrix}0.6998427631\\-0.7142969319\end{bmatrix}.
\]

The unoriented angle between `d_0` and `d_emp` is `0.5856097745 deg`, and the Frobenius distance between their rank-one projectors is `0.0144541688`. These values validate the nominal derivation over the development set but do not calibrate `d_0`.

## 5. Projectors

With unit-norm `d_f`,

\[
P_f=d_fd_f^T
=\frac12\begin{bmatrix}1&-1\\-1&1\end{bmatrix},
\]

\[
P_\perp=I-P_f
=\frac12\begin{bmatrix}1&1\\1&1\end{bmatrix}.
\]

For any raw update,

\[
\Delta\theta_\parallel=P_f\Delta\theta_{raw},\qquad
\Delta\theta_\perp=P_\perp\Delta\theta_{raw}.
\]

`P_f` extracts the differential AB/BC mode and `P_perp` extracts the common mode. Both projectors are fixed, symmetric, idempotent, mutually orthogonal, and sum to the identity.

## 6. M5-DH: directional hard protection

Let `gate_k` be the existing M3 hold-active flag after the unchanged trigger and hold-counter logic. Its code convention is `gate_k=1` during a frozen M3 cycle. Define

\[
w_{hard,k}=1-gate_k\in\{0,1\}.
\]

The M5-DH protected update is

\[
\boxed{
\Delta\theta_{M5-DH,k}
=P_\perp\Delta\theta_{raw,k}
+w_{hard,k}P_f\Delta\theta_{raw,k}.}
\]

When the M3 gate is inactive, M5-DH equals M2. When it is active, only the differential component is suppressed; the common-mode component remains eligible. The existing trigger ratios, `t>1 s` condition, hold length, VFF, rate limit, and bounds are unchanged.

The baseline residual state follows the existing hard-gate semantics:

\[
baseIn_k=baseIn_{k-1}
+w_{hard,k}(baseIn_k^*-baseIn_{k-1}).
\]

## 7. M5-Full: directional continuous protection

Let

\[
w_{REW,k}=g_k=\frac{1}{1+s_k}
\]

be the existing frozen M4 update weight from `m4_fault_evidence.m`, without a new threshold, floor, exponent, or direction-dependent tuning term.

Production M5-Full must use the helper's natural weight. The existing helper's invalid-evidence fallback is `w_REW=1`, and its `forced_update_weight` test option is not an online M5 input.

The M5-Full protected update is

\[
\boxed{
\Delta\theta_{M5-Full,k}
=P_\perp\Delta\theta_{raw,k}
+w_{REW,k}P_f\Delta\theta_{raw,k}.}
\]

Equivalently,

\[
\Delta\theta_{M5-Full,k}
=\left[I-(1-w_{REW,k})P_f\right]\Delta\theta_{raw,k}.
\]

M5-Full reuses the M4 evidence scalar but does **not** first execute M4's global interpolation of `J/h`. Applying the directional law to the already weighted M4 `delta_c_raw` would suppress the perpendicular channel globally and would no longer implement the boxed formula.

The eligible `baseIn` increment remains the frozen M4 weighted update:

\[
baseIn_k=baseIn_{k-1}
+w_{REW,k}(baseIn_k^*-baseIn_{k-1}).
\]

## 8. Minimum state-consistent realization

Changing only the displayed parameter while leaving `h_k=h_k^*` would retain the rejected fault-direction information in the hidden RLS state. The later implementation must therefore realize the protected parameter in the information vector.

For either M5 variant, define

\[
A_k=P_\perp+w_kP_f,
\qquad
\theta_{dir,k}=\theta_{k-1}+A_k\Delta\theta_{raw,k}.
\]

The minimum state-consistent candidate is

\[
\boxed{
J_k=J_k^*,\qquad
h_k=(J_k+10^{-10}I)\theta_{dir,k}.}
\]

This choice has four required properties:

1. `w=1` gives `theta_dir=theta_M2_raw` and therefore `h_k=h_k^*` exactly;
2. `P_perp` passes through unchanged;
3. only the `P_f` component is scaled by `w`;
4. solving `(J_k+1e-10 I)\h_k` returns `theta_dir`, so the suppressed direction is not left in `h` for later release.

`J_k^*` is retained because it contains regressor geometry, while the response-dependent contamination enters through `h`. The inherited VFF can still alter `J_k^*` during a fault; M5 does not redesign VFF and must log this limitation.

## 9. Frozen update order and insertion point

The later implementation must follow this order:

```text
1. Build X, y in [Cs1, Cs2] order.
2. Compute local LS innovation and the inherited lambda.
3. Compute the pre-update residual, E_in, E_quad, and baseIn evidence.
4. Compute the existing M3 gate state or existing M4 REW weight.
5. Form the unprotected M2 information proposal J*, h*.
6. Solve theta_M2_raw and form Delta theta_raw.
7. Apply the M5 directional law to Delta theta_raw.
8. Reconcile h to theta_dir while retaining J*.
9. Apply the existing componentwise rate limit to theta_dir-theta_previous.
10. Apply the existing [0, 40] pF projection/bounds.
11. Store the final theta and the inherited baseline-state update.
```

M5 is therefore inserted after the unconstrained M2 raw proposal and before the existing rate limit and box projection.

The downstream rate limit and projection may rotate the final applied update. That rotation is accepted as the existing physical safety layer. M5 must not add a second directional correction after projection. The stored `h` remains tied to the pre-constraint `theta_dir`, matching the existing convention that rate limiting and projection can create `h-J*theta` mismatch; Step2 must log that mismatch rather than silently changing the frozen constraint semantics.

## 10. Zero-new-hyperparameter audit

M5 adds no fitted scalar:

| Quantity | Origin | New tuning? |
|---|---|---:|
| `d_f=[1,-1]/sqrt(2)` | analytic frozen-model geometry | No |
| `P_f`, `P_perp` | algebra from `d_f` | No |
| `w_hard=1-gate` | existing M3 gate and hold | No |
| `w_REW` | frozen M4 evidence function | No |
| `lambda`, innovation scale | existing M2/M4 | No |
| rate limit and bounds | existing configuration | No |
| `1e-10 I` | existing RLS regularization | No |

No cosine threshold, direction-validity threshold, blend floor, gain, hysteresis term, or post-projection correction is authorized in M5 Step2.

## 11. Required Step2 instrumentation and structural tests

Step2 must record, per cycle:

- `theta_previous`, `theta_M2_raw`, and `Delta theta_raw`;
- `P_f Delta theta_raw` and `P_perp Delta theta_raw`;
- `gate`, `w_hard`, `w_REW`, and the selected M5 weight;
- `theta_dir`, rate-limited theta, projected theta, and each suppression vector;
- projection/rate-limit active flags and pre/post direction angles;
- `J*`, `h*`, reconciled `h`, and `h-(J+1e-10 I)theta_dir`;
- inherited final `h-J theta` mismatch after rate/projection;
- `baseIn` candidate and applied increment.

Minimum structural tests are:

1. parameter order and projector identities;
2. `w=1` exact equality with the M2 proposal;
3. `w=0` exact removal of the differential component and exact preservation of the common component;
4. no hidden directional component in the reconciled information vector;
5. no double use of the M4 global weight;
6. unchanged rate-limit and projection order;
7. unchanged M2/M3/M4 frozen hashes;
8. explicit logging of boundary rotation without a post-projection correction.

## 12. Interpretation limits

- The direction is model-derived for the current AB/BC parameterization and nominal balanced reference geometry, not a universal MOA direction.
- The fixed direction does not correct unknown reference phase error, severe imbalance, sensor-chain mismatch, or an expanded `CsAC`/matrix parameterization.
- Real drift may have a large projection on `d_f`; M5 can suppress such drift together with a fault. It is a directional protection law, not a source separator.
- The empirical Phase1B direction validates the nominal model direction but is not an online input and is not used for calibration.
- Existing projection-active cases remain validity-boundary cases because downstream constraints can rotate the final applied update.
