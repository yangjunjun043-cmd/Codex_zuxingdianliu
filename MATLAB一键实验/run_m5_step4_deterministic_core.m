function output = run_m5_step4_deterministic_core(action)
%RUN_M5_STEP4_DETERMINISTIC_CORE M5 Step 4 preregistered core runner.
%   readiness  - generate and audit only physical data (34 sim calls).
%   execute    - require readiness PASS, then evaluate the 98 matrix rows.
%   all        - readiness followed by execute; never starts Monte Carlo.

if nargin < 1 || isempty(action), action = "readiness"; end
action = lower(string(action));
paths = step4_paths();
addpath(paths.matlab_root);
if ~isfolder(paths.output_root), mkdir(paths.output_root); end
if ~isfolder(paths.cache_root), mkdir(paths.cache_root); end
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
        error('M5Step4:Action','Unsupported action: %s.',action);
end
end

function output = run_readiness(paths)
matrixAudit = m5_step4_validate_matrix(paths.matrix);
pre = source_integrity(paths);
unit = runtests(paths.test_file,'Strict',true);
u1 = matrixAudit.pass && all([unit.Passed]) && pre.pass;
u2 = all([unit.Passed]);
u5 = false;
u3 = true;
u4 = true;
simCalls = 0;
cases = unique(matrixAudit.matrix.case_id,'stable');
caseRows = matrixAudit.matrix(~duplicated_case(matrixAudit.matrix.case_id),:);
cacheIndex = strings(numel(cases),1);
messages = strings(numel(cases),1);

normal = load(paths.normal_workspace,'caseDetails');
baseline = load(paths.baseline_workspace,'caseData','cfg');
for k = 1:height(caseRows)
    row = caseRows(k,:);
    try
        cachePath = fullfile(paths.cache_root,char(row.case_id)+".mat");
        if isfile(cachePath)
            previous = load(cachePath,'cache','audit');
            cache = previous.cache;
            audit = previous.audit;
        elseif row.block == "A"
            [cache,audit] = readiness_a(paths,row,baseline,normal);
        elseif row.block == "B"
            [cache,audit] = readiness_b(paths,row,baseline);
        else
            [cache,audit] = readiness_c(paths,row);
        end
        simCalls = simCalls+audit.sim_calls;
        u3 = u3 && audit.u3_pass;
        u4 = u4 && audit.u4_pass;
        save(cachePath,'cache','audit','-v7.3');
        cacheIndex(k) = string(cachePath);
        messages(k) = audit.message;
        fprintf('M5 STEP4 READINESS %02d/14 %s PASS (%d sims)\n', ...
            k,row.case_id,audit.sim_calls);
    catch exception
        if row.block == "C"
            u4 = false;
        else
            u3 = false;
        end
        messages(k) = string(exception.identifier)+": "+exception.message;
        fprintf(2,'M5 STEP4 READINESS %s FAIL: %s\n', ...
            row.case_id,exception.message);
    end
end

% Exercise all registered frozen cycle schemas without reading performance.
try
    cfg = patent_default_config();
    for name = ["Case01_static","Case02_slow_drift"]
        detail = normal.caseDetails.(char(name));
        for mode = ["M2","M3","M4"]
            m5_step4_cycle_diagnostics(mode,detail.(char(mode)+"_cycle"), ...
                0.8,4.0+cfg.Ts,cfg);
        end
    end
    u5 = true;
catch exception
    messages(end) = messages(end)+"; U5="+string(exception.message);
end

post = source_integrity(paths);
sourceUnchanged = pre.pass && post.pass && ...
    isequal(pre.actual_sha256,post.actual_sha256);
u1 = u1 && sourceUnchanged;
pass = u1 && u2 && u3 && u4 && u5 && simCalls == 34 && ...
    all(strlength(cacheIndex) > 0);
readiness = struct('pass',pass,'U1',u1,'U2',u2,'U3',u3,'U4',u4, ...
    'U5',u5,'sim_calls',simCalls,'cache_index',cacheIndex, ...
    'messages',messages,'source_pre',pre,'source_post',post, ...
    'matrix_audit',matrixAudit);
save(paths.readiness_mat,'readiness','-v7.3');

output = struct('status',pass_fail(pass),'pass',pass, ...
    'U1',u1,'U2',u2,'U3',u3,'U4',u4,'U5',u5, ...
    'sim_calls',simCalls,'performance_viewed',false, ...
    'ready_for_execution',pass,'ready_for_step5',false);
fprintf('M5_STEP4_READINESS=%s\n',pass_fail(pass));
fprintf('U1=%s U2=%s U3=%s U4=%s U5=%s\n', ...
    pass_fail(u1),pass_fail(u2),pass_fail(u3), ...
    pass_fail(u4),pass_fail(u5));
fprintf('PHYSICAL_SIM_CALLS=%d/34\n',simCalls);
fprintf('M5_PERFORMANCE_VIEWED=NO\n');
fprintf('READY_FOR_STEP5=NO\n');
end

function [cache,audit] = readiness_a(paths,row,baseline,normal)
cfg = patent_default_config();
cfg.model = 'AI6109_MOA_AutoComp9';
cfg.StopTime = 4;
cfg.SNR_dB = row.snr_dB;
scenario = "static";
frozenName = "Case01_static";
if row.case_id == "M5_A2_DRIFT_ONLY"
    scenario = "slow_drift";
    frozenName = "Case02_slow_drift";
end
[data,referenceReplay] = simulate_phase2_case(cfg,char(scenario),row.seed);
ref = reconstruct_refs_from_b(data.t,data.ub,cfg.f, ...
    cfg.init_start,cfg.init_end,cfg.phase_error_deg);
signals = generate_coupling_signals(data.t,char(scenario),row.seed);
frozen = baseline.caseData.(char(frozenName));
truthPass = exact_vector(data.t,frozen.t,0) && ...
    exact_vector(data.Cs1,frozen.Cs1_true,1e-12) && ...
    exact_vector(data.Cs2,frozen.Cs2_true,1e-12) && ...
    exact_vector(data.irA,frozen.irA_true,1e-12) && ...
    exact_vector(data.irB,frozen.irB_true,1e-12) && ...
    exact_vector(data.irC,frozen.irC_true,1e-12) && ...
    exact_vector(signals.fault_scale,frozen.fault_scale,0) && ...
    frozen.seed == row.seed;
detail = normal.caseDetails.(char(frozenName));
trajectoryPass = exact_vector(detail.t,data.t,0) && ...
    exact_vector(detail.Cs1_true,data.Cs1,1e-12) && ...
    exact_vector(detail.Cs2_true,data.Cs2,1e-12) && ...
    exact_vector(detail.irB_true,data.irB,1e-12);
signature = data_signature(data,signals,ref,referenceReplay);
cache = struct('row',row,'cfg',cfg,'dataF',data,'dataCF',struct(), ...
    'ref',ref,'signalsF',signals,'signalsCF',struct(), ...
    'data_signature',signature,'historical_name',frozenName);
pass = truthPass && trajectoryPass && all(isfinite([data.ia;data.ib;data.ic]));
audit = struct('sim_calls',2,'u3_pass',pass,'u4_pass',true, ...
    'message',"A frozen seed/truth/trajectory replay; signature="+signature);
if ~pass, error('M5Step4:AReplay','Frozen A replay mismatch.'); end
end

