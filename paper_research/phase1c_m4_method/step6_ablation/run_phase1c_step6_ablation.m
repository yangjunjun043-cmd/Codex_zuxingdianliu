function result = run_phase1c_step6_ablation()
%RUN_PHASE1C_STEP6_ABLATION Run the pre-registered four-case ablation.

step6Root = fileparts(mfilename('fullpath'));
phase1cRoot = fileparts(step6Root);
projectRoot = fileparts(fileparts(phase1cRoot));
matlabRoot = fullfile(projectRoot,'MATLAB一键实验');
step5Root = fullfile(phase1cRoot,'step5_simultaneous_drift_fault');
step5bRoot = fullfile(phase1cRoot,'step5b_triggered_overlap');
tablesRoot = fullfile(step6Root,'tables');
diagnosticsRoot = fullfile(step6Root,'diagnostics');
workspaceRoot = fullfile(step6Root,'workspace');
ensure_directories([string(tablesRoot),string(diagnosticsRoot), ...
    string(workspaceRoot)]);
addpath(matlabRoot); addpath(step5Root); addpath(step5bRoot); addpath(step6Root);

definition = phase1c_step6_definition();
protectedBefore = capture_protected_files( ...
    projectRoot,matlabRoot,phase1cRoot,step6Root);
cfg = patent_default_config();
cfg.model = 'AI6109_MOA_AutoComp9';
selfPF = repmat(cfg.Cself_pF,1,3);

fprintf('STEP6_SIMULATION_START case=Case02\n');
[data02,~] = simulate_phase2_case(cfg,'slow_drift',102);
ref02 = make_ref(data02,cfg);
results02 = run_variants(data02,ref02,cfg,selfPF,definition.variants);

fprintf('STEP6_SIMULATION_START case=Case05\n');
[data05F,~] = simulate_phase2_case(cfg,'fault_only',106);
data05CF = remove_case05_fault(data05F,cfg);
ref05 = make_ref(data05F,cfg);
results05F = run_variants(data05F,ref05,cfg,selfPF,definition.variants);
results05CF = run_variants(data05CF,ref05,cfg,selfPF,definition.variants);

fprintf('STEP6_NOISE_REPLAY_START source=Case06 seed=105\n');
sharedNoise = derive_case06_noise(cfg,105);
timeInput = (0:cfg.Ts:cfg.StopTime).';

definition07 = phase1c_case07_definition();
signals07F = build_phase1c_case07_signals(timeInput,definition07,"F");
signals07CF = build_phase1c_case07_signals(timeInput,definition07,"CF");
fprintf('STEP6_SIMULATION_START case=Case07 branch=F\n');
data07F = simulate_phase1c_case07(cfg,signals07F,sharedNoise);
fprintf('STEP6_SIMULATION_START case=Case07 branch=CF\n');
data07CF = simulate_phase1c_case07(cfg,signals07CF,sharedNoise);
ref07 = make_ref(data07F,cfg);
results07F = run_variants(data07F,ref07,cfg,selfPF,definition.variants);
results07CF = run_variants(data07CF,ref07,cfg,selfPF,definition.variants);

definition08 = phase1c_case08_definition();
signals08F = build_phase1c_case08_signals(timeInput,definition08,"F");
signals08CF = build_phase1c_case08_signals(timeInput,definition08,"CF");
fprintf('STEP6_SIMULATION_START case=Case08 branch=F\n');
data08F = simulate_phase1c_case08(cfg,signals08F,sharedNoise);
fprintf('STEP6_SIMULATION_START case=Case08 branch=CF\n');
data08CF = simulate_phase1c_case08(cfg,signals08CF,sharedNoise);
ref08 = make_ref(data08F,cfg);
results08F = run_variants(data08F,ref08,cfg,selfPF,definition.variants);
results08CF = run_variants(data08CF,ref08,cfg,selfPF,definition.variants);

case02 = evaluate_case02(definition,cfg,data02,results02);
case05 = evaluate_case05(definition,cfg,data05F,data05CF, ...
    results05F,results05CF);
