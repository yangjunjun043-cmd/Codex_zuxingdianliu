function output = run_phase2_overlap_matrix()
%RUN_PHASE2_OVERLAP_MATRIX Phase 2 Step 4 frozen overlap validation.
% This runner executes the preregistered simultaneous drift + temporary
% fault matrix and the Case08 protection-schedule counterfactual replay.
% It does not tune or modify M0/M2/M3/M4 or any frozen registry/source.

paths = step4_paths();
addpath(paths.matlab_root);
if ~isfolder(paths.output_root)
    mkdir(paths.output_root);
end
cacheRoot = fullfile(tempdir,'moa_phase2_step4_cache');
Simulink.fileGenControl('set','CacheFolder',cacheRoot, ...
    'CodeGenFolder',cacheRoot,'createDir',true);

conditionRegistry = read_registry(paths.condition_registry);
executionRegistry = read_registry(paths.execution_registry);
conditionIds = step4_condition_ids();
assert_step4_registry(conditionRegistry,executionRegistry,conditionIds);

pre = capture_frozen_integrity(paths);
rows = repmat(blank_row(),0,1);
conditionComplete = false(numel(conditionIds),1);
newRunComplete = 0;
anchorCache = struct();

if pre.pass
    for k = 1:numel(conditionIds)
        conditionId = conditionIds(k);
        registryRow = conditionRegistry( ...
            conditionRegistry.condition_id == conditionId,:);
        try
            if ismember(conditionId,["P2_AN_C07","P2_AN_C08"])
                [currentRows,anchor] = run_anchor_condition( ...
                    paths,registryRow,executionRegistry);
                anchorCache.(char(conditionId)) = anchor;
            else
                currentRows = run_new_condition( ...
                    registryRow,executionRegistry);
            end
            rows = [rows;currentRows]; %#ok<AGROW>
            complete = arrayfun(@main_row_complete,currentRows);
            conditionComplete(k) = numel(currentRows) == 4 && all(complete);
            newRunComplete = newRunComplete+nnz( ...
                string({currentRows.provenance}).' == "NEW_RUN" & complete);
            fprintf('STEP4 MAIN %02d/13 %s: %d/4 complete.\n', ...
                k,conditionId,nnz(complete));
        catch exception
            failed = failure_rows(registryRow,exception);
            rows = [rows;failed]; %#ok<AGROW>
            fprintf(2,'STEP4 MAIN %s failed: %s\n', ...
                conditionId,exception.message);
        end
    end
else
    exception = MException('Phase2:FrozenIntegrity', ...
        'PRE frozen integrity failed; Step 4 execution was blocked.');
    for k = 1:numel(conditionIds)
        registryRow = conditionRegistry( ...
            conditionRegistry.condition_id == conditionIds(k),:);
        rows = [rows;failure_rows(registryRow,exception)]; %#ok<AGROW>
    end
end

replayGatePass = false;
replayComplete = false;
if pre.pass && isfield(anchorCache,'P2_AN_C08')
    try
        [gateRows,replayRows,replayGatePass,replayComplete] = ...
            run_case08_replay(anchorCache.P2_AN_C08);
        rows = [rows;gateRows;replayRows]; %#ok<AGROW>
        fprintf('REPLAY_EQUIVALENCE_GATE=%s\n',pass_fail(replayGatePass));
    catch exception
        gateRows = replay_failure_rows(exception);
        rows = [rows;gateRows]; %#ok<AGROW>
        fprintf(2,'STEP4 replay failed: %s\n',exception.message);
    end
end

post = capture_frozen_integrity(paths);
frozenPass = pre.pass && post.pass && ...
    isequal(pre.actual_sha256,post.actual_sha256);
for k = 1:numel(rows)
    rows(k).frozen_integrity_pass = frozenPass;
end
resultTable = struct2table(rows,'AsArray',true);
main = resultTable.record_type == "MAIN";
mainComplete = main & ~resultTable.numerical_failure & ...
    ~resultTable.metric_missing & resultTable.registry_match & ...
    resultTable.shared_data_pass;
physicalComplete = nnz(conditionComplete);
mainCount = nnz(mainComplete);
newRunCount = nnz(mainComplete & resultTable.provenance == "NEW_RUN");
numericalFailures = nnz(main & resultTable.numerical_failure);
metricMissing = nnz(main & resultTable.metric_missing);

if ~frozenPass || physicalComplete < 13 || mainCount < 52
    status = "BLOCKED";
elseif ~replayGatePass || ~replayComplete
    status = "PARTIAL";
else
    status = "PASS";
end
readyForStep5 = frozenPass && physicalComplete == 13 && ...
    mainCount == 52;

writetable(resultTable,paths.results_csv);
write_step4_report(paths,resultTable,pre,post,status, ...
    physicalComplete,mainCount,newRunCount,numericalFailures, ...
    metricMissing,replayGatePass,replayComplete,frozenPass,readyForStep5);

output = struct( ...
    'status',status, ...
    'overlap_physical_points',physicalComplete, ...
    'main_evaluation_records',mainCount, ...
    'new_algorithm_runs_complete',newRunCount, ...
    'numerical_failures',numericalFailures, ...
    'metric_missing_rows',metricMissing, ...
    'replay_equivalence_gate',replayGatePass, ...
    'counterfactual_replay_complete',replayComplete, ...
    'frozen_source_modified',~frozenPass, ...
    'ready_for_step5',readyForStep5, ...
    'results_csv',string(paths.results_csv), ...
    'report',string(paths.report));

fprintf('STEP_4_STATUS=%s\n',status);
fprintf('OVERLAP_PHYSICAL_POINTS=%d/13\n',physicalComplete);
fprintf('MAIN_EVALUATION_RECORDS=%d/52\n',mainCount);
fprintf('NEW_ALGORITHM_RUNS_COMPLETE=%d/46\n',newRunCount);
fprintf('NUMERICAL_FAILURES=%d\n',numericalFailures);
fprintf('METRIC_MISSING_ROWS=%d\n',metricMissing);
fprintf('REPLAY_EQUIVALENCE_GATE=%s\n',pass_fail(replayGatePass));
fprintf('COUNTERFACTUAL_REPLAY=%s\n', ...
    complete_blocked(replayComplete));
fprintf('FROZEN_SOURCE_MODIFIED=%s\n',yes_no(~frozenPass));
fprintf('READY_FOR_STEP5=%s\n',yes_no(readyForStep5));
end

function paths = step4_paths()
matlabRoot = fileparts(mfilename('fullpath'));
projectRoot = fileparts(matlabRoot);
step1Root = fullfile(projectRoot,'paper_research', ...
    'phase2_full_validation','step1_matrix_spec');
outputRoot = fullfile(projectRoot,'paper_research', ...
    'phase2_full_validation','step4_overlap_matrix');
paths = struct( ...
    'project_root',projectRoot, ...
    'matlab_root',matlabRoot, ...
    'step1_root',step1Root, ...
    'output_root',outputRoot, ...
    'manifest',fullfile(projectRoot,'paper_research', ...
        'phase1c_m4_method','step6_ablation','tables', ...
        'freeze_hash_manifest.csv'), ...
    'specification',fullfile(step1Root, ...
        'STEP1_PHASE2_MATRIX_SPECIFICATION.md'), ...
    'condition_registry',fullfile(step1Root, ...
        'phase2_condition_registry.csv'), ...
    'execution_registry',fullfile(step1Root, ...
        'phase2_execution_registry.csv'), ...
    'results_csv',fullfile(outputRoot,'step4_overlap_results.csv'), ...
    'report',fullfile(outputRoot, ...
        'STEP4_SIMULTANEOUS_DRIFT_FAULT_MATRIX.md'));
paths.case07_workspace = fullfile(projectRoot,'paper_research', ...
    'phase1c_m4_method','step5_simultaneous_drift_fault', ...
    'workspace','case07_step5_workspace.mat');
paths.case08_workspace = fullfile(projectRoot,'paper_research', ...
    'phase1c_m4_method','step5b_triggered_overlap', ...
    'workspace','case08_step5b_workspace.mat');
end

function ids = step4_condition_ids()
ids = ["P2_OV_R05_F110";"P2_OV_R05_F130";"P2_OV_R05_F160"; ...
    "P2_OV_R10_F110";"P2_AN_C07";"P2_AN_C08"; ...
    "P2_OV_R20_F110";"P2_OV_R20_F130";"P2_OV_R20_F160"; ...
    "P2_DD_D2_F130";"P2_DD_D2_F160"; ...
    "P2_DD_D3_F130";"P2_DD_D3_F160"];
end

function tableOut = read_registry(path)
tableOut = readtable(path,'Delimiter',',','TextType','string', ...
    'VariableNamingRule','preserve');
end

function assert_step4_registry(registry,executionRegistry,ids)
selected = registry(ismember(registry.condition_id,ids),:);
if height(selected) ~= 13 || numel(unique(selected.condition_id)) ~= 13
    error('Phase2:Step4ConditionCount', ...
        'Frozen registry must contain exactly 13 unique Step 4 points.');
end
if any(selected.registry_state ~= "FROZEN") || ...
        any(arrayfun(@truthy,selected.is_blocked))
    error('Phase2:Step4RegistryState', ...
        'Step 4 contains blocked or non-frozen physical points.');
end
evaluations = executionRegistry( ...
    ismember(executionRegistry.condition_id,ids) & ...
    executionRegistry.record_type == "MAIN_ALGORITHM_EVALUATION",:);
if height(evaluations) ~= 52
    error('Phase2:Step4EvaluationCount', ...
        'Frozen registry must contain exactly 52 Step 4 MAIN rows.');
end
for id = ids.'
    modes = sort(evaluations.algorithm_id( ...
        evaluations.condition_id == id));
    if ~isequal(modes,["M0";"M2";"M3";"M4"])
        error('Phase2:Step4AlgorithmSet', ...
            'Condition %s does not map to M0/M2/M3/M4.',id);
    end
end
newIds = setdiff(ids,["P2_AN_C07";"P2_AN_C08"],'stable');
newRows = evaluations(ismember(evaluations.condition_id,newIds),:);
if any(newRows.execution_status ~= "READY") || height(newRows) ~= 44
    error('Phase2:Step4NewExecutionState', ...
        'The 11 new points must map to 44 READY evaluations.');
end
for id = ["P2_AN_C07","P2_AN_C08"]
    current = evaluations(evaluations.condition_id == id,:);
    m0 = current(current.algorithm_id == "M0",:);
    reused = current(ismember(current.algorithm_id,["M2","M3","M4"]),:);
    if height(m0) ~= 1 || ~truthy(m0.execution_required) || ...
            height(reused) ~= 3 || any(reused.result_reuse_status ~= ...
            "EXACT_REUSE")
        error('Phase2:Step4AnchorProvenance', ...
            'Anchor %s does not preserve the frozen M0/reuse split.',id);
    end
end
end

function [rows,cache] = run_new_condition(registryRow,executionRegistry)
assert_ready_execution(executionRegistry,registryRow.condition_id);
cfg = overlap_cfg(registryRow);
signalsF = build_overlap_signals(registryRow,cfg,"F");
signalsCF = build_overlap_signals(registryRow,cfg,"CF");
zero = zeros(size(signalsF.t));
cleanF = run_once(cfg,signalsF,zero,zero,zero);
rng(registryRow.deterministic_seed+10000);
noise = struct( ...
    'A',rms(cleanF.ia)/10^(registryRow.SNR_dB/20)*randn(size(cleanF.ia)), ...
    'B',rms(cleanF.ib)/10^(registryRow.SNR_dB/20)*randn(size(cleanF.ib)), ...
    'C',rms(cleanF.ic)/10^(registryRow.SNR_dB/20)*randn(size(cleanF.ic)));
dataF = run_once(cfg,signalsF,noise.A,noise.B,noise.C);
dataCF = run_once(cfg,signalsCF,noise.A,noise.B,noise.C);
[dataF,dataCF] = add_self_capacitance(dataF,dataCF,cfg.Cself_pF);
ref = reconstruct_refs_from_b(dataF.t,dataF.ub,cfg.f, ...
    cfg.init_start,cfg.init_end,cfg.phase_error_deg);
assert_physical_pair(registryRow,dataF,dataCF,signalsF,signalsCF,noise);

resultsF = struct();
resultsCF = struct();
for mode = ["M0","M2","M3","M4"]
    resultsF.(char(mode)) = run_phase1a_algorithm( ...
        mode,dataF,ref,cfg,repmat(400,1,3));
    resultsCF.(char(mode)) = run_phase1a_algorithm( ...
        mode,dataCF,ref,cfg,repmat(400,1,3));
end
signature = pair_signature(dataF,dataCF,signalsF,noise,ref);
windows = overlap_windows(registryRow.evaluation_window_set_id);
rows = build_main_rows(registryRow,resultsF,resultsCF,dataF,dataCF, ...
    cfg,windows,signature,"NEW_RUN", ...
    "AutoComp9 Phase2 registry run; matched F/CF branches");
cache = struct('registry_row',registryRow,'cfg',cfg,'dataF',dataF, ...
    'dataCF',dataCF,'ref',ref,'resultsF',resultsF, ...
    'resultsCF',resultsCF,'windows',windows,'signature',signature);
end

function [rows,cache] = run_anchor_condition( ...
        paths,registryRow,executionRegistry)
conditionId = registryRow.condition_id;
if conditionId == "P2_AN_C07"
    workspacePath = paths.case07_workspace;
else
    workspacePath = paths.case08_workspace;
end
frozen = load(workspacePath,'caseDetail','definition','cfg');
cfg = frozen.cfg;
cfg.model = 'AI6109_MOA_AutoComp9';
signalsF = build_overlap_signals(registryRow,cfg,"F");
signalsCF = build_overlap_signals(registryRow,cfg,"CF");
noise = struct('A',frozen.caseDetail.shared_noise_A, ...
    'B',frozen.caseDetail.shared_noise_B, ...
    'C',frozen.caseDetail.shared_noise_C);
dataF = run_once(cfg,signalsF,noise.A,noise.B,noise.C);
dataCF = run_once(cfg,signalsCF,noise.A,noise.B,noise.C);
[dataF,dataCF] = add_self_capacitance(dataF,dataCF,cfg.Cself_pF);
ref = reconstruct_refs_from_b(dataF.t,dataF.ub,cfg.f, ...
    cfg.init_start,cfg.init_end,cfg.phase_error_deg);
assert_physical_pair(registryRow,dataF,dataCF,signalsF,signalsCF,noise);
if max(abs(dataF.irB-frozen.caseDetail.irB_true_F)) > 1e-12 || ...
        max(abs(dataCF.irB-frozen.caseDetail.irB_true_CF)) > 1e-12
    error('Phase2:Step4AnchorPhysicalReplay', ...
        'Anchor %s physical replay differs from frozen truth.',conditionId);
end

resultsF = struct();
resultsCF = struct();
resultsF.M0 = run_phase1a_algorithm("M0",dataF,ref,cfg,repmat(400,1,3));
resultsCF.M0 = run_phase1a_algorithm("M0",dataCF,ref,cfg,repmat(400,1,3));
for mode = ["M2","M3","M4"]
    resultsF.(char(mode)) = frozen_result(frozen.caseDetail,mode,"F");
    resultsCF.(char(mode)) = frozen_result(frozen.caseDetail,mode,"CF");
end

signature = pair_signature(dataF,dataCF,signalsF,noise,ref);
windows = overlap_windows(registryRow.evaluation_window_set_id);
m0Rows = build_main_rows(registryRow,resultsF,resultsCF,dataF,dataCF, ...
    cfg,windows,signature,"MIXED",string(workspacePath));
for k = 1:numel(m0Rows)
    if m0Rows(k).algorithm_id == "M0"
        m0Rows(k).provenance = "NEW_RUN";
        m0Rows(k).source_artifact = "M0 missing-anchor completion";
    else
        m0Rows(k).provenance = "EXACT_REUSE";
        m0Rows(k).source_artifact = string(workspacePath);
    end
end
rows = m0Rows;
assert_anchor_execution(executionRegistry,conditionId,rows);
cache = struct('registry_row',registryRow,'cfg',cfg,'dataF',dataF, ...
    'dataCF',dataCF,'ref',ref,'resultsF',resultsF, ...
    'resultsCF',resultsCF,'windows',windows,'signature',signature, ...
    'frozen',frozen,'workspace_path',string(workspacePath));
end

function result = frozen_result(detail,mode,branch)
suffix = char(branch);
name = char(mode);
result = struct('algorithm_mode',mode, ...
    'cHist',detail.([name '_cHist_' suffix]), ...
    'ir',struct('B',detail.([name '_irB_' suffix])), ...
    'tracker',struct());
if mode == "M3" && branch == "F"
    result.tracker.cycle = detail.M3_cycle_F;
elseif mode == "M4" && branch == "F"
    result.tracker.cycle = detail.M4_cycle_F;
elseif mode == "M4" && branch == "CF"
    result.tracker.cycle = detail.M4_cycle_CF;
end
end

function cfg = overlap_cfg(row)
cfg = patent_default_config();
cfg.model = 'AI6109_MOA_AutoComp9';
cfg.StopTime = row.simulation_stop_s;
cfg.SNR_dB = row.SNR_dB;
cfg.h3_ratio = row.h3_ratio;
cfg.phi3_deg = row.h3_phase_deg;
cfg.Vneg_pu = row.negative_sequence_pu;
cfg.Cself_pF = row.Cself_truth_pF;
cfg.phase_error_deg = row.reference_phase_error_deg;
end

function signals = build_overlap_signals(row,cfg,branch)
t = (0:cfg.Ts:cfg.StopTime).';
driftProgress = smooth_step(t,row.drift_start_s,row.drift_end_s);
Cs1 = row.Cs1_initial_pF+row.drift_delta_Cs1_pF*driftProgress;
Cs2 = row.Cs2_initial_pF+row.drift_delta_Cs2_pF*driftProgress;
faultScale = ones(size(t));
if upper(string(branch)) == "F"
    up = smooth_step(t,row.fault_start_s,row.fault_ramp_end_s);
    down = smooth_step(t,row.fault_plateau_end_s,row.fault_end_s);
    faultScale = 1+(row.fault_factor-1)*min(up,1-down);
end
signals = struct('t',t,'Cs1_pF',Cs1,'Cs2_pF',Cs2, ...
    'fault_scale',faultScale,'branch',upper(string(branch)));
end

function y = smooth_step(t,t0,t1)
x = min(max((t-t0)/(t1-t0),0),1);
y = x.^2.*(3-2*x);
end

function data = run_once(cfg,signals,noiseA,noiseB,noiseC)
in = Simulink.SimulationInput(cfg.model);
vars = struct('StopTime',cfg.StopTime,'h3_ratio',cfg.h3_ratio, ...
    'phi3_deg',cfg.phi3_deg,'Vneg_pu',cfg.Vneg_pu,'f',cfg.f, ...
    'Un_LL',cfg.Un_LL,'C0',cfg.C0,'C_moa',cfg.C_moa, ...
    'C1',cfg.C1,'C2',cfg.C2,'Vref_moa',cfg.moa_Vref_V, ...
    'Iref_moa',cfg.moa_Iref_A,'alpha_moa',cfg.moa_alpha, ...
    'Ts',cfg.Ts,'Ts_model',cfg.Ts,'Cself_pF',cfg.Cself_pF, ...
    'Ccoupling_disabled_F',1e-18);
names = fieldnames(vars);
for k = 1:numel(names)
    in = in.setVariable(names{k},vars.(names{k}));
end
dataset = Simulink.SimulationData.Dataset;
dataset{1} = timeseries(signals.Cs1_pF,signals.t);
dataset{2} = timeseries(signals.Cs2_pF,signals.t);
dataset{3} = timeseries(signals.fault_scale,signals.t);
dataset{4} = timeseries(noiseA,signals.t);
dataset{5} = timeseries(noiseB,signals.t);
dataset{6} = timeseries(noiseC,signals.t);
in = in.setExternalInput(dataset);
in = in.setModelParameter('StopTime',num2str(cfg.StopTime));
out = sim(in);
[data.t,data.ua] = read_signal(out,'uA');
[~,data.ub] = read_signal(out,'uB');
[~,data.uc] = read_signal(out,'uC');
[~,data.ia] = read_signal(out,'iA_total');
[~,data.ib] = read_signal(out,'iB_total');
[~,data.ic] = read_signal(out,'iC_total');
[~,data.irA] = read_signal(out,'iA_R_true');
[~,data.irB] = read_signal(out,'iB_R_true');
[~,data.irC] = read_signal(out,'iC_R_true');
[~,data.Cs1] = read_signal(out,'Cs1_true');
[~,data.Cs2] = read_signal(out,'Cs2_true');
end

function [dataF,dataCF] = add_self_capacitance(dataF,dataCF,value)
for name = ["Ca","Cb","Cc"]
    dataF.(char(name)) = value*ones(size(dataF.t));
    dataCF.(char(name)) = value*ones(size(dataCF.t));
end
dataF.scenario = 'phase2_step4_overlap_F';
dataCF.scenario = 'phase2_step4_overlap_CF';
dataF.current_source = "simulink";
dataCF.current_source = "simulink";
end

function [t,x] = read_signal(out,name)
s = out.get(name);
if isa(s,'timeseries')
    t = s.Time; x = s.Data;
else
    t = s.time; x = s.signals.values;
end
t = t(:); x = squeeze(x); x = x(:);
end

function assert_physical_pair(row,dataF,dataCF,signalsF,signalsCF,noise)
tol = 1e-10;
if ~isequal(dataF.t,dataCF.t) || ...
        max(abs(dataF.Cs1-signalsF.Cs1_pF)) > tol || ...
        max(abs(dataF.Cs2-signalsF.Cs2_pF)) > tol || ...
        max(abs(dataCF.Cs1-signalsCF.Cs1_pF)) > tol || ...
        max(abs(dataCF.Cs2-signalsCF.Cs2_pF)) > tol || ...
        abs(dataF.Cs1(end)-row.Cs1_final_pF) > tol || ...
        abs(dataF.Cs2(end)-row.Cs2_final_pF) > tol || ...
        abs(max(signalsF.fault_scale)-row.fault_factor) > tol || ...
        any(signalsCF.fault_scale ~= 1) || ...
        any(~isfinite([noise.A;noise.B;noise.C]))
    error('Phase2:Step4PhysicalMapping', ...
        'Physical mapping failed for %s.',row.condition_id);
end
pre = dataF.t < row.fault_start_s;
fields = {'ua','ub','uc','ia','ib','ic','irA','irB','irC','Cs1','Cs2'};
for k = 1:numel(fields)
    if max(abs(dataF.(fields{k})(pre)-dataCF.(fields{k})(pre))) > 0
        error('Phase2:Step4BranchFairness', ...
            'F/CF pre-fault mismatch in %s.',fields{k});
    end
end
end

function windows = overlap_windows(id)
switch string(id)
    case "WINDOWSET_OV_R05"
        values = [1.60 2.10;2.32 2.44;2.44 2.58; ...
            2.7383333333 3.5216666667;3.80 4.20];
    case "WINDOWSET_OV_R10"
        values = [1.20 1.45;1.62 1.74;1.74 1.88; ...
            1.98 2.18;2.40 2.80];
    case "WINDOWSET_OV_R20"
        values = [1.00 1.125;1.2611764706 1.3635294118; ...
            1.3635294118 1.4829411765;NaN NaN;1.81 2.21];
    otherwise
        error('Phase2:Step4WindowSet','Unknown window set %s.',id);
end
windows = array2table(values,'VariableNames',{'start_s','end_s'}, ...
    'RowNames',{'W0','W1','W2','W3','W4'});
windows.id = repmat(string(id),5,1);
end

function rows = build_main_rows(row,resultsF,resultsCF,dataF,dataCF, ...
        cfg,windows,signature,provenance,sourceArtifact)
rows = repmat(blank_row(),4,1);
for k = 1:4
    mode = ["M0","M2","M3","M4"];
    algorithm = mode(k);
    metrics = overlap_metrics(algorithm,resultsF.(char(algorithm)), ...
        resultsCF.(char(algorithm)),dataF,dataCF,cfg,windows, ...
        row.fault_start_s,row.fault_end_s);
    current = blank_row();
    current.record_type = "MAIN";
    current.condition_id = row.condition_id;
    current.algorithm_id = algorithm;
    current.provenance = string(provenance);
    current.source_artifact = string(sourceArtifact);
    current.data_signature = signature;
    current.drift_rate_multiplier = row.drift_rate_multiplier;
    current.fault_factor = row.fault_factor;
    current.drift_direction_id = row.drift_direction_id;
    current.evaluation_window_set_id = row.evaluation_window_set_id;
    metricNames = fieldnames(metrics);
    for j = 1:numel(metricNames)
        current.(metricNames{j}) = metrics.(metricNames{j});
    end
    current.registry_match = true;
    current.shared_data_pass = true;
    current.numerical_failure = ~main_outputs_finite( ...
        resultsF.(char(algorithm)),resultsCF.(char(algorithm)));
    current.metric_missing = ~required_main_metrics(metrics,algorithm);
    current.notes = "Movement interval: W0 end to W2 end; memory: W4; "+ ...
        "retention reported separately for W1/W2.";
    rows(k) = current;
end
end

function metrics = overlap_metrics(mode,resultF,resultCF, ...
        dataF,dataCF,cfg,windows,faultStart,faultEnd)
w1 = sample_window(dataF.t,windows{'W1','start_s'},windows{'W1','end_s'});
w2 = sample_window(dataF.t,windows{'W2','start_s'},windows{'W2','end_s'});
overlap = w1 | w2;
truth = [dataF.Cs1,dataF.Cs2];
parameterError = resultF.cHist-truth;
metrics = struct();
metrics.overlap_Cs1_RMSE_pF = sqrt(mean(parameterError(overlap,1).^2));
metrics.overlap_Cs2_RMSE_pF = sqrt(mean(parameterError(overlap,2).^2));
metrics.parameter_error_RMS_norm_pF = ...
    sqrt(mean(sum(parameterError(overlap,:).^2,2)));
metrics.W1_fault_increment_retention_ratio = retention_ratio( ...
    dataF,dataCF,resultF,resultCF,cfg.f,w1);
metrics.W2_fault_increment_retention_ratio = retention_ratio( ...
    dataF,dataCF,resultF,resultCF,cfg.f,w2);

startIndex = find(dataF.t < windows{'W0','end_s'},1,'last');
endIndex = find(dataF.t < windows{'W2','end_s'},1,'last');
truthMove = truth(endIndex,:)-truth(startIndex,:);
fMove = resultF.cHist(endIndex,:)-resultF.cHist(startIndex,:);
cfMove = resultCF.cHist(endIndex,:)-resultCF.cHist(startIndex,:);
faultMove = fMove-cfMove;
metrics.true_drift_Cs1_pF = truthMove(1);
metrics.true_drift_Cs2_pF = truthMove(2);
metrics.true_drift_norm_pF = norm(truthMove);
metrics.F_movement_Cs1_pF = fMove(1);
metrics.F_movement_Cs2_pF = fMove(2);
metrics.F_movement_norm_pF = norm(fMove);
metrics.CF_movement_Cs1_pF = cfMove(1);
metrics.CF_movement_Cs2_pF = cfMove(2);
metrics.CF_movement_norm_pF = norm(cfMove);
metrics.F_minus_CF_Cs1_pF = faultMove(1);
metrics.F_minus_CF_Cs2_pF = faultMove(2);
metrics.F_minus_CF_norm_pF = norm(faultMove);

delta = resultF.cHist-resultCF.cHist;
distance = vecnorm(delta,2,2);
w4 = sample_window(dataF.t,windows{'W4','start_s'},windows{'W4','end_s'});
metrics.mean_memory_norm_pF = mean(distance(w4));
metrics.endpoint_memory_norm_pF = distance(find(w4,1,'last'));
auc = dataF.t >= faultEnd & dataF.t < windows{'W4','end_s'};
metrics.post_fault_AUC_pF_s = trapz(dataF.t(auc),distance(auc));
metrics.hard_gate_active_ratio = NaN;
metrics.hard_gate_latency_s = NaN;
metrics.mean_update_weight = NaN;
metrics.rate_limit_active_cycles = NaN;
metrics.projection_active_cycles = NaN;

if mode == "M3" && isfield(resultF.tracker,'cycle')
    cycle = resultF.tracker.cycle;
    cOverlap = cycle_window(cycle.time_s,windows,"W1") | ...
        cycle_window(cycle.time_s,windows,"W2");
    active = logical(cycle.gate);
    metrics.hard_gate_active_ratio = mean(active(cOverlap));
    first = find(active & cycle.time_s >= faultStart,1,'first');
    if ~isempty(first)
        metrics.hard_gate_latency_s = cycle.time_s(first)-faultStart;
    end
    [metrics.rate_limit_active_cycles, ...
        metrics.projection_active_cycles] = ...
        inferred_constraint_counts(cycle,cOverlap,cfg);
elseif mode == "M4" && isfield(resultF.tracker,'cycle')
    cycle = resultF.tracker.cycle;
    cOverlap = cycle_window(cycle.time_s,windows,"W1") | ...
        cycle_window(cycle.time_s,windows,"W2");
    metrics.mean_update_weight = mean(cycle.update_weight(cOverlap));
    metrics.rate_limit_active_cycles = sum(cycle.rate_limit_active(cOverlap));
    metrics.projection_active_cycles = sum(cycle.projection_active(cOverlap));
elseif mode == "M2" && isfield(resultF.tracker,'cycle')
    cycle = resultF.tracker.cycle;
    cOverlap = cycle_window(cycle.time_s,windows,"W1") | ...
        cycle_window(cycle.time_s,windows,"W2");
    [metrics.rate_limit_active_cycles, ...
        metrics.projection_active_cycles] = ...
        inferred_constraint_counts(cycle,cOverlap,cfg);
end
end

function ratio = retention_ratio(dataF,dataCF,resultF,resultCF,f,index)
trueIncrement = fundamental_rms(dataF.t(index),dataF.irB(index),f)- ...
    fundamental_rms(dataCF.t(index),dataCF.irB(index),f);
estimatedIncrement = fundamental_rms(dataF.t(index), ...
    resultF.ir.B(index),f)-fundamental_rms(dataCF.t(index), ...
    resultCF.ir.B(index),f);
ratio = estimatedIncrement/(trueIncrement+eps);
end

function [rateCount,projectionCount] = ...
        inferred_constraint_counts(cycle,overlap,cfg)
change = diff(cycle{:,{'Cs1_pF','Cs2_pF'}},1,1);
rateAll = any(abs(change) >= cfg.rate_limit_pF_per_cycle-1e-12,2);
bounds = cycle{2:end,{'Cs1_pF','Cs2_pF'}};
projectionAll = any(bounds <= cfg.coupling_bounds_pF(1)+1e-12 | ...
    bounds >= cfg.coupling_bounds_pF(2)-1e-12,2);
rateCount = sum(rateAll(overlap(2:end)));
projectionCount = sum(projectionAll(overlap(2:end)));
end

function index = sample_window(time,startTime,endTime)
index = time >= startTime & time < endTime;
if ~any(index)
    error('Phase2:Step4SampleWindow', ...
        'Empty sample window [%.10f, %.10f).',startTime,endTime);
end
end

function index = cycle_window(time,windows,name)
startTime = windows{name,'start_s'};
endTime = windows{name,'end_s'};
index = time >= startTime & time < endTime;
if ~any(index)
    error('Phase2:Step4CycleWindow','Empty cycle window %s.',name);
end
end

function value = fundamental_rms(time,signal,frequency)
omega = 2*pi*frequency;
coefficients = [sin(omega*time),cos(omega*time), ...
    ones(size(time))]\signal;
value = hypot(coefficients(1),coefficients(2))/sqrt(2);
end

function pass = main_outputs_finite(resultF,resultCF)
pass = all(isfinite(resultF.cHist),'all') && ...
    all(isfinite(resultCF.cHist),'all') && ...
    all(isfinite(resultF.ir.B)) && all(isfinite(resultCF.ir.B));
end

function pass = required_main_metrics(metrics,mode)
required = [metrics.overlap_Cs1_RMSE_pF; ...
    metrics.overlap_Cs2_RMSE_pF; ...
    metrics.W1_fault_increment_retention_ratio; ...
    metrics.W2_fault_increment_retention_ratio; ...
    metrics.true_drift_Cs1_pF;metrics.true_drift_Cs2_pF; ...
    metrics.true_drift_norm_pF;metrics.F_movement_Cs1_pF; ...
    metrics.F_movement_Cs2_pF;metrics.F_movement_norm_pF; ...
    metrics.CF_movement_Cs1_pF;metrics.CF_movement_Cs2_pF; ...
    metrics.CF_movement_norm_pF;metrics.F_minus_CF_Cs1_pF; ...
    metrics.F_minus_CF_Cs2_pF;metrics.F_minus_CF_norm_pF; ...
    metrics.parameter_error_RMS_norm_pF; ...
    metrics.mean_memory_norm_pF;metrics.endpoint_memory_norm_pF; ...
    metrics.post_fault_AUC_pF_s];
pass = all(isfinite(required));
if mode == "M3"
    pass = pass && isfinite(metrics.hard_gate_active_ratio);
elseif mode == "M4"
    pass = pass && isfinite(metrics.mean_update_weight);
end
end

function signature = pair_signature(dataF,dataCF,signals,noise,ref)
digester = java.security.MessageDigest.getInstance('SHA-256');
values = {dataF.t,dataF.ua,dataF.ub,dataF.uc,dataF.ia,dataF.ib, ...
    dataF.ic,dataF.irB,dataF.Cs1,dataF.Cs2,dataCF.ia,dataCF.ib, ...
    dataCF.ic,dataCF.irB,signals.fault_scale,noise.A,noise.B,noise.C, ...
    ref.ua,ref.ub,ref.uc,ref.dua,ref.dub,ref.duc};
for k = 1:numel(values)
    digester.update(typecast(double(values{k}(:)),'uint8'));
end
hashBytes = typecast(digester.digest(),'uint8');
signature = upper(string(reshape(dec2hex(hashBytes,2).',1,[])));
end

function assert_ready_execution(executionRegistry,conditionId)
rows = executionRegistry(executionRegistry.condition_id == conditionId & ...
    executionRegistry.record_type == "MAIN_ALGORITHM_EVALUATION",:);
if height(rows) ~= 4 || any(rows.execution_status ~= "READY")
    error('Phase2:Step4ExecutionRegistry', ...
        '%s does not have four READY execution rows.',conditionId);
end
end

function assert_anchor_execution(executionRegistry,conditionId,rows)
registered = executionRegistry( ...
    executionRegistry.condition_id == conditionId & ...
    executionRegistry.record_type == "MAIN_ALGORITHM_EVALUATION",:);
for k = 1:numel(rows)
    item = registered(registered.algorithm_id == rows(k).algorithm_id,:);
    expected = "NEW_RUN";
    if rows(k).algorithm_id ~= "M0"
        expected = "EXACT_REUSE";
    end
    if height(item) ~= 1 || rows(k).provenance ~= expected
        error('Phase2:Step4AnchorExecution', ...
            'Anchor execution provenance mismatch for %s/%s.', ...
            conditionId,rows(k).algorithm_id);
    end
end
end

function [gateRows,replayRows,gatePass,replayComplete] = ...
        run_case08_replay(cache)
detail = cache.frozen.caseDetail;
cfg = cache.cfg;
dataF = cache.dataF;
dataN = cache.dataCF;
ref = cache.ref;
selfPF = repmat(400,1,3);
windows = cache.windows;
originalM3 = detail.M3_cycle_F;
originalM4 = detail.M4_cycle_F;
tolerance = 1e-12;

replayedM3 = replay_m3(dataF,ref,cfg,selfPF, ...
    originalM3.gate,originalM3.lambda);
replayedM4 = replay_m4(dataF,ref,cfg,selfPF, ...
    originalM4.update_weight,originalM4.lambda);
irM3 = extract_resistive_current(dataF,ref,selfPF,replayedM3.hist);
irM4 = extract_resistive_current(dataF,ref,selfPF,replayedM4.hist);

gateRows = repmat(blank_row(),2,1);
gateRows(1) = equivalence_row("M3",replayedM3,irM3, ...
    detail.M3_cHist_F,detail.M3_irB_F,originalM3,tolerance);
gateRows(2) = equivalence_row("M4",replayedM4,irM4, ...
    detail.M4_cHist_F,detail.M4_irB_F,originalM4,tolerance);
gatePass = all([gateRows.equivalence_pass]);
if ~gatePass
    replayRows = repmat(blank_row(),0,1);
    replayComplete = false;
    return
end

% P uses the fault protection schedule and natural no-fault lambda.
% A uses both the fault protection schedule and the fault lambda schedule.
m3P = replay_m3(dataN,ref,cfg,selfPF,originalM3.gate,[]);
m3A = replay_m3(dataN,ref,cfg,selfPF,originalM3.gate,originalM3.lambda);
m4P = replay_m4(dataN,ref,cfg,selfPF,originalM4.update_weight,[]);
m4A = replay_m4(dataN,ref,cfg,selfPF, ...
    originalM4.update_weight,originalM4.lambda);

trajectoriesM3 = struct( ...
    'F',detail.M3_cHist_F,'N',detail.M3_cHist_CF, ...
    'P',m3P.hist,'A',m3A.hist);
trajectoriesM4 = struct( ...
    'F',detail.M4_cHist_F,'N',detail.M4_cHist_CF, ...
    'P',m4P.hist,'A',m4A.hist);
replayRows = [replay_trajectory_rows("M3",trajectoriesM3, ...
    dataF.t,windows,cache.signature); ...
    replay_trajectory_rows("M4",trajectoriesM4, ...
    dataF.t,windows,cache.signature)];
replayComplete = numel(replayRows) == 8 && ...
    all(~[replayRows.numerical_failure]) && ...
    all(~[replayRows.metric_missing]);
end

function row = equivalence_row(mode,replayed,ir, ...
        frozenHist,frozenIrB,frozenCycle,tolerance)
row = blank_row();
row.record_type = "REPLAY_GATE";
row.condition_id = "P2_AN_C08";
row.algorithm_id = mode;
row.provenance = "REPLAY_EQUIVALENCE_GATE";
row.source_artifact = "Frozen Case08 F trajectory and recorded schedules";
row.trajectory = "F_EQUIVALENCE";
row.max_cHist_difference = max(abs(replayed.hist-frozenHist),[],'all');
row.max_irB_difference_A = max(abs(ir.B-frozenIrB));
row.max_final_Cs_difference_pF = max(abs( ...
    replayed.hist(end,:)-frozenHist(end,:)));
if mode == "M3"
    row.max_schedule_difference = max(abs([ ...
        replayed.cycle.gate-frozenCycle.gate; ...
        replayed.cycle.lambda-frozenCycle.lambda]));
    row.max_state_difference = NaN;
else
    row.max_schedule_difference = max(abs([ ...
        replayed.cycle.update_weight-frozenCycle.update_weight; ...
        replayed.cycle.lambda-frozenCycle.lambda]));
    replayFinal = [replayed.cycle{end,{'J_11','J_12','J_21','J_22'}}, ...
        replayed.cycle{end,{'h_1','h_2'}}];
    frozenFinal = [frozenCycle{end,{'J_11','J_12','J_21','J_22'}}, ...
        frozenCycle{end,{'h_1','h_2'}}];
    row.max_state_difference = max(abs(replayFinal-frozenFinal));
end
required = [row.max_cHist_difference,row.max_irB_difference_A, ...
    row.max_final_Cs_difference_pF,row.max_schedule_difference];
statePass = isnan(row.max_state_difference) || ...
    row.max_state_difference <= tolerance;
row.equivalence_pass = all(required <= tolerance) && statePass;
row.registry_match = true;
row.shared_data_pass = true;
row.numerical_failure = any(~isfinite(required));
row.metric_missing = false;
row.notes = sprintf('Existing numerical tolerance %.1e; no relaxation.', ...
    tolerance);
end

function rows = replay_trajectory_rows(mode,trajectories,time,windows,signature)
names = ["F","N","P","A"];
startIndex = find(time < windows{'W0','end_s'},1,'last');
endIndex = find(time < windows{'W2','end_s'},1,'last');
movement = struct();
for name = names
    c = trajectories.(char(name));
    movement.(char(name)) = c(endIndex,:)-c(startIndex,:);
end
components = struct( ...
    'F_minus_A',movement.F-movement.A, ...
    'A_minus_P',movement.A-movement.P, ...
    'P_minus_N',movement.P-movement.N, ...
    'F_minus_N',movement.F-movement.N);
identityResidual = components.F_minus_N-(components.F_minus_A+ ...
    components.A_minus_P+components.P_minus_N);
rows = repmat(blank_row(),4,1);
for k = 1:4
    name = names(k);
    current = blank_row();
    current.record_type = "REPLAY";
    current.condition_id = "P2_AN_C08";
    current.algorithm_id = mode;
    current.provenance = "EXACT_REUSE";
    if ismember(name,["P","A"])
        current.provenance = "NEW_REPLAY";
    end
    current.source_artifact = "Case08 replay wrapper";
    current.data_signature = signature;
    current.trajectory = name;
    current.replay_movement_Cs1_pF = movement.(char(name))(1);
    current.replay_movement_Cs2_pF = movement.(char(name))(2);
    current.replay_movement_norm_pF = norm(movement.(char(name)));
    for component = ["F_minus_A","A_minus_P","P_minus_N","F_minus_N"]
        vector = components.(char(component));
        prefix = char(component);
        current.([prefix '_Cs1_pF']) = vector(1);
        current.([prefix '_Cs2_pF']) = vector(2);
        current.([prefix '_norm_pF']) = norm(vector);
    end
    current.decomposition_identity_residual_pF = norm(identityResidual);
    current.equivalence_pass = true;
    current.registry_match = true;
    current.shared_data_pass = true;
    current.numerical_failure = any(~isfinite(trajectories.(char(name))),'all');
    current.metric_missing = any(~isfinite([ ...
        current.replay_movement_Cs1_pF, ...
        current.replay_movement_Cs2_pF, ...
        current.replay_movement_norm_pF, ...
        current.F_minus_A_Cs1_pF,current.F_minus_A_Cs2_pF, ...
        current.A_minus_P_Cs1_pF,current.A_minus_P_Cs2_pF, ...
        current.P_minus_N_Cs1_pF,current.P_minus_N_Cs2_pF, ...
        current.F_minus_N_Cs1_pF,current.F_minus_N_Cs2_pF, ...
        current.decomposition_identity_residual_pF]));
    current.notes = [ ...
        "Operational decomposition: F-N=(F-A)+(A-P)+(P-N); " ...
        "movement interval W0 end to W2 end; not perfect causal identification."];
    rows(k) = current;
end
end

function out = replay_m3(data,ref,cfg,selfPF,forcedGate,forcedLambda)
t = data.t; sampleCount = numel(t);
sampleRate = 1/median(diff(t));
samplesPerCycle = round(sampleRate/cfg.f);
c = initial_coupling_estimate(data,ref,cfg,selfPF);
hist = repmat(c(:).',sampleCount,1);
init = t >= cfg.init_start & t < cfg.init_end;
[X0,~] = coupling_regressor(data,ref,init,selfPF);
J = 0.05*(X0'*X0)+1e-8*eye(2); h = J*c;
baseIn = NaN; rows = []; cycleIndex = 0;
startIndex = find(t >= cfg.init_end,1);
startIndex = floor((startIndex-1)/samplesPerCycle)*samplesPerCycle+1;
lastFilled = startIndex-1;
for cycleStart = startIndex:samplesPerCycle: ...
        (sampleCount-samplesPerCycle+1)
    cycleIndex = cycleIndex+1;
    index = cycleStart:(cycleStart+samplesPerCycle-1);
    [X,y] = coupling_regressor(data,ref,index,selfPF);
    R = X'*X; z = X'*y;
    localLs = (R+1e-10*eye(2))\z;
    innovation = norm((localLs-c)./[5;5]);
    lambdaNatural = cfg.lambda_max-(cfg.lambda_max-cfg.lambda_min)* ...
        min(max(innovation/0.20,0),1);
    [Ein,Equad] = replay_residual_components( ...
        data,ref,index,c,selfPF,cfg.f);
    if isnan(baseIn), baseIn = Ein; end
    gateNatural = t(index(end)) > 1.0 && ...
        Ein > cfg.gate_ratio*baseIn && ...
        Ein > cfg.gate_quad_ratio*Equad;
    if isempty(forcedGate)
        gate = gateNatural;
    else
        gate = logical(forcedGate(cycleIndex));
    end
    if isempty(forcedLambda)
        lambda = lambdaNatural;
    else
        lambda = forcedLambda(cycleIndex);
    end
    if ~gate
        J = lambda*J+R; h = lambda*h+z;
        cNew = (J+1e-10*eye(2))\h;
        dc = max(min(cNew-c,cfg.rate_limit_pF_per_cycle), ...
            -cfg.rate_limit_pF_per_cycle);
        c = c+dc;
        c = min(max(c,cfg.coupling_bounds_pF(1)), ...
            cfg.coupling_bounds_pF(2));
        if Ein < 1.08*baseIn
            baseIn = 0.985*baseIn+0.015*Ein;
        end
    end
    hist(index,:) = repmat(c(:).',numel(index),1);
    lastFilled = index(end);
    rows = [rows;t(index(end)),c(:).',lambda,Ein,Equad, ...
        double(gate),baseIn,J(1,1),J(1,2),J(2,1),J(2,2),h(:).']; %#ok<AGROW>
end
if lastFilled < sampleCount
    hist(lastFilled+1:sampleCount,:) = ...
        repmat(c(:).',sampleCount-lastFilled,1);
end
if ~isempty(forcedGate) && cycleIndex ~= numel(forcedGate)
    error('Phase2:ReplayM3Schedule','M3 gate schedule length mismatch.');
end
out = struct('hist',hist,'cycle',array2table(rows, ...
    'VariableNames',{'time_s','Cs1_pF','Cs2_pF','lambda','E_in', ...
    'E_quad','gate','base_in','J_11','J_12','J_21','J_22','h_1','h_2'}));
end

function out = replay_m4(data,ref,cfg,selfPF,forcedWeight,forcedLambda)
t = data.t; sampleCount = numel(t);
sampleRate = 1/median(diff(t));
samplesPerCycle = round(sampleRate/cfg.f);
c = initial_coupling_estimate(data,ref,cfg,selfPF);
hist = repmat(c(:).',sampleCount,1);
init = t >= cfg.init_start & t < cfg.init_end;
[X0,~] = coupling_regressor(data,ref,init,selfPF);
J = 0.05*(X0'*X0)+1e-8*eye(2); h = J*c;
baseIn = NaN; rows = []; cycleIndex = 0;
startIndex = find(t >= cfg.init_end,1);
startIndex = floor((startIndex-1)/samplesPerCycle)*samplesPerCycle+1;
lastFilled = startIndex-1;
for cycleStart = startIndex:samplesPerCycle: ...
        (sampleCount-samplesPerCycle+1)
    cycleIndex = cycleIndex+1;
    index = cycleStart:(cycleStart+samplesPerCycle-1);
    [X,y] = coupling_regressor(data,ref,index,selfPF);
    R = X'*X; z = X'*y;
    localLs = (R+1e-10*eye(2))\z;
    innovation = norm((localLs-c)./[5;5]);
    lambdaNatural = cfg.lambda_max-(cfg.lambda_max-cfg.lambda_min)* ...
        min(max(innovation/0.20,0),1);
    [Ein,Equad] = replay_residual_components( ...
        data,ref,index,c,selfPF,cfg.f);
    if isnan(baseIn), baseIn = Ein; end
    evidence = m4_fault_evidence(Ein,Equad,baseIn, ...
        cfg.gate_ratio,cfg.gate_quad_ratio,NaN);
    if isempty(forcedWeight)
        updateWeight = evidence.update_weight;
    else
        updateWeight = forcedWeight(cycleIndex);
    end
    if isempty(forcedLambda)
        lambda = lambdaNatural;
    else
        lambda = forcedLambda(cycleIndex);
    end
    JPrevious = J; hPrevious = h; cPrevious = c;
    JStar = lambda*JPrevious+R;
    hStar = lambda*hPrevious+z;
    JIncrementRaw = JStar-JPrevious;
    hIncrementRaw = hStar-hPrevious;
    if updateWeight == 0
        J = JPrevious; h = hPrevious; cRaw = cPrevious;
    elseif updateWeight == 1
        J = JStar; h = hStar;
        cRaw = (J+1e-10*eye(2))\h;
    else
        J = JPrevious+updateWeight*JIncrementRaw;
        h = hPrevious+updateWeight*hIncrementRaw;
        cRaw = (J+1e-10*eye(2))\h;
    end
    deltaRaw = cRaw-cPrevious;
    rateDelta = max(min(deltaRaw,cfg.rate_limit_pF_per_cycle), ...
        -cfg.rate_limit_pF_per_cycle);
    cAfterRate = cPrevious+rateDelta;
    c = min(max(cAfterRate,cfg.coupling_bounds_pF(1)), ...
        cfg.coupling_bounds_pF(2));
    if updateWeight == 0
        c = cPrevious; cAfterRate = cPrevious;
    end
    rateActive = any(deltaRaw-(cAfterRate-cPrevious) ~= 0);
    projectionActive = any((cAfterRate-cPrevious)-(c-cPrevious) ~= 0);
    if Ein < 1.08*baseIn
        baseCandidate = 0.985*baseIn+0.015*Ein;
    else
        baseCandidate = baseIn;
    end
    if updateWeight == 0
        % no change
    elseif updateWeight == 1
        baseIn = baseCandidate;
    else
        baseIn = baseIn+updateWeight*(baseCandidate-baseIn);
    end
    hist(index,:) = repmat(c(:).',numel(index),1);
    lastFilled = index(end);
    rows = [rows;t(index(end)),c(:).',lambda,updateWeight, ...
        double(rateActive),double(projectionActive),baseIn, ...
        J(1,1),J(1,2),J(2,1),J(2,2),h(:).']; %#ok<AGROW>
end
if lastFilled < sampleCount
    hist(lastFilled+1:sampleCount,:) = ...
        repmat(c(:).',sampleCount-lastFilled,1);
end
if ~isempty(forcedWeight) && cycleIndex ~= numel(forcedWeight)
    error('Phase2:ReplayM4Schedule','M4 weight schedule length mismatch.');
end
out = struct('hist',hist,'cycle',array2table(rows, ...
    'VariableNames',{'time_s','Cs1_pF','Cs2_pF','lambda', ...
    'update_weight','rate_limit_active','projection_active','base_in', ...
    'J_11','J_12','J_21','J_22','h_1','h_2'}));
end

function [Ein,Equad] = replay_residual_components( ...
        data,ref,index,c,selfPF,f)
[X,y] = coupling_regressor(data,ref,index,selfPF);
residual = y-X*c;
n = numel(index); time = data.t(index); omega = 2*pi*f;
phase = [2*pi/3,0,-2*pi/3];
EinP = zeros(3,1); EquadP = zeros(3,1);
for p = 1:3
    rows = (p-1)*n+1:p*n;
    e = residual(rows);
    inBasis = [sin(omega*time+ref.phi1+phase(p)), ...
        sin(3*omega*time+ref.phi3)];
    quadBasis = [cos(omega*time+ref.phi1+phase(p)), ...
        cos(3*omega*time+ref.phi3)];
    basis = [inBasis,quadBasis,ones(n,1)];
    coefficients = basis\e;
    EinP(p) = sqrt(mean((inBasis*coefficients(1:2)).^2));
    EquadP(p) = sqrt(mean((quadBasis*coefficients(3:4)).^2));
end
Ein = sqrt(mean(EinP.^2));
Equad = sqrt(mean(EquadP.^2));
end

function row = blank_row()
row = struct( ...
    'record_type',"", ...
    'condition_id',"", ...
    'algorithm_id',"", ...
    'provenance',"", ...
    'source_artifact',"", ...
    'data_signature',"", ...
    'drift_rate_multiplier',NaN, ...
    'fault_factor',NaN, ...
    'drift_direction_id',"", ...
    'evaluation_window_set_id',"", ...
    'overlap_Cs1_RMSE_pF',NaN, ...
    'overlap_Cs2_RMSE_pF',NaN, ...
    'W1_fault_increment_retention_ratio',NaN, ...
    'W2_fault_increment_retention_ratio',NaN, ...
    'true_drift_Cs1_pF',NaN, ...
    'true_drift_Cs2_pF',NaN, ...
    'true_drift_norm_pF',NaN, ...
    'F_movement_Cs1_pF',NaN, ...
    'F_movement_Cs2_pF',NaN, ...
    'F_movement_norm_pF',NaN, ...
    'CF_movement_Cs1_pF',NaN, ...
    'CF_movement_Cs2_pF',NaN, ...
    'CF_movement_norm_pF',NaN, ...
    'F_minus_CF_Cs1_pF',NaN, ...
    'F_minus_CF_Cs2_pF',NaN, ...
    'F_minus_CF_norm_pF',NaN, ...
    'parameter_error_RMS_norm_pF',NaN, ...
    'mean_memory_norm_pF',NaN, ...
    'endpoint_memory_norm_pF',NaN, ...
    'post_fault_AUC_pF_s',NaN, ...
    'hard_gate_active_ratio',NaN, ...
    'hard_gate_latency_s',NaN, ...
    'mean_update_weight',NaN, ...
    'rate_limit_active_cycles',NaN, ...
    'projection_active_cycles',NaN, ...
    'trajectory',"", ...
    'replay_movement_Cs1_pF',NaN, ...
    'replay_movement_Cs2_pF',NaN, ...
    'replay_movement_norm_pF',NaN, ...
    'F_minus_A_Cs1_pF',NaN, ...
    'F_minus_A_Cs2_pF',NaN, ...
    'F_minus_A_norm_pF',NaN, ...
    'A_minus_P_Cs1_pF',NaN, ...
    'A_minus_P_Cs2_pF',NaN, ...
    'A_minus_P_norm_pF',NaN, ...
    'P_minus_N_Cs1_pF',NaN, ...
    'P_minus_N_Cs2_pF',NaN, ...
    'P_minus_N_norm_pF',NaN, ...
    'F_minus_N_Cs1_pF',NaN, ...
    'F_minus_N_Cs2_pF',NaN, ...
    'F_minus_N_norm_pF',NaN, ...
    'decomposition_identity_residual_pF',NaN, ...
    'max_cHist_difference',NaN, ...
    'max_irB_difference_A',NaN, ...
    'max_final_Cs_difference_pF',NaN, ...
    'max_schedule_difference',NaN, ...
    'max_state_difference',NaN, ...
    'equivalence_pass',false, ...
    'numerical_failure',false, ...
    'metric_missing',false, ...
    'registry_match',false, ...
    'shared_data_pass',false, ...
    'frozen_integrity_pass',false, ...
    'notes',"");
end

function rows = failure_rows(registryRow,exception)
rows = repmat(blank_row(),4,1);
for k = 1:4
    modes = ["M0","M2","M3","M4"];
    rows(k).record_type = "MAIN";
    rows(k).condition_id = registryRow.condition_id;
    rows(k).algorithm_id = modes(k);
    rows(k).provenance = "FAILED_EXECUTION";
    rows(k).drift_rate_multiplier = registryRow.drift_rate_multiplier;
    rows(k).fault_factor = registryRow.fault_factor;
    rows(k).drift_direction_id = registryRow.drift_direction_id;
    rows(k).evaluation_window_set_id = ...
        registryRow.evaluation_window_set_id;
    rows(k).numerical_failure = true;
    rows(k).metric_missing = true;
    rows(k).notes = string(exception.identifier)+": "+ ...
        string(exception.message);
end
end

function rows = replay_failure_rows(exception)
rows = repmat(blank_row(),2,1);
for k = 1:2
    modes = ["M3","M4"];
    rows(k).record_type = "REPLAY_GATE";
    rows(k).condition_id = "P2_AN_C08";
    rows(k).algorithm_id = modes(k);
    rows(k).provenance = "REPLAY_BLOCKED";
    rows(k).trajectory = "F_EQUIVALENCE";
    rows(k).numerical_failure = true;
    rows(k).metric_missing = true;
    rows(k).notes = string(exception.identifier)+": "+ ...
        string(exception.message);
end
end

function pass = main_row_complete(row)
pass = row.record_type == "MAIN" && ~row.numerical_failure && ...
    ~row.metric_missing && row.registry_match && row.shared_data_pass;
end

function integrity = capture_frozen_integrity(paths)
manifest = read_registry(paths.manifest);
n = height(manifest);
labels = strings(n+3,1);
filePaths = strings(n+3,1);
expected = strings(n+3,1);
actual = strings(n+3,1);
for k = 1:n
    labels(k) = "PHASE1:"+manifest.roles(k)+":"+ ...
        manifest.relative_path(k);
    filePaths(k) = fullfile(paths.project_root, ...
        char(manifest.relative_path(k)));
    expected(k) = upper(manifest.sha256(k));
    actual(k) = file_sha256(filePaths(k));
end
labels(n+1:n+3) = ["STEP1_SPECIFICATION"; ...
    "STEP1_CONDITION_REGISTRY";"STEP1_EXECUTION_REGISTRY"];
filePaths(n+1:n+3) = [string(paths.specification); ...
    string(paths.condition_registry);string(paths.execution_registry)];
expected(n+1:n+3) = [ ...
    "9FAB573BCE6D5D0A1F3F6A569771F5B1C69706AB6E6E38FD97843BF41B931531"; ...
    "8A498E19A455C13CAA7B5371BE2F933CA7B7637B893C656C92DA84D88D1938BE"; ...
    "974B8874404C46C4B549CAD8E2D52CCCC7F1D4F81D68AF8911201307230394D7"];
actual(n+1) = canonical_specification_sha256(paths.specification);
actual(n+2) = file_sha256(paths.condition_registry);
actual(n+3) = file_sha256(paths.execution_registry);
itemPass = expected == actual;
integrity = struct('labels',labels,'paths',filePaths, ...
    'expected_sha256',expected,'actual_sha256',actual, ...
    'item_pass',itemPass,'phase1_count',n, ...
    'phase1_pass_count',nnz(itemPass(1:n)), ...
    'step1_pass_count',nnz(itemPass(n+1:end)), ...
    'pass',all(itemPass));
end

function hash = canonical_specification_sha256(path)
textValue = fileread(path);
pattern = '(specification_sha256_canonical:\s*)[0-9A-Fa-f]{64}';
replacement = '$1<SELF_SHA256_CANONICAL_PLACEHOLDER>';
canonical = regexprep(textValue,pattern,replacement,'once');
if strcmp(canonical,textValue)
    error('Phase2:CanonicalHash', ...
        'Specification canonical self-hash field was not found.');
end
hash = bytes_sha256(unicode2native(canonical,'UTF-8'));
end

function hash = file_sha256(path)
fileId = fopen(path,'rb');
if fileId < 0
    error('Phase2:HashRead','Unable to open %s.',path);
end
cleanup = onCleanup(@() fclose(fileId));
bytes = fread(fileId,Inf,'*uint8');
delete(cleanup);
hash = bytes_sha256(bytes);
end

function hash = bytes_sha256(bytes)
digester = java.security.MessageDigest.getInstance('SHA-256');
digester.update(uint8(bytes));
hashBytes = typecast(digester.digest(),'uint8');
hash = upper(string(reshape(dec2hex(hashBytes,2).',1,[])));
end

function value = truthy(input)
if islogical(input)
    value = input;
elseif isnumeric(input)
    value = input ~= 0;
else
    value = any(upper(string(input)) == ["TRUE","YES","1"]);
end
value = logical(value);
end

function write_step4_report(paths,rows,pre,post,status, ...
        physicalComplete,mainCount,newRunCount,numericalFailures, ...
        metricMissing,replayGatePass,replayComplete,frozenPass,readyForStep5)
fileId = fopen(paths.report,'w','n','UTF-8');
if fileId < 0
    error('Phase2:Step4ReportWrite','Unable to create Step 4 report.');
end
cleanup = onCleanup(@() fclose(fileId));
line = @(value) fprintf(fileId,'%s\n',value);
main = rows(rows.record_type == "MAIN",:);

line('# Phase 2 Step 4 — Simultaneous Drift + Fault Matrix');
line('');
line('## 1. Scope and execution discipline');
line('');
line(sprintf(['The frozen Step 4 matrix completed **%d/13 physical ' ...
    'points** and **%d/52 MAIN condition-by-algorithm records**. ' ...
    'The execution contains **%d/46 NEW_RUN** records and six exact ' ...
    'M2/M3/M4 anchor reuses from frozen Case07/08.'], ...
    physicalComplete,mainCount,newRunCount));
line('');
line(['No M0/M2/M3/M4 formula, parameter, gate threshold, registry, ' ...
    'AutoComp9 source, Phase 1 result, or evaluation window was changed. ' ...
    'Each physical point used one matched F/CF data pair shared by all ' ...
    'four algorithms. Negative results are retained.']);
line('');
line(['Signed movement vectors use one declared interval for the whole ' ...
    'matrix: the last sample before W0 end to the last sample before W2 ' ...
    'end. Memory metrics use W4; post-fault AUC spans fault clear to W4 ' ...
    'end. The 2x W3 interval remains `N/A_BY_DESIGN`.']);
line('');

line('## 2. Integrity and completeness');
line('');
line(sprintf(['PRE integrity: Phase 1 **%d/%d**, Step 1 **%d/3**. ' ...
    'POST integrity: Phase 1 **%d/%d**, Step 1 **%d/3**. ' ...
    'PRE/POST unchanged: **%s**.'], ...
    pre.phase1_pass_count,pre.phase1_count,pre.step1_pass_count, ...
    post.phase1_pass_count,post.phase1_count,post.step1_pass_count, ...
    pass_fail(frozenPass)));
line('');
line(sprintf(['Registry matches: **%d/52**; shared-data checks: ' ...
    '**%d/52**; numerical failures: **%d**; metric-missing MAIN rows: ' ...
    '**%d**.'],nnz(main.registry_match),nnz(main.shared_data_pass), ...
    numericalFailures,metricMissing));
line('');

line('## 3. Core D1 rate × fault-factor matrix');
line('');
line(['Combined W1+W2 parameter error is the frozen overlap tracking ' ...
    'quantity. Retention remains separately reported for W1 and W2.']);
line('');
line(['| Condition | Rate | Factor | Algorithm | Cs RMSE norm (pF) | ' ...
    'W1 retention | W2 retention | F-CF signed (Cs1, Cs2) pF | ' ...
    'F-CF norm (pF) | M3 gate ratio | M4 mean g |']);
line('|---|---:|---:|---|---:|---:|---:|---:|---:|---:|---:|');
core = main(main.drift_direction_id == "D1",:);
conditionOrder = step4_condition_ids();
for id = conditionOrder.'
    current = core(core.condition_id == id,:);
    if isempty(current), continue, end
    for mode = ["M0","M2","M3","M4"]
        item = current(current.algorithm_id == mode,:);
        if isempty(item), continue, end
        line(sprintf(['| `%s` | %.1f | %.2f | %s | %.6f | %.6f | ' ...
            '%.6f | %.6f, %.6f | %.6f | %.6g | %.6g |'], ...
            id,item.drift_rate_multiplier,item.fault_factor,mode, ...
            item.parameter_error_RMS_norm_pF, ...
            item.W1_fault_increment_retention_ratio, ...
            item.W2_fault_increment_retention_ratio, ...
            item.F_minus_CF_Cs1_pF,item.F_minus_CF_Cs2_pF, ...
            item.F_minus_CF_norm_pF,item.hard_gate_active_ratio, ...
            item.mean_update_weight));
    end
end
line('');
write_rate_analysis(fileId,core);
line('');
write_fault_analysis(fileId,core);
line('');

line('## 4. Direction extension D1 / D2 / D3');
line('');
line(['The direction extension keeps rate=1 and compares factor 1.30/' ...
    '1.60 without expanding to a full direction×rate×factor grid.']);
line('');
line(['| Direction | Factor | Algorithm | True signed drift (Cs1, Cs2) ' ...
    'pF | F movement (Cs1, Cs2) pF | CF movement (Cs1, Cs2) pF | ' ...
    'F-CF (Cs1, Cs2) pF | Error norm (pF) |']);
line('|---|---:|---|---:|---:|---:|---:|---:|');
directionRows = main(main.drift_rate_multiplier == 1 & ...
    ismember(main.fault_factor,[1.3,1.6]),:);
for direction = ["D1","D2","D3"]
    for factor = [1.3,1.6]
        current = directionRows(directionRows.drift_direction_id == direction & ...
            abs(directionRows.fault_factor-factor) < 1e-12,:);
        for mode = ["M0","M2","M3","M4"]
            item = current(current.algorithm_id == mode,:);
            if isempty(item), continue, end
            line(sprintf(['| %s | %.2f | %s | %.6f, %.6f | ' ...
                '%.6f, %.6f | %.6f, %.6f | %.6f, %.6f | %.6f |'], ...
                direction,factor,mode,item.true_drift_Cs1_pF, ...
                item.true_drift_Cs2_pF,item.F_movement_Cs1_pF, ...
                item.F_movement_Cs2_pF,item.CF_movement_Cs1_pF, ...
                item.CF_movement_Cs2_pF,item.F_minus_CF_Cs1_pF, ...
                item.F_minus_CF_Cs2_pF, ...
                item.parameter_error_RMS_norm_pF));
        end
    end
end
line('');
write_direction_analysis(fileId,directionRows);
line('');

line('## 5. M3 hard gate and M4 continuous weighting');
line('');
write_protection_analysis(fileId,main);
line('');
line(['Rate-limit and projection activity are diagnostics, not scores. ' ...
    'Their per-row counts are preserved in the CSV when the frozen cycle ' ...
    'trace makes them available; exact-reuse M2 anchors do not contain a ' ...
    'saved M2 cycle table and therefore retain `NaN` for these optional ' ...
    'fields.']);
line('');

line('## 6. Case08 protection-schedule counterfactual replay');
line('');
gate = rows(rows.record_type == "REPLAY_GATE",:);
line('| Algorithm | max c(t) diff | max irB diff (A) | final Cs diff | schedule diff | state diff | Pass |');
line('|---|---:|---:|---:|---:|---:|---|');
for k = 1:height(gate)
    line(sprintf('| %s | %.3g | %.3g | %.3g | %.3g | %.3g | %s |', ...
        gate.algorithm_id(k),gate.max_cHist_difference(k), ...
        gate.max_irB_difference_A(k), ...
        gate.max_final_Cs_difference_pF(k), ...
        gate.max_schedule_difference(k),gate.max_state_difference(k), ...
        pass_fail(gate.equivalence_pass(k))));
end
line('');
if replayGatePass && replayComplete
    replay = rows(rows.record_type == "REPLAY",:);
    line(['The equivalence gate passed at the existing `1e-12` numerical ' ...
        'tolerance. P and A were then generated by the independent replay ' ...
        'wrapper; no frozen source was edited.']);
    line('');
    line(['| Algorithm | F-N signed/norm (pF) | F-A signed/norm | ' ...
        'A-P signed/norm | P-N signed/norm | identity residual (pF) |']);
    line('|---|---:|---:|---:|---:|---:|');
    for mode = ["M3","M4"]
        item = replay(replay.algorithm_id == mode & replay.trajectory == "F",:);
        line(sprintf(['| %s | %.6f, %.6f / %.6f | ' ...
            '%.6f, %.6f / %.6f | %.6f, %.6f / %.6f | ' ...
            '%.6f, %.6f / %.6f | %.3g |'],mode, ...
            item.F_minus_N_Cs1_pF,item.F_minus_N_Cs2_pF, ...
            item.F_minus_N_norm_pF,item.F_minus_A_Cs1_pF, ...
            item.F_minus_A_Cs2_pF,item.F_minus_A_norm_pF, ...
            item.A_minus_P_Cs1_pF,item.A_minus_P_Cs2_pF, ...
            item.A_minus_P_norm_pF,item.P_minus_N_Cs1_pF, ...
            item.P_minus_N_Cs2_pF,item.P_minus_N_norm_pF, ...
            item.decomposition_identity_residual_pF));
    end
    line('');
    line(['Operational interpretation only: F-A is the remaining direct ' ...
        'fault-related contribution under a matched adaptation schedule; ' ...
        'A-P is the VFF/adaptation-schedule contribution; P-N is the ' ...
        'protection-induced loss of true-drift learning. This is not ' ...
        'perfect causal identification.']);
else
    line(['The equivalence gate did not pass, so P/A causal replay was ' ...
        'blocked without relaxing tolerance. The MAIN overlap matrix ' ...
        'remains valid and complete if reported above.']);
end
line('');

line('## 7. Evidence balance and limitations');
line('');
write_evidence_balance(fileId,main);
line('');
line(['No claim is made that M4 is universally best. `||Δc_CF||/' ...
    '||Δc_F||` is not computed or used as purity, and no composite score ' ...
    'is created. Performance errors are not reclassified as numerical ' ...
    'failures.']);
line('');

line('## 8. Final status');
line('');
line('STEP 4 STATUS:');
line('**'+status+'**');
line('');
line('OVERLAP PHYSICAL POINTS:');
line(sprintf('**%d / 13**',physicalComplete));
line('');
line('MAIN EVALUATION RECORDS:');
line(sprintf('**%d / 52**',mainCount));
line('');
line('NEW ALGORITHM RUNS COMPLETE:');
line(sprintf('**%d / 46**',newRunCount));
line('');
line('NUMERICAL FAILURES:');
line(sprintf('**%d**',numericalFailures));
line('');
line('METRIC-MISSING ROWS:');
line(sprintf('**%d**',metricMissing));
line('');
line('REPLAY_EQUIVALENCE_GATE:');
line('**'+pass_fail(replayGatePass)+'**');
line('');
line('COUNTERFACTUAL REPLAY:');
line('**'+complete_blocked(replayComplete)+'**');
line('');
line('FROZEN SOURCE MODIFIED:');
line('**'+yes_no(~frozenPass)+'**');
line('');
line('READY FOR STEP 5:');
line('**'+yes_no(readyForStep5)+'**');
delete(cleanup);
end

function write_rate_analysis(fileId,core)
fprintf(fileId,'Rate effect (mean across D1 fault factors where registered):\n\n');
fprintf(fileId,'| Rate | Algorithm | mean Cs error norm (pF) | mean W1 retention | mean W2 retention |\n');
fprintf(fileId,'|---:|---|---:|---:|---:|\n');
for rate = [0.5,1,2]
    for mode = ["M0","M2","M3","M4"]
        x = core(core.drift_rate_multiplier == rate & ...
            core.algorithm_id == mode,:);
        fprintf(fileId,'| %.1f | %s | %.6f | %.6f | %.6f |\n', ...
            rate,mode,mean(x.parameter_error_RMS_norm_pF), ...
            mean(x.W1_fault_increment_retention_ratio), ...
            mean(x.W2_fault_increment_retention_ratio));
    end
end
fprintf(fileId,'\n');
for mode = ["M0","M2","M3","M4"]
    x = core(core.algorithm_id == mode,:);
    means = zeros(3,1);
    rates = [0.5,1,2];
    for k = 1:3
        means(k) = mean(x.parameter_error_RMS_norm_pF( ...
            x.drift_rate_multiplier == rates(k)));
    end
    [~,worst] = max(means);
    fprintf(fileId,['%s has its largest mean overlap tracking error at ' ...
        '**%.1fx** (%.6f pF); the observed rate response is descriptive ' ...
        'and is not assumed monotone.  \n'],mode,rates(worst),means(worst));
end
end

function write_fault_analysis(fileId,core)
fprintf(fileId,'Fault-amplitude effect at each rate:\n\n');
for rate = [0.5,1,2]
    x = core(core.drift_rate_multiplier == rate,:);
    m3 = x(x.algorithm_id == "M3",:);
    m4 = x(x.algorithm_id == "M4",:);
    [f3,o3] = sort(m3.fault_factor);
    [~,o4] = sort(m4.fault_factor);
    fprintf(fileId,['- %.1fx: M3 gate ratios at factors %s are %s; ' ...
        'M4 mean g values are %s.\n'],rate, ...
        strjoin(compose('%.2f',f3.'),'/'), ...
        strjoin(compose('%.4f',m3.hard_gate_active_ratio(o3).'),'/'), ...
        strjoin(compose('%.4f',m4.mean_update_weight(o4).'),'/'));
end
end

function write_direction_analysis(fileId,rows)
for mode = ["M2","M3","M4"]
    current = rows(rows.algorithm_id == mode,:);
    wrong = false(height(current),1);
    for k = 1:height(current)
        truth = [current.true_drift_Cs1_pF(k), ...
            current.true_drift_Cs2_pF(k)];
        fault = [current.F_minus_CF_Cs1_pF(k), ...
            current.F_minus_CF_Cs2_pF(k)];
        wrong(k) = dot(truth,fault) < 0;
    end
    if any(wrong)
        ids = current.condition_id(wrong);
        fprintf(fileId,['%s shows fault-induced movement opposite to the ' ...
            'true drift vector in %d/%d direction-extension rows: `%s`.  \n'], ...
            mode,nnz(wrong),height(current),strjoin(ids,'`, `'));
    else
        fprintf(fileId,['%s has no negative full-vector dot product in ' ...
            'these %d rows; component-level signed biases remain in the ' ...
            'table and CSV.  \n'],mode,height(current));
    end
end
end

function write_protection_analysis(fileId,main)
m3 = main(main.algorithm_id == "M3",:);
triggered = m3.hard_gate_active_ratio > 0;
if any(~triggered)
    miss = m3.condition_id(~triggered);
    fprintf(fileId,'M3 does not trigger in **%d/%d** points: `%s`.  \n', ...
        nnz(~triggered),height(m3),strjoin(miss,'`, `'));
else
    fprintf(fileId,'M3 triggers in all %d points.  \n',height(m3));
end
if any(triggered)
    frozen = m3(triggered,:);
    fprintf(fileId,['When triggered, M3 overlap hard-gate activity spans ' ...
        '**%.4f–%.4f** and parameter-error RMS norm spans ' ...
        '**%.6f–%.6f pF**. This preserves both fault protection and the ' ...
        'possible loss of real drift learning under hard freeze.  \n'], ...
        min(frozen.hard_gate_active_ratio),max(frozen.hard_gate_active_ratio), ...
        min(frozen.parameter_error_RMS_norm_pF), ...
        max(frozen.parameter_error_RMS_norm_pF));
end
m4 = main(main.algorithm_id == "M4",:);
fprintf(fileId,['M4 mean update weight spans **%.6f–%.6f** across the ' ...
    'registered matrix. It remains continuous where observed, but a ' ...
    'nonzero weight does not by itself prove correct drift separation.  \n'], ...
    min(m4.mean_update_weight),max(m4.mean_update_weight));
end

function write_evidence_balance(fileId,main)
m2 = main(main.algorithm_id == "M2",:);
m3 = main(main.algorithm_id == "M3",:);
m4 = main(main.algorithm_id == "M4",:);
[m2,m3,m4] = align_algorithms(m2,m3,m4);
m4BetterM2Retention = mean(abs([ ...
    m4.W1_fault_increment_retention_ratio-1, ...
    m4.W2_fault_increment_retention_ratio-1]),2) < ...
    mean(abs([m2.W1_fault_increment_retention_ratio-1, ...
    m2.W2_fault_increment_retention_ratio-1]),2);
m4BetterM3Tracking = m4.parameter_error_RMS_norm_pF < ...
    m3.parameter_error_RMS_norm_pF;
m4LowerBiasM2 = m4.F_minus_CF_norm_pF < m2.F_minus_CF_norm_pF;
m4LowerBiasM3 = m4.F_minus_CF_norm_pF < m3.F_minus_CF_norm_pF;
fprintf(fileId,['Across the 13 points, M4 has lower mean absolute W1/W2 ' ...
    'retention error than M2 in **%d/13**, lower overlap tracking error ' ...
    'than M3 in **%d/13**, lower F-CF movement norm than M2 in ' ...
    '**%d/13**, and lower F-CF movement norm than M3 in **%d/13**.  \n'], ...
    nnz(m4BetterM2Retention),nnz(m4BetterM3Tracking), ...
    nnz(m4LowerBiasM2),nnz(m4LowerBiasM3));
fprintf(fileId,['The complementary rows are formal limitations: continuous ' ...
    'weighting can retain more drift learning than hard freeze, but it can ' ...
    'also retain fault-related model bias. M3 threshold misses and hard-' ...
    'freeze costs are both reported rather than repaired by tuning.  \n']);
end

function [m2,m3,m4] = align_algorithms(m2,m3,m4)
[~,o2] = sort(m2.condition_id); m2 = m2(o2,:);
[~,o3] = sort(m3.condition_id); m3 = m3(o3,:);
[~,o4] = sort(m4.condition_id); m4 = m4(o4,:);
if ~isequal(m2.condition_id,m3.condition_id,m4.condition_id)
    error('Phase2:Step4ReportAlignment','Algorithm rows do not align.');
end
end

function label = pass_fail(pass)
if pass, label = "PASS"; else, label = "FAIL"; end
end

function label = yes_no(value)
if value, label = "YES"; else, label = "NO"; end
end

function label = complete_blocked(value)
if value, label = "COMPLETE"; else, label = "BLOCKED"; end
end