function [cache,audit] = readiness_b(paths,row,baseline)
if row.case_id ~= "M5_B_F160"
    run = run_phase2_deterministic_core("run_condition", ...
        row.source_condition_id);
    data = run.data; clean = run.clean_data; noise = run.noise;
    ref = run.reference; signals = run.signals; cfg = run.algorithm_assumption_config;
    signature = run.shared_execution_signature;
    frozenTable = readtable(paths.phase2_results,'TextType','string');
    expected = unique(frozenTable.data_signature( ...
        frozenTable.condition_id == row.source_condition_id));
    pass = isscalar(expected) && signature == expected && ...
        run.registry_mapping_pass && run.shared_data_pass && ...
        injected_noise_pass(data,clean,noise);
else
    cfg = patent_default_config(); cfg.model = 'AI6109_MOA_AutoComp9';
    cfg.StopTime = 4; cfg.SNR_dB = row.snr_dB;
    [data,referenceReplay] = simulate_phase2_case(cfg,'fault_only',row.seed);
    ref = reconstruct_refs_from_b(data.t,data.ub,cfg.f, ...
        cfg.init_start,cfg.init_end,cfg.phase_error_deg);
    signals = generate_coupling_signals(data.t,'fault_only',row.seed);
    frozen = baseline.caseData.Case05_fault_only;
    pass = frozen.seed == row.seed && ...
        exact_vector(data.t,frozen.t,0) && ...
        exact_vector(data.Cs1,frozen.Cs1_true,1e-12) && ...
        exact_vector(data.Cs2,frozen.Cs2_true,1e-12) && ...
        exact_vector(data.irB,frozen.irB_true,1e-12) && ...
        exact_vector(signals.fault_scale,frozen.fault_scale,1e-12);
    signature = data_signature(data,signals,ref,referenceReplay);
end
dataCF = remove_fault_component_local(data,signals.fault_scale);
cache = struct('row',row,'cfg',cfg,'dataF',data,'dataCF',dataCF, ...
    'ref',ref,'signalsF',signals,'signalsCF',signals, ...
    'data_signature',signature,'historical_name',row.source_condition_id);
audit = struct('sim_calls',2,'u3_pass',pass,'u4_pass',true, ...
    'message',"B frozen seed/truth/noise/data replay; signature="+signature);
if ~pass, error('M5Step4:BReplay','Frozen B replay mismatch.'); end
end

function [cache,audit] = readiness_c(paths,row)
mixed = startsWith(row.drift_geometry,"MIXED");
if row.fault_factor == 1.3
    workspace = paths.case07_workspace;
    expectedSignature = "C5EC0992BE0CDC0737380583256E4199AFF0C119E90902AC93D7BF8BBE6CB3C6";
else
    workspace = paths.case08_workspace;
    expectedSignature = "20BE4D99E0075CE916D7895B37272A0A04BFA7DF47320A5B0AD3D7655E3C83B0";
end
frozen = load(workspace,'caseDetail','cfg');
cfg = frozen.cfg; cfg.model = 'AI6109_MOA_AutoComp9'; cfg.StopTime = 4;
signalsF = controlled_overlap_signals(row,cfg,"F");
signalsCF = controlled_overlap_signals(row,cfg,"CF");
zero = zeros(size(signalsF.t));
cleanF = run_once_local(cfg,signalsF,zero,zero,zero);
if mixed
    noise = struct('A',frozen.caseDetail.shared_noise_A, ...
        'B',frozen.caseDetail.shared_noise_B, ...
        'C',frozen.caseDetail.shared_noise_C);
else
    rng(row.seed+10000);
    noise = struct('A',noise_for_snr(cleanF.ia,row.snr_dB), ...
        'B',noise_for_snr(cleanF.ib,row.snr_dB), ...
        'C',noise_for_snr(cleanF.ic,row.snr_dB));
end
dataF = run_once_local(cfg,signalsF,noise.A,noise.B,noise.C);
dataCF = run_once_local(cfg,signalsCF,noise.A,noise.B,noise.C);
[dataF,dataCF] = add_self_capacitance(dataF,dataCF,cfg.Cself_pF);
ref = reconstruct_refs_from_b(dataF.t,dataF.ub,cfg.f, ...
    cfg.init_start,cfg.init_end,cfg.phase_error_deg);
signature = pair_signature_local(dataF,dataCF,signalsF,noise,ref);
sharedPass = exact_vector(dataF.t,dataCF.t,0) && ...
    exact_vector(dataF.ia(signalsF.t<1.5),dataCF.ia(signalsF.t<1.5),0) && ...
    exact_vector(dataF.ib(signalsF.t<1.5),dataCF.ib(signalsF.t<1.5),0) && ...
    exact_vector(dataF.ic(signalsF.t<1.5),dataCF.ic(signalsF.t<1.5),0);
geometryPass = abs(dataF.Cs1(end)-row.Cs1_final_pF) < 1e-10 && ...
    abs(dataF.Cs2(end)-row.Cs2_final_pF) < 1e-10 && ...
    abs(hypot(row.drift_delta_Cs1_pF,row.drift_delta_Cs2_pF)-sqrt(13)) < 1e-12;
u4 = true;
if mixed
    u4 = signature == expectedSignature && ...
        exact_vector(dataF.irB,frozen.caseDetail.irB_true_F,1e-12) && ...
        exact_vector(dataCF.irB,frozen.caseDetail.irB_true_CF,1e-12);
end
pass = sharedPass && geometryPass && u4;
cache = struct('row',row,'cfg',cfg,'dataF',dataF,'dataCF',dataCF, ...
    'ref',ref,'signalsF',signalsF,'signalsCF',signalsCF, ...
    'data_signature',signature,'historical_name',string(workspace));
audit = struct('sim_calls',3,'u3_pass',sharedPass && geometryPass, ...
    'u4_pass',u4,'message',"C paired replay; signature="+signature);
if ~pass, error('M5Step4:CReplay','C paired replay/signature mismatch.'); end
end

function output = run_execution(paths)
if ~isfile(paths.readiness_mat)
    error('M5Step4:ReadinessMissing','Run readiness first.');
end
loaded = load(paths.readiness_mat,'readiness');
if ~loaded.readiness.pass
    error('M5Step4:ReadinessBlocked','U1-U5 readiness gate is not PASS.');
end
pre = source_integrity(paths);
if ~pre.pass, error('M5Step4:SourceIntegrity','PRE source hash mismatch.'); end
matrix = loaded.readiness.matrix_audit.matrix;
rows = repmat(blank_result_row(),height(matrix),1);
normal = load(paths.normal_workspace,'caseDetails');
case07 = load(paths.case07_workspace,'caseDetail');
case08 = load(paths.case08_workspace,'caseDetail');
phase2 = readtable(paths.phase2_results,'TextType','string');
phase1Fault = readtable(paths.phase1_fault_results,'TextType','string');