case07 = evaluate_overlap(definition07,cfg,data07F,data07CF, ...
    results07F,results07CF,NaN);
[gateStart,gateEnd,gateRatio] = m3_gate_interval( ...
    definition08,results08F.M3.tracker.cycle);
case08 = evaluate_overlap(definition08,cfg,data08F,data08CF, ...
    results08F,results08CF,[gateStart gateEnd]);
case08.gate_active_ratio = gateRatio;

equivalence = no_weight_equivalence({ ...
    "Case02","Case05_F","Case05_CF","Case07_F","Case07_CF", ...
    "Case08_F","Case08_CF"}, ...
    {results02,results05F,results05CF,results07F,results07CF, ...
     results08F,results08CF});
regression = validate_regression(projectRoot);
hashes = freeze_hashes(projectRoot,matlabRoot,phase1cRoot,step6Root);
metadata = capture_metadata(matlabRoot,cfg,hashes);

validation = struct( ...
    'formal_validator_pass',regression.formal_pass, ...
    'historical_regression_pass',regression.historical_pass, ...
    'no_weight_equals_m2',all(equivalence.pass), ...
    'four_cases_complete',height(case02) == 6 && height(case05) == 6 && ...
        height(case07.summary) == 6 && height(case08.summary) == 6, ...
    'no_rate_or_projection', ...
        all(case05.rate_limit_cycles == 0) && ...
        all(case05.projection_cycles == 0));
validation.overall_pass = validation.formal_validator_pass && ...
    validation.historical_regression_pass && ...
    validation.no_weight_equals_m2 && validation.four_cases_complete && ...
    validation.no_rate_or_projection;

writetable(case02,fullfile(tablesRoot,'case02_ablation.csv'));
writetable(case05,fullfile(tablesRoot,'case05_ablation.csv'));
writetable(case07.summary,fullfile(tablesRoot,'case07_ablation.csv'));
writetable(case07.windows,fullfile(tablesRoot,'case07_window_detail.csv'));
writetable(case08.summary,fullfile(tablesRoot,'case08_ablation.csv'));
writetable(case08.windows,fullfile(tablesRoot,'case08_window_detail.csv'));
writetable(case08.gate,fullfile(tablesRoot,'case08_gate_interval.csv'));
writetable(equivalence,fullfile(tablesRoot,'no_weight_equivalence.csv'));
writetable(definition.parameters,fullfile(tablesRoot,'parameter_table.csv'));
writetable(hashes,fullfile(tablesRoot,'freeze_hash_manifest.csv'));
writetable(struct2table(regression), ...
    fullfile(tablesRoot,'regression_summary.csv'));

cycleNames = ["A_FULL","A_NO_WEIGHT", ...
    "A_BACKGROUND_ONLY","A_FIXED_LAMBDA"];
for variant = cycleNames
    writetable(results05F.(char(variant)).tracker.cycle, ...
        fullfile(diagnosticsRoot,'Case05_'+variant+'_cycle.csv'));
end

schemaVersion = definition.schema_version;
workspacePath = fullfile(workspaceRoot,'step6_ablation_workspace.mat');
result = struct('schema_version',schemaVersion,'definition',definition, ...
    'cfg',cfg,'case02',case02,'case05',case05,'case07',case07, ...
    'case08',case08,'equivalence',equivalence,'regression',regression, ...
    'hashes',hashes,'metadata',metadata,'validation',validation);
save(workspacePath,'schemaVersion','definition','cfg','case02','case05', ...
    'case07','case08','equivalence','regression','hashes','metadata', ...
    'validation','result','-v7.3');
assert_protected_unchanged(protectedBefore);

disp(case02); disp(case05); disp(case07.summary); disp(case08.summary);
disp(case08.gate); disp(equivalence);
fprintf('STEP6_FORMAL_VALIDATOR=%d/%d\n', ...
    regression.formal_pass_count,regression.formal_check_count);
fprintf('STEP6_HISTORICAL_REGRESSION=%d/%d\n', ...
    regression.historical_pass_count,regression.historical_check_count);
