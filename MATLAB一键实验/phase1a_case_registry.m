function registry = phase1a_case_registry()
%PHASE1A_CASE_REGISTRY Phase 1A 六个正式工况的冻结映射。
% Step 2 冻结正式名称、legacy 映射、seed 与信号来源。

caseName = [
    "Case01_static"
    "Case02_slow_drift"
    "Case03_smooth_step"
    "Case04_random_drift"
    "Case05_fault_only"
    "Case06_drift_then_fault"
    ];
legacyScenarioName = [
    "static"
    "slow_drift"
    "smooth_step"
    "random_drift"
    "fault_only"
    "fault_with_drift"
    ];
seed = [101; 102; 103; 104; 106; 105];
durationS = repmat(4.0,6,1);
model = repmat("AI6109_MOA_AutoComp9.slx",6,1);
sourceType = [
    "autocomp9_partial"
    "autocomp9_partial"
    "legacy_trajectory_migrated_to_autocomp9"
    "legacy_trajectory_migrated_to_autocomp9"
    "phase1a_new_signal_definition"
    "autocomp9_fragmented"
    ];
historicalResultAvailable = [true; true; true; true; false; true];
requiresPhase1aRun = true(6,1);
notes = [
    "AutoComp9 仅有静态链路一致性；缺统一 M0/M2/M3 结果。"
    "AutoComp9 已有 M0/M3 历史指标；缺 M2 和统一结果结构。"
    "旧 smooth_step 轨迹已原样迁移；历史结果仍来自 MATLAB 合成链。"
    "旧 random_drift 轨迹已原样迁移；历史结果仍来自 MATLAB 合成链。"
    "Phase 1A new deterministic seed; no historical Case05 result exists."
    "现有 fault_with_drift 与目标语义一致；证据分散且需统一输出。"
    ];

registry = table(caseName,legacyScenarioName,seed,durationS,model, ...
    sourceType,historicalResultAvailable,requiresPhase1aRun,notes, ...
    'VariableNames',{'case_name','legacy_scenario_name','seed', ...
    'duration_s','model','source_type','historical_result_available', ...
    'requires_phase1a_run','notes'});
end