for k = 1:height(matrix)
    registration = matrix(k,:);
    cached = load(fullfile(paths.cache_root,char(registration.case_id)+".mat"),'cache');
    try
        rows(k) = evaluate_registered_row(registration,cached.cache, ...
            normal,case07,case08,phase2,phase1Fault);
        fprintf('M5 STEP4 EVAL %02d/98 %s/%s COMPLETE\n', ...
            k,registration.case_id,registration.algorithm);
    catch exception
        rows(k) = blank_result_row();
        rows(k).case_id = registration.case_id;
        rows(k).block = registration.block;
        rows(k).algorithm = registration.algorithm;
        rows(k).run_or_reuse = registration.run_or_reuse;
        rows(k).numerical_failure = true;
        rows(k).metric_missing = true;
        rows(k).notes = string(exception.identifier)+": "+exception.message;
        fprintf(2,'M5 STEP4 EVAL %s/%s FAIL: %s\n', ...
            registration.case_id,registration.algorithm,exception.message);
    end
end
results = struct2table(rows,'AsArray',true);
[results,gates,factorial] = finalize_decision(results);
post = source_integrity(paths);
sourceUnchanged = pre.pass && post.pass && ...
    isequal(pre.actual_sha256,post.actual_sha256);
results.source_integrity_pass(:) = sourceUnchanged;
complete = ~results.numerical_failure & ~results.metric_missing;
decisionPass = all(complete) && height(results) == 98 && ...
    sourceUnchanged && gates.overall_go;
status = "STOP";
if decisionPass, status = "GO"; end
writetable(results,paths.master_csv);
write_decision_report(paths,results,gates,factorial,pre,post,status);

output = struct('status',status,'rows_complete',nnz(complete), ...
    'rows_total',height(results),'gate_A',gates.A,'gate_B',gates.B, ...
    'gate_C',gates.C,'gate_D',gates.D,'source_unchanged',sourceUnchanged, ...
    'monte_carlo_executed',false,'ready_for_step5',false, ...
    'master_results',string(paths.master_csv), ...
    'decision_report',string(paths.report));
fprintf('M5_STEP4_STATUS=%s\n',status);
fprintf('ROWS=%d/98 COMPLETE\n',nnz(complete));
fprintf('GATE_A=%s GATE_B=%s GATE_C=%s GATE_D=%s\n', ...
    pass_fail(gates.A),pass_fail(gates.B),pass_fail(gates.C),pass_fail(gates.D));
fprintf('MONTE_CARLO_EXECUTED=NO\n');
fprintf('READY_FOR_STEP5=NO\n');
end

function row = evaluate_registered_row(reg,cache,normal,case07,case08,phase2,phase1Fault)
algorithm = reg.algorithm;
cfg = cache.cfg;
selfPF = repmat(400,1,3);
resultF = struct(); resultCF = struct();
diagnosticAvailability = "AVAILABLE";

if reg.run_or_reuse == "REUSE_FROZEN_RESULT"
    if reg.block == "A"
        detail = normal.caseDetails.(char(cache.historical_name));
        resultF = frozen_normal_result(detail,algorithm);
    elseif reg.fault_factor < 1.6
        source = phase2(phase2.condition_id == reg.source_condition_id & ...
            phase2.algorithm_id == algorithm,:);
        if height(source) ~= 1
            error('M5Step4:FrozenB','Missing Phase2 row for %s/%s.', ...
                reg.case_id,algorithm);
        end
        resultF = source;
        diagnosticAvailability = "HISTORICAL_PRIMARY_ONLY";
    else
        source = phase1Fault(phase1Fault.case_name == "Case05_fault_only" & ...
            phase1Fault.algorithm_mode == algorithm,:);
        if height(source) ~= 1
            error('M5Step4:FrozenB160','Missing Phase1 Case05 row for %s.',algorithm);
        end
        resultF = source;
        diagnosticAvailability = "HISTORICAL_PRIMARY_ONLY";
    end
elseif reg.run_or_reuse == "RECOMPUTE_NEW_METRICS_FROM_FROZEN_TRAJECTORY"
    frozen = case07.caseDetail;
    if reg.fault_factor == 1.6, frozen = case08.caseDetail; end
    resultF = frozen_overlap_result(frozen,algorithm,"F");
    resultCF = frozen_overlap_result(frozen,algorithm,"CF");
else
    if ismember(algorithm,["M2","M3","M4"])
        resultF = run_phase1a_algorithm(algorithm,cache.dataF, ...
            cache.ref,cfg,selfPF);
        if reg.block ~= "A"
            resultCF = run_phase1a_algorithm(algorithm,cache.dataCF, ...
                cache.ref,cfg,selfPF);
        end
    else
        mode = m5_mode(algorithm);
        trackerF = track_coupling_m5_directional_rls( ...
            cache.dataF,cache.ref,cfg,selfPF,mode);
        resultF = wrap_tracker_result(cache.dataF,cache.ref,selfPF,trackerF);
        if reg.block ~= "A"
            trackerCF = track_coupling_m5_directional_rls( ...
                cache.dataCF,cache.ref,cfg,selfPF,mode);
            resultCF = wrap_tracker_result(cache.dataCF,cache.ref,selfPF,trackerCF);
        end
    end
end

row = blank_result_row();
row.case_id = reg.case_id;
row.block = reg.block;
row.case_role = reg.case_role;
row.source_condition_id = reg.source_condition_id;
row.algorithm = algorithm;
row.run_or_reuse = reg.run_or_reuse;
row.fault_factor = reg.fault_factor;
row.drift_geometry = reg.drift_geometry;
row.drift_norm_pF = reg.drift_norm_pF;
row.seed = reg.seed;
row.snr_dB = reg.snr_dB;
row.data_signature = cache.data_signature;
row.model_sha256 = reg.model_sha256;
row.algorithm_source_sha256 = reg.algorithm_source_sha256;
row.diagnostic_availability = diagnosticAvailability;

if reg.block == "A"
    row = fill_a_metrics(row,resultF,cache,algorithm,cfg);
elseif reg.block == "B"
    row = fill_b_metrics(row,resultF,resultCF,cache,algorithm,cfg);
else
    row = fill_c_metrics(row,resultF,resultCF,cache,algorithm,cfg);
end
row.numerical_failure = required_numeric_failure(row,resultF,resultCF,reg.block);
row.metric_missing = required_metric_missing(row,reg.block);
row.readiness_pass = true;
row.notes = "Preregistered Step4 evaluation; no MC; no Step5.";
end

function result = frozen_normal_result(detail,algorithm)
name = char(algorithm);
result = struct('cHist',detail.([name '_cHist']), ...
    'ir',struct('B',detail.([name '_irB'])), ...
    'tracker',struct('cycle',detail.([name '_cycle'])));
end

function result = frozen_overlap_result(detail,algorithm,branch)
name = char(algorithm); suffix = char(branch);
result = struct('cHist',detail.([name '_cHist_' suffix]), ...
    'ir',struct('B',detail.([name '_irB_' suffix])), ...
    'tracker',struct());
cycleName = [name '_cycle_' suffix];
if isfield(detail,cycleName), result.tracker.cycle = detail.(cycleName); end
end

function result = wrap_tracker_result(data,ref,selfPF,tracker)
result = struct('cHist',tracker.hist, ...
    'ir',extract_resistive_current(data,ref,selfPF,tracker.hist), ...
    'tracker',tracker);
end

function mode = m5_mode(algorithm)
switch algorithm
    case "GH", mode = "GLOBAL_HARD_MATCHED";
    case "GC", mode = "GLOBAL_CONTINUOUS_MATCHED";
    case "M5_DH", mode = "M5_DH";
    case "M5_FULL", mode = "M5_FULL";
    case {"M2","M3","M4"}, mode = algorithm;
    otherwise, error('M5Step4:Algorithm','Unknown algorithm %s.',algorithm);
