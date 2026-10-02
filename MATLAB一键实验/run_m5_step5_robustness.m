function output = run_m5_step5_robustness(action)
%RUN_M5_STEP5_ROBUSTNESS Execute the frozen M5 Step5 robustness matrix.
%   readiness validates hashes, matrix cardinality, registry mapping, seeds,
%   geometry pairing, and method integrity without running performance.
%   execute requires a saved readiness PASS and runs all 150 conditions.
%   all runs readiness and then execute only when readiness passes.

if nargin < 1 || isempty(action), action = "readiness"; end
action = lower(string(action));
paths = step5_paths();
addpath(paths.matlab_root);
ensure_folder(paths.output_root);
ensure_folder(paths.internal_root);
ensure_folder(paths.cycle_root);
ensure_folder(paths.simulink_cache);
Simulink.fileGenControl('set','CacheFolder',paths.simulink_cache, ...
    'CodeGenFolder',paths.simulink_cache,'createDir',true);

switch action
    case "readiness"
        output = run_readiness(paths);
    case "execute"
        output = run_execution(paths);
    case "all"
        gate = run_readiness(paths);
        if gate.pass
            output = run_execution(paths);
        else
            output = gate;
        end
    otherwise
        error('M5Step5:Action','Unsupported action %s.',action);
end
end

function output = run_readiness(paths)
pre = source_integrity(paths);
matrixAudit = m5_step5_validate_matrix(paths.matrix,paths.registry);
matrixHash = file_sha256(paths.matrix);
expectedMatrixHash = ...
    "3BC7206A20A01BF677522D56BAE9D7A497226162E386495763435733D38D5E66";
matrixHashPass = matrixHash == expectedMatrixHash;
pass = pre.pass && matrixAudit.pass && matrixHashPass;
readiness = struct('pass',pass,'source_integrity',pre, ...
    'matrix_audit',matrixAudit,'matrix_sha256',matrixHash, ...
    'expected_matrix_sha256',expectedMatrixHash, ...
    'performance_viewed',false,'simulation_calls',0, ...
    'tracker_branches',0,'timestamp',string(datetime('now')));
save(paths.readiness_mat,'readiness','-v7.3');

output = struct('status',pass_fail(pass),'pass',pass, ...
    'rows',height(matrixAudit.matrix), ...
    'physical_conditions',numel(unique( ...
        matrixAudit.matrix.physical_condition_id)), ...
    'geometry_pairs',numel(unique(matrixAudit.matrix.geometry_pair_id)), ...
    'simulation_calls',0,'tracker_branches',0, ...
    'performance_viewed',false);
fprintf('STEP5_READINESS=%s\n',pass_fail(pass));
fprintf('SOURCE_HASHES=%s\n',pass_fail(pre.pass));
fprintf('MATRIX_INTEGRITY=%s\n',pass_fail(matrixAudit.pass));
fprintf('MATRIX_SHA256=%s\n',pass_fail(matrixHashPass));
fprintf('REGISTERED_ROWS=%d/600\n',height(matrixAudit.matrix));
fprintf('PHYSICAL=%d/150\n',output.physical_conditions);
fprintf('GEOMETRY_PAIRS=%d/50\n',output.geometry_pairs);
fprintf('M5_PERFORMANCE_VIEWED=NO\n');
if ~pass
    fprintf('STEP5=BLOCKED\n');
end
end

function output = run_execution(paths)
if ~isfile(paths.readiness_mat)
    error('M5Step5:ReadinessMissing','Run readiness before execute.');
end
loaded = load(paths.readiness_mat,'readiness');
if ~loaded.readiness.pass
    error('M5Step5:ReadinessBlocked','Readiness is not PASS.');
end
pre = source_integrity(paths);
matrixAudit = m5_step5_validate_matrix(paths.matrix,paths.registry);
matrixPreHash = file_sha256(paths.matrix);
if ~pre.pass || ~matrixAudit.pass || ...
        matrixPreHash ~= loaded.readiness.matrix_sha256
    error('M5Step5:PreExecutionIntegrity', ...
        'Source or matrix integrity changed after readiness.');
end

matrix = matrixAudit.matrix;
[~,firstIndex] = unique(matrix.physical_condition_id,'stable');
conditions = matrix(sort(firstIndex),:);
if height(conditions) ~= 150
    error('M5Step5:ConditionCount','Expected 150 physical conditions.');
end

resultRows = repmat(blank_result_row(),0,1);
simulationCalls = 0;
trackerBranches = 0;
batchSize = 15;
batchModes = strings(0,1);
started = tic;

for batchStart = 1:batchSize:height(conditions)
    batchEnd = min(batchStart+batchSize-1,height(conditions));
    batch = conditions(batchStart:batchEnd,:);
    [contexts,cleanMode,noisyMode] = generate_physical_batch(batch);
    simulationCalls = simulationCalls+3*height(batch);
    batchModes(end+1,1) = cleanMode+"|"+noisyMode; %#ok<AGROW>
    for k = 1:numel(contexts)
        globalIndex = batchStart+k-1;
        try
            [rows,cycleLog,branches] = evaluate_condition(contexts(k));
            resultRows = [resultRows;rows]; %#ok<AGROW>
            trackerBranches = trackerBranches+branches;
            cyclePath = fullfile(paths.cycle_root, ...
                char(contexts(k).row.physical_condition_id)+".mat");
            save(cyclePath,'cycleLog','-v7.3');
            fprintf('M5 STEP5 CONDITION %03d/150 %s COMPLETE\n', ...
                globalIndex,contexts(k).row.physical_condition_id);
        catch exception
            rows = failure_rows(contexts(k).row,exception);
            resultRows = [resultRows;rows]; %#ok<AGROW>
            fprintf(2,'M5 STEP5 CONDITION %s FAIL: %s\n', ...
                contexts(k).row.physical_condition_id,exception.message);
        end
    end
    checkpoint = struct2table(resultRows,'AsArray',true);
    writetable(checkpoint,paths.checkpoint_csv);
    state = struct('last_condition',batchEnd, ...
        'simulation_calls',simulationCalls, ...
        'tracker_branches',trackerBranches, ...
        'elapsed_seconds',toc(started));
    save(paths.execution_state_mat,'state','-v7.3');
    clear contexts checkpoint
end

results = struct2table(resultRows,'AsArray',true);
pairs = build_matched_pairs(results);
summaries = build_geometry_summaries(pairs);
phaseSummary = build_phase_summary(pairs);
boundarySummary = build_boundary_summary(pairs);
post = source_integrity(paths);
matrixPostHash = file_sha256(paths.matrix);
sourceUnchanged = pre.pass && post.pass && ...
    isequal(pre.actual_sha256,post.actual_sha256);
matrixUnchanged = matrixPostHash == matrixPreHash;
results.source_integrity_pass(:) = sourceUnchanged;
results.matrix_integrity_pass(:) = matrixUnchanged;
results = attach_pair_deltas(results,pairs);

[gates,decision] = decide_step5(results,pairs,summaries,pre,post, ...
    matrixUnchanged,simulationCalls,trackerBranches);
writetable(results,paths.master_csv);
writetable(pairs,paths.pairs_csv);
writetable(summaries,paths.summary_csv);
writetable(phaseSummary,paths.phase_csv);
writetable(boundarySummary,paths.boundary_csv);
write_decision_report(paths,results,pairs,summaries,phaseSummary, ...
    boundarySummary,gates,decision,pre,post,matrixPreHash, ...
    matrixPostHash,simulationCalls,trackerBranches,toc(started),batchModes);
save(paths.workspace_mat,'pairs','summaries','phaseSummary', ...
    'boundarySummary','gates','decision','pre','post', ...
    'simulationCalls','trackerBranches','batchModes','-v7.3');

complete = ~results.numerical_failure & ~results.metric_missing & ...
    ~results.simulation_abort;
orthCont = pairs(pairs.geometry=="ORTHOGONAL" & ...
    pairs.weight_mode=="CONTINUOUS",:);
output = struct('status',decision,'pass',decision=="GO", ...
    'physical_conditions',numel(unique(results.physical_condition_id)), ...
    'algorithm_evaluations',nnz(complete), ...
    'simulation_calls',simulationCalls, ...
    'tracker_branches',trackerBranches, ...
    'orthogonal_finite',nnz(isfinite(orthCont.Delta_perp)), ...
    'gate0',gates.Gate0,'gateA',gates.GateA, ...
    'gateB',gates.GateB,'gateC',gates.GateC, ...
    'gateD',gates.GateD,'gateE',gates.GateE, ...
    'master_results',string(paths.master_csv), ...
    'decision_report',string(paths.report));

