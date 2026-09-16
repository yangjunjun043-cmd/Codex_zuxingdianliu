function schema = phase1a_result_schema()
%PHASE1A_RESULT_SCHEMA Phase 1A 统一结果表的字段定义。
% 每一行未来对应一个 case x algorithm。Step 1 不计算任何结果。

variableNames = [
    "case_name"
    "algorithm_mode"
    "Cs1_RMSE_pF"
    "Cs2_RMSE_pF"
    "B_resistive_fundamental_error_pct"
    "fault_factor_true"
    "fault_factor_est"
    "fault_retention_error_pct"
    "Cs1_pre_post_change_pF"
    "Cs2_pre_post_change_pF"
    "first_gate_trigger_s"
    "gate_duration_cycles"
    "gate_duration_s"
    "random_seed"
    "model_file"
    "model_sha256"
    "run_timestamp"
    "git_commit"
    "git_branch"
    "git_dirty_status"
    ];
variableTypes = [
    "string"
    "string"
    "double"
    "double"
    "double"
    "double"
    "double"
    "double"
    "double"
    "double"
    "double"
    "double"
    "double"
    "double"
    "string"
    "string"
    "string"
    "string"
    "string"
    "string"
    ];

schema = struct();
schema.schema_version = "phase1a_step1_v1";
schema.row_granularity = "one row per case x algorithm";
schema.numeric_not_applicable_value = NaN;
schema.not_applicable_rule = ...
    "All non-applicable numeric metrics must be NaN, never zero.";
schema.variable_names = variableNames;
schema.variable_types = variableTypes;
schema.empty_result_table = table('Size',[0,numel(variableNames)], ...
    'VariableTypes',cellstr(variableTypes), ...
    'VariableNames',cellstr(variableNames));
end