end
end

function row = fill_a_metrics(row,result,cache,algorithm,cfg)
index = cache.dataF.t >= 0.8 & cache.dataF.t < 4+cfg.Ts;
truth = [cache.dataF.Cs1,cache.dataF.Cs2];
error = result.cHist(index,:)-truth(index,:);
row.Cs1_RMSE_pF = sqrt(mean(error(:,1).^2));
row.Cs2_RMSE_pF = sqrt(mean(error(:,2).^2));
row.Cs_tracking_RMSE_pF = sqrt(mean(sum(error.^2,2)));
row.final_signed_Cs1_error_pF = result.cHist(find(index,1,'last'),1)- ...
    truth(find(index,1,'last'),1);
row.final_signed_Cs2_error_pF = result.cHist(find(index,1,'last'),2)- ...
    truth(find(index,1,'last'),2);
row.final_error_L2_pF = hypot(row.final_signed_Cs1_error_pF, ...
    row.final_signed_Cs2_error_pF);
if isfield(result,'tracker') && isfield(result.tracker,'cycle')
    row = apply_diagnostics(row,m5_step4_cycle_diagnostics( ...
        algorithm,result.tracker.cycle,0.8,4+cfg.Ts,cfg));
end
end

function row = fill_b_metrics(row,resultF,resultCF,cache,algorithm,cfg)
if istable(resultF)
    row.fault_factor_true = resultF.fault_factor_true;
    row.fault_factor_est = resultF.fault_factor_est;
    row.signed_fault_retention_error_pct = resultF.fault_retention_error_pct;
    row.abs_fault_retention_error_pct = abs(resultF.fault_retention_error_pct);
    row.signed_DeltaCs1_fault_induced_pF = resultF.DeltaCs1_fault_induced_pF;
    row.signed_DeltaCs2_fault_induced_pF = resultF.DeltaCs2_fault_induced_pF;
    if ismember('Cs_fault_induced_bias_norm_pF',resultF.Properties.VariableNames)
        row.Cs_fault_induced_bias_norm_pF = resultF.Cs_fault_induced_bias_norm_pF;
    else
        row.Cs_fault_induced_bias_norm_pF = hypot( ...
            row.signed_DeltaCs1_fault_induced_pF, ...
            row.signed_DeltaCs2_fault_induced_pF);
    end
    return
end
pre = cache.dataF.t >= 2.6 & cache.dataF.t < 2.9;
fault = cache.dataF.t >= 3.4 & cache.dataF.t < 3.8;
row.fault_factor_true = fault_factor_local(cache.dataF.t,cache.dataF.irB,pre,fault,cfg.f);
row.fault_factor_est = fault_factor_local(cache.dataF.t,resultF.ir.B,pre,fault,cfg.f);
row.signed_fault_retention_error_pct = (row.fault_factor_est- ...
    row.fault_factor_true)/row.fault_factor_true*100;
row.abs_fault_retention_error_pct = abs(row.signed_fault_retention_error_pct);
actualChange = mean(resultF.cHist(fault,:),1)-mean(resultF.cHist(pre,:),1);
cfChange = mean(resultCF.cHist(fault,:),1)-mean(resultCF.cHist(pre,:),1);
induced = actualChange-cfChange;
row.signed_DeltaCs1_fault_induced_pF = induced(1);
row.signed_DeltaCs2_fault_induced_pF = induced(2);
row.Cs_fault_induced_bias_norm_pF = norm(induced);
if isfield(resultF.tracker,'cycle')
    row = apply_diagnostics(row,m5_step4_cycle_diagnostics( ...
        algorithm,resultF.tracker.cycle,3.4,3.8,cfg));
end
end

function row = fill_c_metrics(row,resultF,resultCF,cache,algorithm,cfg)
t = cache.dataF.t;
w1 = t >= 1.62 & t < 1.74;
w2 = t >= 1.74 & t < 1.88;
overlap = w1 | w2;
truth = [cache.dataF.Cs1,cache.dataF.Cs2];
direction = m5_step4_direction_metrics(resultF.cHist,truth,overlap);
row.RMSE_total_pF = direction.RMSE_total_pF;
row.RMSE_parallel_pF = direction.RMSE_parallel_pF;
row.RMSE_perp_pF = direction.RMSE_perp_pF;
row.decomposition_max_abs_pF = direction.decomposition_max_abs_pF;
row.energy_closure_max_abs_pF2 = direction.energy_closure_max_abs_pF2;
row.W1_fault_increment_retention_ratio = retention_ratio_local( ...
    cache.dataF,cache.dataCF,resultF,resultCF,cfg.f,w1);
row.W1_signed_retention_error = row.W1_fault_increment_retention_ratio-1;
row.W1_abs_retention_error = abs(row.W1_signed_retention_error);
row.W2_fault_increment_retention_ratio = retention_ratio_local( ...
    cache.dataF,cache.dataCF,resultF,resultCF,cfg.f,w2);
row.W2_signed_retention_error = row.W2_fault_increment_retention_ratio-1;
row.W2_abs_retention_error = abs(row.W2_signed_retention_error);
startIndex = find(t < 1.45,1,'last');
endIndex = find(t < 1.88,1,'last');
fMove = resultF.cHist(endIndex,:)-resultF.cHist(startIndex,:);
cfMove = resultCF.cHist(endIndex,:)-resultCF.cHist(startIndex,:);
delta = fMove-cfMove;
row.signed_F_minus_CF_Cs1_pF = delta(1);
row.signed_F_minus_CF_Cs2_pF = delta(2);
row.bias_norm_pF = norm(delta);
if isfield(resultF.tracker,'cycle')
    row = apply_diagnostics(row,m5_step4_cycle_diagnostics( ...
        algorithm,resultF.tracker.cycle,1.62,1.88,cfg));
end
end

function row = apply_diagnostics(row,d)
names = fieldnames(d);
for k = 1:numel(names)
    if isfield(row,names{k}), row.(names{k}) = d.(names{k}); end
end
end

function [results,gates,factorial] = finalize_decision(results)
factorialAlgorithms = ["GH","GC","M5_DH","M5_FULL"];
factorial = table();
cases = unique(results.case_id,'stable');
for caseId = cases.'
    part = results(results.case_id == caseId & ...
        ismember(results.algorithm,factorialAlgorithms),:);
    if height(part) ~= 4, continue, end
    if part.block(1) == "B"
        response = "abs_fault_retention_error_pct";
        bias = "Cs_fault_induced_bias_norm_pF";
    elseif part.block(1) == "C"
        response = "W2_abs_retention_error";
        bias = "RMSE_perp_pF";
    else
        response = "Cs_tracking_RMSE_pF";
        bias = "final_error_L2_pF";
    end
    gh = part(part.algorithm=="GH",:); gc = part(part.algorithm=="GC",:);
    dh = part(part.algorithm=="M5_DH",:); full = part(part.algorithm=="M5_FULL",:);
    interactionResponse = (full.(response)-gc.(response))- ...
        (dh.(response)-gh.(response));
    interactionBias = (full.(bias)-gc.(bias))- ...
        (dh.(bias)-gh.(bias));
    add = table(caseId,part.block(1),string(response),interactionResponse, ...
        string(bias),interactionBias,'VariableNames', ...
        {'case_id','block','response_metric','interaction_response', ...
        'bias_metric','interaction_bias'});
    factorial = [factorial;add]; %#ok<AGROW>
    index = results.case_id == caseId & ismember(results.algorithm,factorialAlgorithms);
    results.factorial_interaction_response(index) = interactionResponse;
    results.factorial_interaction_bias(index) = interactionBias;