fprintf('STEP6_NO_WEIGHT_EQUIVALENCE=%d/%d\n', ...
    nnz(equivalence.pass),height(equivalence));
fprintf('STEP6_WORKSPACE=%s\n',workspacePath);
fprintf('STEP6_EXECUTION_STATUS=%s\n', ...
    string(ternary(validation.overall_pass,'PASS','FAIL')));
end

function results = run_variants(data,ref,cfg,selfPF,variants)
results = struct();
for variant = variants.'
    fprintf('STEP6_ALGORITHM_START variant=%s branch=%s\n', ...
        variant,string(field_or(data,'branch','single')));
    switch variant
        case {"M2","M3"}
            current = run_phase1a_algorithm(variant,data,ref,cfg,selfPF);
        case "A_FULL"
            current = run_phase1a_algorithm("M4",data,ref,cfg,selfPF);
            current.algorithm_mode = variant;
        case "A_NO_WEIGHT"
            tracker = track_coupling_m4_weighted_rls(data,ref,cfg,selfPF, ...
                struct('forced_update_weight',1, ...
                'direction_diagnostics_enabled',false));
            current = result_from_tracker(variant,data,ref,selfPF,tracker);
        otherwise
            tracker = track_phase1c_step6_ablation( ...
                data,ref,cfg,selfPF,variant);
            current = result_from_tracker(variant,data,ref,selfPF,tracker);
    end
    results.(char(variant)) = current;
end
end

function result = result_from_tracker(mode,data,ref,selfPF,tracker)
result = struct('algorithm_mode',mode,'algorithm_name',mode, ...
    'c0',tracker.hist(1,:).','cHist',tracker.hist, ...
    'ir',extract_resistive_current(data,ref,selfPF,tracker.hist), ...
    'tracker',tracker);
end

function tableOut = evaluate_case02(definition,cfg,data,results)
variants = definition.variants;
idx = data.t >= definition.windows.case02_metric(1) & ...
    data.t <= definition.windows.case02_metric(2);
truthEndpoints1 = [data.Cs1(1),data.Cs1(end)];
truthEndpoints2 = [data.Cs2(1),data.Cs2(end)];
trueMid1 = midpoint_time(data.t,data.Cs1,1.0,truthEndpoints1);
trueMid2 = midpoint_time(data.t,data.Cs2,1.0,truthEndpoints2);
rows = cell(numel(variants),1);
for k = 1:numel(variants)
    variant = variants(k); current = results.(char(variant));
    cycle = current.tracker.cycle;
    g = update_weight(variant,cycle);
    estMid1 = midpoint_time(data.t,current.cHist(:,1),1.0,truthEndpoints1);
    estMid2 = midpoint_time(data.t,current.cHist(:,2),1.0,truthEndpoints2);
    rows{k} = table(variant, ...
        sqrt(mean((current.cHist(idx,1)-data.Cs1(idx)).^2)), ...
        sqrt(mean((current.cHist(idx,2)-data.Cs2(idx)).^2)), ...
        100*(fundamental_rms(data.t(idx),current.ir.B(idx),cfg.f)/ ...
        fundamental_rms(data.t(idx),data.irB(idx),cfg.f)-1), ...
        mean(g),mean(1-g),estMid1-trueMid1,estMid2-trueMid2, ...
        'VariableNames',{'variant','Cs1_RMSE_pF','Cs2_RMSE_pF', ...
        'B_resistive_error_pct','mean_g','USR', ...
        'Cs1_tracking_lag_s','Cs2_tracking_lag_s'});
end
tableOut = vertcat(rows{:});
end

function tableOut = evaluate_case05( ...
        definition,cfg,dataF,dataCF,resultsF,resultsCF)
variants = definition.variants;
pre = sample_window(dataF.t,definition.windows.case05_pre);
fault = sample_window(dataF.t,definition.windows.case05_fault);
trueFactor = fundamental_rms(dataF.t(fault),dataF.irB(fault),cfg.f)/ ...
    fundamental_rms(dataF.t(pre),dataF.irB(pre),cfg.f);
