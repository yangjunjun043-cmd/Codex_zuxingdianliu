function result = reprocess_phase1c_step5_saved_workspace()
%REPROCESS_PHASE1C_STEP5_SAVED_WORKSPACE Rebuild tables/figures, no simulation.

step5Root = fileparts(mfilename('fullpath'));
workspacePath = fullfile(step5Root,'workspace', ...
    'case07_step5_workspace.mat');
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
evaluated = evaluate_phase1c_step5_case( ...
    definition,cfg,dataF,dataCF,resultsF,resultsCF);

tablesRoot = fullfile(step5Root,'tables');
diagnosticsRoot = fullfile(step5Root,'diagnostics');
figuresRoot = fullfile(step5Root,'figures');
write_tables(tablesRoot,diagnosticsRoot,evaluated);
figurePaths = generate_phase1c_step5_figures( ...
    figuresRoot,definition,dataF,resultsF,resultsCF,evaluated);

saved.evaluated = evaluated;
saved.figurePaths = figurePaths;
saved.result.evaluated = evaluated;
saved.result.figure_paths = figurePaths;
result = saved.result;
save(workspacePath,'-struct','saved','-v7.3');
fprintf('STEP5_REPROCESS_ONLY=PASS\n');
fprintf('M4_OVERLAP_TRADEOFF_ASSESSMENT=%s\n', ...
    evaluated.assessment.label);
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

function write_tables(tablesRoot,diagnosticsRoot,evaluated)
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
writetable(evaluated.tradeoff, ...
    fullfile(tablesRoot,'two_objective_tradeoff.csv'));
writetable(evaluated.direction, ...
    fullfile(diagnosticsRoot,'direction_overlap_diagnostics.csv'));
writetable(evaluated.constraints, ...
    fullfile(diagnosticsRoot,'constraint_activity.csv'));
end