end

% Gate A: primary candidate improves median retention and bias over M2 in B.
b = results(results.block=="B" & ismember(results.algorithm,["M2","M5_FULL"]),:);
m2 = b(b.algorithm=="M2",:); full = b(b.algorithm=="M5_FULL",:);
[~,i1] = sort(m2.fault_factor); m2=m2(i1,:);
[~,i2] = sort(full.fault_factor); full=full(i2,:);
gates.A = height(m2)==6 && height(full)==6 && ...
    median(full.abs_fault_retention_error_pct-m2.abs_fault_retention_error_pct) < 0 && ...
    median(full.Cs_fault_induced_bias_norm_pF-m2.Cs_fault_induced_bias_norm_pF) < 0;

% Gate B: orthogonal drift must not worsen perpendicular error at either level.
orth = results(results.block=="C" & results.drift_geometry=="ORTHOGONAL" & ...
    ismember(results.algorithm,["GC","M5_FULL"]),:);
deltaPerp = NaN(2,1);
roundoffTolerance = NaN(2,1);
levels = [1.3,1.6];
for k=1:2
    q=orth(orth.fault_factor==levels(k),:);
    pair=[q.RMSE_perp_pF(q.algorithm=="M5_FULL"), ...
        q.RMSE_perp_pF(q.algorithm=="GC")];
    deltaPerp(k)=pair(1)-pair(2);
    roundoffTolerance(k)=1e-12*(1+max(abs(pair)));
end
gates.B = all(deltaPerp <= roundoffTolerance) && ...
    any(deltaPerp < -roundoffTolerance);

% Gate C: mixed cases need no joint total/perp regression; if present,
% registered diagnostics must directly evidence the mechanism.
mixed = results(results.block=="C" & startsWith(results.drift_geometry,"MIXED") & ...
    ismember(results.algorithm,["GC","M5_FULL"]),:);
gates.C = true;
jointWorseCount = 0;
registeredExplanation = false;
for level=levels
    q=mixed(mixed.fault_factor==level,:);
    gc=q(q.algorithm=="GC",:); mf=q(q.algorithm=="M5_FULL",:);
    jointWorse = mf.RMSE_perp_pF > gc.RMSE_perp_pF && ...
        mf.RMSE_total_pF > gc.RMSE_total_pF;
    jointWorseCount = jointWorseCount+jointWorse;
    angleRotation = abs(mf.mean_post_rate_angle_to_df_deg- ...
        mf.mean_protected_angle_to_df_deg) > 1e-12 || ...
        abs(mf.mean_post_projection_angle_to_df_deg- ...
        mf.mean_post_rate_angle_to_df_deg) > 1e-12;
    registeredExplanation = registeredExplanation || ...
        mf.rate_limit_cycles > 0 || mf.projection_cycles > 0 || angleRotation;
end
gates.C = jointWorseCount < 2 || registeredExplanation;

% Gate D has no performance threshold. It passes only when every registered
% parallel-boundary row, including negative results, remains in the record.
parallel = results(results.block=="C" & results.drift_geometry=="PARALLEL",:);
gates.D = height(parallel)==14 && ...
    numel(unique(parallel.case_id))==2 && ...
    all(~parallel.numerical_failure & ~parallel.metric_missing);
gates.overall_go = gates.A && gates.B && gates.C && gates.D;
end

function failed = required_numeric_failure(row,resultF,resultCF,block)
failed = false;
if istable(resultF), return, end
failed = ~all(isfinite(resultF.cHist),'all') || ...
    ~all(isfinite(resultF.ir.B));
if block ~= "A"
    failed = failed || ~all(isfinite(resultCF.cHist),'all') || ...
        ~all(isfinite(resultCF.ir.B));
end
end

function missing = required_metric_missing(row,block)
if block == "A"
    required = [row.Cs_tracking_RMSE_pF,row.Cs1_RMSE_pF, ...
        row.Cs2_RMSE_pF,row.final_error_L2_pF];
elseif block == "B"
    required = [row.abs_fault_retention_error_pct, ...
        row.Cs_fault_induced_bias_norm_pF, ...
        row.signed_DeltaCs1_fault_induced_pF, ...
        row.signed_DeltaCs2_fault_induced_pF];
else
    required = [row.W1_abs_retention_error,row.W2_abs_retention_error, ...
        row.RMSE_total_pF,row.RMSE_parallel_pF,row.RMSE_perp_pF, ...
        row.bias_norm_pF,row.decomposition_max_abs_pF, ...
        row.energy_closure_max_abs_pF2];
end
missing = any(~isfinite(required));
end

function row = blank_result_row()
row = struct( ...
    'case_id',"",'block',"",'case_role',"", ...
    'source_condition_id',"",'algorithm',"",'run_or_reuse',"", ...
    'fault_factor',NaN,'drift_geometry',"",'drift_norm_pF',NaN, ...
    'seed',NaN,'snr_dB',NaN,'data_signature',"", ...
    'model_sha256',"",'algorithm_source_sha256',"", ...
    'Cs_tracking_RMSE_pF',NaN,'Cs1_RMSE_pF',NaN, ...
    'Cs2_RMSE_pF',NaN,'final_signed_Cs1_error_pF',NaN, ...
    'final_signed_Cs2_error_pF',NaN,'final_error_L2_pF',NaN, ...
    'fault_factor_true',NaN,'fault_factor_est',NaN, ...
    'signed_fault_retention_error_pct',NaN, ...
    'abs_fault_retention_error_pct',NaN, ...
    'signed_DeltaCs1_fault_induced_pF',NaN, ...
    'signed_DeltaCs2_fault_induced_pF',NaN, ...
    'Cs_fault_induced_bias_norm_pF',NaN, ...
    'W1_fault_increment_retention_ratio',NaN, ...
    'W1_signed_retention_error',NaN,'W1_abs_retention_error',NaN, ...
    'W2_fault_increment_retention_ratio',NaN, ...
    'W2_signed_retention_error',NaN,'W2_abs_retention_error',NaN, ...
    'RMSE_total_pF',NaN,'RMSE_parallel_pF',NaN,'RMSE_perp_pF',NaN, ...
    'signed_F_minus_CF_Cs1_pF',NaN, ...
    'signed_F_minus_CF_Cs2_pF',NaN,'bias_norm_pF',NaN, ...
    'decomposition_max_abs_pF',NaN,'energy_closure_max_abs_pF2',NaN, ...
    'schema_mapping',"",'cycle_count',NaN, ...
    'hard_gate_active_ratio',NaN,'mean_w_REW',NaN, ...
    'mean_selected_weight',NaN, ...
    'raw_parallel_update_energy_pF2',NaN, ...
    'raw_perp_update_energy_pF2',NaN, ...
    'applied_parallel_update_energy_pF2',NaN, ...
    'applied_perp_update_energy_pF2',NaN, ...
    'rate_limit_cycles',NaN,'projection_cycles',NaN, ...
    'near_zero_update_cycles',NaN,'mean_raw_angle_to_df_deg',NaN, ...
    'mean_protected_angle_to_df_deg',NaN, ...
    'mean_post_rate_angle_to_df_deg',NaN, ...
    'mean_post_projection_angle_to_df_deg',NaN, ...
    'factorial_interaction_response',NaN, ...
    'factorial_interaction_bias',NaN, ...
    'readiness_pass',false,'source_integrity_pass',false, ...
    'diagnostic_availability',"",'numerical_failure',false, ...
    'metric_missing',false,'notes',"");