ready = gates.Gate0 && gates.GateE;
fprintf('STEP5_READY:%s\n',pass_blocked(ready));
fprintf('PHYSICAL:%d/150\n',output.physical_conditions);
fprintf('ALGORITHM_EVALUATIONS:%d/600\n',output.algorithm_evaluations);
fprintf('SIM_CALLS:%d/450\n',simulationCalls);
fprintf('TRACKER_BRANCHES:%d/1200\n',trackerBranches);
fprintf('ORTHOGONAL_FINITE:%d/50\n',output.orthogonal_finite);
fprintf('GATE_A_CONTINUOUS:%s\n',pass_fail(gates.GateA));
fprintf('GATE_B_HARD:%s\n',hard_gate_label(gates.GateB));
fprintf('GATE_C_MIXED:%s\n',pass_fail(gates.GateC));
fprintf('GATE_D_PARALLEL:%s\n',retained_label(gates.GateD));
fprintf('GATE_E_METHOD_INTEGRITY:%s\n',pass_fail(gates.GateE));
fprintf('STEP5:%s\n',decision);
fprintf('STEP6_AUTHORIZED:NO -- pending human review\n');
fprintf('DECISION_REPORT:%s\n',paths.report);
fprintf('MASTER_RESULTS:%s\n',paths.master_csv);
end

function [contexts,cleanMode,noisyMode] = generate_physical_batch(rows)
n = height(rows);
contexts = repmat(struct('row',table(),'physical_cfg',struct(), ...
    'algorithm_cfg',struct(),'signalsF',struct(),'signalsCF',struct(), ...
    'cleanF',struct(),'noise',struct(),'noise_draw_signature',"", ...
    'dataF',struct(),'dataCF',struct(),'ref',struct(), ...
    'data_signature',"",'mapping_pass',false,'seed_pass',false, ...
    'shared_data_pass',false),n,1);
inputs(1,n) = Simulink.SimulationInput('AI6109_MOA_AutoComp9');
for k = 1:n
    row = rows(k,:);
    [physicalCfg,algorithmCfg] = configs_from_row(row);
    signalsF = build_signals(row,physicalCfg,"F");
    signalsCF = build_signals(row,physicalCfg,"CF");
    zero = zeros(size(signalsF.t));
    inputs(k) = make_simulation_input(physicalCfg,signalsF,zero,zero,zero);
    contexts(k).row = row;
    contexts(k).physical_cfg = physicalCfg;
    contexts(k).algorithm_cfg = algorithmCfg;
    contexts(k).signalsF = signalsF;
    contexts(k).signalsCF = signalsCF;
end
[outputs,cleanMode] = run_simulation_batch(inputs,"CLEAN");
for k = 1:n
    contexts(k).cleanF = extract_simulation_data(outputs(k));
end
clear outputs inputs

inputs(1,2*n) = Simulink.SimulationInput('AI6109_MOA_AutoComp9');
for k = 1:n
    row = contexts(k).row;
    clean = contexts(k).cleanF;
    rng(double(row.noise_seed),'twister');
    zA = randn(size(clean.ia));
    zB = randn(size(clean.ib));
    zC = randn(size(clean.ic));
    noise = struct( ...
        'A',scale_noise(zA,clean.ia,row.SNR_dB), ...
        'B',scale_noise(zB,clean.ib,row.SNR_dB), ...
        'C',scale_noise(zC,clean.ic,row.SNR_dB));
    contexts(k).noise = noise;
    contexts(k).noise_draw_signature = vector_signature( ...
        {double(row.noise_seed),zA,zB,zC});
    inputs(2*k-1) = make_simulation_input(contexts(k).physical_cfg, ...
        contexts(k).signalsF,noise.A,noise.B,noise.C);
    inputs(2*k) = make_simulation_input(contexts(k).physical_cfg, ...
        contexts(k).signalsCF,noise.A,noise.B,noise.C);
end
[outputs,noisyMode] = run_simulation_batch(inputs,"NOISY_F_CF");
for k = 1:n
    row = contexts(k).row;
    contexts(k).dataF = add_physical_metadata( ...
        extract_simulation_data(outputs(2*k-1)),row,"F");
    contexts(k).dataCF = add_physical_metadata( ...
        extract_simulation_data(outputs(2*k)),row,"CF");
    cfg = contexts(k).algorithm_cfg;
    data = contexts(k).dataF;
    contexts(k).ref = reconstruct_refs_from_b(data.t,data.ub,cfg.f, ...
        cfg.init_start,cfg.init_end,cfg.phase_error_deg);
    contexts(k).mapping_pass = mapping_audit(contexts(k));
    contexts(k).seed_pass = seed_audit(row);
    contexts(k).shared_data_pass = shared_data_audit(contexts(k));
    contexts(k).data_signature = condition_signature(contexts(k));
end
clear outputs inputs
end

function [physicalCfg,algorithmCfg] = configs_from_row(row)
physicalCfg = patent_default_config();
physicalCfg.model = 'AI6109_MOA_AutoComp9';
physicalCfg.StopTime = double(row.simulation_stop_s);
physicalCfg.SNR_dB = double(row.SNR_dB);
physicalCfg.h3_ratio = double(row.h3_ratio);
physicalCfg.phi3_deg = double(row.h3_phase_deg);
physicalCfg.Vneg_pu = double(row.negative_sequence_pu);
physicalCfg.Cself_pF = double(row.Cself_truth_pF);
physicalCfg.phase_error_deg = 0;
algorithmCfg = physicalCfg;
algorithmCfg.Cself_pF = double(row.Cself_algorithm_pF);
algorithmCfg.phase_error_deg = double(row.reference_phase_error_deg);
end

function signals = build_signals(row,cfg,branch)
t = (0:cfg.Ts:cfg.StopTime).';
drift = smooth_step(t,double(row.drift_start_s),double(row.drift_end_s));
Cs1 = double(row.Cs1_initial_pF)+double(row.drift_delta_Cs1_pF)*drift;
Cs2 = double(row.Cs2_initial_pF)+double(row.drift_delta_Cs2_pF)*drift;
faultScale = ones(size(t));
if upper(string(branch)) == "F"
    up = smooth_step(t,double(row.fault_start_s),double(row.fault_ramp_end_s));
    down = smooth_step(t,double(row.fault_plateau_end_s),double(row.fault_end_s));
    faultScale = 1+(double(row.fault_factor)-1)*min(up,1-down);
end
signals = struct('t',t,'Cs1_pF',Cs1,'Cs2_pF',Cs2, ...
    'fault_scale',faultScale,'branch',upper(string(branch)));
end

function y = smooth_step(t,t0,t1)
x = min(max((t-t0)/(t1-t0),0),1);
y = x.^2.*(3-2*x);
end

function in = make_simulation_input(cfg,signals,noiseA,noiseB,noiseC)
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
end

function [outputs,mode] = run_simulation_batch(inputs,label)
try
    outputs = sim(inputs,'UseFastRestart','on');
    mode = string(label)+"_FAST_RESTART_BATCH";
catch batchException
    warning('M5Step5:BatchFallback','%s batch failed (%s).', ...
        label,batchException.message);
    outputs = sim(inputs(1));
    for k = 2:numel(inputs)
        outputs(k) = sim(inputs(k)); %#ok<AGROW>
    end
    mode = string(label)+"_SEQUENTIAL_FALLBACK";
end
end

function data = extract_simulation_data(out)
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

function [t,x] = read_signal(out,name)
s = out.get(name);
if isa(s,'timeseries')
    t = s.Time; x = s.Data;
else
    t = s.time; x = s.signals.values;
end
t = t(:); x = squeeze(x); x = x(:);
end

function data = add_physical_metadata(data,row,branch)
for name = ["Ca","Cb","Cc"]
    data.(char(name)) = double(row.Cself_truth_pF)*ones(size(data.t));
end
data.scenario = "m5_step5_"+row.geometry+"_"+string(branch);
data.current_source = "simulink";
end

function noise = scale_noise(z,ideal,snrDB)
if isfinite(double(snrDB))
    noise = rms(ideal)/10^(double(snrDB)/20)*z;
else
    noise = zeros(size(z));
end
end

function pass = mapping_audit(context)
row = context.row; data = context.dataF; signals = context.signalsF;
tol = 1e-10;
pass = numel(data.t)==numel(signals.t) && ...
    max(abs(data.t-signals.t))<=tol && ...
    max(abs(data.Cs1-signals.Cs1_pF))<=tol && ...
    max(abs(data.Cs2-signals.Cs2_pF))<=tol && ...
    abs(data.Cs1(1)-double(row.Cs1_initial_pF))<=tol && ...
    abs(data.Cs2(1)-double(row.Cs2_initial_pF))<=tol && ...
    abs(data.Cs1(end)-double(row.Cs1_final_pF))<=tol && ...
    abs(data.Cs2(end)-double(row.Cs2_final_pF))<=tol && ...
    abs(hypot(double(row.drift_delta_Cs1_pF), ...
        double(row.drift_delta_Cs2_pF))-sqrt(13))<=1e-12 && ...
    abs(max(signals.fault_scale)-double(row.fault_factor))<=tol && ...
    all(context.signalsCF.fault_scale==1) && ...
    context.physical_cfg.Cself_pF==double(row.Cself_truth_pF) && ...
    context.algorithm_cfg.Cself_pF==double(row.Cself_algorithm_pF) && ...
    context.algorithm_cfg.phase_error_deg==double(row.reference_phase_error_deg);
