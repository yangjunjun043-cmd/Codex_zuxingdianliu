function result = reprocess_phase1c_step5b_saved_workspace()
%REPROCESS_PHASE1C_STEP5B_SAVED_WORKSPACE Rebuild outputs without simulation.

step5bRoot = fileparts(mfilename('fullpath'));
phase1cRoot = fileparts(step5bRoot);
step5Root = fullfile(phase1cRoot,'step5_simultaneous_drift_fault');
matlabRoot = fullfile(fileparts(fileparts(phase1cRoot)),'MATLAB一键实验');
addpath(matlabRoot);
addpath(step5Root);
addpath(step5bRoot);
workspacePath = fullfile(step5bRoot,'workspace', ...
    'case08_step5b_workspace.mat');
saved = load(workspacePath);
detail = saved.caseDetail;
definition = saved.definition;
cfg = saved.cfg;

dataF = struct('t',detail.t,'Cs1',detail.Cs1_true, ...
    'Cs2',detail.Cs2_true,'irB',detail.irB_true_F);
dataCF = struct('t',detail.t,'Cs1',detail.Cs1_true, ...
    'Cs2',detail.Cs2_true,'irB',detail.irB_true_CF);
resultsF = rebuild_results(detail,"F");
resultsCF = rebuild_results(detail,"CF");
case07Saved = load(fullfile(step5Root,'workspace', ...
    'case07_step5_workspace.mat'),'evaluated');
evaluated = evaluate_phase1c_step5b_case( ...
    definition,cfg,dataF,dataCF,resultsF,resultsCF, ...
    case07Saved.evaluated);

tablesRoot = fullfile(step5bRoot,'tables');
diagnosticsRoot = fullfile(step5bRoot,'diagnostics');
figuresRoot = fullfile(step5bRoot,'figures');
write_tables(tablesRoot,diagnosticsRoot,evaluated,resultsF,resultsCF);
figurePaths = generate_phase1c_step5b_figures( ...
    figuresRoot,definition,dataF,resultsF,resultsCF,evaluated);

saved.evaluated = evaluated;
saved.figurePaths = figurePaths;
saved.result.evaluated = evaluated;
saved.result.figure_paths = figurePaths;
result = saved.result;
save(workspacePath,'-struct','saved','-v7.3');
fprintf('STEP5B_REPROCESS_ONLY=PASS\n');
fprintf('M4_TRIGGERED_OVERLAP_TRADEOFF=%s\n', ...
    evaluated.triggered_tradeoff.assessment);
end

function results = rebuild_results(detail,branch)
branch = upper(string(branch));
results = struct();
for mode = ["M2" "M3" "M4"]
    results.(char(mode)) = struct();
    results.(char(mode)).cHist = detail.(char(mode+"_cHist_"+branch));
    results.(char(mode)).ir = struct( ...
        'B',detail.(char(mode+"_irB_"+branch)));
    results.(char(mode)).tracker = struct();
end
if branch == "F"
    results.M2.tracker.cycle = detail.M3_cycle_F;
    results.M3.tracker.cycle = detail.M3_cycle_F;
    results.M4.tracker.cycle = detail.M4_cycle_F;
else
    results.M2.tracker.cycle = detail.M4_cycle_CF;
    results.M3.tracker.cycle = detail.M4_cycle_CF;
    results.M4.tracker.cycle = detail.M4_cycle_CF;
end
end

function write_tables(tablesRoot,diagnosticsRoot,evaluated,resultsF,resultsCF)
writetable(evaluated.tracking_fault, ...
    fullfile(tablesRoot,'actual_parameter_tracking.csv'));
writetable(evaluated.tracking_counterfactual, ...
    fullfile(tablesRoot,'no_fault_drift_baseline.csv'));
writetable(evaluated.fault_deviation, ...
    fullfile(tablesRoot,'fault_induced_parameter_deviation.csv'));
writetable(evaluated.retention, ...
    fullfile(tablesRoot,'fault_increment_preservation.csv'));
writetable(evaluated.protection, ...
    fullfile(tablesRoot,'protection_behavior.csv'));
writetable(evaluated.m4_window, ...
    fullfile(tablesRoot,'m4_window_response.csv'));
writetable(evaluated.memory, ...
    fullfile(tablesRoot,'post_fault_memory.csv'));
writetable(evaluated.gate_interval_adaptation, ...
    fullfile(tablesRoot,'gate_interval_adaptation.csv'));
writetable(struct2table(evaluated.gate_interval), ...
    fullfile(tablesRoot,'gate_interval_summary.csv'));
writetable(evaluated.triggered_tradeoff, ...
    fullfile(tablesRoot,'triggered_tradeoff_assessment.csv'));
writetable(evaluated.cross_case, ...
    fullfile(tablesRoot,'case07_case08_comparison.csv'));
writetable(evaluated.constraints, ...
    fullfile(diagnosticsRoot,'constraint_activity.csv'));
writetable(evaluated.direction, ...
    fullfile(diagnosticsRoot,'direction_overlap_diagnostics.csv'));
writetable(resultsF.M3.tracker.cycle, ...
    fullfile(diagnosticsRoot,'m3_fault_cycle_diagnostics.csv'));
writetable(resultsF.M4.tracker.cycle, ...
    fullfile(diagnosticsRoot,'m4_fault_cycle_diagnostics.csv'));
writetable(resultsCF.M4.tracker.cycle, ...
    fullfile(diagnosticsRoot,'m4_counterfactual_cycle_diagnostics.csv'));
end