m2FaultDelta = fault_delta(resultsF.M2.cHist,resultsCF.M2.cHist,pre,fault);
rows = cell(numel(variants),1);
for k = 1:numel(variants)
    variant = variants(k); f = resultsF.(char(variant));
    cf = resultsCF.(char(variant));
    delta = fault_delta(f.cHist,cf.cHist,pre,fault);
    estFactor = fundamental_rms(dataF.t(fault),f.ir.B(fault),cfg.f)/ ...
        fundamental_rms(dataF.t(pre),f.ir.B(pre),cfg.f);
    cycle = f.tracker.cycle;
    cycleFault = cycle.time_s >= definition.windows.case05_fault(1) & ...
        cycle.time_s < definition.windows.case05_fault(2);
    g = update_weight(variant,cycle);
    [latency,isrJ,isrH] = information_metrics( ...
        variant,cycle,definition.windows.case05_pre, ...
        definition.windows.case05_onset_s,cycleFault);
    rows{k} = table(variant,trueFactor,estFactor, ...
        100*(estFactor-trueFactor)/trueFactor,delta(1),delta(2), ...
        norm(delta)/(norm(m2FaultDelta)+eps),mean(g(cycleFault)), ...
        latency,isrJ,isrH,sum(active_column(cycle,'rate_limit_active')), ...
        sum(active_column(cycle,'projection_active')), ...
        'VariableNames',{'variant','fault_factor_true','fault_factor_est', ...
        'retention_error_pct','fault_induced_DeltaCs1_pF', ...
        'fault_induced_DeltaCs2_pF','PAR_norm','fault_mean_g', ...
        'material_latency_s','ISR_J_fault','ISR_h_fault', ...
        'rate_limit_cycles','projection_cycles'});
end
tableOut = vertcat(rows{:});
end

function evaluated = evaluate_overlap( ...
        caseDefinition,cfg,dataF,dataCF,resultsF,resultsCF,gateInterval)
variants = fieldnames(resultsF); variants = string(variants);
windowNames = ["W1","W2"];
windowRows = cell(numel(variants)*2,1); row = 0;
summaryRows = cell(numel(variants),1);
gateRows = cell(numel(variants),1);
for k = 1:numel(variants)
    variant = variants(k); f = resultsF.(char(variant));
    cf = resultsCF.(char(variant));
    deltaAll = f.cHist-cf.cHist;
    retention = zeros(2,1);
    biasNorm = zeros(2,1);
    for w = 1:2
        window = caseDefinition.windows( ...
            caseDefinition.windows.window == windowNames(w),:);
        idx = dataF.t >= window.start_s & dataF.t < window.end_s;
        delta = deltaAll(idx,:);
        trueIncrement = fundamental_rms(dataF.t(idx),dataF.irB(idx),cfg.f)- ...
            fundamental_rms(dataCF.t(idx),dataCF.irB(idx),cfg.f);
        estimatedIncrement = fundamental_rms(dataF.t(idx),f.ir.B(idx),cfg.f)- ...
            fundamental_rms(dataCF.t(idx),cf.ir.B(idx),cfg.f);
        retention(w) = estimatedIncrement/(trueIncrement+eps);
        biasNorm(w) = sqrt(mean(sum(delta.^2,2)));
        row = row+1;
        windowRows{row} = table(variant,windowNames(w), ...
            mean(delta(:,1)),mean(delta(:,2)),biasNorm(w),retention(w), ...
            'VariableNames',{'variant','window', ...
            'mean_fault_DeltaCs1_pF','mean_fault_DeltaCs2_pF', ...
            'fault_induced_RMS_norm_pF','fault_increment_retention_ratio'});
    end
    overlapCycle = cycle_window(f.tracker.cycle.time_s, ...
        caseDefinition.windows,["W1","W2"]);
    g = update_weight(variant,f.tracker.cycle);
    post = dataF.t >= caseDefinition.fault.clear_s & dataF.t < 2.80;
    memoryAuc = trapz(dataF.t(post),vecnorm(deltaAll(post,:),2,2));
    summaryRows{k} = table(variant,mean(biasNorm),mean(retention), ...
        mean(g(overlapCycle)),memoryAuc, ...
        'VariableNames',{'variant','mean_fault_bias_RMS_norm_pF', ...
        'mean_fault_increment_retention_ratio','overlap_mean_g', ...
        'post_fault_memory_AUC_pF_s'});
    if all(isfinite(gateInterval))
        startIndex = find(dataF.t <= gateInterval(1),1,'last');
        endIndex = find(dataF.t <= gateInterval(2),1,'last');
        deltaF = f.cHist(endIndex,:)-f.cHist(startIndex,:);
        deltaCF = cf.cHist(endIndex,:)-cf.cHist(startIndex,:);
        deltaFault = deltaF-deltaCF;
        gateRows{k} = table(variant,deltaF(1),deltaF(2),norm(deltaF), ...
            deltaCF(1),deltaCF(2),norm(deltaCF), ...
            deltaFault(1),deltaFault(2),norm(deltaFault), ...
            vector_cosine(deltaCF,deltaFault), ...
            'VariableNames',{'variant','F_delta_Cs1_pF','F_delta_Cs2_pF', ...
            'F_movement_norm_pF','CF_delta_Cs1_pF','CF_delta_Cs2_pF', ...
            'CF_movement_norm_pF','fault_delta_Cs1_pF', ...
            'fault_delta_Cs2_pF','fault_movement_norm_pF', ...
            'cosine_CF_vs_fault'});
    end