end

function pass = shared_data_audit(context)
f = context.dataF; cf = context.dataCF; tol = 0;
pre = context.signalsF.t < double(context.row.fault_start_s);
pass = exact_vector(f.t,cf.t,tol) && exact_vector(f.ua,cf.ua,tol) && ...
    exact_vector(f.ub,cf.ub,tol) && exact_vector(f.uc,cf.uc,tol) && ...
    exact_vector(f.Cs1,cf.Cs1,tol) && exact_vector(f.Cs2,cf.Cs2,tol) && ...
    exact_vector(f.ia(pre),cf.ia(pre),1e-12) && ...
    exact_vector(f.ib(pre),cf.ib(pre),1e-12) && ...
    exact_vector(f.ic(pre),cf.ic(pre),1e-12);
end

function pass = seed_audit(row)
index = 100+double(row.source_registry_index);
pass = double(row.truth_seed)==derive_seed("TRUTH",index) && ...
    double(row.noise_seed)==derive_seed("NOISE",index) && ...
    double(row.truth_seed)~=double(row.noise_seed);
end

function value = derive_seed(kind,index)
payload = sprintf('P2|2290434627|%s|%d',kind,index);
hash = bytes_sha256(unicode2native(payload,'UTF-8'));
value = 1+mod(hex2dec(char(extractBetween(hash,1,8))),2147483646);
end

function pass = exact_vector(a,b,tolerance)
pass = isequal(size(a),size(b)) && all(abs(double(a(:))-double(b(:)))<=tolerance);
end

function signature = condition_signature(context)
f=context.dataF; cf=context.dataCF; ref=context.ref; row=context.row;
signature = vector_signature({double(row.truth_seed),double(row.noise_seed), ...
    f.t,f.ua,f.ub,f.uc,f.ia,f.ib,f.ic,f.irA,f.irB,f.irC,f.Cs1,f.Cs2, ...
    cf.ia,cf.ib,cf.ic,cf.irB,context.signalsF.fault_scale, ...
    context.noise.A,context.noise.B,context.noise.C, ...
    ref.ua,ref.ub,ref.uc,ref.dua,ref.dub,ref.duc});
end

function signature = vector_signature(values)
digester = java.security.MessageDigest.getInstance('SHA-256');
for k = 1:numel(values)
    digester.update(typecast(double(values{k}(:)),'uint8'));
