# Phase 2 Step 1C — Monte-Carlo Registry Freeze

## 1. Frozen registry size

| Cohort | Meaning | Formal N | Pilot subset |
|---|---|---:|---:|
| H | healthy / D1 drift | 50 | indices 001–020 |
| F | persistent fault only | 50 | indices 001–020 |
| O | simultaneous D1 drift + temporary fault | 50 | indices 001–020 |
| **Total** |  | **150** | **60** |

Pilot rows are literally the first 20 rows of each formal cohort, not a separately sampled dataset. M0/M2/M3/M4 share truth seed, noise seed, physical data and windows within each condition.

## 2. Master-seed derivation

Source artifacts are ordered exactly as follows. Their SHA-256 values at registry construction were:

| Order | Artifact | SHA-256 |
|---:|---|---|
| 1 | `STEP1B_FACTOR_METRIC_FREEZE.md` | `EB7F9E178ED2B5A604000859BD30EF2893201AE2C66B72BF92307AE3541520CD` |
| 2 | `STEP1B_FACTOR_LEVELS.csv` | `AFD88EDCA3B84344B02462415179182FA52F48CAC1B40BBE01C143C98EC04D85` |
| 3 | `STEP1B_METRIC_FREEZE.csv` | `4EE869B21567023BBF8F16266146D355DF9CA5DE3C04016E2E52343958A5BE52` |

Derivation rule:

1. Join the three uppercase hex hashes with a single LF byte and no trailing LF.
2. SHA-256 the UTF-8 payload.
3. Interpret the first eight hex digits as an unsigned big-endian 32-bit integer.

```text
combined SHA-256 = 88854243331A2E219FBB8F2EB638839F5B86F43909C548E99BFCD5527085A745
master seed       = 0x88854243 = 2290434627
```

No alternative seed was tried.

## 3. Seed and categorical mapping rule

For global registry index 1–150:

```text
truth_seed = 1 + uint32_prefix(SHA256("P2|<master>|TRUTH|<global_index>")) mod 2147483646
noise_seed = 1 + uint32_prefix(SHA256("P2|<master>|NOISE|<global_index>")) mod 2147483646
```

Categorical selections use the first unsigned 32 bits of:

```text
SHA256("P2|<master>|LEVEL|<cohort>|<cohort_index>|<factor>")
```

and index the frozen level list by modulo list length. The lists retain their Step 1B order. This is a deterministic equal-probability categorical construction; the realized registry is saved and must never be resampled based on outcomes.

All 300 truth/noise seeds are nonzero and mutually unique. No algorithm-specific seed exists.

## 4. Active variables and unresolved-bound exclusions

| Cohort | Active categorical factors | Fixed fields |
|---|---|---|
| H | SNR, reference phase, drift rate, Cself mismatch | no fault; D1; initial `[10,10]`; total drift `[+3,-2] pF` |
| F | SNR, reference phase, fault factor, Cself mismatch | Case05 timing; initial/final Cs `[10,10]`; no drift |
| O | SNR, reference phase, fault factor, drift rate, Cself mismatch | D1; initial `[10,10]`; total drift `[+3,-2] pF`; rate-normalized timing |

Negative sequence and CsAC are excluded from primary MC by Step 1B. File audit did not recover traceable numerical bounds for fault onset, Cs initial value or drift amplitude. They are therefore frozen as:

```text
fault_onset     = EXCLUDED_UNRESOLVED_BOUND; use Case05/rate-normalized nominal timing
Cs initial      = EXCLUDED_UNRESOLVED_BOUND; use [10,10] pF
drift amplitude = EXCLUDED_UNRESOLVED_BOUND; use D1 [+3,-2] pF where applicable
```

No new bounds were invented.

## 5. Marginal balance audit

Counts are descriptive only; they were not used to regenerate the registry.

### H cohort

| Factor | Realized counts | Min–max |
|---|---|---:|
| SNR | 20:20; 30:14; 40:16 | 14–20 |
| reference phase | 0:7; 0.33:4; 0.5:9; 1:6; 2:11; 3:13 | 4–13 |
| Cself mismatch / % | -10:7; -5:7; -2:6; 0:10; +2:9; +5:8; +10:3 | 3–10 |
| drift rate | 0.5:11; 1:18; 2:21 | 11–21 |

### F cohort

| Factor | Realized counts | Min–max |
|---|---|---:|
| SNR | 20:19; 30:16; 40:15 | 15–19 |
| reference phase | 0:8; 0.33:11; 0.5:6; 1:6; 2:5; 3:14 | 5–14 |
| Cself mismatch / % | -10:9; -5:5; -2:7; 0:7; +2:11; +5:5; +10:6 | 5–11 |
| fault factor | 1.05:2; 1.10:10; 1.20:12; 1.30:7; 1.40:12; 1.60:7 | 2–12 |

### O cohort

| Factor | Realized counts | Min–max |
|---|---|---:|
| SNR | 20:13; 30:19; 40:18 | 13–19 |
| reference phase | 0:6; 0.33:8; 0.5:8; 1:9; 2:5; 3:14 | 5–14 |
| Cself mismatch / % | -10:10; -5:6; -2:3; 0:12; +2:5; +5:8; +10:6 | 3–12 |
| fault factor | 1.10:19; 1.30:16; 1.60:15 | 15–19 |
| drift rate | 0.5:16; 1:18; 2:16 | 16–18 |

Every frozen level appears at least once in its applicable cohort.

## 6. Pairwise empty-cell audit

With N=50, empty pairwise cells are expected and do not trigger resampling. Empty/total cell counts:

- H: SNR×phase 1/18; SNR×Cself 3/21; SNR×rate 0/9; phase×Cself 14/42; phase×rate 1/18; Cself×rate 2/21.
- F: SNR×phase 1/18; SNR×Cself 4/21; SNR×factor 1/18; phase×Cself 17/42; phase×factor 10/36; Cself×factor 11/42.
- O: SNR×phase 1/18; SNR×Cself 1/21; SNR×factor 0/9; SNR×rate 0/9; phase×Cself 12/42; phase×factor 0/18; phase×rate 1/18; Cself×factor 3/21; Cself×rate 3/21; factor×rate 0/9.

No illegal level, duplicate seed or illegal cohort combination was found. The registry remains frozen despite imbalance.

## 7. Gate state

121/150 MC conditions drew nonzero Cself mismatch and are `PENDING_GATE` under `CSELF_SPLIT_INTERFACE_GATE`; 29 drew zero mismatch and are `READY`. Pending is not blocked. No MC was run.