end
evaluated = struct('summary',vertcat(summaryRows{:}), ...
    'windows',vertcat(windowRows{:}));
if all(isfinite(gateInterval))
    evaluated.gate = vertcat(gateRows{:});
else
    evaluated.gate = table();
end
end

function [startTime,endTime,ratio] = m3_gate_interval(definition,cycle)
active = logical(cycle.gate);
first = find(active & cycle.time_s >= definition.fault.onset_s,1,'first');
if isempty(first), error('Phase1C:Step6M3Gate','Case08 M3 did not trigger.'); end
last = first;
while last < height(cycle) && active(last+1), last = last+1; end
startTime = cycle.time_s(first); endTime = cycle.time_s(last);
overlap = cycle_window(cycle.time_s,definition.windows,["W1","W2"]);
ratio = mean(active(overlap));
end

function tableOut = no_weight_equivalence(labels,resultSets)
rows = cell(numel(labels),1);
for k = 1:numel(labels)
    current = resultSets{k};
    parameterDifference = max(abs( ...
        current.M2.cHist-current.A_NO_WEIGHT.cHist),[],'all');
    currentDifference = max(abs( ...
        current.M2.ir.B-current.A_NO_WEIGHT.ir.B));
    rows{k} = table(string(labels{k}),parameterDifference,currentDifference, ...
        parameterDifference == 0 && currentDifference == 0, ...
        'VariableNames',{'condition','max_parameter_difference_pF', ...
        'max_B_current_difference_A','pass'});
end
tableOut = vertcat(rows{:});
end

function [latency,isrJ,isrH] = information_metrics( ...
        variant,cycle,preWindow,onset,cycleFault)
if ~ismember('update_weight',cycle.Properties.VariableNames)
    latency = NaN; isrJ = NaN; isrH = NaN; return
end
suppression = 1-cycle.update_weight;
pre = cycle.time_s >= preWindow(1) & cycle.time_s < preWindow(2);
med = median(suppression(pre)); madValue = median(abs(suppression(pre)-med));
threshold = max(prctile(suppression(pre),95), ...
    med+max(3*madValue,100*eps(max(1,abs(med)))));
candidate = suppression > threshold & cycle.time_s >= onset;
first = first_consecutive(candidate,2);
if isnan(first), latency = NaN; else, latency = cycle.time_s(first)-onset; end
rawJ = cycle.J_increment_norm_raw(cycleFault);
rawH = cycle.h_increment_norm_raw(cycleFault);
isrJ = 1-sum(cycle.J_increment_norm_applied(cycleFault))/(sum(rawJ)+eps);
isrH = 1-sum(cycle.h_increment_norm_applied(cycleFault))/(sum(rawH)+eps);
if variant == "A_NO_WEIGHT", isrJ = 0; isrH = 0; end
end