end

function paths = step4_paths()
matlabRoot = fileparts(mfilename('fullpath'));
projectRoot = fileparts(matlabRoot);
root = fullfile(projectRoot,'paper_research','phase_m5_directional_update');
outputRoot = fullfile(root,'step4_deterministic_core');
paths = struct( ...
    'project_root',projectRoot,'matlab_root',matlabRoot, ...
    'output_root',outputRoot,'cache_root',fullfile(outputRoot,'cache'), ...
    'simulink_cache',fullfile(outputRoot,'simulink_cache'), ...
    'matrix',fullfile(root,'step3_preregistration', ...
        'M5_STEP3_EXPERIMENT_MATRIX.csv'), ...
    'test_file',fullfile(matlabRoot,'tests','M5Step4ReadinessTest.m'), ...
    'readiness_mat',fullfile(outputRoot,'readiness_gate.mat'), ...
    'master_csv',fullfile(outputRoot,'M5_STEP4_MASTER_RESULTS.csv'), ...
    'report',fullfile(outputRoot,'M5_STEP4_DECISION_REPORT.md'), ...
    'baseline_workspace',fullfile(projectRoot,'paper_research', ...
        'phase1a_baseline','baseline_workspace.mat'), ...
    'normal_workspace',fullfile(projectRoot,'paper_research', ...
        'phase1c_m4_method','step3_normal_tracking','workspace', ...
        'normal_tracking_workspace.mat'), ...
    'case07_workspace',fullfile(projectRoot,'paper_research', ...
        'phase1c_m4_method','step5_simultaneous_drift_fault', ...
        'workspace','case07_step5_workspace.mat'), ...
    'case08_workspace',fullfile(projectRoot,'paper_research', ...
        'phase1c_m4_method','step5b_triggered_overlap','workspace', ...
        'case08_step5b_workspace.mat'), ...
    'phase2_results',fullfile(projectRoot,'paper_research', ...
        'phase2_full_validation','step2b2_deterministic_core', ...
        'step2b2_deterministic_results.csv'), ...
    'phase1_fault_results',fullfile(projectRoot,'paper_research', ...
        'phase1c_m4_method','step4_fault_preservation','tables', ...
        'fault_preservation_summary.csv'));
end

function signals = controlled_overlap_signals(row,cfg,branch)
t = (0:cfg.Ts:cfg.StopTime).';
progress = smooth_step_local(t,0.8,2.2);
Cs1 = row.Cs1_initial_pF+row.drift_delta_Cs1_pF*progress;
Cs2 = row.Cs2_initial_pF+row.drift_delta_Cs2_pF*progress;
faultScale = ones(size(t));
if branch == "F"
    up = smooth_step_local(t,1.5,1.56);
    down = smooth_step_local(t,1.90,1.96);
    faultScale = 1+(row.fault_factor-1)*min(up,1-down);
end
signals = struct('t',t,'Cs1_pF',Cs1,'Cs2_pF',Cs2, ...
    'fault_scale',faultScale,'branch',branch);
end

function y = smooth_step_local(t,t0,t1)
x = min(max((t-t0)/(t1-t0),0),1);
y = x.^2.*(3-2*x);
end

function data = run_once_local(cfg,signals,noiseA,noiseB,noiseC)
in = Simulink.SimulationInput(cfg.model);
vars = struct('StopTime',cfg.StopTime,'h3_ratio',cfg.h3_ratio, ...
    'phi3_deg',cfg.phi3_deg,'Vneg_pu',cfg.Vneg_pu,'f',cfg.f, ...
    'Un_LL',cfg.Un_LL,'C0',cfg.C0,'C_moa',cfg.C_moa, ...
    'C1',cfg.C1,'C2',cfg.C2,'Vref_moa',cfg.moa_Vref_V, ...
    'Iref_moa',cfg.moa_Iref_A,'alpha_moa',cfg.moa_alpha, ...
    'Ts',cfg.Ts,'Ts_model',cfg.Ts,'Cself_pF',cfg.Cself_pF, ...
    'Ccoupling_disabled_F',1e-18);
names = fieldnames(vars);
for k=1:numel(names), in=in.setVariable(names{k},vars.(names{k})); end
dataset = Simulink.SimulationData.Dataset;
dataset{1}=timeseries(signals.Cs1_pF,signals.t);
dataset{2}=timeseries(signals.Cs2_pF,signals.t);
dataset{3}=timeseries(signals.fault_scale,signals.t);
dataset{4}=timeseries(noiseA,signals.t);
dataset{5}=timeseries(noiseB,signals.t);
dataset{6}=timeseries(noiseC,signals.t);
in=in.setExternalInput(dataset);
in=in.setModelParameter('StopTime',num2str(cfg.StopTime));
out=sim(in);
[data.t,data.ua]=read_signal_local(out,'uA');
[~,data.ub]=read_signal_local(out,'uB'); [~,data.uc]=read_signal_local(out,'uC');
[~,data.ia]=read_signal_local(out,'iA_total'); [~,data.ib]=read_signal_local(out,'iB_total');
[~,data.ic]=read_signal_local(out,'iC_total');
[~,data.irA]=read_signal_local(out,'iA_R_true'); [~,data.irB]=read_signal_local(out,'iB_R_true');
[~,data.irC]=read_signal_local(out,'iC_R_true');
[~,data.Cs1]=read_signal_local(out,'Cs1_true'); [~,data.Cs2]=read_signal_local(out,'Cs2_true');
end

function [t,x] = read_signal_local(out,name)
s=out.get(name);
if isa(s,'timeseries'), t=s.Time; x=s.Data; else, t=s.time; x=s.signals.values; end
t=t(:); x=squeeze(x); x=x(:);
end

function [dataF,dataCF] = add_self_capacitance(dataF,dataCF,value)
for name=["Ca","Cb","Cc"]
    dataF.(char(name))=value*ones(size(dataF.t));
    dataCF.(char(name))=value*ones(size(dataCF.t));
end
dataF.scenario="m5_step4_F"; dataCF.scenario="m5_step4_CF";
dataF.current_source="simulink"; dataCF.current_source="simulink";
end

function dataCF = remove_fault_component_local(data,faultScale)
dataCF=data;
increment=(1-1./faultScale).*data.irB;
dataCF.ib=data.ib-increment;
dataCF.irB=data.irB-increment;
dataCF.scenario="m5_step4_counterfactual";
end

function noise = noise_for_snr(x,snrDB)
if isfinite(snrDB), noise=rms(x)/10^(snrDB/20)*randn(size(x));
else, noise=zeros(size(x)); end
end

