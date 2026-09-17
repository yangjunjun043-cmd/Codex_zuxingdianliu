function reference = phase1a_historical_reference()
%PHASE1A_HISTORICAL_REFERENCE Frozen regression-only Phase 2 values.
% These values must never be substituted for newly evaluated metrics.

reference.reference_role = "regression_only";
reference.absolute_tolerance = 1e-9;
reference.relative_tolerance = 1e-8;

reference.Case02_slow_drift.M0. ...
    B_resistive_fundamental_error_pct = 8.9587533463069;
reference.Case02_slow_drift.M3. ...
    B_resistive_fundamental_error_pct = 0.354785857594943;
reference.Case02_slow_drift.M3.Cs1_RMSE_pF = 0.157320251866564;
reference.Case02_slow_drift.M3.Cs2_RMSE_pF = 0.108513587962671;

reference.Case06_drift_then_fault.fault_factor_true = 1.59999999999967;
reference.Case06_drift_then_fault.M2. ...
    Cs1_pre_post_change_pF = 5.00627092717497;
reference.Case06_drift_then_fault.M2. ...
    Cs2_pre_post_change_pF = -4.97734794650682;
reference.Case06_drift_then_fault.M2.fault_factor_est = ...
    1.40226869710244;
reference.Case06_drift_then_fault.M3. ...
    Cs1_pre_post_change_pF = 0.561114929229058;
reference.Case06_drift_then_fault.M3. ...
    Cs2_pre_post_change_pF = -0.616252631092842;
reference.Case06_drift_then_fault.M3.fault_factor_est = ...
    1.58287648629316;

reference.source_files = [ ...
    "results_phase2/phase2_key_metrics.csv"
    "results_phase2/fault_retention.csv"
    "results_phase2/gating_ablation/cs_parameter_change.csv"
    "results_phase2/gating_ablation/fault_retention_summary.csv"
    ];
end