function delta = fault_delta(cF,cCF,pre,fault)
delta = (mean(cF(fault,:),1)-mean(cF(pre,:),1))- ...
    (mean(cCF(fault,:),1)-mean(cCF(pre,:),1));
end

function g = update_weight(variant,cycle)
if ismember('update_weight',cycle.Properties.VariableNames)
    g = cycle.update_weight;
elseif variant == "M3"
    g = 1-double(cycle.gate > 0);
else
    g = ones(height(cycle),1);
end
end

function values = active_column(cycle,name)
if ismember(name,cycle.Properties.VariableNames)
    values = cycle.(name);
else
    values = false(height(cycle),1);
end
end

function ref = make_ref(data,cfg)
ref = reconstruct_refs_from_b(data.t,data.ub,cfg.f, ...
    cfg.init_start,cfg.init_end,cfg.phase_error_deg);
end

function data = remove_case05_fault(data,cfg)
signals = generate_coupling_signals(data.t,'fault_only',106);
scale = signals.fault_scale;
% Reproduce the frozen Step 4 counterfactual exactly: the monitored
% B-phase resistive fault component is removed; A/C remain unchanged.
increment = (1-1./scale).*data.irB;
data.irB = data.irB-increment;
data.ib = data.ib-increment;
data.branch = 'CF'; data.scenario = 'Case05_fault_only_counterfactual';
assert(max(abs(scale-1.6)) < 0.61);
assert(cfg.SNR_dB == 30);
end

function noise = derive_case06_noise(cfg,seed)
noisyCfg = cfg; noisyCfg.SNR_dB = 30;
cleanCfg = cfg; cleanCfg.SNR_dB = Inf;
[noisy,~] = simulate_phase2_case(noisyCfg,'fault_with_drift',seed);
[clean,~] = simulate_phase2_case(cleanCfg,'fault_with_drift',seed);
noise = struct('A',noisy.ia-clean.ia, ...
    'B',noisy.ib-clean.ib,'C',noisy.ic-clean.ic);
end

function regression = validate_regression(projectRoot)
formal = load(fullfile(projectRoot,'paper_research', ...
    'phase1a_baseline','baseline_workspace.mat'),'validation');
checks = formal.validation.checks;
historical = run_phase1a_step7_regression();
regression = struct( ...
    'formal_check_count',height(checks), ...
    'formal_pass_count',nnz(checks.pass), ...
    'formal_pass',height(checks) == 19 && all(checks.pass), ...
    'historical_check_count',height(historical.regression), ...
    'historical_pass_count',nnz(historical.regression.pass), ...
    'historical_pass',historical.historical_results_reproduced);
end

function hashes = freeze_hashes(projectRoot,matlabRoot,phase1cRoot,step6Root)
paths = [ ...
    string(fullfile(matlabRoot,'track_coupling_m4_weighted_rls.m')); ...
    string(fullfile(matlabRoot,'m4_fault_evidence.m')); ...
    string(fullfile(matlabRoot,'phase1a_algorithm_registry.m')); ...
    string(fullfile(matlabRoot,'patent_default_config.m')); ...
    string(fullfile(matlabRoot,'AI6109_MOA_AutoComp9.slx')); ...
    string(fullfile(phase1cRoot,'step5_simultaneous_drift_fault', ...
        'CASE07_SPECIFICATION.md')); ...
    string(fullfile(phase1cRoot,'step5b_triggered_overlap', ...
        'CASE08_SPECIFICATION.md')); ...
    string(fullfile(step6Root,'phase1c_step6_definition.m')); ...
    string(fullfile(step6Root,'track_phase1c_step6_ablation.m'))];
roles = ["source";"evidence_helper";"registry";"configuration"; ...
    "model";"case07_specification";"case08_specification"; ...
    "step6_definition";"ablation_only_source"];
sha256 = strings(size(paths));
for k = 1:numel(paths), sha256(k) = step6_file_sha256(paths(k)); end
relative_path = erase(paths,string(projectRoot)+filesep);
hashes = table(roles,relative_path,sha256);
end