function pass = injected_noise_pass(data,clean,noise)
pass = max(abs((data.ia-clean.ia)-noise.A))<1e-12 && ...
    max(abs((data.ib-clean.ib)-noise.B))<1e-12 && ...
    max(abs((data.ic-clean.ic)-noise.C))<1e-12;
end

function pass = exact_vector(a,b,tolerance)
pass = isequal(size(a),size(b)) && ...
    all(abs(double(a(:))-double(b(:)))<=tolerance);
end

function signature = data_signature(data,signals,ref,referenceReplay)
values={data.t,data.ua,data.ub,data.uc,data.ia,data.ib,data.ic, ...
    data.irA,data.irB,data.irC,data.Cs1,data.Cs2,signals.fault_scale, ...
    ref.ua,ref.ub,ref.uc,ref.dua,ref.dub,ref.duc, ...
    referenceReplay.ia,referenceReplay.ib,referenceReplay.ic};
signature=numeric_values_sha256(values);
end

function signature = pair_signature_local(dataF,dataCF,signals,noise,ref)
values={dataF.t,dataF.ua,dataF.ub,dataF.uc,dataF.ia,dataF.ib, ...
    dataF.ic,dataF.irB,dataF.Cs1,dataF.Cs2,dataCF.ia,dataCF.ib, ...
    dataCF.ic,dataCF.irB,signals.fault_scale,noise.A,noise.B,noise.C, ...
    ref.ua,ref.ub,ref.uc,ref.dua,ref.dub,ref.duc};
signature=numeric_values_sha256(values);
end

function signature = numeric_values_sha256(values)
digester=java.security.MessageDigest.getInstance('SHA-256');
for k=1:numel(values)
    digester.update(typecast(double(values{k}(:)),'uint8'));