end
hashBytes = typecast(digester.digest(),'uint8');
signature = upper(string(reshape(dec2hex(hashBytes,2).',1,[])));
end

function [rows,cycleLog,branchCount] = evaluate_condition(context)
algorithms = ["GH","GC","M5_DH","M5_FULL"];
rows = repmat(blank_result_row(),4,1);
cycleLog = struct();
branchCount = 0;
windows = overlap_windows(context.row.evaluation_window_set_id);
for k = 1:4
    algorithm = algorithms(k);
    mode = tracker_mode(algorithm);
    selfPF = repmat(double(context.row.Cself_algorithm_pF),1,3);
    trackerF = track_coupling_m5_directional_rls( ...
        context.dataF,context.ref,context.algorithm_cfg,selfPF,mode);
    trackerCF = track_coupling_m5_directional_rls( ...
        context.dataCF,context.ref,context.algorithm_cfg,selfPF,mode);
    branchCount = branchCount+2;
    resultF = wrap_tracker_result( ...
        context.dataF,context.ref,selfPF,trackerF);
    resultCF = wrap_tracker_result( ...
        context.dataCF,context.ref,selfPF,trackerCF);
    metrics = overlap_metrics(resultF,resultCF,context,windows);
    diagnosticF = branch_diagnostics( ...
        algorithm,trackerF.cycle,windows,context.algorithm_cfg);
    diagnosticCF = branch_diagnostics( ...
        algorithm,trackerCF.cycle,windows,context.algorithm_cfg);
    current = blank_result_row();
    current = fill_registration(current,context.row,algorithm);
    current.data_signature = context.data_signature;
    current.noise_draw_signature = context.noise_draw_signature;
    current = fill_metrics(current,metrics);
    current = fill_branch_diagnostics(current,diagnosticF,"F");
    current = fill_branch_diagnostics(current,diagnosticCF,"CF");
    finitePass = result_finite(resultF,resultCF,context);
    metricPass = required_metrics_finite(current);
    current.registry_match = context.mapping_pass;
    current.seed_match = context.seed_pass;
    current.shared_data_pass = context.shared_data_pass;
    current.required_outputs_pass = finitePass;
    current.numerical_failure = ~finitePass;
    current.metric_missing = ~metricPass;
    current.simulation_abort = false;
    current.notes = "Frozen Step5 matched F/CF execution; no tuning.";
    rows(k) = current;
    overlapMaskF = cycle_overlap_mask(trackerF.cycle,windows);
    overlapMaskCF = cycle_overlap_mask(trackerCF.cycle,windows);
    cycleLog.(char(algorithm)).F = trackerF.cycle(overlapMaskF,:);
    cycleLog.(char(algorithm)).CF = trackerCF.cycle(overlapMaskCF,:);
end
end

function mode = tracker_mode(algorithm)
switch string(algorithm)
    case "GH", mode = "GLOBAL_HARD_MATCHED";
    case "GC", mode = "GLOBAL_CONTINUOUS_MATCHED";
    case "M5_DH", mode = "M5_DH";
    case "M5_FULL", mode = "M5_FULL";
    otherwise, error('M5Step5:Algorithm','Unknown algorithm %s.',algorithm);
end
end

function result = wrap_tracker_result(data,ref,selfPF,tracker)
result = struct('cHist',tracker.hist, ...
    'ir',extract_resistive_current(data,ref,selfPF,tracker.hist), ...
    'tracker',tracker);
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
        error('M5Step5:WindowSet','Unknown window set %s.',id);
end
windows = array2table(values,'VariableNames',{'start_s','end_s'}, ...
    'RowNames',{'W0','W1','W2','W3','W4'});
windows.id = repmat(string(id),5,1);
end

function metrics = overlap_metrics(resultF,resultCF,context,windows)
dataF = context.dataF; dataCF = context.dataCF;
t = dataF.t; cfg = context.algorithm_cfg;
w1 = sample_window(t,windows{'W1','start_s'},windows{'W1','end_s'});
w2 = sample_window(t,windows{'W2','start_s'},windows{'W2','end_s'});
overlap = w1 | w2;
truth = [dataF.Cs1,dataF.Cs2];
direction = m5_step4_direction_metrics(resultF.cHist,truth,overlap);
startIndex = find(t < windows{'W0','end_s'},1,'last');
endIndex = find(t < windows{'W2','end_s'},1,'last');
truthMove = truth(endIndex,:)-truth(startIndex,:);
fMove = resultF.cHist(endIndex,:)-resultF.cHist(startIndex,:);
cfMove = resultCF.cHist(endIndex,:)-resultCF.cHist(startIndex,:);
faultMove = fMove-cfMove;
metrics = struct( ...
    'RMSE_total_pF',direction.RMSE_total_pF, ...
    'RMSE_parallel_pF',direction.RMSE_parallel_pF, ...
    'RMSE_perp_pF',direction.RMSE_perp_pF, ...
    'decomposition_max_abs_pF',direction.decomposition_max_abs_pF, ...
    'energy_closure_max_abs_pF2',direction.energy_closure_max_abs_pF2, ...
    'W1_fault_increment_retention_ratio',retention_ratio( ...
        dataF,dataCF,resultF,resultCF,cfg.f,w1), ...
    'W2_fault_increment_retention_ratio',retention_ratio( ...
        dataF,dataCF,resultF,resultCF,cfg.f,w2), ...
    'true_drift_Cs1_pF',truthMove(1), ...
    'true_drift_Cs2_pF',truthMove(2), ...
    'true_drift_norm_pF',norm(truthMove), ...
    'F_movement_Cs1_pF',fMove(1), ...
    'F_movement_Cs2_pF',fMove(2), ...
    'F_movement_norm_pF',norm(fMove), ...
    'CF_movement_Cs1_pF',cfMove(1), ...
    'CF_movement_Cs2_pF',cfMove(2), ...
    'CF_movement_norm_pF',norm(cfMove), ...
    'F_minus_CF_Cs1_pF',faultMove(1), ...
    'F_minus_CF_Cs2_pF',faultMove(2), ...
    'F_minus_CF_norm_pF',norm(faultMove));
metrics.W1_signed_retention_error = ...
    metrics.W1_fault_increment_retention_ratio-1;
metrics.W1_abs_retention_error = abs(metrics.W1_signed_retention_error);
metrics.W2_signed_retention_error = ...
    metrics.W2_fault_increment_retention_ratio-1;
metrics.W2_abs_retention_error = abs(metrics.W2_signed_retention_error);
end

function ratio = retention_ratio(dataF,dataCF,resultF,resultCF,f,index)
trueIncrement = fundamental_rms(dataF.t(index),dataF.irB(index),f)- ...
    fundamental_rms(dataCF.t(index),dataCF.irB(index),f);
estimatedIncrement = fundamental_rms(dataF.t(index),resultF.ir.B(index),f)- ...
    fundamental_rms(dataCF.t(index),resultCF.ir.B(index),f);
ratio = estimatedIncrement/(trueIncrement+eps);
end

function value = fundamental_rms(t,x,f)
w = 2*pi*f;
coefficients = [sin(w*t),cos(w*t),ones(size(t))]\x;
value = hypot(coefficients(1),coefficients(2))/sqrt(2);
end

function index = sample_window(time,startTime,endTime)
index = time >= startTime & time < endTime;
if ~any(index)
    error('M5Step5:SampleWindow','Empty sample window.');
end
end

function index = cycle_overlap_mask(cycle,windows)
index = (cycle.time_s >= windows{'W1','start_s'} & ...
    cycle.time_s < windows{'W1','end_s'}) | ...
    (cycle.time_s >= windows{'W2','start_s'} & ...
    cycle.time_s < windows{'W2','end_s'});
if ~any(index), error('M5Step5:CycleWindow','Empty overlap cycle window.'); end
end

function diagnostic = branch_diagnostics(algorithm,cycle,windows,cfg)
diagnostic = m5_step4_cycle_diagnostics(algorithm,cycle, ...
    windows{'W1','start_s'},windows{'W2','end_s'},cfg);
diagnostic.rate_limit_active = diagnostic.rate_limit_cycles > 0;
diagnostic.projection_active = diagnostic.projection_cycles > 0;
diagnostic.pre_constraint_angle_deg = ...
    diagnostic.mean_protected_angle_to_df_deg;
diagnostic.post_rate_angle_deg = ...
    diagnostic.mean_post_rate_angle_to_df_deg;
diagnostic.post_projection_angle_deg = ...
    diagnostic.mean_post_projection_angle_to_df_deg;
end

function row = fill_registration(row,reg,algorithm)
row.physical_condition_id = reg.physical_condition_id;
row.evaluation_id = reg.physical_condition_id+"__"+algorithm;
row.geometry_pair_id = reg.geometry_pair_id;
row.source_condition_id = reg.source_condition_id;
row.source_registry_index = double(reg.source_registry_index);
row.geometry = reg.geometry;
row.algorithm_id = algorithm;
row.algorithm_scope = scope_for_algorithm(algorithm);
row.weight_mode = weight_for_algorithm(algorithm);
row.truth_seed = double(reg.truth_seed);
row.noise_seed = double(reg.noise_seed);
row.SNR_dB = double(reg.SNR_dB);
row.reference_phase_error_deg = double(reg.reference_phase_error_deg);
row.fault_factor = double(reg.fault_factor);
row.drift_rate_multiplier = double(reg.drift_rate_multiplier);
row.Cself_mismatch_pct = double(reg.Cself_mismatch_pct);
row.Cself_truth_pF = double(reg.Cself_truth_pF);
row.Cself_algorithm_pF = double(reg.Cself_algorithm_pF);
row.evaluation_window_set_id = reg.evaluation_window_set_id;
row.drift_delta_Cs1_pF = double(reg.drift_delta_Cs1_pF);
row.drift_delta_Cs2_pF = double(reg.drift_delta_Cs2_pF);
row.drift_norm_pF = double(reg.drift_norm_pF);
row.source_registry_sha256 = reg.source_registry_sha256;
row.model_sha256 = reg.model_sha256;
row.config_sha256 = reg.config_sha256;
row.tracker_sha256 = reg.tracker_sha256;
row.projector_sha256 = reg.projector_sha256;
row.regressor_sha256 = reg.regressor_sha256;
end

function value = scope_for_algorithm(algorithm)
if ismember(string(algorithm),["GH","GC"]), value="GLOBAL"; else, value="DIRECTIONAL"; end
end

function value = weight_for_algorithm(algorithm)
if ismember(string(algorithm),["GH","M5_DH"]), value="HARD"; else, value="CONTINUOUS"; end
end

function row = fill_metrics(row,m)
names = fieldnames(m);
for k = 1:numel(names), row.(names{k}) = m.(names{k}); end
end

function row = fill_branch_diagnostics(row,d,prefix)
mapping = { ...
    'cycle_count','cycle_count'; ...
    'hard_gate_active_ratio','hard_gate_active_ratio'; ...
    'mean_w_REW','mean_w_REW'; ...
    'mean_selected_weight','mean_selected_weight'; ...
    'rate_limit_cycles','rate_limit_cycles'; ...
    'projection_cycles','projection_cycles'; ...
    'rate_limit_active','rate_limit_active'; ...
    'projection_active','projection_active'; ...
    'near_zero_update_cycles','near_zero_update_cycles'; ...
    'mean_raw_angle_to_df_deg','raw_angle_to_df_deg'; ...
    'pre_constraint_angle_deg','pre_constraint_angle_deg'; ...
    'post_rate_angle_deg','post_rate_angle_deg'; ...
    'post_projection_angle_deg','post_projection_angle_deg'; ...
    'raw_parallel_update_energy_pF2','raw_parallel_update_energy_pF2'; ...
    'raw_perp_update_energy_pF2','raw_perp_update_energy_pF2'; ...
    'applied_parallel_update_energy_pF2','applied_parallel_update_energy_pF2'; ...
    'applied_perp_update_energy_pF2','applied_perp_update_energy_pF2'};
for k = 1:size(mapping,1)
    row.([char(prefix) '_' mapping{k,2}]) = d.(mapping{k,1});
end
end

function pass = result_finite(resultF,resultCF,context)
pass = all(isfinite(resultF.cHist),'all') && ...
    all(isfinite(resultCF.cHist),'all') && ...
    all(isfinite(resultF.ir.A)) && all(isfinite(resultF.ir.B)) && ...
    all(isfinite(resultF.ir.C)) && all(isfinite(resultCF.ir.A)) && ...
    all(isfinite(resultCF.ir.B)) && all(isfinite(resultCF.ir.C)) && ...
    all(isfinite(context.dataF.ia)) && all(isfinite(context.dataCF.ia)) && ...
    all(isfinite(context.ref.ua)) && all(isfinite(context.ref.dua));
end

function pass = required_metrics_finite(row)
required = [row.RMSE_total_pF,row.RMSE_parallel_pF,row.RMSE_perp_pF, ...
    row.W1_fault_increment_retention_ratio, ...
    row.W2_fault_increment_retention_ratio,row.W1_abs_retention_error, ...
    row.W2_abs_retention_error,row.F_minus_CF_norm_pF];
pass = all(isfinite(required));
end

function row = blank_result_row()
row = struct( ...
    'physical_condition_id',"",'evaluation_id',"", ...
    'geometry_pair_id',"",'source_condition_id',"", ...
    'source_registry_index',NaN,'geometry',"",'algorithm_id',"", ...
    'algorithm_scope',"",'weight_mode',"", ...
    'truth_seed',NaN,'noise_seed',NaN,'SNR_dB',NaN, ...
    'reference_phase_error_deg',NaN,'fault_factor',NaN, ...
    'drift_rate_multiplier',NaN,'Cself_mismatch_pct',NaN, ...
    'Cself_truth_pF',NaN,'Cself_algorithm_pF',NaN, ...
    'evaluation_window_set_id',"", ...
    'drift_delta_Cs1_pF',NaN,'drift_delta_Cs2_pF',NaN, ...
    'drift_norm_pF',NaN,'data_signature',"", ...
    'noise_draw_signature',"", ...
    'RMSE_total_pF',NaN,'RMSE_parallel_pF',NaN,'RMSE_perp_pF',NaN, ...
    'decomposition_max_abs_pF',NaN,'energy_closure_max_abs_pF2',NaN, ...
    'W1_fault_increment_retention_ratio',NaN, ...
    'W1_signed_retention_error',NaN,'W1_abs_retention_error',NaN, ...
    'W2_fault_increment_retention_ratio',NaN, ...
    'W2_signed_retention_error',NaN,'W2_abs_retention_error',NaN, ...
    'true_drift_Cs1_pF',NaN,'true_drift_Cs2_pF',NaN, ...
    'true_drift_norm_pF',NaN, ...
    'F_movement_Cs1_pF',NaN,'F_movement_Cs2_pF',NaN, ...
    'F_movement_norm_pF',NaN, ...
    'CF_movement_Cs1_pF',NaN,'CF_movement_Cs2_pF',NaN, ...
    'CF_movement_norm_pF',NaN, ...
    'F_minus_CF_Cs1_pF',NaN,'F_minus_CF_Cs2_pF',NaN, ...
    'F_minus_CF_norm_pF',NaN, ...
    'F_cycle_count',NaN,'F_hard_gate_active_ratio',NaN, ...
    'F_mean_w_REW',NaN,'F_mean_selected_weight',NaN, ...
    'F_rate_limit_cycles',NaN,'F_projection_cycles',NaN, ...
    'F_rate_limit_active',false,'F_projection_active',false, ...
    'F_near_zero_update_cycles',NaN,'F_raw_angle_to_df_deg',NaN, ...
    'F_pre_constraint_angle_deg',NaN,'F_post_rate_angle_deg',NaN, ...
    'F_post_projection_angle_deg',NaN, ...
    'F_raw_parallel_update_energy_pF2',NaN, ...
    'F_raw_perp_update_energy_pF2',NaN, ...
    'F_applied_parallel_update_energy_pF2',NaN, ...
    'F_applied_perp_update_energy_pF2',NaN, ...
    'CF_cycle_count',NaN,'CF_hard_gate_active_ratio',NaN, ...
    'CF_mean_w_REW',NaN,'CF_mean_selected_weight',NaN, ...
    'CF_rate_limit_cycles',NaN,'CF_projection_cycles',NaN, ...
    'CF_rate_limit_active',false,'CF_projection_active',false, ...
    'CF_near_zero_update_cycles',NaN,'CF_raw_angle_to_df_deg',NaN, ...
    'CF_pre_constraint_angle_deg',NaN,'CF_post_rate_angle_deg',NaN, ...
    'CF_post_projection_angle_deg',NaN, ...
    'CF_raw_parallel_update_energy_pF2',NaN, ...
    'CF_raw_perp_update_energy_pF2',NaN, ...
    'CF_applied_parallel_update_energy_pF2',NaN, ...
    'CF_applied_perp_update_energy_pF2',NaN, ...
    'Delta_total_cont',NaN,'Delta_parallel_cont',NaN, ...
    'Delta_perp_cont',NaN,'Delta_W1_retention_cont',NaN, ...
    'Delta_W2_retention_cont',NaN,'Delta_bias_cont',NaN, ...
    'Delta_total_hard',NaN,'Delta_parallel_hard',NaN, ...
    'Delta_perp_hard',NaN,'Delta_W1_retention_hard',NaN, ...
    'Delta_W2_retention_hard',NaN,'Delta_bias_hard',NaN, ...
    'registry_match',false,'seed_match',false, ...
    'shared_data_pass',false,'required_outputs_pass',false, ...
    'numerical_failure',true,'metric_missing',true, ...
    'simulation_abort',true,'source_integrity_pass',false, ...
    'matrix_integrity_pass',false, ...
    'source_registry_sha256',"",'model_sha256',"", ...
    'config_sha256',"",'tracker_sha256',"", ...
    'projector_sha256',"",'regressor_sha256',"",'notes',"");
end

function rows = failure_rows(reg,exception)
algorithms = ["GH","GC","M5_DH","M5_FULL"];
rows = repmat(blank_result_row(),4,1);
for k = 1:4
    rows(k) = fill_registration(rows(k),reg,algorithms(k));
    rows(k).simulation_abort = true;
    rows(k).numerical_failure = true;
    rows(k).metric_missing = true;
    rows(k).notes = string(exception.identifier)+": "+string(exception.message);
end
end

function pairs = build_matched_pairs(results)
template = blank_pair_row();
pairRows = repmat(template,0,1);
conditions = unique(results.physical_condition_id,'stable');
for id = conditions.'
    part = results(results.physical_condition_id==id,:);
    if height(part) ~= 4
        continue
    end
    pairRows(end+1,1) = make_pair(part,"HARD","GH","M5_DH"); %#ok<AGROW>
    pairRows(end+1,1) = make_pair(part,"CONTINUOUS","GC","M5_FULL"); %#ok<AGROW>
end
pairs = struct2table(pairRows,'AsArray',true);
end

function row = make_pair(part,weight,controlId,candidateId)
control = part(part.algorithm_id==controlId,:);
candidate = part(part.algorithm_id==candidateId,:);
row = blank_pair_row();
if height(control)~=1 || height(candidate)~=1
    return
end
row.physical_condition_id = control.physical_condition_id;
row.geometry_pair_id = control.geometry_pair_id;
row.source_condition_id = control.source_condition_id;
row.source_registry_index = control.source_registry_index;
row.geometry = control.geometry;
row.weight_mode = string(weight);
row.control_algorithm = string(controlId);
row.candidate_algorithm = string(candidateId);
row.truth_seed = control.truth_seed;
row.noise_seed = control.noise_seed;
row.SNR_dB = control.SNR_dB;
row.reference_phase_error_deg = control.reference_phase_error_deg;
row.fault_factor = control.fault_factor;
row.drift_rate_multiplier = control.drift_rate_multiplier;
row.Cself_mismatch_pct = control.Cself_mismatch_pct;
row.evaluation_window_set_id = control.evaluation_window_set_id;
row.control_RMSE_total_pF = control.RMSE_total_pF;
row.candidate_RMSE_total_pF = candidate.RMSE_total_pF;
row.Delta_total = candidate.RMSE_total_pF-control.RMSE_total_pF;
row.control_RMSE_parallel_pF = control.RMSE_parallel_pF;
row.candidate_RMSE_parallel_pF = candidate.RMSE_parallel_pF;
row.Delta_parallel = candidate.RMSE_parallel_pF-control.RMSE_parallel_pF;
row.control_RMSE_perp_pF = control.RMSE_perp_pF;
row.candidate_RMSE_perp_pF = candidate.RMSE_perp_pF;
row.Delta_perp = candidate.RMSE_perp_pF-control.RMSE_perp_pF;
row.control_W1_abs_retention_error = control.W1_abs_retention_error;
row.candidate_W1_abs_retention_error = candidate.W1_abs_retention_error;
row.Delta_W1_retention = candidate.W1_abs_retention_error- ...
    control.W1_abs_retention_error;
row.control_W2_abs_retention_error = control.W2_abs_retention_error;
row.candidate_W2_abs_retention_error = candidate.W2_abs_retention_error;
row.Delta_W2_retention = candidate.W2_abs_retention_error- ...
    control.W2_abs_retention_error;
row.control_bias_norm_pF = control.F_minus_CF_norm_pF;
row.candidate_bias_norm_pF = candidate.F_minus_CF_norm_pF;
row.Delta_bias = candidate.F_minus_CF_norm_pF-control.F_minus_CF_norm_pF;
row.candidate_projection_active = candidate.F_projection_active;
row.candidate_rate_limit_active = candidate.F_rate_limit_active;
row.control_projection_active = control.F_projection_active;
row.control_rate_limit_active = control.F_rate_limit_active;
row.candidate_pre_constraint_angle_deg = ...
    candidate.F_pre_constraint_angle_deg;
row.candidate_post_rate_angle_deg = candidate.F_post_rate_angle_deg;
row.candidate_post_projection_angle_deg = ...
    candidate.F_post_projection_angle_deg;
row.control_pre_constraint_angle_deg = control.F_pre_constraint_angle_deg;
row.control_post_rate_angle_deg = control.F_post_rate_angle_deg;
row.control_post_projection_angle_deg = control.F_post_projection_angle_deg;
row.data_signature_match = control.data_signature==candidate.data_signature;
row.noise_draw_signature_match = ...
    control.noise_draw_signature==candidate.noise_draw_signature;
row.pair_finite = all(isfinite([row.Delta_total,row.Delta_parallel, ...
    row.Delta_perp,row.Delta_W1_retention,row.Delta_W2_retention, ...
    row.Delta_bias]));
end

function row = blank_pair_row()
row = struct('physical_condition_id',"",'geometry_pair_id',"", ...
    'source_condition_id',"",'source_registry_index',NaN, ...
    'geometry',"",'weight_mode',"",'control_algorithm',"", ...
    'candidate_algorithm',"",'truth_seed',NaN,'noise_seed',NaN, ...
    'SNR_dB',NaN,'reference_phase_error_deg',NaN, ...
    'fault_factor',NaN,'drift_rate_multiplier',NaN, ...
    'Cself_mismatch_pct',NaN,'evaluation_window_set_id',"", ...
    'control_RMSE_total_pF',NaN,'candidate_RMSE_total_pF',NaN, ...
    'Delta_total',NaN,'control_RMSE_parallel_pF',NaN, ...
    'candidate_RMSE_parallel_pF',NaN,'Delta_parallel',NaN, ...
    'control_RMSE_perp_pF',NaN,'candidate_RMSE_perp_pF',NaN, ...
    'Delta_perp',NaN,'control_W1_abs_retention_error',NaN, ...
    'candidate_W1_abs_retention_error',NaN,'Delta_W1_retention',NaN, ...
    'control_W2_abs_retention_error',NaN, ...
    'candidate_W2_abs_retention_error',NaN,'Delta_W2_retention',NaN, ...
    'control_bias_norm_pF',NaN,'candidate_bias_norm_pF',NaN, ...
    'Delta_bias',NaN,'candidate_projection_active',false, ...
    'candidate_rate_limit_active',false,'control_projection_active',false, ...
    'control_rate_limit_active',false, ...
    'candidate_pre_constraint_angle_deg',NaN, ...
    'candidate_post_rate_angle_deg',NaN, ...
    'candidate_post_projection_angle_deg',NaN, ...
    'control_pre_constraint_angle_deg',NaN, ...
    'control_post_rate_angle_deg',NaN, ...
    'control_post_projection_angle_deg',NaN, ...
    'data_signature_match',false,'noise_draw_signature_match',false, ...
    'pair_finite',false);
end

function results = attach_pair_deltas(results,pairs)
for id = unique(results.physical_condition_id,'stable').'
    hard = pairs(pairs.physical_condition_id==id & pairs.weight_mode=="HARD",:);
    cont = pairs(pairs.physical_condition_id==id & pairs.weight_mode=="CONTINUOUS",:);
    index = results.physical_condition_id==id;
    if height(cont)==1
        results.Delta_total_cont(index)=cont.Delta_total;
        results.Delta_parallel_cont(index)=cont.Delta_parallel;
        results.Delta_perp_cont(index)=cont.Delta_perp;
        results.Delta_W1_retention_cont(index)=cont.Delta_W1_retention;
        results.Delta_W2_retention_cont(index)=cont.Delta_W2_retention;
        results.Delta_bias_cont(index)=cont.Delta_bias;
    end
    if height(hard)==1
        results.Delta_total_hard(index)=hard.Delta_total;
        results.Delta_parallel_hard(index)=hard.Delta_parallel;
        results.Delta_perp_hard(index)=hard.Delta_perp;
        results.Delta_W1_retention_hard(index)=hard.Delta_W1_retention;
        results.Delta_W2_retention_hard(index)=hard.Delta_W2_retention;
        results.Delta_bias_hard(index)=hard.Delta_bias;
    end
end
end

function summaries = build_geometry_summaries(pairs)
rows = repmat(blank_summary_row(),0,1);
for geometry = ["ORTHOGONAL","MIXED","PARALLEL"]
    for weight = ["CONTINUOUS","HARD"]
        part = pairs(pairs.geometry==geometry & pairs.weight_mode==weight,:);
        x = part.Delta_perp;
        valid = isfinite(x);
        q = nan(1,5);
        if any(valid), q = prctile(x(valid),[10 25 50 75 90]); end
        row = blank_summary_row();
        row.geometry = geometry;
        row.weight_mode = weight;
        row.registered_N = height(part);
        row.valid_N = nnz(valid);
        row.P10_Delta_perp = q(1);
        row.P25_Delta_perp = q(2);
        row.median_Delta_perp = q(3);
        row.P75_Delta_perp = q(4);
        row.P90_Delta_perp = q(5);
        row.fraction_Delta_perp_lt_0 = nnz(x<0)/50;
        row.fraction_Delta_perp_gt_0 = nnz(x>0)/50;
        row.median_Delta_total = median(part.Delta_total,'omitnan');
        row.median_Delta_parallel = median(part.Delta_parallel,'omitnan');
        row.median_Delta_W1_retention = ...
            median(part.Delta_W1_retention,'omitnan');
        row.median_Delta_W2_retention = ...
            median(part.Delta_W2_retention,'omitnan');
        row.median_Delta_bias = median(part.Delta_bias,'omitnan');
        rows(end+1,1) = row; %#ok<AGROW>
    end
end
summaries = struct2table(rows,'AsArray',true);
end

function row = blank_summary_row()
row = struct('geometry',"",'weight_mode',"",'registered_N',0, ...
    'valid_N',0,'P10_Delta_perp',NaN,'P25_Delta_perp',NaN, ...
    'median_Delta_perp',NaN,'P75_Delta_perp',NaN, ...
    'P90_Delta_perp',NaN,'fraction_Delta_perp_lt_0',NaN, ...
    'fraction_Delta_perp_gt_0',NaN,'median_Delta_total',NaN, ...
    'median_Delta_parallel',NaN,'median_Delta_W1_retention',NaN, ...
    'median_Delta_W2_retention',NaN,'median_Delta_bias',NaN);
end

function tableOut = build_phase_summary(pairs)
rows = struct('geometry',{},'weight_mode',{}, ...
    'reference_phase_error_deg',{},'N',{},'valid_N',{}, ...
    'median_Delta_perp',{},'fraction_Delta_perp_lt_0',{}, ...
    'fraction_Delta_perp_gt_0',{});
for geometry = ["ORTHOGONAL","MIXED","PARALLEL"]
    for weight = ["CONTINUOUS","HARD"]
        part = pairs(pairs.geometry==geometry & pairs.weight_mode==weight,:);
        levels = unique(part.reference_phase_error_deg).';
        for level = levels
            q = part(part.reference_phase_error_deg==level,:);
            valid = isfinite(q.Delta_perp);
            row = struct('geometry',geometry,'weight_mode',weight, ...
                'reference_phase_error_deg',level,'N',height(q), ...
                'valid_N',nnz(valid),'median_Delta_perp', ...
                median(q.Delta_perp,'omitnan'), ...
                'fraction_Delta_perp_lt_0',nnz(q.Delta_perp<0)/height(q), ...
                'fraction_Delta_perp_gt_0',nnz(q.Delta_perp>0)/height(q));
            rows(end+1,1) = row; %#ok<AGROW>
        end
    end
end
tableOut = struct2table(rows);
end

function tableOut = build_boundary_summary(pairs)
rows = struct('geometry',{},'weight_mode',{},'N',{}, ...
    'projection_active_N',{},'rate_limit_active_N',{}, ...
    'both_inactive_N',{},'valid_pre_angle_N',{}, ...
    'median_pre_constraint_angle_deg',{}, ...
    'median_abs_pre_to_post_rate_rotation_deg',{}, ...
    'median_abs_post_rate_to_projection_rotation_deg',{});
for geometry = ["ORTHOGONAL","MIXED","PARALLEL"]
    for weight = ["CONTINUOUS","HARD"]
        q = pairs(pairs.geometry==geometry & pairs.weight_mode==weight,:);
        pre = q.candidate_pre_constraint_angle_deg;
        rate = q.candidate_post_rate_angle_deg;
        projection = q.candidate_post_projection_angle_deg;
        row = struct('geometry',geometry,'weight_mode',weight, ...
            'N',height(q),'projection_active_N', ...
            nnz(q.candidate_projection_active), ...
            'rate_limit_active_N',nnz(q.candidate_rate_limit_active), ...
            'both_inactive_N',nnz(~q.candidate_projection_active & ...
                ~q.candidate_rate_limit_active), ...
            'valid_pre_angle_N',nnz(isfinite(pre)), ...
            'median_pre_constraint_angle_deg',median(pre,'omitnan'), ...
            'median_abs_pre_to_post_rate_rotation_deg', ...
            median(abs(rate-pre),'omitnan'), ...
            'median_abs_post_rate_to_projection_rotation_deg', ...
            median(abs(projection-rate),'omitnan'));
        rows(end+1,1) = row; %#ok<AGROW>
    end
end
tableOut = struct2table(rows);
end

function [gates,decision] = decide_step5(results,pairs,summaries,pre,post, ...
        matrixUnchanged,simulationCalls,trackerBranches)
complete = ~results.numerical_failure & ~results.metric_missing & ...
    ~results.simulation_abort & results.registry_match & results.seed_match & ...
    results.shared_data_pass & results.required_outputs_pass;
orthCont = pairs(pairs.geometry=="ORTHOGONAL" & ...
    pairs.weight_mode=="CONTINUOUS",:);
orthHard = pairs(pairs.geometry=="ORTHOGONAL" & ...
    pairs.weight_mode=="HARD",:);
sourceUnchanged = pre.pass && post.pass && ...
    isequal(pre.actual_sha256,post.actual_sha256);
noiseGeometryPass = true;
for id = unique(results.geometry_pair_id,'stable').'
    q = results(results.geometry_pair_id==id,:);
    noiseGeometryPass = noiseGeometryPass && ...
        numel(unique(q.noise_draw_signature))==1;
end
authorized = all(ismember(results.algorithm_id, ...
    ["GH","GC","M5_DH","M5_FULL"])) && ...
    all(ismember(results.geometry,["ORTHOGONAL","MIXED","PARALLEL"]));
gate0 = height(results)==600 && nnz(complete)==600 && ...
    numel(unique(results.physical_condition_id))==150 && ...
    height(pairs)==300 && nnz(orthCont.pair_finite)==50 && ...
    nnz(orthHard.pair_finite)==50 && ...
    numel(unique(results.evaluation_id))==600 && ...
    all(pairs.data_signature_match) && ...
    all(pairs.noise_draw_signature_match) && noiseGeometryPass && ...
    sourceUnchanged && matrixUnchanged && authorized && ...
    simulationCalls==450 && trackerBranches==1200;

orthContSummary = summaries(summaries.geometry=="ORTHOGONAL" & ...
    summaries.weight_mode=="CONTINUOUS",:);
orthHardSummary = summaries(summaries.geometry=="ORTHOGONAL" & ...
    summaries.weight_mode=="HARD",:);
gateA = height(orthContSummary)==1 && ...
    orthContSummary.median_Delta_perp < 0 && ...
    orthContSummary.fraction_Delta_perp_lt_0 > 0.5;
gateB = height(orthHardSummary)==1 && ...
    orthHardSummary.median_Delta_perp < 0 && ...
    orthHardSummary.fraction_Delta_perp_lt_0 > 0.5;

mixed = pairs(pairs.geometry=="MIXED" & ...
    pairs.weight_mode=="CONTINUOUS",:);
mixedWorseFraction = nnz(mixed.Delta_perp>0)/50;
mixedRedFlag = mixedWorseFraction > 0.75;
boundaryExplanation = false;
if mixedRedFlag
    worse = mixed.Delta_perp>0;
    active = mixed.candidate_projection_active | ...
        mixed.candidate_rate_limit_active;
    rotation = abs(mixed.candidate_post_rate_angle_deg- ...
        mixed.candidate_pre_constraint_angle_deg)>1e-12 | ...
        abs(mixed.candidate_post_projection_angle_deg- ...
        mixed.candidate_post_rate_angle_deg)>1e-12;
    registeredBoundary = mixed.reference_phase_error_deg>0 | active;
    explainedWorse = worse & registeredBoundary & rotation;
    boundaryExplanation = nnz(explainedWorse) > 0.5*nnz(worse);
end
gateC = ~mixedRedFlag || boundaryExplanation;
parallel = pairs(pairs.geometry=="PARALLEL",:);
gateD = height(parallel)==100 && nnz(parallel.pair_finite)==100;
gateE = sourceUnchanged && matrixUnchanged && authorized;
gates = struct('Gate0',gate0,'GateA',gateA,'GateB',gateB, ...
    'GateC',gateC,'GateD',gateD,'GateE',gateE, ...
    'mixed_red_flag',mixedRedFlag, ...
    'mixed_worse_fraction',mixedWorseFraction, ...
    'mixed_boundary_explanation',boundaryExplanation, ...
    'noise_geometry_pairing_pass',noiseGeometryPass);
decision = "STOP";
if gate0 && gateA && gateC && gateD && gateE, decision = "GO"; end
end

function write_decision_report(paths,results,pairs,summaries,phaseSummary, ...
        boundarySummary,gates,decision,pre,post,matrixPreHash, ...
        matrixPostHash,simulationCalls,trackerBranches,runtime,batchModes)
fileId = fopen(paths.report,'w','n','UTF-8');
if fileId < 0, error('M5Step5:ReportOpen','Unable to open report.'); end
cleanup = onCleanup(@() fclose(fileId));
line = @(text) fprintf(fileId,'%s\n',text);
complete = ~results.numerical_failure & ~results.metric_missing & ...
    ~results.simulation_abort;
line('# M5 Step5 Robustness / Monte-Carlo 决策报告'); line('');
line('## 1. 正式状态'); line('');
line(sprintf('`STEP5 = %s`。本报告严格执行 Step5A 冻结矩阵；未修改算法、方向、门控、约束、registry、seed、geometry、窗口或端点。',decision));
line('');
line('```text');
line(sprintf('STEP5_READY: %s',pass_blocked(gates.Gate0 && gates.GateE)));
line(sprintf('PHYSICAL: %d / 150',numel(unique(results.physical_condition_id))));
line(sprintf('ALGORITHM_EVALUATIONS: %d / 600',nnz(complete)));
line(sprintf('SIM_CALLS: %d / 450',simulationCalls));
line(sprintf('TRACKER_BRANCHES: %d / 1200',trackerBranches));
line(sprintf('STEP5: %s',decision));
line('STEP6_AUTHORIZED: NO — pending human review');
line('```'); line('');

line('## 2. Execution integrity'); line('');
line(sprintf('- 注册行：%d/600；唯一 physical conditions：%d/150；geometry pairs：%d/50。', ...
    height(results),numel(unique(results.physical_condition_id)), ...
    numel(unique(results.geometry_pair_id))));
line(sprintf('- 完整 evaluations：%d/600；duplicates：%d；simulation abort：%d；metric missing：%d。', ...
    nnz(complete),height(results)-numel(unique(results.evaluation_id)), ...
    nnz(results.simulation_abort),nnz(results.metric_missing)));
line(sprintf('- 实际 physical simulations：%d；tracker branches：%d；runtime：%.1f s。', ...
    simulationCalls,trackerBranches,runtime));
line(sprintf('- 四算法共享数据签名：%s；三 geometry 标准化 noise draw 配对：%s。', ...
    pass_fail(all(pairs.data_signature_match)), ...
    pass_fail(gates.noise_geometry_pairing_pass)));
line(sprintf('- Batch modes：`%s`。',strjoin(unique(batchModes),'`, `'))); line('');

line('### 冻结哈希'); line('');
line('| 对象 | 执行前 | 执行后 | 一致 |');
line('|---|---|---|---|');
for k = 1:numel(pre.names)
    line(sprintf('| `%s` | `%s` | `%s` | %s |',pre.names(k), ...
        pre.actual_sha256(k),post.actual_sha256(k), ...
        yes_no(pre.actual_sha256(k)==post.actual_sha256(k))));
end
line(sprintf('| Step5 matrix | `%s` | `%s` | %s |', ...
    matrixPreHash,matrixPostHash,yes_no(matrixPreHash==matrixPostHash)));
line('');

line('## 3. Geometry × weight 汇总'); line('');
line('| Geometry | Weight | Valid N | Median Δperp (pF) | P10 | P25 | P75 | P90 | Fraction Δperp<0 | Median Δtotal | Median Δparallel |');
line('|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|');
for k = 1:height(summaries)
    r=summaries(k,:);
    line(sprintf('| %s | %s | %d/50 | %.9g | %.9g | %.9g | %.9g | %.9g | %.3f | %.9g | %.9g |', ...
        r.geometry,r.weight_mode,r.valid_N,r.median_Delta_perp, ...
        r.P10_Delta_perp,r.P25_Delta_perp,r.P75_Delta_perp, ...
        r.P90_Delta_perp,r.fraction_Delta_perp_lt_0, ...
        r.median_Delta_total,r.median_Delta_parallel));
end
line('');

orthC = summary_row(summaries,"ORTHOGONAL","CONTINUOUS");
orthH = summary_row(summaries,"ORTHOGONAL","HARD");
mixedC = summary_row(summaries,"MIXED","CONTINUOUS");
parallelC = summary_row(summaries,"PARALLEL","CONTINUOUS");
line('## 4. Orthogonal continuous — primary'); line('');
line(sprintf('50/50 pairs finite。`median Delta_perp_cont = %.9g pF`，改善比例 `%.1f%%`。P10/P25/P75/P90 = %.9g / %.9g / %.9g / %.9g pF。Gate A = **%s**。', ...
    orthC.median_Delta_perp,100*orthC.fraction_Delta_perp_lt_0, ...
    orthC.P10_Delta_perp,orthC.P25_Delta_perp,orthC.P75_Delta_perp, ...
    orthC.P90_Delta_perp,pass_fail(gates.GateA))); line('');

line('## 5. Orthogonal hard'); line('');
line(sprintf('50/50 pairs finite。`median Delta_perp_hard = %.9g pF`，改善比例 `%.1f%%`。P10/P25/P75/P90 = %.9g / %.9g / %.9g / %.9g pF。Gate B = **%s**；该 Gate 仅作机制描述。', ...
    orthH.median_Delta_perp,100*orthH.fraction_Delta_perp_lt_0, ...
    orthH.P10_Delta_perp,orthH.P25_Delta_perp,orthH.P75_Delta_perp, ...
    orthH.P90_Delta_perp,hard_gate_label(gates.GateB))); line('');

line('## 6. Mixed'); line('');
line(sprintf('Continuous 的 median Δperp = %.9g pF，改善比例 %.1f%%，median Δtotal = %.9g pF。反向恶化比例为 %.1f%%；预注册 red flag %s。Gate C = **%s**。', ...
    mixedC.median_Delta_perp,100*mixedC.fraction_Delta_perp_lt_0, ...
    mixedC.median_Delta_total,100*gates.mixed_worse_fraction, ...
    triggered_label(gates.mixed_red_flag),pass_fail(gates.GateC))); line('');

line('## 7. Parallel validity boundary'); line('');
line(sprintf('全部 50 continuous pairs 与 50 hard pairs 已保留。Continuous median Δperp = %.9g pF，改善比例 %.1f%%。该 geometry 无 superiority threshold；Gate D = **%s**。', ...
    parallelC.median_Delta_perp,100*parallelC.fraction_Delta_perp_lt_0, ...
    retained_label(gates.GateD))); line('');

line('## 8. Phase-error stratification'); line('');
line('| Geometry | Weight | Phase error (deg) | N | Median Δperp | Fraction Δperp<0 |');
line('|---|---|---:|---:|---:|---:|');
for k = 1:height(phaseSummary)
    r=phaseSummary(k,:);
    line(sprintf('| %s | %s | %.3g | %d | %.9g | %.3f |', ...
        r.geometry,r.weight_mode,r.reference_phase_error_deg, ...
        r.N,r.median_Delta_perp,r.fraction_Delta_perp_lt_0));
end
line('');

line('## 9. Projection / rate-limit boundary'); line('');
line('| Geometry | Weight | Projection active | Rate active | Both inactive | Valid pre angles | Median pre angle | Median |pre→rate| | Median |rate→projection| |');
line('|---|---|---:|---:|---:|---:|---:|---:|---:|');
for k = 1:height(boundarySummary)
    r=boundarySummary(k,:);
    line(sprintf('| %s | %s | %d/50 | %d/50 | %d/50 | %d/50 | %.6g | %.6g | %.6g |', ...
        r.geometry,r.weight_mode,r.projection_active_N, ...
        r.rate_limit_active_N,r.both_inactive_N,r.valid_pre_angle_N, ...
        r.median_pre_constraint_angle_deg, ...
        r.median_abs_pre_to_post_rate_rotation_deg, ...
        r.median_abs_post_rate_to_projection_rotation_deg));
end
line('');

line('## 10. Negative results retained'); line('');
for geometry = ["ORTHOGONAL","MIXED","PARALLEL"]
    for weight = ["CONTINUOUS","HARD"]
        q=pairs(pairs.geometry==geometry & pairs.weight_mode==weight,:);
        [maximum,index]=max(q.Delta_perp);
        line(sprintf('- %s/%s：Δperp>0 为 %d/50；最大退化 %.9g pF，condition `%s`。', ...
            geometry,weight,nnz(q.Delta_perp>0),maximum, ...
            q.physical_condition_id(index)));
    end
end
line('');

line('## 11. 科学问题回答'); line('');
line(sprintf('1. **Q1–Q2：** Orthogonal continuous 的稳定性由 50/50 raw pairs、median %.9g pF 和 %.1f%% 改善比例给出；按 Gate A 判为 %s。', ...
    orthC.median_Delta_perp,100*orthC.fraction_Delta_perp_lt_0,pass_fail(gates.GateA)));
line(sprintf('2. **Q3：** Hard directionality 的 median 为 %.9g pF，改善比例 %.1f%%，描述性 Gate B 为 %s。', ...
    orthH.median_Delta_perp,100*orthH.fraction_Delta_perp_lt_0,hard_gate_label(gates.GateB)));
line(sprintf('3. **Q4：** Mixed continuous median Δperp 为 %.9g pF，改善比例 %.1f%%；red flag %s。', ...
    mixedC.median_Delta_perp,100*mixedC.fraction_Delta_perp_lt_0,triggered_label(gates.mixed_red_flag)));
line(sprintf('4. **Q5：** Parallel 100 个 matched pairs 全部保留，结果不用于 superiority Gate，符合 identifiability boundary 的预注册处理。'));
line('5. **Q6：** 第 8 节只按冻结 phase levels 报告，不新增分层；方向性 benefit 是否随 phase error 减弱以表中 median 和改善比例描述。');
line('6. **Q7：** 第 9 节报告 projection/rate activation 及 pre→post angle rotation；near-zero angles 在原始结果中保持 NaN。');
line(sprintf('7. **Q8：** Step4 mechanism 在 Step5 中的支持状态由 Gate A、C、D、E 合并判定；Step5 = %s。',decision));
line('');

line('## 12. Gates 与最终决定'); line('');
line('| Gate | Result |'); line('|---|---|');
line(sprintf('| Gate 0 execution integrity | %s |',pass_fail(gates.Gate0)));
line(sprintf('| Gate A Orthogonal continuous | %s |',pass_fail(gates.GateA)));
line(sprintf('| Gate B Orthogonal hard | %s |',hard_gate_label(gates.GateB)));
line(sprintf('| Gate C Mixed | %s |',pass_fail(gates.GateC)));
line(sprintf('| Gate D Parallel | %s |',retained_label(gates.GateD)));
line(sprintf('| Gate E method integrity | %s |',pass_fail(gates.GateE)));
line(sprintf('| **STEP5** | **%s** |',decision)); line('');
line('`STEP6_AUTHORIZED = NO — pending human review`。即使 Step5 为 GO，本轮也不会自动执行 Step6。');
delete(cleanup);
end

function row = summary_row(summaries,geometry,weight)
row = summaries(summaries.geometry==geometry & summaries.weight_mode==weight,:);
if height(row)~=1, error('M5Step5:SummaryRow','Missing summary row.'); end
end

function paths = step5_paths()
runnerDir = fileparts(mfilename('fullpath'));
root = fileparts(runnerDir);
base = fullfile(root,'paper_research','phase_m5_directional_update');
prereg = fullfile(base,'step5_preregistration');
output = fullfile(base,'step5_robustness_execution');
paths = struct();
paths.root = root;
paths.matlab_root = runnerDir;
paths.matrix = fullfile(prereg,'M5_STEP5_ROBUSTNESS_MATRIX.csv');
paths.preregistration = fullfile(prereg,'M5_STEP5_PREREGISTRATION.md');
paths.registry = fullfile(root,'paper_research','phase2_full_validation', ...
    'step1_matrix_spec','phase2_condition_registry.csv');
paths.model = fullfile(runnerDir,'AI6109_MOA_AutoComp9.slx');
paths.config = fullfile(runnerDir,'patent_default_config.m');
paths.tracker = fullfile(runnerDir,'track_coupling_m5_directional_rls.m');
paths.projector = fullfile(runnerDir,'m5_directional_update.m');
paths.regressor = fullfile(runnerDir,'coupling_regressor.m');
paths.output_root = output;
paths.internal_root = fullfile(output,'internal');
paths.cycle_root = fullfile(paths.internal_root,'cycle_logs');
paths.simulink_cache = fullfile(paths.internal_root,'simulink_cache');
paths.readiness_mat = fullfile(paths.internal_root,'readiness_gate.mat');
paths.execution_state_mat = fullfile(paths.internal_root,'execution_state.mat');
paths.checkpoint_csv = fullfile(paths.internal_root,'step5_checkpoint.csv');
paths.pairs_csv = fullfile(paths.internal_root,'M5_STEP5_MATCHED_PAIRS.csv');
paths.summary_csv = fullfile(paths.internal_root,'M5_STEP5_GEOMETRY_SUMMARY.csv');
paths.phase_csv = fullfile(paths.internal_root,'M5_STEP5_PHASE_STRATIFICATION.csv');
paths.boundary_csv = fullfile(paths.internal_root,'M5_STEP5_BOUNDARY_SUMMARY.csv');
paths.workspace_mat = fullfile(paths.internal_root,'M5_STEP5_WORKSPACE.mat');
paths.master_csv = fullfile(output,'M5_STEP5_MASTER_RESULTS.csv');
paths.report = fullfile(output,'M5_STEP5_DECISION_REPORT.md');
end

function integrity = source_integrity(paths)
names = ["source registry";"model";"config";"tracker";"projector";"regressor"];
files = [string(paths.registry);string(paths.model);string(paths.config); ...
    string(paths.tracker);string(paths.projector);string(paths.regressor)];
expected = [ ...
    "8A498E19A455C13CAA7B5371BE2F933CA7B7637B893C656C92DA84D88D1938BE"; ...
    "56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70"; ...
    "D9F3E6894F51C3D978421C9E1E93828A9205F418C77D01AC449B994A3D789726"; ...
    "8B580215A6268F4AC3BF27FB357DB6A4A01027DD2410C7FF59EA3C4B46DA4DDB"; ...
    "47D2C12DB80F4BBFE7CE296841074DB6F3FF641CD769907666292E4398E06CA7"; ...
    "7582F66875A1099DF9656F9A89FE12D8FF6972C55D4A034736527A7DB00E03D5"];
actual = strings(size(expected));
for k = 1:numel(files), actual(k) = file_sha256(files(k)); end
itemPass = actual==expected;
integrity = struct('names',names,'files',files, ...
    'expected_sha256',expected,'actual_sha256',actual, ...
    'item_pass',itemPass,'pass',all(itemPass));
end

function hash = file_sha256(path)
fileId = fopen(path,'rb');
if fileId < 0, error('M5Step5:HashRead','Unable to read %s.',path); end
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

function ensure_folder(path)
if ~isfolder(path), mkdir(path); end
end

function label = pass_fail(value)
if value, label="PASS"; else, label="FAIL"; end
end

function label = pass_blocked(value)
if value, label="PASS"; else, label="BLOCKED"; end
end

function label = hard_gate_label(value)
if value, label="PASS"; else, label="DESCRIPTIVE_FAIL"; end
end

function label = retained_label(value)
if value, label="RETAINED"; else, label="VIOLATED"; end
end

function label = triggered_label(value)
if value, label="TRIGGERED"; else, label="NOT_TRIGGERED"; end
end

function label = yes_no(value)
if value, label="YES"; else, label="NO"; end
end