function metadata = capture_metadata(matlabRoot,cfg,hashes)
simulinkInfo = ver('simulink');
metadata = struct( ...
    'run_timestamp',string(datetime('now','TimeZone','Asia/Shanghai', ...
        'Format',"yyyy-MM-dd'T'HH:mm:ssXXX")), ...
    'matlab_version',string(version), ...
    'simulink_version',string(simulinkInfo.Version), ...
    'platform',string(computer), ...
    'model',string(cfg.model), ...
    'model_sha256',hashes.sha256(hashes.roles == "model"), ...
    'matlab_root',string(matlabRoot));
end

function protected = capture_protected_files( ...
        projectRoot,matlabRoot,phase1cRoot,step6Root)
paths = strings(0,1);
files = [dir(fullfile(matlabRoot,'*.m'));dir(fullfile(matlabRoot,'*.slx')); ...
    dir(fullfile(matlabRoot,'tests','*.m'))];
for k = 1:numel(files)
    paths(end+1,1) = string(fullfile(files(k).folder,files(k).name)); %#ok<AGROW>
end
roots = [string(fullfile(projectRoot,'paper_research','phase1a_baseline')); ...
    string(fullfile(projectRoot,'paper_research','phase1b_fault_absorption')); ...
    string(phase1cRoot)];
for root = roots.'
    files = dir(fullfile(root,'**','*')); files = files(~[files.isdir]);
    for k = 1:numel(files)
        path = string(fullfile(files(k).folder,files(k).name));
        if startsWith(path,string(step6Root)) || ...
                endsWith(path,'STEP6_ABLATION_AND_FREEZE.md') || ...
                endsWith(path,'PHASE1C_M4_METHOD_REPORT.md')
            continue
        end
        paths(end+1,1) = path; %#ok<AGROW>
    end
end
paths = unique(paths,'stable'); sha256 = strings(size(paths));
for k = 1:numel(paths), sha256(k) = step6_file_sha256(paths(k)); end
protected = table(paths,sha256);
end

function assert_protected_unchanged(protected)
for k = 1:height(protected)
    if step6_file_sha256(protected.paths(k)) ~= protected.sha256(k)
        error('Phase1C:Step6ProtectedFile', ...
            'Protected file changed: %s.',protected.paths(k));
    end
end
end

function idx = sample_window(time,window)
idx = time >= window(1) & time < window(2);
if ~any(idx), error('Phase1C:Step6Window','Empty sample window.'); end
end

function idx = cycle_window(time,windows,names)
idx = false(size(time));
for name = names
    window = windows(windows.window == name,:);
    idx = idx | (time >= window.start_s & time < window.end_s);
end
if ~any(idx), error('Phase1C:Step6CycleWindow','Empty cycle window.'); end
end

function value = fundamental_rms(time,signal,frequency)
omega = 2*pi*frequency;
coefficients = [sin(omega*time),cos(omega*time),ones(size(time))]\signal;
value = hypot(coefficients(1),coefficients(2))/sqrt(2);
end

function value = midpoint_time(time,signal,onset,endpoints)
target = mean(endpoints);
direction = sign(endpoints(2)-endpoints(1));
hit = direction*(signal-target) >= 0;
index = find(hit & time >= onset,1,'first');
if isempty(index), value = NaN; else, value = time(index); end
end

function index = first_consecutive(mask,count)
index = NaN;
for k = 1:numel(mask)-count+1
    if all(mask(k:k+count-1)), index = k; return; end
end
end

function value = vector_cosine(a,b)
if norm(a) <= sqrt(eps) || norm(b) <= sqrt(eps)
    value = NaN;
else
    value = dot(a,b)/(norm(a)*norm(b));
end
end

function value = field_or(input,name,defaultValue)
if isfield(input,name), value = input.(name); else, value = defaultValue; end
end

function ensure_directories(paths)
for path = paths, if ~isfolder(path), mkdir(path); end, end
end

function value = ternary(condition,trueValue,falseValue)
if condition, value = trueValue; else, value = falseValue; end
end