end
bytes=typecast(digester.digest(),'uint8');
signature=upper(string(reshape(dec2hex(bytes,2).',1,[])));
end

function value = fundamental_rms_local(t,x,f)
w=2*pi*f; beta=[sin(w*t),cos(w*t),ones(size(t))]\x;
value=hypot(beta(1),beta(2))/sqrt(2);
end

function value = fault_factor_local(t,x,pre,post,f)
value=fundamental_rms_local(t(post),x(post),f)/(fundamental_rms_local(t(pre),x(pre),f)+eps);
end

function ratio = retention_ratio_local(dataF,dataCF,resultF,resultCF,f,index)
truth=fundamental_rms_local(dataF.t(index),dataF.irB(index),f)- ...
    fundamental_rms_local(dataCF.t(index),dataCF.irB(index),f);
estimate=fundamental_rms_local(dataF.t(index),resultF.ir.B(index),f)- ...
    fundamental_rms_local(dataCF.t(index),resultCF.ir.B(index),f);
ratio=estimate/(truth+eps);
end

function audit = source_integrity(paths)
names=["AI6109_MOA_AutoComp9.slx";"patent_default_config.m"; ...
    "track_coupling_cvff_rls.m";"track_coupling_m4_weighted_rls.m"; ...
    "m4_fault_evidence.m";"track_coupling_m5_directional_rls.m"; ...
    "m5_directional_update.m";"coupling_regressor.m"];
expected=[ ...
    "56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70"; ...
    "D9F3E6894F51C3D978421C9E1E93828A9205F418C77D01AC449B994A3D789726"; ...
    "033135775D81BE4521AA76B8C6C2C8C3415988DA8870561722779DB0FC485D7E"; ...
    "A0504AD65B490F803AED454BF4D8CD2C6F724D0A96DF60502F7F32789521EEC1"; ...
    "486FF017CE4491C84FBBF84D042EF661A5AFC5A8D255F0B88AC583304D593D15"; ...
    "8B580215A6268F4AC3BF27FB357DB6A4A01027DD2410C7FF59EA3C4B46DA4DDB"; ...
    "47D2C12DB80F4BBFE7CE296841074DB6F3FF641CD769907666292E4398E06CA7"; ...
    "7582F66875A1099DF9656F9A89FE12D8FF6972C55D4A034736527A7DB00E03D5"];
filePaths=strings(size(names)); actual=strings(size(names));
for k=1:numel(names)
    filePaths(k)=fullfile(paths.matlab_root,names(k));
    actual(k)=file_sha256_local(filePaths(k));
end
audit=struct('names',names,'paths',filePaths,'expected_sha256',expected, ...
    'actual_sha256',actual,'item_pass',expected==actual, ...
    'pass',all(expected==actual));
end

function hash = file_sha256_local(path)
id=fopen(path,'rb');
if id<0, error('M5Step4:HashRead','Unable to open %s.',path); end
cleanup=onCleanup(@()fclose(id));
bytes=fread(id,Inf,'*uint8');
digester=java.security.MessageDigest.getInstance('SHA-256');
digester.update(bytes);
hashBytes=typecast(digester.digest(),'uint8');
hash=upper(string(reshape(dec2hex(hashBytes,2).',1,[])));
end

function duplicate = duplicated_case(caseIds)
duplicate=false(numel(caseIds),1); seen=strings(0,1);
for k=1:numel(caseIds)
    duplicate(k)=any(seen==caseIds(k));
    seen(end+1,1)=caseIds(k); %#ok<AGROW>
end
end

function write_decision_report(paths,results,gates,factorial,pre,post,status)
id=fopen(paths.report,'w','n','UTF-8');
if id<0, error('M5Step4:ReportWrite','Unable to write report.'); end
cleanup=onCleanup(@()fclose(id));
line=@(x)fprintf(id,'%s\n',x);
line('# M5 Step4 Deterministic Core Decision Report'); line('');
line('## Decision'); line('');
line(sprintf('- **M5_STEP4_STATUS: %s**',status));
line(sprintf('- Rows complete: %d / 98',nnz(~results.numerical_failure & ~results.metric_missing)));
line(sprintf('- Gate A / B / C / D: %s / %s / %s / %s', ...
    pass_fail(gates.A),pass_fail(gates.B),pass_fail(gates.C), ...
    retained_violated(gates.D)));
line('- Monte Carlo: NOT RUN');
line('- Step5: NOT RUN; this report does not authorize automatic continuation.');
line(''); line('## Readiness and provenance'); line('');
line('- U1-U5 were required to pass before any M5 performance evaluation.');
line('- Physical simulations: 34 exact calls for 14 registered cases.');
line('- Execution matrix: 98 rows = 24 frozen reuse + 6 frozen-trajectory metrics-only + 68 new tracker rows.');
line(sprintf('- Registered source hashes PRE/POST: %s / %s.', ...
    pass_fail(pre.pass),pass_fail(post.pass)));
line('');
line('| Readiness gate | Result |'); line('|---|---|');
for gateName = ["U1 independent runner","U2 directional identities", ...
        "U3 A/B physical replay","U4 mixed F/CF signature replay", ...
        "U5 explicit cycle schemas"]
    line(sprintf('| %s | PASS |',gateName));
end
line(''); line('### Data integrity by physical case'); line('');
line('| Case | Signature | Rows sharing signature |');
line('|---|---|---:|');
for caseId = unique(results.case_id,'stable').'
    q=results(results.case_id==caseId,:);
    line(sprintf('| %s | `%s` | %d |',caseId,q.data_signature(1), ...
        nnz(q.data_signature==q.data_signature(1))));
end

line(''); line('## Block A — sanity tracking'); line('');
line('| Case | Algorithm | Tracking RMSE pF | Final Cs1 error pF | Final Cs2 error pF | Final L2 pF |');
line('|---|---|---:|---:|---:|---:|');
a=results(results.block=="A",:);
for k=1:height(a)
    line(sprintf('| %s | %s | %.9g | %.9g | %.9g | %.9g |', ...
        a.case_id(k),a.algorithm(k),a.Cs_tracking_RMSE_pF(k), ...
        a.final_signed_Cs1_error_pF(k),a.final_signed_Cs2_error_pF(k), ...
        a.final_error_L2_pF(k)));
end

line(''); line('## Block B — pure-fault protection'); line('');
line('| Algorithm | Median abs retention error % | Median fault-induced bias pF |');
line('|---|---:|---:|');
b=results(results.block=="B",:);
for algorithm=unique(b.algorithm,'stable').'
    q=b(b.algorithm==algorithm,:);
    line(sprintf('| %s | %.9g | %.9g |',algorithm, ...
        median(q.abs_fault_retention_error_pct), ...
        median(q.Cs_fault_induced_bias_norm_pF)));
end
line('');
line('Historical comparison uses exact frozen M2/M3/M4 primary results at all six severities; no historical tracker was rerun. GH/GC/M5-DH/M5-Full share each regenerated physical case.');

line(''); line('## Block C — matched overlap geometry'); line('');
line('| Case | Algorithm | W1 abs retention | W2 abs retention | Total RMSE pF | Parallel RMSE pF | Perpendicular RMSE pF | Bias pF |');
line('|---|---|---:|---:|---:|---:|---:|---:|');
c=results(results.block=="C" & ismember(results.algorithm,["GC","M5_FULL"]),:);
for k=1:height(c)
    line(sprintf('| %s | %s | %.9g | %.9g | %.9g | %.9g | %.9g | %.9g |', ...
        c.case_id(k),c.algorithm(k),c.W1_abs_retention_error(k), ...
        c.W2_abs_retention_error(k),c.RMSE_total_pF(k), ...
        c.RMSE_parallel_pF(k),c.RMSE_perp_pF(k),c.bias_norm_pF(k)));
end
line('');
line('Mixed M2/M3/M4 rows are metrics-only calculations from frozen Case07/08 trajectories. Orthogonal/parallel M2/M3/M4 rows are new executions because those physical geometries did not previously exist.');
line(''); line('## Gate definitions and outcome'); line('');
line('| Gate | Registered decision question | Outcome |');
line('|---|---|---|');
line(sprintf('| A | M5-Full median pure-fault retention and bias improve over M2 | %s |',pass_fail(gates.A)));
line(sprintf('| B | Orthogonal drift perpendicular RMSE is preserved at both severities and improves at least once | %s |',pass_fail(gates.B)));
line(sprintf('| C | Mixed-geometry joint regression is absent or directly explained by registered diagnostics | %s |',pass_fail(gates.C)));
line(sprintf('| D | All parallel-boundary rows, including negative results, are retained without a performance threshold | %s |',retained_violated(gates.D)));
line(''); line('## Matched 2x2 factorial'); line('');
line('The strict attribution compares GH, GC, M5-DH, and M5-Full. Interaction is `(M5-Full-GC)-(M5-DH-GH)` for the registered response and bias metric.');
line('');
line('| Case | Block | Response metric | Interaction | Bias metric | Interaction |');
line('|---|---|---|---:|---|---:|');
for k=1:height(factorial)
    line(sprintf('| %s | %s | %s | %.9g | %s | %.9g |', ...
        factorial.case_id(k),factorial.block(k),factorial.response_metric(k), ...
        factorial.interaction_response(k),factorial.bias_metric(k), ...
        factorial.interaction_bias(k)));
end
line(''); line('## Projection, rate, and direction diagnostics'); line('');
line('| Case | Algorithm | Rate cycles | Projection cycles | Near-zero cycles | Raw angle deg | Protected angle deg | Post-rate angle deg | Post-projection angle deg |');
line('|---|---|---:|---:|---:|---:|---:|---:|---:|');
d=results(results.algorithm=="M5_FULL",:);
for k=1:height(d)
    line(sprintf('| %s | %s | %.0f | %.0f | %.0f | %.9g | %.9g | %.9g | %.9g |', ...
        d.case_id(k),d.algorithm(k),d.rate_limit_cycles(k), ...
        d.projection_cycles(k),d.near_zero_update_cycles(k), ...
        d.mean_raw_angle_to_df_deg(k),d.mean_protected_angle_to_df_deg(k), ...
        d.mean_post_rate_angle_to_df_deg(k), ...
        d.mean_post_projection_angle_to_df_deg(k)));
end
line(''); line('## Preserved negative and boundary results'); line('');
totalWorse=0; perpWorse=0; w2Worse=0;
for caseId=unique(c.case_id,'stable').'
    q=c(c.case_id==caseId,:); gc=q(q.algorithm=="GC",:); mf=q(q.algorithm=="M5_FULL",:);
    totalWorse=totalWorse+(mf.RMSE_total_pF>gc.RMSE_total_pF);
    perpWorse=perpWorse+(mf.RMSE_perp_pF>gc.RMSE_perp_pF);
    w2Worse=w2Worse+(mf.W2_abs_retention_error>gc.W2_abs_retention_error);
end
line(sprintf('- Relative to GC across the six Block C cases, M5-Full has worse total RMSE in %d, worse perpendicular RMSE in %d, and worse W2 retention error in %d. These rows are retained.',totalWorse,perpWorse,w2Worse));
line(sprintf('- Natural Step4 data triggered %d rate-limited and %d projection-active M5-Full cycles; the preregistered U6 boundary remains outside Step4.',sum(d.rate_limit_cycles),sum(d.projection_cycles)));
line('- Parallel geometry is an identifiability boundary with no performance PASS threshold; both severities and all seven algorithms remain in the master CSV.');
line(''); line('## Primary numerical summary'); line('');
line('| Case | Algorithm | A tracking RMSE pF | B abs retention % | B bias pF | C W2 abs retention | C total/perp RMSE pF |');
line('|---|---|---:|---:|---:|---:|---:|');
for k=1:height(results)
    line(sprintf('| %s | %s | %.6g | %.6g | %.6g | %.6g | %.6g / %.6g |', ...
        results.case_id(k),results.algorithm(k),results.Cs_tracking_RMSE_pF(k), ...
        results.abs_fault_retention_error_pct(k), ...
        results.Cs_fault_induced_bias_norm_pF(k), ...
        results.W2_abs_retention_error(k),results.RMSE_total_pF(k), ...
        results.RMSE_perp_pF(k)));
end
line(''); line('## Scientific boundary'); line('');
line('The deterministic result is limited to the preregistered model, seeds, windows, and fixed fault direction. A GO supports only progression to separately reviewed Monte Carlo work; it is not population-level validation. A STOP forbids that progression until the registered failure is reviewed.');
line('');
line('**STEP5_AUTHORIZED: NO — pending human review.**');
end

function value = pass_fail(pass)
if pass, value='PASS'; else, value='FAIL'; end
end

function value = retained_violated(pass)
if pass, value='RETAINED'; else, value='VIOLATED'; end
end
