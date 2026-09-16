function registry = phase1a_case_registry()
%PHASE1A_CASE_REGISTRY Phase 1A 六个正式工况的冻结映射。
% Step 1 只登记名称、历史来源和运行需求，不定义或迁移工况轨迹。

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
seed = [101; 102; 103; 104; NaN; 105];
durationS = repmat(4.0,6,1);
model = repmat("AI6109_MOA_AutoComp9.slx",6,1);
sourceType = [
    "autocomp9_partial"
    "autocomp9_partial"
    "legacy_matlab_synthetic_only"
    "legacy_matlab_synthetic_only"
    "none"
    "autocomp9_fragmented"
    ];
historicalResultAvailable = [true; true; true; true; false; true];
requiresPhase1aRun = true(6,1);
notes = [
    "AutoComp9 仅有静态链路一致性；缺统一 M0/M2/M3 结果。"
    "AutoComp9 已有 M0/M3 历史指标；缺 M2 和统一结果结构。"
    "仅有旧 MATLAB 合成链结果；轨迹迁移留到 Step 2。"
    "仅有旧 MATLAB 合成链结果；轨迹迁移留到 Step 2。"
    "无历史定义或结果；seed 与轨迹均留到 Step 2 确认。"
    "现有 fault_with_drift 与目标语义一致；证据分散且需统一输出。"
    ];

registry = table(caseName,legacyScenarioName,seed,durationS,model, ...
    sourceType,historicalResultAvailable,requiresPhase1aRun,notes, ...
    'VariableNames',{'case_name','legacy_scenario_name','seed', ...
    'duration_s','model','source_type','historical_result_available', ...
    'requires_phase1a_run','notes'});
end
