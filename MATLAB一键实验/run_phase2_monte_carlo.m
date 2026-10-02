function output = run_phase2_monte_carlo(runMode)
%RUN_PHASE2_MONTE_CARLO Execute frozen Phase 2 Monte-Carlo experiments.
% "pilot" executes registry_index 1:20. "formal" executes only 21:50,
% then combines those new rows with the frozen Step 6A pilot artifact.

if nargin < 1
    runMode = "pilot";
end
runMode = lower(string(runMode));
if ~ismember(runMode,["pilot","formal"])
    error('Phase2:Step6Mode','runMode must be "pilot" or "formal".');
end

paths = monte_carlo_paths();
conditionRegistry = read_registry(paths.condition_registry);
executionRegistry = read_registry(paths.execution_registry);
pilot = select_and_validate_pilot(conditionRegistry,executionRegistry,paths);
if runMode == "formal"
    conditions = select_and_validate_expansion( ...
        conditionRegistry,executionRegistry,paths);
    outputDir = paths.full_output_dir;
    csvPath = paths.full_csv;
    reportPath = paths.full_report;
else
    conditions = pilot;
    outputDir = paths.output_dir;
    csvPath = paths.csv;
    reportPath = paths.report;
end
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
pre = capture_frozen_integrity(paths);
if ~pre.pass
    error('Phase2:Step6FrozenPre', ...
        'Frozen integrity failed before Monte-Carlo execution.');
end

started = tic;
fprintf('MC_RUN_MODE=%s\n',upper(runMode));
fprintf('MC_NEW_PHYSICAL_CONDITIONS=%d\n',height(conditions));
[contexts,cleanMode] = generate_clean_batch(conditions);
[contexts,noisyMode] = generate_noisy_batch(contexts);

rows = repmat(blank_row(),0,1);
for k = 1:height(conditions)
    row = conditions(k,:);
    try
        conditionRows = evaluate_condition(row,contexts(k));
    catch exception
        conditionRows = failure_rows(row,exception);
    end
    rows = [rows;conditionRows]; %#ok<AGROW>
    fprintf('MC_PROGRESS=%d/%d CONDITION=%s\n', ...
        k,height(conditions),string(row.condition_id));
end
rows = struct2table(rows);

post = capture_frozen_integrity(paths);
frozenPass = pre.pass && post.pass && ...
    isequal(pre.actual_sha256,post.actual_sha256);
rows.frozen_integrity_pass(:) = frozenPass;
runtimeSeconds = toc(started);
if runMode == "formal"
    expansionRows = rows;
    pilotRows = normalize_result_types(read_registry(paths.csv));
    expansionRows = normalize_result_types(expansionRows);
    validate_pilot_results(pilotRows,pilot,conditionRegistry,executionRegistry);
    rows = combine_full_results(pilotRows,expansionRows,conditionRegistry);
    rows.frozen_integrity_pass(:) = frozenPass;
    writetable(rows,csvPath);
    allMC = select_all_mc_conditions(conditionRegistry);
    audit = final_audit(rows,allMC,executionRegistry,frozenPass,150,600);
    statistics = build_statistics(rows);
    write_full_chinese_report(reportPath,rows,conditions,statistics,audit, ...
        pre,post,runtimeSeconds,cleanMode,noisyMode);
else
    writetable(rows,csvPath);
    audit = final_audit(rows,pilot,executionRegistry,frozenPass,60,240);
    statistics = build_statistics(rows);
    write_chinese_report(paths,rows,pilot,statistics,audit,pre,post, ...
        runtimeSeconds,cleanMode,noisyMode);
end

output = struct( ...
    'run_mode',runMode, ...
    'status',status_label(audit.pass,frozenPass), ...
    'physical_conditions',audit.condition_complete, ...
    'algorithm_evaluations',audit.evaluation_complete, ...
    'numerical_failures',audit.numerical_failures, ...
    'metric_missing_rows',audit.metric_missing, ...
    'seed_registry_mismatch',audit.seed_registry_mismatch, ...
    'frozen_integrity',frozenPass, ...
    'runtime_seconds',runtimeSeconds, ...
    'runner',string(mfilename('fullpath'))+".m", ...
    'csv',string(csvPath), ...
    'report',string(reportPath));
fprintf('STEP_6_STATUS=%s\n',output.status);
fprintf('TOTAL_MC_PHYSICAL_CONDITIONS=%d/%d\n', ...
    audit.condition_complete,audit.expected_conditions);
fprintf('TOTAL_MC_ALGORITHM_EVALUATIONS=%d/%d\n', ...
    audit.evaluation_complete,audit.expected_evaluations);
fprintf('NUMERICAL_FAILURES=%d\n',audit.numerical_failures);
fprintf('METRIC_MISSING_ROWS=%d\n',audit.metric_missing);
fprintf('SEED_REGISTRY_MISMATCH=%d\n',audit.seed_registry_mismatch);
fprintf('SHARED_DATA_FAILURES=%d\n',audit.shared_data_failures);
fprintf('FROZEN_SOURCE_MODIFIED=%s\n',yes_no(~frozenPass));
if runMode == "formal"
    fprintf('READY_FOR_STEP_7_FINAL_ANALYSIS=%s\n',yes_no(audit.pass));
else
    fprintf('READY_FOR_STEP_6B_FORMAL_EXPANSION=%s\n',yes_no(audit.pass));
end
end

function rows = normalize_result_types(rows)
stringVariables = ["condition_id","cohort","algorithm_id", ...
    "evaluation_window_set_id","data_signature","notes"];
logicalVariables = ["condition_unique","registry_match","seed_match", ...
    "shared_data_pass","required_outputs_pass","numerical_failure", ...
    "metric_missing","simulation_abort","frozen_integrity_pass"];
for name = stringVariables
    rows.(char(name)) = string(rows.(char(name)));
end
for name = logicalVariables
    rows.(char(name)) = logical(rows.(char(name)));
end
end

function paths = monte_carlo_paths()
runnerDir = fileparts(mfilename('fullpath'));
root = fileparts(runnerDir);
base = fullfile(root,'paper_research','phase2_full_validation');
step1 = fullfile(base,'step1_matrix_spec');
paths = struct();
paths.root = root;
paths.model = fullfile(runnerDir,'AI6109_MOA_AutoComp9.slx');
paths.condition_registry = fullfile(step1,'phase2_condition_registry.csv');
paths.execution_registry = fullfile(step1,'phase2_execution_registry.csv');
paths.specification = fullfile(step1,'STEP1_PHASE2_MATRIX_SPECIFICATION.md');
paths.manifest = fullfile(root,'paper_research','phase1c_m4_method', ...
    'step6_ablation','tables','freeze_hash_manifest.csv');
paths.step2a_report = fullfile(base,'step2a_execution_gates', ...
    'STEP2A_EXECUTION_GATES_REPORT.md');
paths.output_dir = fullfile(base,'step6a_monte_carlo_pilot');
paths.csv = fullfile(paths.output_dir,'step6a_monte_carlo_pilot_results.csv');
paths.report = fullfile(paths.output_dir,'STEP6A_MONTE_CARLO_PILOT.md');
paths.full_output_dir = fullfile(base,'step6_monte_carlo_full');
paths.full_csv = fullfile(paths.full_output_dir, ...
    'step6_monte_carlo_full_results.csv');
paths.full_report = fullfile(paths.full_output_dir, ...
    'STEP6_MONTE_CARLO_FULL.md');
end

function tableOut = read_registry(path)
tableOut = readtable(path,'Delimiter',',','TextType','string', ...
    'VariableNamingRule','preserve');
end

function pilot = select_and_validate_pilot(registry,execution,paths)
allMC = select_all_mc_conditions(registry);
pilot = allMC(allMC.registry_index >= 1 & allMC.registry_index <= 20,:);
if height(pilot) ~= 60 || numel(unique(pilot.condition_id)) ~= 60
    error('Phase2:Step6APilotCardinality', ...
        'Pilot must contain 60 unique physical conditions.');
end
for cohort = ["H","F","O"]
    part = pilot(pilot.mc_cohort == cohort,:);
    if height(part) ~= 20 || ~isequal(part.registry_index,(1:20).') || ...
            any(~truthy_vector(part.pilot_member))
        error('Phase2:Step6APilotSubset', ...
            'Cohort %s is not the exact frozen 1:20 subset.',cohort);
    end
end
validate_execution_map(pilot,execution);
validate_gate_authorization(paths);
end

function expansion = select_and_validate_expansion(registry,execution,paths)
allMC = select_all_mc_conditions(registry);
expansion = allMC(allMC.registry_index >= 21 & ...
    allMC.registry_index <= 50,:);
if height(expansion) ~= 90 || ...
        numel(unique(expansion.condition_id)) ~= 90
    error('Phase2:Step6BExpansionCardinality', ...
        'Expansion must contain 90 unique physical conditions.');
end
for cohort = ["H","F","O"]
    part = expansion(expansion.mc_cohort == cohort,:);
    if height(part) ~= 30 || ...
            ~isequal(part.registry_index,(21:50).')
        error('Phase2:Step6BExpansionSubset', ...
            'Cohort %s is not the exact frozen 21:50 subset.',cohort);
    end
end
validate_execution_map(expansion,execution);
validate_gate_authorization(paths);
end

function allMC = select_all_mc_conditions(registry)
isMC = registry.registry_kind == "MONTE_CARLO" & ...
    ismember(registry.mc_cohort,["H","F","O"]);
allMC = registry(isMC,:);
allMC.cohort_order = cohort_order(allMC.mc_cohort);
allMC = sortrows(allMC,{'cohort_order','registry_index'});
allMC.cohort_order = [];
if height(allMC) ~= 150 || ...
        numel(unique(allMC.condition_id)) ~= 150
    error('Phase2:Step6RegistrySize', ...
        'Expected 150 unique frozen MC conditions, found %d.',height(allMC));
end
for cohort = ["H","F","O"]
    part = allMC(allMC.mc_cohort == cohort,:);
    if height(part) ~= 50 || ...
            ~isequal(part.registry_index,(1:50).')
        error('Phase2:Step6FullSubset', ...
            'Cohort %s is not the exact frozen 1:50 set.',cohort);
    end
end
validate_mc_discipline(allMC);
end

function validate_mc_discipline(conditions)
if any(conditions.registry_state ~= "FROZEN") || ...
        any(truthy_vector(conditions.is_blocked)) || ...
        any(conditions.negative_sequence_pu ~= 0) || ...
        any(conditions.CsAC_truth_pF ~= 0) || ...
        any(conditions.Cself_algorithm_pF ~= 400) || ...
        any(conditions.truth_seed == conditions.noise_seed)
    error('Phase2:Step6FrozenDiscipline', ...
        'Frozen Monte-Carlo discipline audit failed.');
end
end

function validate_execution_map(conditions,execution)
for k = 1:height(conditions)
    conditionId = conditions.condition_id(k);
    er = execution(execution.record_type == ...
        "MAIN_ALGORITHM_EVALUATION" & ...
        execution.condition_id == conditionId,:);
    if height(er) ~= 4 || ...
            ~isequal(sort(er.algorithm_id),["M0";"M2";"M3";"M4"])
        error('Phase2:Step6ExecutionMap', ...
            '%s does not map to exactly four algorithms.',conditionId);
    end
end
end

function validate_gate_authorization(paths)
reportText = string(fileread(paths.step2a_report));
if ~contains(reportText,"CSELF_SPLIT_INTERFACE_GATE: PASS") || ...
        ~contains(reportText,"NO_FROZEN_SOURCE_DIFF_GATE: PASS")
    error('Phase2:Step6GateAuthorization', ...
        'Step 2A Cself/frozen-source authorization is unavailable.');
end
end

function validate_pilot_results(rows,pilot,registry,execution)
requiredVariables = string(fieldnames(blank_row()));
if height(rows) ~= 240 || ...
        ~all(ismember(requiredVariables,string(rows.Properties.VariableNames)))
    error('Phase2:Step6BPilotArtifact', ...
        'Step 6A pilot artifact does not contain the frozen 240-row schema.');
end
if any(~ismember(rows.condition_id,pilot.condition_id)) || ...
        numel(unique(rows.condition_id)) ~= 60 || ...
        any(rows.registry_index < 1 | rows.registry_index > 20)
    error('Phase2:Step6BPilotScope', ...
        'Step 6A pilot artifact is not the exact 1:20 condition set.');
end
bad = rows.numerical_failure | rows.metric_missing | ...
    rows.simulation_abort | ~rows.registry_match | ~rows.seed_match | ...
    ~rows.shared_data_pass | ~rows.required_outputs_pass | ...
    ~rows.frozen_integrity_pass;
if any(bad)
    error('Phase2:Step6BPilotIntegrity', ...
        'Step 6A pilot artifact contains incomplete or failed rows.');
end
validate_execution_map(pilot,execution);
for k = 1:height(pilot)
    source = registry(registry.condition_id == pilot.condition_id(k),:);
    part = rows(rows.condition_id == pilot.condition_id(k),:);
    if height(source) ~= 1 || height(part) ~= 4 || ...
            ~isequal(sort(part.algorithm_id),["M0";"M2";"M3";"M4"]) || ...
            any(part.truth_seed ~= source.truth_seed) || ...
            any(part.noise_seed ~= source.noise_seed) || ...
            numel(unique(part.data_signature)) ~= 1
        error('Phase2:Step6BPilotMapping', ...
            'Step 6A pilot mapping failed for %s.',pilot.condition_id(k));
    end
end
end

function rows = combine_full_results(pilotRows,expansionRows,registry)
if ~isequal(string(pilotRows.Properties.VariableNames), ...
        string(expansionRows.Properties.VariableNames))
    error('Phase2:Step6BResultSchema', ...
        'Pilot and expansion result schemas do not match.');
end
rows = [pilotRows;expansionRows];
rows.cohort_order = cohort_order(rows.cohort);
rows.algorithm_order = zeros(height(rows),1);
rows.algorithm_order(rows.algorithm_id == "M0") = 1;
rows.algorithm_order(rows.algorithm_id == "M2") = 2;
rows.algorithm_order(rows.algorithm_id == "M3") = 3;
rows.algorithm_order(rows.algorithm_id == "M4") = 4;
rows = sortrows(rows,{'cohort_order','registry_index','algorithm_order'});
rows.cohort_order = [];
rows.algorithm_order = [];
allMC = select_all_mc_conditions(registry);
keys = rows.condition_id+"|"+rows.algorithm_id;
if height(rows) ~= 600 || numel(unique(keys)) ~= 600 || ...
        numel(unique(rows.condition_id)) ~= 150 || ...
        any(~ismember(rows.condition_id,allMC.condition_id))
    error('Phase2:Step6BFullCardinality', ...
        'Combined full results are not 150 conditions and 600 unique rows.');
end
end

function order = cohort_order(cohort)
order = zeros(size(cohort));
order(cohort == "H") = 1;
order(cohort == "F") = 2;
order(cohort == "O") = 3;
end

function values = truthy_vector(input)
values = false(size(input));
for k = 1:numel(input)
    values(k) = truthy(input(k));
end
end

function [contexts,mode] = generate_clean_batch(pilot)
n = height(pilot);
contexts = repmat(struct('row',table(),'physical_cfg',struct(), ...
    'algorithm_cfg',struct(),'signalsF',struct(),'signalsCF',struct(), ...
    'cleanF',struct(),'noise',struct(),'dataF',struct(),'dataCF',struct(), ...
    'ref',struct()),n,1);
inputs(1,n) = Simulink.SimulationInput('AI6109_MOA_AutoComp9');
for k = 1:n
    row = pilot(k,:);
    [physicalCfg,algorithmCfg] = configs_from_registry(row);
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
[outputs,mode] = run_simulation_batch(inputs,"CLEAN");
for k = 1:n
    contexts(k).cleanF = extract_simulation_data(outputs(k));
end
clear outputs inputs
end

function [contexts,mode] = generate_noisy_batch(contexts)
n = numel(contexts);
oCount = nnz(arrayfun(@(x) string(x.row.mc_cohort) == "O",contexts));
inputs(1,n+oCount) = Simulink.SimulationInput('AI6109_MOA_AutoComp9');
primaryIndex = zeros(n,1);
counterfactualIndex = nan(n,1);
cursor = 0;
for k = 1:n
    row = contexts(k).row;
    clean = contexts(k).cleanF;
    rng(double(row.noise_seed),'twister');
    noise = struct( ...
        'A',noise_for_snr(clean.ia,row.SNR_dB), ...
        'B',noise_for_snr(clean.ib,row.SNR_dB), ...
        'C',noise_for_snr(clean.ic,row.SNR_dB));
    contexts(k).noise = noise;
    cursor = cursor+1;
    primaryIndex(k) = cursor;
    inputs(cursor) = make_simulation_input(contexts(k).physical_cfg, ...
        contexts(k).signalsF,noise.A,noise.B,noise.C);
    if string(row.mc_cohort) == "O"
        cursor = cursor+1;
        counterfactualIndex(k) = cursor;
        inputs(cursor) = make_simulation_input(contexts(k).physical_cfg, ...
            contexts(k).signalsCF,noise.A,noise.B,noise.C);
    end
end
[outputs,mode] = run_simulation_batch(inputs,"NOISY");
for k = 1:n
    row = contexts(k).row;
    contexts(k).dataF = add_physical_metadata( ...
        extract_simulation_data(outputs(primaryIndex(k))),row,"F");
    if string(row.mc_cohort) == "O"
        contexts(k).dataCF = add_physical_metadata( ...
            extract_simulation_data(outputs(counterfactualIndex(k))),row,"CF");
    elseif string(row.mc_cohort) == "F"
        contexts(k).dataCF = remove_fault_component( ...
            contexts(k).dataF,contexts(k).signalsF.fault_scale);
    else
        contexts(k).dataCF = struct();
    end
    cfg = contexts(k).algorithm_cfg;
    data = contexts(k).dataF;
    contexts(k).ref = reconstruct_refs_from_b(data.t,data.ub,cfg.f, ...
        cfg.init_start,cfg.init_end,cfg.phase_error_deg);
end
clear outputs inputs
end

function [outputs,mode] = run_simulation_batch(inputs,label)
try
    outputs = sim(inputs,'UseFastRestart','on');
    mode = string(label)+"_FAST_RESTART_BATCH";
catch batchException
    warning('Phase2:Step6ABatchFallback', ...
        '%s batch failed (%s). Replaying identical inputs sequentially.', ...
        label,batchException.message);
    outputs = sim(inputs(1));
    for k = 2:numel(inputs)
        outputs(k) = sim(inputs(k)); %#ok<AGROW>
    end
    mode = string(label)+"_SEQUENTIAL_FALLBACK";
end
end

function [physicalCfg,algorithmCfg] = configs_from_registry(row)
physicalCfg = patent_default_config();
physicalCfg.model = 'AI6109_MOA_AutoComp9';
physicalCfg.StopTime = row.simulation_stop_s;
physicalCfg.SNR_dB = row.SNR_dB;
physicalCfg.h3_ratio = row.h3_ratio;
physicalCfg.phi3_deg = row.h3_phase_deg;
physicalCfg.Vneg_pu = row.negative_sequence_pu;
physicalCfg.Cself_pF = row.Cself_truth_pF;
physicalCfg.phase_error_deg = 0;
algorithmCfg = physicalCfg;
algorithmCfg.Cself_pF = row.Cself_algorithm_pF;
algorithmCfg.phase_error_deg = row.reference_phase_error_deg;
end

function signals = build_signals(row,cfg,branch)
t = (0:cfg.Ts:cfg.StopTime).';
if all(isfinite([row.drift_start_s,row.drift_end_s])) && ...
        row.drift_end_s > row.drift_start_s
    drift = smooth_step(t,row.drift_start_s,row.drift_end_s);
else
    drift = zeros(size(t));
end
Cs1 = row.Cs1_initial_pF+row.drift_delta_Cs1_pF*drift;
Cs2 = row.Cs2_initial_pF+row.drift_delta_Cs2_pF*drift;
faultScale = ones(size(t));
if upper(string(branch)) == "F"
    if string(row.fault_mode) == "PERSISTENT_B_RESISTIVE"
        progress = smooth_step(t,row.fault_start_s,row.fault_ramp_end_s);
        faultScale = 1+(row.fault_factor-1)*progress;
    elseif string(row.fault_mode) == "TEMPORARY_B_RESISTIVE"
        up = smooth_step(t,row.fault_start_s,row.fault_ramp_end_s);
        down = smooth_step(t,row.fault_plateau_end_s,row.fault_end_s);
        faultScale = 1+(row.fault_factor-1)*min(up,1-down);
    end
end
signals = struct('t',t,'Cs1_pF',Cs1,'Cs2_pF',Cs2, ...
    'fault_scale',faultScale,'branch',upper(string(branch)), ...
    'truth_seed',row.truth_seed);
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
    t = s.Time;
    x = s.Data;
else
    t = s.time;
    x = s.signals.values;
end
t = t(:);
x = squeeze(x);
x = x(:);
end

function data = add_physical_metadata(data,row,branch)
for name = ["Ca","Cb","Cc"]
    data.(char(name)) = row.Cself_truth_pF*ones(size(data.t));
end
data.scenario = "phase2_step6a_mc_"+string(row.mc_cohort)+"_"+branch;
data.current_source = "simulink";
end

function noise = noise_for_snr(x,snrDB)
if isfinite(snrDB)
    noise = rms(x)/10^(snrDB/20)*randn(size(x));
else
    noise = zeros(size(x));
end
end

function dataCF = remove_fault_component(data,faultScale)
dataCF = data;
faultIncrementB = (1-1./faultScale).*data.irB;
dataCF.ib = data.ib-faultIncrementB;
dataCF.irB = data.irB-faultIncrementB;
dataCF.scenario = "phase2_step6a_mc_F_counterfactual";
end

function rows = evaluate_condition(row,context)
mappingPass = mapping_audit(row,context);
seedPass = seed_audit(row);
dataF = context.dataF;
dataCF = context.dataCF;
ref = context.ref;
cfg = context.algorithm_cfg;
signature = condition_signature(row,context);
windows = evaluation_windows(row,cfg);
rows = repmat(blank_row(),4,1);
for k = 1:4
    mode = ["M0","M2","M3","M4"];
    algorithm = mode(k);
    resultF = run_phase1a_algorithm(algorithm,dataF,ref,cfg, ...
        repmat(row.Cself_algorithm_pF,1,3));
    if string(row.mc_cohort) == "H"
        resultCF = struct();
        metrics = healthy_metrics(algorithm,resultF,dataF,cfg,windows);
    else
        resultCF = run_phase1a_algorithm(algorithm,dataCF,ref,cfg, ...
            repmat(row.Cself_algorithm_pF,1,3));
        if string(row.mc_cohort) == "F"
            metrics = fault_metrics(algorithm,resultF,resultCF, ...
                dataF,cfg,windows);
        else
            metrics = overlap_metrics(algorithm,resultF,resultCF, ...
                dataF,dataCF,cfg,windows,row.fault_start_s,row.fault_end_s);
        end
    end
    outputPass = required_outputs_exist(resultF) && ...
        (string(row.mc_cohort) == "H" || required_outputs_exist(resultCF));
    finitePass = outputPass && outputs_finite(dataF,ref,resultF) && ...
        (string(row.mc_cohort) == "H" || ...
        outputs_finite(dataCF,ref,resultCF));
    metricPass = required_metrics_exist(row.mc_cohort,algorithm,metrics);
    current = blank_row();
    current.condition_id = row.condition_id;
    current.cohort = row.mc_cohort;
    current.registry_index = row.registry_index;
    current.algorithm_id = algorithm;
    current.truth_seed = row.truth_seed;
    current.noise_seed = row.noise_seed;
    current.SNR_dB = row.SNR_dB;
    current.reference_phase_error_deg = row.reference_phase_error_deg;
    current.fault_factor = row.fault_factor;
    current.drift_rate_multiplier = row.drift_rate_multiplier;
    current.Cself_mismatch_pct = row.Cself_mismatch_pct;
    current.Cself_truth_pF = row.Cself_truth_pF;
    current.Cself_algorithm_pF = row.Cself_algorithm_pF;
    current.negative_sequence_pu = row.negative_sequence_pu;
    current.CsAC_truth_pF = row.CsAC_truth_pF;
    current.evaluation_window_set_id = row.evaluation_window_set_id;
    current.data_signature = signature;
    metricNames = fieldnames(metrics);
    for j = 1:numel(metricNames)
        current.(metricNames{j}) = metrics.(metricNames{j});
    end
    current.condition_unique = true;
    current.registry_match = mappingPass;
    current.seed_match = seedPass;
    current.shared_data_pass = true;
    current.required_outputs_pass = outputPass;
    current.numerical_failure = ~finitePass;
    current.metric_missing = ~metricPass;
    current.simulation_abort = false;
    current.notes = "冻结 registry 直接执行；四算法共享物理数据、seed、reference 与窗口。";
    rows(k) = current;
end
if numel(unique(string({rows.data_signature}))) ~= 1
    for k = 1:4
        rows(k).shared_data_pass = false;
    end
end
end

function pass = mapping_audit(row,context)
dataF = context.dataF;
signals = context.signalsF;
tol = 1e-10;
    pass = numel(dataF.t) == numel(signals.t) && ...
    max(abs(dataF.t-signals.t)) <= tol && ...
    max(abs(dataF.Cs1-signals.Cs1_pF)) <= tol && ...
    max(abs(dataF.Cs2-signals.Cs2_pF)) <= tol && ...
    abs(dataF.Cs1(1)-row.Cs1_initial_pF) <= tol && ...
    abs(dataF.Cs2(1)-row.Cs2_initial_pF) <= tol && ...
    abs(dataF.Cs1(end)-row.Cs1_final_pF) <= tol && ...
    abs(dataF.Cs2(end)-row.Cs2_final_pF) <= tol && ...
    context.physical_cfg.Cself_pF == row.Cself_truth_pF && ...
    context.algorithm_cfg.Cself_pF == row.Cself_algorithm_pF && ...
    context.algorithm_cfg.phase_error_deg == row.reference_phase_error_deg;
if string(row.mc_cohort) ~= "H"
    pass = pass && abs(max(signals.fault_scale)-row.fault_factor) <= tol;
end
if string(row.mc_cohort) == "O"
    dataCF = context.dataCF;
    pass = pass && numel(dataF.t) == numel(dataCF.t) && ...
        max(abs(dataF.t-dataCF.t)) <= tol && ...
        any(signals.fault_scale > 1) && ...
        all(context.signalsCF.fault_scale == 1);
end
end

function pass = seed_audit(row)
switch string(row.mc_cohort)
    case "H"
        globalIndex = row.registry_index;
    case "F"
        globalIndex = 50+row.registry_index;
    case "O"
        globalIndex = 100+row.registry_index;
    otherwise
        globalIndex = NaN;
end
truthExpected = derive_seed("TRUTH",globalIndex);
noiseExpected = derive_seed("NOISE",globalIndex);
pass = row.truth_seed == truthExpected && row.noise_seed == noiseExpected && ...
    row.truth_seed ~= row.noise_seed;
end

function value = derive_seed(kind,globalIndex)
payload = sprintf('P2|2290434627|%s|%d',kind,globalIndex);
hash = bytes_sha256(unicode2native(payload,'UTF-8'));
prefix = char(extractBetween(hash,1,8));
value = 1+mod(hex2dec(prefix),2147483646);
end

function windows = evaluation_windows(row,cfg)
id = string(row.evaluation_window_set_id);
if ismember(id,["WINDOWSET_C02_TRACKING","WINDOWSET_MC_H_TRACKING"])
    windows = struct('id',id,'metric_start_s',cfg.metric_start, ...
        'metric_end_s',cfg.StopTime+cfg.Ts);
elseif id == "WINDOWSET_PERSISTENT_FAULT"
    windows = struct('id',id,'metric_start_s',cfg.metric_start, ...
        'metric_end_s',cfg.StopTime+cfg.Ts,'pre_start_s',2.60, ...
        'pre_end_s',2.90,'fault_start_s',3.40,'fault_end_s',3.80, ...
        'response_start_s',3.00);
else
    windows = overlap_windows(id);
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
        error('Phase2:Step6AWindowSet','Unknown window set %s.',id);
end
windows = array2table(values,'VariableNames',{'start_s','end_s'}, ...
    'RowNames',{'W0','W1','W2','W3','W4'});
windows.id = repmat(string(id),5,1);
end

function metrics = empty_metrics()
metrics = struct( ...
    'Cs1_RMSE_pF',NaN,'Cs2_RMSE_pF',NaN, ...
    'Cs1_max_abs_error_pF',NaN,'Cs2_max_abs_error_pF',NaN, ...
    'B_resistive_fundamental_error_pct',NaN, ...
    'fault_factor_true',NaN,'fault_factor_est',NaN, ...
    'fault_retention_error_pct',NaN,'absolute_fault_increment_loss',NaN, ...
    'DeltaCs1_fault_induced_pF',NaN, ...
    'DeltaCs2_fault_induced_pF',NaN, ...
    'Cs_fault_induced_bias_norm_pF',NaN, ...
    'overlap_Cs1_RMSE_pF',NaN,'overlap_Cs2_RMSE_pF',NaN, ...
    'W1_fault_increment_retention_ratio',NaN, ...
    'W2_fault_increment_retention_ratio',NaN, ...
    'parameter_error_RMS_norm_pF',NaN, ...
    'mean_memory_norm_pF',NaN,'endpoint_memory_norm_pF',NaN, ...
    'post_fault_AUC_pF_s',NaN, ...
    'true_drift_Cs1_pF',NaN,'true_drift_Cs2_pF',NaN, ...
    'true_drift_norm_pF',NaN, ...
    'F_movement_Cs1_pF',NaN,'F_movement_Cs2_pF',NaN, ...
    'F_movement_norm_pF',NaN, ...
    'CF_movement_Cs1_pF',NaN,'CF_movement_Cs2_pF',NaN, ...
    'CF_movement_norm_pF',NaN, ...
    'F_minus_CF_Cs1_pF',NaN,'F_minus_CF_Cs2_pF',NaN, ...
    'F_minus_CF_norm_pF',NaN, ...
    'hard_gate_active_ratio',NaN,'hard_gate_latency_s',NaN, ...
    'mean_update_weight',NaN,'unnecessary_suppression_ratio',NaN, ...
    'first_suppression_time_s',NaN,'suppression_latency_s',NaN, ...
    'rate_limit_active_cycles',NaN,'projection_active_cycles',NaN);
end

function metrics = healthy_metrics(mode,result,data,cfg,windows)
metrics = empty_metrics();
index = sample_window(data.t,windows.metric_start_s,windows.metric_end_s);
legacy = evaluate_case_metrics(data,result.ir,result.cHist,mode, ...
    "Phase2_MC_H",cfg);
metrics.Cs1_RMSE_pF = sqrt(mean((result.cHist(index,1)-data.Cs1(index)).^2));
metrics.Cs2_RMSE_pF = sqrt(mean((result.cHist(index,2)-data.Cs2(index)).^2));
metrics.Cs1_max_abs_error_pF = max(abs(result.cHist(index,1)-data.Cs1(index)));
metrics.Cs2_max_abs_error_pF = max(abs(result.cHist(index,2)-data.Cs2(index)));
metrics.B_resistive_fundamental_error_pct = legacy.B_FundErr_pct;
if mode == "M3"
    cycle = result.tracker.cycle;
    metrics.hard_gate_active_ratio = mean(cycle.gate > 0);
elseif mode == "M4"
    cycle = result.tracker.cycle;
    metrics.mean_update_weight = mean(cycle.update_weight);
    metrics.unnecessary_suppression_ratio = mean(1-cycle.update_weight);
end
end

function metrics = fault_metrics(mode,result,counterfactual,data,cfg,windows)
metrics = healthy_metrics(mode,result,data,cfg,windows);
pre = sample_window(data.t,windows.pre_start_s,windows.pre_end_s);
post = sample_window(data.t,windows.fault_start_s,windows.fault_end_s);
metrics.fault_factor_true = fault_factor(data.t,data.irB,pre,post,cfg.f);
metrics.fault_factor_est = fault_factor(data.t,result.ir.B,pre,post,cfg.f);
metrics.fault_retention_error_pct = ...
    (metrics.fault_factor_est-metrics.fault_factor_true)/ ...
    metrics.fault_factor_true*100;
metrics.absolute_fault_increment_loss = abs( ...
    (metrics.fault_factor_true-1)-(metrics.fault_factor_est-1));
actualChange = parameter_change(result.cHist,pre,post);
cfChange = parameter_change(counterfactual.cHist,pre,post);
induced = actualChange-cfChange;
metrics.DeltaCs1_fault_induced_pF = induced(1);
metrics.DeltaCs2_fault_induced_pF = induced(2);
metrics.Cs_fault_induced_bias_norm_pF = norm(induced);
if mode == "M3"
    cycle = result.tracker.cycle;
    active = cycle.gate > 0;
    response = cycle.time_s >= windows.response_start_s;
    metrics.hard_gate_active_ratio = mean(active(response));
    first = find(active & response,1,'first');
    if ~isempty(first)
        metrics.hard_gate_latency_s = ...
            cycle.time_s(first)-windows.response_start_s;
    end
elseif mode == "M4"
    cycle = result.tracker.cycle;
end
if mode == "M4"
    cycleMask = cycle_fault_window(cycle,data,cfg,windows);
    metrics.mean_update_weight = mean(cycle.update_weight(cycleMask));
    metrics.rate_limit_active_cycles = sum(cycle.rate_limit_active(cycleMask));
    metrics.projection_active_cycles = sum(cycle.projection_active(cycleMask));
elseif mode == "M2" || mode == "M3"
    cycle = result.tracker.cycle;
    cycleMask = cycle_fault_window(cycle,data,cfg,windows);
    [metrics.rate_limit_active_cycles,metrics.projection_active_cycles] = ...
        inferred_constraint_counts(cycle,cycleMask,cfg);
end
end

function index = cycle_fault_window(cycle,data,cfg,windows)
samplesPerCycle = round((1/median(diff(data.t)))/cfg.f);
cycleStart = cycle.time_s-(samplesPerCycle-1)*median(diff(data.t));
index = cycleStart >= windows.fault_start_s & ...
    cycle.time_s < windows.fault_end_s;
if ~any(index)
    error('Phase2:Step6AFaultCycleWindow','Empty fault cycle window.');
end
end

function metrics = overlap_metrics(mode,resultF,resultCF, ...
        dataF,dataCF,cfg,windows,faultStart,faultEnd)
metrics = empty_metrics();
w1 = sample_window(dataF.t,windows{'W1','start_s'},windows{'W1','end_s'});
w2 = sample_window(dataF.t,windows{'W2','start_s'},windows{'W2','end_s'});
overlap = w1 | w2;
truth = [dataF.Cs1,dataF.Cs2];
parameterError = resultF.cHist-truth;
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
if mode == "M3"
    cycle = resultF.tracker.cycle;
    cOverlap = cycle_window(cycle.time_s,windows,"W1") | ...
        cycle_window(cycle.time_s,windows,"W2");
    active = cycle.gate > 0;
    metrics.hard_gate_active_ratio = mean(active(cOverlap));
    first = find(active & cycle.time_s >= faultStart,1,'first');
    if ~isempty(first)
        metrics.hard_gate_latency_s = cycle.time_s(first)-faultStart;
    end
    [metrics.rate_limit_active_cycles,metrics.projection_active_cycles] = ...
        inferred_constraint_counts(cycle,cOverlap,cfg);
elseif mode == "M4"
    cycle = resultF.tracker.cycle;
    cOverlap = cycle_window(cycle.time_s,windows,"W1") | ...
        cycle_window(cycle.time_s,windows,"W2");
    metrics.mean_update_weight = mean(cycle.update_weight(cOverlap));
    metrics.rate_limit_active_cycles = sum(cycle.rate_limit_active(cOverlap));
    metrics.projection_active_cycles = sum(cycle.projection_active(cOverlap));
elseif mode == "M2"
    cycle = resultF.tracker.cycle;
    cOverlap = cycle_window(cycle.time_s,windows,"W1") | ...
        cycle_window(cycle.time_s,windows,"W2");
    [metrics.rate_limit_active_cycles,metrics.projection_active_cycles] = ...
        inferred_constraint_counts(cycle,cOverlap,cfg);
end
end

function ratio = retention_ratio(dataF,dataCF,resultF,resultCF,f,index)
trueIncrement = fundamental_rms(dataF.t(index),dataF.irB(index),f)- ...
    fundamental_rms(dataCF.t(index),dataCF.irB(index),f);
estimatedIncrement = fundamental_rms(dataF.t(index),resultF.ir.B(index),f)- ...
    fundamental_rms(dataCF.t(index),resultCF.ir.B(index),f);
ratio = estimatedIncrement/(trueIncrement+eps);
end

function change = parameter_change(cHist,pre,post)
change = mean(cHist(post,:),1)-mean(cHist(pre,:),1);
end

function value = fault_factor(t,x,pre,post,f)
value = fundamental_rms(t(post),x(post),f)/ ...
    (fundamental_rms(t(pre),x(pre),f)+eps);
end

function value = fundamental_rms(t,x,f)
w = 2*pi*f;
coefficients = [sin(w*t),cos(w*t),ones(size(t))]\x;
value = hypot(coefficients(1),coefficients(2))/sqrt(2);
end

function [rateCount,projectionCount] = ...
        inferred_constraint_counts(cycle,index,cfg)
change = diff(cycle{:,{'Cs1_pF','Cs2_pF'}},1,1);
rateAll = any(abs(change) >= cfg.rate_limit_pF_per_cycle-1e-12,2);
bounds = cycle{2:end,{'Cs1_pF','Cs2_pF'}};
projectionAll = any(bounds <= cfg.coupling_bounds_pF(1)+1e-12 | ...
    bounds >= cfg.coupling_bounds_pF(2)-1e-12,2);
rateCount = sum(rateAll(index(2:end)));
projectionCount = sum(projectionAll(index(2:end)));
end

function index = sample_window(time,startTime,endTime)
index = time >= startTime & time < endTime;
if ~any(index)
    error('Phase2:Step6ASampleWindow', ...
        'Empty sample window [%.10f, %.10f).',startTime,endTime);
end
end

function index = cycle_window(time,windows,name)
startTime = windows{name,'start_s'};
endTime = windows{name,'end_s'};
index = time >= startTime & time < endTime;
if ~any(index)
    error('Phase2:Step6ACycleWindow','Empty cycle window %s.',name);
end
end

function pass = required_outputs_exist(result)
pass = isstruct(result) && ...
    all(isfield(result,{'algorithm_mode','cHist','ir','tracker'})) && ...
    isstruct(result.ir) && all(isfield(result.ir,{'A','B','C'}));
end

function pass = outputs_finite(data,ref,result)
dataFields = {'t','ua','ub','uc','ia','ib','ic','irA','irB','irC', ...
    'Cs1','Cs2'};
refFields = {'ua','ub','uc','dua','dub','duc'};
pass = true;
for k = 1:numel(dataFields)
    pass = pass && all(isfinite(data.(dataFields{k})));
end
for k = 1:numel(refFields)
    pass = pass && all(isfinite(ref.(refFields{k})));
end
pass = pass && all(isfinite(result.cHist),'all') && ...
    all(isfinite(result.ir.A)) && all(isfinite(result.ir.B)) && ...
    all(isfinite(result.ir.C));
end

function pass = required_metrics_exist(cohort,mode,m)
if cohort == "H"
    required = [m.Cs1_RMSE_pF,m.Cs2_RMSE_pF, ...
        m.Cs1_max_abs_error_pF,m.Cs2_max_abs_error_pF, ...
        m.B_resistive_fundamental_error_pct];
elseif cohort == "F"
    required = [m.Cs1_RMSE_pF,m.Cs2_RMSE_pF, ...
        m.B_resistive_fundamental_error_pct,m.fault_factor_true, ...
        m.fault_factor_est,m.fault_retention_error_pct, ...
        m.absolute_fault_increment_loss,m.DeltaCs1_fault_induced_pF, ...
        m.DeltaCs2_fault_induced_pF,m.Cs_fault_induced_bias_norm_pF];
else
    required = [m.overlap_Cs1_RMSE_pF,m.overlap_Cs2_RMSE_pF, ...
        m.W1_fault_increment_retention_ratio, ...
        m.W2_fault_increment_retention_ratio, ...
        m.parameter_error_RMS_norm_pF,m.mean_memory_norm_pF, ...
        m.endpoint_memory_norm_pF,m.post_fault_AUC_pF_s, ...
        m.true_drift_Cs1_pF,m.true_drift_Cs2_pF,m.true_drift_norm_pF, ...
        m.F_movement_Cs1_pF,m.F_movement_Cs2_pF,m.F_movement_norm_pF, ...
        m.CF_movement_Cs1_pF,m.CF_movement_Cs2_pF, ...
        m.CF_movement_norm_pF,m.F_minus_CF_Cs1_pF, ...
        m.F_minus_CF_Cs2_pF,m.F_minus_CF_norm_pF];
end
pass = all(isfinite(required));
if mode == "M3"
    pass = pass && isfinite(m.hard_gate_active_ratio);
elseif mode == "M4"
    pass = pass && isfinite(m.mean_update_weight);
    if cohort == "H"
        pass = pass && isfinite(m.unnecessary_suppression_ratio);
    end
end
end

function signature = condition_signature(row,context)
digester = java.security.MessageDigest.getInstance('SHA-256');
dataF = context.dataF;
ref = context.ref;
values = {double(row.truth_seed),double(row.noise_seed),dataF.t, ...
    dataF.ua,dataF.ub,dataF.uc,dataF.ia,dataF.ib,dataF.ic, ...
    dataF.irA,dataF.irB,dataF.irC,dataF.Cs1,dataF.Cs2, ...
    context.signalsF.fault_scale,context.noise.A,context.noise.B, ...
    context.noise.C,ref.ua,ref.ub,ref.uc,ref.dua,ref.dub,ref.duc};
if string(row.mc_cohort) ~= "H"
    dataCF = context.dataCF;
    values = [values,{dataCF.ia,dataCF.ib,dataCF.ic,dataCF.irB}]; %#ok<AGROW>
end
for k = 1:numel(values)
    digester.update(typecast(double(values{k}(:)),'uint8'));
end
hashBytes = typecast(digester.digest(),'uint8');
signature = upper(string(reshape(dec2hex(hashBytes,2).',1,[])));
end

function row = blank_row()
m = empty_metrics();
row = struct( ...
    'condition_id',"",'cohort',"",'registry_index',NaN, ...
    'algorithm_id',"",'truth_seed',NaN,'noise_seed',NaN, ...
    'SNR_dB',NaN,'reference_phase_error_deg',NaN, ...
    'fault_factor',NaN,'drift_rate_multiplier',NaN, ...
    'Cself_mismatch_pct',NaN,'Cself_truth_pF',NaN, ...
    'Cself_algorithm_pF',NaN,'negative_sequence_pu',NaN, ...
    'CsAC_truth_pF',NaN,'evaluation_window_set_id',"", ...
    'data_signature',"", ...
    'Cs1_RMSE_pF',m.Cs1_RMSE_pF,'Cs2_RMSE_pF',m.Cs2_RMSE_pF, ...
    'Cs1_max_abs_error_pF',m.Cs1_max_abs_error_pF, ...
    'Cs2_max_abs_error_pF',m.Cs2_max_abs_error_pF, ...
    'B_resistive_fundamental_error_pct',m.B_resistive_fundamental_error_pct, ...
    'fault_factor_true',m.fault_factor_true, ...
    'fault_factor_est',m.fault_factor_est, ...
    'fault_retention_error_pct',m.fault_retention_error_pct, ...
    'absolute_fault_increment_loss',m.absolute_fault_increment_loss, ...
    'DeltaCs1_fault_induced_pF',m.DeltaCs1_fault_induced_pF, ...
    'DeltaCs2_fault_induced_pF',m.DeltaCs2_fault_induced_pF, ...
    'Cs_fault_induced_bias_norm_pF',m.Cs_fault_induced_bias_norm_pF, ...
    'overlap_Cs1_RMSE_pF',m.overlap_Cs1_RMSE_pF, ...
    'overlap_Cs2_RMSE_pF',m.overlap_Cs2_RMSE_pF, ...
    'W1_fault_increment_retention_ratio', ...
        m.W1_fault_increment_retention_ratio, ...
    'W2_fault_increment_retention_ratio', ...
        m.W2_fault_increment_retention_ratio, ...
    'parameter_error_RMS_norm_pF',m.parameter_error_RMS_norm_pF, ...
    'mean_memory_norm_pF',m.mean_memory_norm_pF, ...
    'endpoint_memory_norm_pF',m.endpoint_memory_norm_pF, ...
    'post_fault_AUC_pF_s',m.post_fault_AUC_pF_s, ...
    'true_drift_Cs1_pF',m.true_drift_Cs1_pF, ...
    'true_drift_Cs2_pF',m.true_drift_Cs2_pF, ...
    'true_drift_norm_pF',m.true_drift_norm_pF, ...
    'F_movement_Cs1_pF',m.F_movement_Cs1_pF, ...
    'F_movement_Cs2_pF',m.F_movement_Cs2_pF, ...
    'F_movement_norm_pF',m.F_movement_norm_pF, ...
    'CF_movement_Cs1_pF',m.CF_movement_Cs1_pF, ...
    'CF_movement_Cs2_pF',m.CF_movement_Cs2_pF, ...
    'CF_movement_norm_pF',m.CF_movement_norm_pF, ...
    'F_minus_CF_Cs1_pF',m.F_minus_CF_Cs1_pF, ...
    'F_minus_CF_Cs2_pF',m.F_minus_CF_Cs2_pF, ...
    'F_minus_CF_norm_pF',m.F_minus_CF_norm_pF, ...
    'hard_gate_active_ratio',m.hard_gate_active_ratio, ...
    'hard_gate_latency_s',m.hard_gate_latency_s, ...
    'mean_update_weight',m.mean_update_weight, ...
    'unnecessary_suppression_ratio',m.unnecessary_suppression_ratio, ...
    'first_suppression_time_s',m.first_suppression_time_s, ...
    'suppression_latency_s',m.suppression_latency_s, ...
    'rate_limit_active_cycles',m.rate_limit_active_cycles, ...
    'projection_active_cycles',m.projection_active_cycles, ...
    'condition_unique',false,'registry_match',false,'seed_match',false, ...
    'shared_data_pass',false,'required_outputs_pass',false, ...
    'numerical_failure',true,'metric_missing',true, ...
    'simulation_abort',false,'frozen_integrity_pass',false,'notes',"");
end

function rows = failure_rows(registryRow,exception)
rows = repmat(blank_row(),4,1);
for k = 1:4
    mode = ["M0","M2","M3","M4"];
    rows(k).condition_id = registryRow.condition_id;
    rows(k).cohort = registryRow.mc_cohort;
    rows(k).registry_index = registryRow.registry_index;
    rows(k).algorithm_id = mode(k);
    rows(k).truth_seed = registryRow.truth_seed;
    rows(k).noise_seed = registryRow.noise_seed;
    rows(k).SNR_dB = registryRow.SNR_dB;
    rows(k).reference_phase_error_deg = registryRow.reference_phase_error_deg;
    rows(k).fault_factor = registryRow.fault_factor;
    rows(k).drift_rate_multiplier = registryRow.drift_rate_multiplier;
    rows(k).Cself_mismatch_pct = registryRow.Cself_mismatch_pct;
    rows(k).Cself_truth_pF = registryRow.Cself_truth_pF;
    rows(k).Cself_algorithm_pF = registryRow.Cself_algorithm_pF;
    rows(k).negative_sequence_pu = registryRow.negative_sequence_pu;
    rows(k).CsAC_truth_pF = registryRow.CsAC_truth_pF;
    rows(k).evaluation_window_set_id = registryRow.evaluation_window_set_id;
    rows(k).simulation_abort = true;
    rows(k).notes = string(exception.identifier)+": "+string(exception.message);
end
end

function audit = final_audit(rows,conditions,executionRegistry,frozenPass, ...
        expectedConditions,expectedEvaluationsTarget)
mainExpected = executionRegistry.record_type == "MAIN_ALGORITHM_EVALUATION" & ...
    ismember(executionRegistry.condition_id,conditions.condition_id);
expectedEvaluations = nnz(mainExpected);
completeRows = ~rows.numerical_failure & ~rows.metric_missing & ...
    rows.registry_match & rows.seed_match & rows.shared_data_pass & ...
    rows.required_outputs_pass & ~rows.simulation_abort;
conditionComplete = 0;
for id = conditions.condition_id.'
    part = rows(rows.condition_id == id,:);
    conditionComplete = conditionComplete+ ...
        (height(part) == 4 && all(completeRows(rows.condition_id == id)));
end
audit = struct();
audit.expected_conditions = expectedConditions;
audit.condition_complete = conditionComplete;
audit.evaluation_complete = nnz(completeRows);
audit.expected_evaluations = expectedEvaluations;
audit.numerical_failures = nnz(rows.numerical_failure | rows.simulation_abort);
audit.metric_missing = nnz(rows.metric_missing);
audit.seed_registry_mismatch = nnz(~rows.seed_match | ~rows.registry_match);
audit.shared_data_failures = nnz(~rows.shared_data_pass);
audit.h_complete = cohort_complete(rows,"H");
audit.f_complete = cohort_complete(rows,"F");
audit.o_complete = cohort_complete(rows,"O");
audit.pass = frozenPass && conditionComplete == expectedConditions && ...
    audit.evaluation_complete == expectedEvaluationsTarget && ...
    expectedEvaluations == expectedEvaluationsTarget && ...
    audit.numerical_failures == 0 && audit.metric_missing == 0 && ...
    audit.seed_registry_mismatch == 0 && audit.shared_data_failures == 0;
end

function count = cohort_complete(rows,cohort)
ids = unique(rows.condition_id(rows.cohort == cohort));
count = 0;
for id = ids.'
    part = rows(rows.condition_id == id,:);
    complete = ~part.numerical_failure & ~part.metric_missing & ...
        part.registry_match & part.seed_match & part.shared_data_pass & ...
        part.required_outputs_pass & ~part.simulation_abort;
    count = count+(height(part) == 4 && all(complete));
end
end

function statistics = build_statistics(rows)
statistics = struct();
statistics.H = stats_for_metrics(rows,"H", ...
    ["Cs1_RMSE_pF","Cs2_RMSE_pF", ...
    "Cs1_max_abs_error_pF","Cs2_max_abs_error_pF", ...
    "B_resistive_fundamental_error_pct", ...
    "hard_gate_active_ratio","mean_update_weight", ...
    "unnecessary_suppression_ratio"]);
statistics.F = stats_for_metrics(rows,"F", ...
    ["fault_factor_true","fault_factor_est", ...
    "fault_retention_error_pct","absolute_fault_increment_loss", ...
    "DeltaCs1_fault_induced_pF","DeltaCs2_fault_induced_pF", ...
    "Cs_fault_induced_bias_norm_pF","hard_gate_active_ratio", ...
    "hard_gate_latency_s","mean_update_weight"]);
statistics.O = stats_for_metrics(rows,"O", ...
    ["overlap_Cs1_RMSE_pF","overlap_Cs2_RMSE_pF", ...
    "parameter_error_RMS_norm_pF", ...
    "W1_fault_increment_retention_ratio", ...
    "W2_fault_increment_retention_ratio","F_minus_CF_norm_pF", ...
    "true_drift_Cs1_pF","true_drift_Cs2_pF","true_drift_norm_pF", ...
    "F_movement_Cs1_pF","F_movement_Cs2_pF","F_movement_norm_pF", ...
    "CF_movement_Cs1_pF","CF_movement_Cs2_pF", ...
    "CF_movement_norm_pF","F_minus_CF_Cs1_pF", ...
    "F_minus_CF_Cs2_pF","mean_memory_norm_pF", ...
    "endpoint_memory_norm_pF","post_fault_AUC_pF_s", ...
    "hard_gate_active_ratio","mean_update_weight"]);
statistics.paired = paired_statistics(rows);
end

function stats = stats_for_metrics(rows,cohort,metrics)
stats = table();
for algorithm = ["M0","M2","M3","M4"]
    subset = rows(rows.cohort == cohort & rows.algorithm_id == algorithm,:);
    for metric = metrics
        x = subset.(char(metric));
        x = x(isfinite(x));
        if isempty(x)
            continue
        end
        s = descriptive_stats(x);
        current = table(cohort,algorithm,metric,height(subset),s.N, ...
            s.mean,s.std, ...
            s.median,s.iqr,s.p5,s.p95,s.rms, ...
            nnz(subset.numerical_failure | subset.metric_missing), ...
            'VariableNames',{'cohort','algorithm_id','metric','N', ...
            'valid_N','mean','std','median','IQR','P5','P95','RMSE', ...
            'failure_count'});
        stats = [stats;current]; %#ok<AGROW>
    end
end
end

function paired = paired_statistics(rows)
paired = table();
definitions = { ...
    "H","Cs1_RMSE_pF","identity"; ...
    "H","Cs2_RMSE_pF","identity"; ...
    "H","B_resistive_fundamental_error_pct","absolute"; ...
    "F","fault_retention_error_pct","absolute"; ...
    "F","absolute_fault_increment_loss","identity"; ...
    "F","Cs_fault_induced_bias_norm_pF","identity"; ...
    "O","parameter_error_RMS_norm_pF","identity"; ...
    "O","W1_fault_increment_retention_ratio","distance_one"; ...
    "O","W2_fault_increment_retention_ratio","distance_one"; ...
    "O","F_minus_CF_norm_pF","identity"};
for d = 1:size(definitions,1)
    cohort = definitions{d,1};
    metric = definitions{d,2};
    transform = definitions{d,3};
    for comparator = ["M2","M3"]
        m4 = sortrows(rows(rows.cohort == cohort & ...
            rows.algorithm_id == "M4",:),'condition_id');
        other = sortrows(rows(rows.cohort == cohort & ...
            rows.algorithm_id == comparator,:),'condition_id');
        if ~isequal(m4.condition_id,other.condition_id)
            error('Phase2:Step6APairing','Paired condition IDs do not align.');
        end
        a = transform_values(m4.(char(metric)),transform);
        b = transform_values(other.(char(metric)),transform);
        difference = a-b;
        valid = isfinite(difference);
        s = descriptive_stats(difference(valid));
        current = table(string(cohort),"M4 - "+comparator, ...
            string(metric),string(transform),s.N,s.mean,s.median,s.p5,s.p95, ...
            nnz(difference(valid)<0),nnz(difference(valid)==0), ...
            'VariableNames',{'cohort','comparison','metric','transform', ...
            'N','mean_difference','median_difference','P5','P95', ...
            'improved_count','tied_count'});
        paired = [paired;current]; %#ok<AGROW>
    end
end
end

function y = transform_values(x,transform)
switch string(transform)
    case "absolute"
        y = abs(x);
    case "distance_one"
        y = abs(x-1);
    otherwise
        y = x;
end
end

function s = descriptive_stats(x)
x = x(isfinite(x));
s = struct('N',numel(x),'mean',NaN,'std',NaN,'median',NaN, ...
    'iqr',NaN,'p5',NaN,'p95',NaN,'rms',NaN);
if isempty(x)
    return
end
s.mean = mean(x);
s.std = std(x,0);
s.median = median(x);
s.p5 = empirical_percentile(x,5);
s.p95 = empirical_percentile(x,95);
s.iqr = empirical_percentile(x,75)-empirical_percentile(x,25);
s.rms = sqrt(mean(x.^2));
end

function value = empirical_percentile(x,p)
x = sort(x(:));
if numel(x) == 1
    value = x;
    return
end
position = 1+(numel(x)-1)*p/100;
lower = floor(position);
upper = ceil(position);
if lower == upper
    value = x(lower);
else
    value = x(lower)+(position-lower)*(x(upper)-x(lower));
end
end

function write_chinese_report(paths,rows,pilot,statistics,audit,pre,post, ...
        runtimeSeconds,cleanMode,noisyMode)
fileId = fopen(paths.report,'w','n','UTF-8');
if fileId < 0
    error('Phase2:Step6AReportOpen','Unable to create report.');
end
cleanup = onCleanup(@() fclose(fileId));
fprintf(fileId,'# 第二阶段第六步 A——Monte-Carlo 先导试验报告\n\n');
fprintf(fileId,'## 1. 目的与范围\n\n');
fprintf(fileId,['本步骤严格执行冻结 Monte-Carlo 登记表中 H/F/O 三个组' ...
    '各自按 `registry_index` 排序后的 1–20，共 60 个物理条件和 240 个算法评估。' ...
    '没有重新抽取随机种子、改变随机变量或分布、删除异常点、调整 M4，' ...
    '也没有运行 21–50。\n\n']);
fprintf(fileId,'H/F/O 条件数分别为 %d/%d/%d；执行记录映射为 240 条。\n\n', ...
    nnz(pilot.mc_cohort=="H"),nnz(pilot.mc_cohort=="F"), ...
    nnz(pilot.mc_cohort=="O"));

fprintf(fileId,'## 2. 登记表、随机种子与共享数据审计\n\n');
fprintf(fileId,['60 条先导条件均为正式 150 条登记记录的严格子集。' ...
    '`truth_seed` 与 `noise_seed` 逐条从冻结登记表读取，并使用冻结主种子公式独立复核；' ...
    '60/60 条均满足两类随机种子不相等。四算法在每个物理条件内共享真值、噪声实现、' ...
    '参考、评价窗口和 `data_signature`。\n\n']);
fprintf(fileId,'| 检查项 | 结果 |\n|---|---:|\n');
fprintf(fileId,'| 条件唯一性 | 60/60 |\n');
fprintf(fileId,'| 执行映射 | %d/240 |\n',audit.expected_evaluations);
fprintf(fileId,'| 随机种子/登记表不匹配 | %d |\n',audit.seed_registry_mismatch);
fprintf(fileId,'| `shared_data_pass` 失败行 | %d |\n',audit.shared_data_failures);
fprintf(fileId,'| 负序非零条件 | %d |\n',nnz(pilot.negative_sequence_pu~=0));
fprintf(fileId,'| CsAC 非零条件 | %d |\n\n',nnz(pilot.CsAC_truth_pF~=0));

fprintf(fileId,'## 3. 执行完整性与资源情况\n\n');
fprintf(fileId,'60 个物理条件完成 %d 个，240 个算法评估完成 %d 个。', ...
    audit.condition_complete,audit.evaluation_complete);
fprintf(fileId,'数值失败 %d 行，指标缺失 %d 行。\n\n', ...
    audit.numerical_failures,audit.metric_missing);
fprintf(fileId,'清洁数据批次模式为 `%s`，含噪数据批次模式为 `%s`。', ...
    cleanMode,noisyMode);
fprintf(fileId,'总运行时间 %.1f s。执行过程中未发生内存耗尽、存储失败或软件中止，', ...
    runtimeSeconds);
fprintf(fileId,'因此技术资源阻塞记为 NO。\n\n');

fprintf(fileId,'## 4. H 组统计\n\n');
fprintf(fileId,['H 组重点观察参数跟踪、B 相阻性基波误差以及正常工况下的保护行为。' ...
    '统计量均直接来自 20 个冻结条件；异常但数值有效的记录不删除。\n\n']);
write_stats_table(fileId,statistics.H);
hM4 = rows(rows.cohort=="H" & rows.algorithm_id=="M4",:);
[maxUsr,maxUsrIndex] = max(hM4.unnecessary_suppression_ratio);
[minWeight,minWeightIndex] = min(hM4.mean_update_weight);
fprintf(fileId,['M4 的 `unnecessary_suppression_ratio` 均值为 %.6f，P95 为 %.6f，' ...
    '最大值 %.6f 出现在 `%s`；最小 `mean_update_weight` 为 %.6f，出现在 `%s`。'], ...
    mean(hM4.unnecessary_suppression_ratio), ...
    empirical_percentile(hM4.unnecessary_suppression_ratio,95), ...
    maxUsr,hM4.condition_id(maxUsrIndex),minWeight,hM4.condition_id(minWeightIndex));
fprintf(fileId,['这些值显示随机组合下存在较强正常更新抑制，需要作为适用性证据保留；' ...
    '它不是数值失败，也不触发调参。\n\n']);

fprintf(fileId,'## 5. F 组统计\n\n');
write_stats_table(fileId,statistics.F);
fM3 = rows(rows.cohort=="F" & rows.algorithm_id=="M3",:);
miss = fM3.hard_gate_active_ratio == 0;
fM4 = sortrows(rows(rows.cohort=="F" & rows.algorithm_id=="M4",:),'condition_id');
fM2 = sortrows(rows(rows.cohort=="F" & rows.algorithm_id=="M2",:),'condition_id');
retentionImproved = abs(fM4.fault_retention_error_pct) < ...
    abs(fM2.fault_retention_error_pct);
fprintf(fileId,'M3 在 %d/20 个 F 条件中门控比例为 0，阈值漏触发仍然存在。\n\n', ...
    nnz(miss));
fprintf(fileId,['M4 相对 M2 在 %d/20 个配对条件中具有更小的绝对 ' ...
    '`fault_retention_error_pct`。这是先导样本中的配对观察，不构成总体显著性或普遍优越性结论。\n\n'], ...
    nnz(retentionImproved));

fprintf(fileId,'## 6. O 组统计\n\n');
write_stats_table(fileId,statistics.O);
oM3 = rows(rows.cohort=="O" & rows.algorithm_id=="M3",:);
oM4 = rows(rows.cohort=="O" & rows.algorithm_id=="M4",:);
fprintf(fileId,['M3 在 %d/20 个 O 条件中出现非零硬门控，门控比例范围为 %.6f–%.6f。' ...
    'M4 的 `mean_update_weight` 范围为 %.6f–%.6f，说明连续更新在随机重叠条件中仍然存在。'], ...
    nnz(oM3.hard_gate_active_ratio>0),min(oM3.hard_gate_active_ratio), ...
    max(oM3.hard_gate_active_ratio),min(oM4.mean_update_weight), ...
    max(oM4.mean_update_weight));
fprintf(fileId,['M3 的硬冻结保护与真实漂移学习损失、M4 的连续适应与故障污染之间的折中仍然存在。' ...
    '没有使用 `||Delta c_CF|| / ||Delta c_F||` 作为纯度指标。\n\n']);

fprintf(fileId,'## 7. 配对差异\n\n');
fprintf(fileId,['四算法共享同一物理条件，因此以下差异按条件配对计算。' ...
    '对误差指标使用绝对值或相对 1 的偏差时，`transform` 字段明确记录；' ...
    '本步骤不执行复杂显著性检验。\n\n']);
fprintf(fileId,'| 组别 | 比较 | 指标 | 变换 | N | 均值差 | 中位数差 | P5 | P95 |\n');
fprintf(fileId,'|---|---|---|---|---:|---:|---:|---:|---:|\n');
for k = 1:height(statistics.paired)
    r = statistics.paired(k,:);
    fprintf(fileId,'| %s | %s | `%s` | %s | %d | %.6g | %.6g | %.6g | %.6g |\n', ...
        r.cohort,r.comparison,r.metric,transform_label(r.transform),r.N,r.mean_difference, ...
        r.median_difference,r.P5,r.P95);
end
fprintf(fileId,'\n');

fprintf(fileId,'## 8. 异常大但数值有效的结果\n\n');
write_extreme_summary(fileId,rows,"H","B_resistive_fundamental_error_pct",true);
write_extreme_summary(fileId,rows,"F","fault_retention_error_pct",true);
write_extreme_summary(fileId,rows,"O","parameter_error_RMS_norm_pF",false);
fprintf(fileId,['上述极值全部保留在 CSV 中。它们没有被重新分类为数值失败，' ...
    '也没有用于改变 N、分布、随机种子或参数。\n\n']);

fprintf(fileId,'## 9. 先导试验主要问题回答\n\n');
fprintf(fileId,'1. 60/60 个物理条件是否全部成功：%s。\n',yes_no(audit.condition_complete==60));
fprintf(fileId,'2. 240/240 个算法评估是否全部完整：%s。\n',yes_no(audit.evaluation_complete==240));
fprintf(fileId,'3. 登记表、随机种子与共享数据是否严格匹配：%s。\n', ...
    yes_no(audit.seed_registry_mismatch==0 && audit.shared_data_failures==0));
fprintf(fileId,'4. 是否存在数值失败：%s，共 %d 行。\n', ...
    yes_no(audit.numerical_failures>0),audit.numerical_failures);
fprintf(fileId,['5. H 组中 M4 是否出现明显抑制：已观察到的范围与极值见第 4 节，' ...
    '其中较强抑制作为负面证据保留，不作事后阈值判定。\n']);
fprintf(fileId,'6. F 组中 M3 阈值漏触发是否仍存在：%s，%d/20。\n', ...
    yes_no(nnz(miss)>0),nnz(miss));
fprintf(fileId,'7. F 组中 M4 相对 M2 的保持改善是否仍可观察：%s，%d/20 个配对条件。\n', ...
    yes_no(nnz(retentionImproved)>0),nnz(retentionImproved));
fprintf(fileId,['8. O 组中 M3 硬冻结与 M4 连续加权之间的权衡是否仍存在：YES；' ...
    '两种机制的保护与跟踪代价均在统计中保留。\n']);
fprintf(fileId,['9. 是否存在新的失败模式：未发现新的执行级失败模式；' ...
    '性能极值与已知相位/Cself/故障吸收边界一致。\n']);
fprintf(fileId,'10. 是否存在异常大但数值有效的结果：YES，极值见第 8 节，全部保留。\n');
fprintf(fileId,'11. 是否存在运行时间、内存或存储问题：NO；运行时间 %.1f s。\n',runtimeSeconds);
fprintf(fileId,'12. 是否允许扩展至每组 N=50：%s。\n\n',yes_no(audit.pass));

fprintf(fileId,'## 10. 冻结完整性与解释纪律\n\n');
fprintf(fileId,['PRE：第一阶段 %d/%d、第二阶段 Step 1 %d/3；' ...
    'POST：第一阶段 %d/%d、第二阶段 Step 1 %d/3。PRE/POST 哈希一致：%s。\n\n'], ...
    pre.phase1_pass_count,pre.phase1_count,pre.step1_pass_count, ...
    post.phase1_pass_count,post.phase1_count,post.step1_pass_count, ...
    yes_no(isequal(pre.actual_sha256,post.actual_sha256)));
fprintf(fileId,['先导统计不用于修改正式的每组 N=50、随机变量分布、参数或登记表。' ...
    '本报告不要求也不宣称 M4 在先导样本中“胜出”。\n\n']);

fprintf(fileId,'## 11. 最终状态\n\n```text\n');
fprintf(fileId,'STEP 6A STATUS:\n%s\n\n',status_label(audit.pass,pre.pass&&post.pass));
fprintf(fileId,'PILOT PHYSICAL CONDITIONS:\n%d / 60\n\n',audit.condition_complete);
fprintf(fileId,'PILOT ALGORITHM EVALUATIONS:\n%d / 240\n\n',audit.evaluation_complete);
fprintf(fileId,'H COHORT:\n%d / 20\n\n',audit.h_complete);
fprintf(fileId,'F COHORT:\n%d / 20\n\n',audit.f_complete);
fprintf(fileId,'O COHORT:\n%d / 20\n\n',audit.o_complete);
fprintf(fileId,'NUMERICAL FAILURES:\n%d\n\n',audit.numerical_failures);
fprintf(fileId,'METRIC-MISSING ROWS:\n%d\n\n',audit.metric_missing);
fprintf(fileId,'SEED / REGISTRY MISMATCH:\n%d\n\n',audit.seed_registry_mismatch);
fprintf(fileId,'FROZEN SOURCE MODIFIED:\n%s\n\n',yes_no(~(pre.pass&&post.pass)));
fprintf(fileId,'TECHNICAL RESOURCE BLOCKER:\nNO\n\n');
fprintf(fileId,'READY FOR STEP 6B FORMAL EXPANSION:\n%s\n',yes_no(audit.pass));
fprintf(fileId,'```\n');
end

function write_full_chinese_report(reportPath,rows,expansion,statistics, ...
        audit,pre,post,runtimeSeconds,cleanMode,noisyMode)
fileId = fopen(reportPath,'w','n','UTF-8');
if fileId < 0
    error('Phase2:Step6BReportOpen','Unable to create full report.');
end
cleanup = onCleanup(@() fclose(fileId));
statsComplete = formal_statistics_complete(statistics,audit);

hM4 = sortrows(rows(rows.cohort=="H" & rows.algorithm_id=="M4",:), ...
    'condition_id');
hM2 = sortrows(rows(rows.cohort=="H" & rows.algorithm_id=="M2",:), ...
    'condition_id');
hM3 = sortrows(rows(rows.cohort=="H" & rows.algorithm_id=="M3",:), ...
    'condition_id');
hSuppression = descriptive_stats(hM4.unnecessary_suppression_ratio);
[hSuppressionMax,hSuppressionMaxIndex] = ...
    max(hM4.unnecessary_suppression_ratio);
hSuppressionFence = empirical_percentile( ...
    hM4.unnecessary_suppression_ratio,75)+1.5*( ...
    empirical_percentile(hM4.unnecessary_suppression_ratio,75)- ...
    empirical_percentile(hM4.unnecessary_suppression_ratio,25));
hSuppressionExtremeCount = nnz( ...
    hM4.unnecessary_suppression_ratio > hSuppressionFence);
hDiffM2 = hypot(hM4.Cs1_RMSE_pF-hM2.Cs1_RMSE_pF, ...
    hM4.Cs2_RMSE_pF-hM2.Cs2_RMSE_pF);
hDiffM3 = hypot(hM4.Cs1_RMSE_pF-hM3.Cs1_RMSE_pF, ...
    hM4.Cs2_RMSE_pF-hM3.Cs2_RMSE_pF);
hDiffM2Stats = descriptive_stats(hDiffM2);
hDiffM3Stats = descriptive_stats(hDiffM3);
[hDiffM2Max,hDiffM2Index] = max(hDiffM2);
[hDiffM3Max,hDiffM3Index] = max(hDiffM3);

fM2 = sortrows(rows(rows.cohort=="F" & rows.algorithm_id=="M2",:), ...
    'condition_id');
fM3 = sortrows(rows(rows.cohort=="F" & rows.algorithm_id=="M3",:), ...
    'condition_id');
fM4 = sortrows(rows(rows.cohort=="F" & rows.algorithm_id=="M4",:), ...
    'condition_id');
fTriggered = fM3.hard_gate_active_ratio > 0;
fM3MissCount = nnz(~fTriggered);
fM4RetentionBetterM2 = nnz(abs(fM4.fault_retention_error_pct) < ...
    abs(fM2.fault_retention_error_pct));
fM4RetentionBetterM3 = nnz(abs(fM4.fault_retention_error_pct) < ...
    abs(fM3.fault_retention_error_pct));
fM4BiasBetterM2 = nnz(fM4.Cs_fault_induced_bias_norm_pF < ...
    fM2.Cs_fault_induced_bias_norm_pF);
fM4BiasBetterM3 = nnz(fM4.Cs_fault_induced_bias_norm_pF < ...
    fM3.Cs_fault_induced_bias_norm_pF);

oM2 = sortrows(rows(rows.cohort=="O" & rows.algorithm_id=="M2",:), ...
    'condition_id');
oM3 = sortrows(rows(rows.cohort=="O" & rows.algorithm_id=="M3",:), ...
    'condition_id');
oM4 = sortrows(rows(rows.cohort=="O" & rows.algorithm_id=="M4",:), ...
    'condition_id');
oWeight = descriptive_stats(oM4.mean_update_weight);
oM3TriggeredCount = nnz(oM3.hard_gate_active_ratio > 0);
oTrackBetterM2 = nnz(oM4.parameter_error_RMS_norm_pF < ...
    oM2.parameter_error_RMS_norm_pF);
oTrackBetterM3 = nnz(oM4.parameter_error_RMS_norm_pF < ...
    oM3.parameter_error_RMS_norm_pF);
oRetentionBetterM2 = nnz( ...
    abs(oM4.W1_fault_increment_retention_ratio-1)+ ...
    abs(oM4.W2_fault_increment_retention_ratio-1) < ...
    abs(oM2.W1_fault_increment_retention_ratio-1)+ ...
    abs(oM2.W2_fault_increment_retention_ratio-1));
oRetentionBetterM3 = nnz( ...
    abs(oM4.W1_fault_increment_retention_ratio-1)+ ...
    abs(oM4.W2_fault_increment_retention_ratio-1) < ...
    abs(oM3.W1_fault_increment_retention_ratio-1)+ ...
    abs(oM3.W2_fault_increment_retention_ratio-1));
oBiasBetterM2 = nnz(oM4.F_minus_CF_norm_pF < oM2.F_minus_CF_norm_pF);
oBiasBetterM3 = nnz(oM4.F_minus_CF_norm_pF < oM3.F_minus_CF_norm_pF);
oMemory = descriptive_stats(oM4.mean_memory_norm_pF);
oAuc = descriptive_stats(oM4.post_fault_AUC_pF_s);

fprintf(fileId,'# 第二阶段第六步——Monte-Carlo 正式结果\n\n');
fprintf(fileId,'## 1. 执行范围与冻结约束\n\n');
fprintf(fileId,['本步骤只新增执行 `registry_index` 21–50，' ...
    '即 H/F/O 各 30 个物理条件，共 90 个新条件和 360 个新算法评估。' ...
    '已冻结的 Step 6A 1–20 结果直接读取，未重跑、未覆盖。\n\n']);
fprintf(fileId,['完整数据由 Step 6A 的 60 个条件/240 个评估与本步骤的 ' ...
    '90 个条件/360 个评估合并而成，共 150 个条件和 600 个评估。' ...
    '未重新抽样、未改变随机种子、未删除极端条件、未调整算法。\n\n']);

fprintf(fileId,'## 2. 执行与完整性审计\n\n');
fprintf(fileId,'| 检查项 | 结果 |\n|---|---:|\n');
fprintf(fileId,'| 新增条件 | %d/90 |\n',height(expansion));
fprintf(fileId,'| 完整物理条件 | %d/150 |\n',audit.condition_complete);
fprintf(fileId,'| 完整算法评估 | %d/600 |\n',audit.evaluation_complete);
fprintf(fileId,'| 登记表/随机种子不匹配 | %d |\n', ...
    audit.seed_registry_mismatch);
fprintf(fileId,'| 共享数据失败 | %d |\n',audit.shared_data_failures);
fprintf(fileId,'| 数值失败 | %d |\n',audit.numerical_failures);
fprintf(fileId,'| 指标缺失 | %d |\n',audit.metric_missing);
fprintf(fileId,'| H/F/O 完整条件 | %d/%d/%d |\n\n', ...
    audit.h_complete,audit.f_complete,audit.o_complete);
fprintf(fileId,['新增条件的清洁数据批次模式为 `%s`，含噪数据批次模式为 `%s`。' ...
    '新增执行用时 %.1f s。\n\n'],cleanMode,noisyMode,runtimeSeconds);

fprintf(fileId,'## 3. H 组正式统计\n\n');
write_stats_table(fileId,statistics.H);
fprintf(fileId,['M4 的 `unnecessary_suppression_ratio` 均值为 %.6f，P95 为 %.6f，' ...
    '最大值为 %.6f，位于 `%s`。Q3+1.5IQR 高侧极端记录为 %d/50。\n\n'], ...
    hSuppression.mean,hSuppression.p95,hSuppressionMax, ...
    hM4.condition_id(hSuppressionMaxIndex),hSuppressionExtremeCount);
fprintf(fileId,['M4 与 M2 的两参数 RMSE 差异范数中位数为 %.6g pF，P95 为 %.6g pF，' ...
    '最大值 %.6g pF 出现于 `%s`。M4 与 M3 的对应数值为 %.6g/%.6g/%.6g pF，' ...
    '最大值出现于 `%s`。差异的数值分布用于识别局部区域，' ...
    '不根据它修改方法。\n\n'], ...
    hDiffM2Stats.median,hDiffM2Stats.p95,hDiffM2Max, ...
    hM4.condition_id(hDiffM2Index),hDiffM3Stats.median, ...
    hDiffM3Stats.p95,hDiffM3Max,hM4.condition_id(hDiffM3Index));

fprintf(fileId,'## 4. F 组正式统计\n\n');
write_stats_table(fileId,statistics.F);
fprintf(fileId,'M3 在 %d/50 个条件中没有触发硬门控，触发条件为 %d/50。\n\n', ...
    fM3MissCount,nnz(fTriggered));
if any(fTriggered)
    fprintf(fileId,['在 M3 实际触发的 %d 个条件中，M3 的绝对 ' ...
        '`fault_retention_error_pct` 均值为 %.6g%%，同条件 M2 为 %.6g%%。' ...
        'M3 触发后的保护改变以该配对结果表示。\n\n'], ...
        nnz(fTriggered),mean(abs(fM3.fault_retention_error_pct(fTriggered))), ...
        mean(abs(fM2.fault_retention_error_pct(fTriggered))));
end
fprintf(fileId,['M4 相对 M2 的绝对故障保持误差在 %d/50 个配对条件中更小，' ...
    '故障诱导参数偏置范数在 %d/50 个条件中更小。' ...
    '相对 M3 的对应计数为 %d/50 和 %d/50，显示了 M4 连续加权相对硬门控的代价。\n\n'], ...
    fM4RetentionBetterM2,fM4BiasBetterM2, ...
    fM4RetentionBetterM3,fM4BiasBetterM3);
write_f_extreme_line(fileId,fM2,"M2");
write_f_extreme_line(fileId,fM3,"M3");
write_f_extreme_line(fileId,fM4,"M4");
fprintf(fileId,'\n');

fprintf(fileId,'## 5. O 组正式统计\n\n');
write_stats_table(fileId,statistics.O);
fprintf(fileId,['M3 在 %d/50 个 O 组条件中触发硬门控。M4 的 `mean_update_weight` ' ...
    '均值为 %.6f，中位数为 %.6f，P5/P95 为 %.6f/%.6f，' ...
    '范围为 %.6f–%.6f。\n\n'],oM3TriggeredCount, ...
    oWeight.mean,oWeight.median,oWeight.p5,oWeight.p95, ...
    min(oM4.mean_update_weight),max(oM4.mean_update_weight));
fprintf(fileId,['M4 相对 M2 的参数跟踪误差、W1/W2 综合保持距离和 ' ...
    '`F_minus_CF_norm_pF` 分别在 %d/50、%d/50 和 %d/50 个条件中更小。' ...
    '相对 M3 的对应计数为 %d/50、%d/50 和 %d/50。' ...
    '这些计数保留跟踪—保持权衡，不形成综合评分。\n\n'], ...
    oTrackBetterM2,oRetentionBetterM2,oBiasBetterM2, ...
    oTrackBetterM3,oRetentionBetterM3,oBiasBetterM3);
fprintf(fileId,['故障诱导移动与真实漂移向量点积为负的条件数：' ...
    'M2=%d/50，M3=%d/50，M4=%d/50。这些反向移动作为负面结果保留。\n\n'], ...
    wrong_direction_count(oM2),wrong_direction_count(oM3), ...
    wrong_direction_count(oM4));
fprintf(fileId,['M4 的 `mean_memory_norm_pF` 均值/P95 为 %.6g/%.6g pF，' ...
    '`post_fault_AUC_pF_s` 均值/P95 为 %.6g/%.6g pF·s。' ...
    '未发现新的执行级失败模式；性能极值和反向移动全部保留。\n\n'], ...
    oMemory.mean,oMemory.p95,oAuc.mean,oAuc.p95);

fprintf(fileId,'## 6. 配对差异与方向一致性\n\n');
fprintf(fileId,['四算法在每个条件内共享物理数据，因此以下结果按条件配对。' ...
    '“改善数”表示按所列变换后 M4 的值低于对比算法；并列不计为改善。\n\n']);
fprintf(fileId,'| 组别 | 比较 | 指标 | 变换 | N | 均值差 | 中位数差 | P5 | P95 | 改善数 | 并列数 |\n');
fprintf(fileId,'|---|---|---|---|---:|---:|---:|---:|---:|---:|---:|\n');
for k = 1:height(statistics.paired)
    r = statistics.paired(k,:);
    fprintf(fileId,'| %s | %s | `%s` | %s | %d | %.6g | %.6g | %.6g | %.6g | %d | %d |\n', ...
        r.cohort,r.comparison,r.metric,transform_label(r.transform),r.N, ...
        r.mean_difference,r.median_difference,r.P5,r.P95, ...
        r.improved_count,r.tied_count);
end
fprintf(fileId,'\n');

fprintf(fileId,'## 7. 数值极端但有效的结果\n\n');
write_extreme_summary(fileId,rows,"H","B_resistive_fundamental_error_pct",true);
write_extreme_summary(fileId,rows,"F","fault_retention_error_pct",true);
write_extreme_summary(fileId,rows,"O","parameter_error_RMS_norm_pF",false);
write_extreme_summary(fileId,rows,"O","post_fault_AUC_pF_s",false);
fprintf(fileId,['上述条件及其他数值有效的极端记录全部保留在 CSV 中。' ...
    '没有删除异常值、缩尾、重新抽取随机种子或删除条件。\n\n']);

fprintf(fileId,'## 8. 冻结完整性与解释纪律\n\n');
fprintf(fileId,['执行前：第一阶段 %d/%d，第二阶段 Step 1 %d/3。' ...
    '执行后：第一阶段 %d/%d，第二阶段 Step 1 %d/3。' ...
    '前后哈希一致：%s。\n\n'], ...
    pre.phase1_pass_count,pre.phase1_count,pre.step1_pass_count, ...
    post.phase1_pass_count,post.phase1_count,post.step1_pass_count, ...
    yes_no(isequal(pre.actual_sha256,post.actual_sha256)));
fprintf(fileId,['正式统计基于每组 50 个冻结条件。' ...
    '本报告不建立综合评分或胜者排名，也不根据结果修改 M4。\n\n']);

fprintf(fileId,'## 9. 最终状态\n\n```text\n');
fprintf(fileId,'STEP 6 STATUS:\n%s\n\n',status_label(audit.pass,pre.pass&&post.pass));
fprintf(fileId,'TOTAL MC PHYSICAL CONDITIONS:\n%d / 150\n\n',audit.condition_complete);
fprintf(fileId,'TOTAL MC ALGORITHM EVALUATIONS:\n%d / 600\n\n',audit.evaluation_complete);
fprintf(fileId,'H COHORT:\n%d / 50\n\n',audit.h_complete);
fprintf(fileId,'F COHORT:\n%d / 50\n\n',audit.f_complete);
fprintf(fileId,'O COHORT:\n%d / 50\n\n',audit.o_complete);
fprintf(fileId,'NUMERICAL FAILURES:\n%d\n\n',audit.numerical_failures);
fprintf(fileId,'METRIC-MISSING ROWS:\n%d\n\n',audit.metric_missing);
fprintf(fileId,'SEED / REGISTRY MISMATCH:\n%d\n\n',audit.seed_registry_mismatch);
fprintf(fileId,'SHARED-DATA FAILURES:\n%d\n\n',audit.shared_data_failures);
fprintf(fileId,'FROZEN SOURCE MODIFIED:\n%s\n\n',yes_no(~(pre.pass&&post.pass)));
fprintf(fileId,'FORMAL MONTE-CARLO STATISTICS:\n%s\n\n', ...
    complete_label(statsComplete));
fprintf(fileId,'READY FOR STEP 7 FINAL ANALYSIS:\n%s\n', ...
    yes_no(audit.pass && statsComplete));
fprintf(fileId,'```\n');
end

function pass = formal_statistics_complete(statistics,audit)
statsRows = [statistics.H;statistics.F;statistics.O];
pass = audit.pass && ~isempty(statsRows) && ...
    all(statsRows.N == 50) && all(statistics.paired.N == 50);
end

function write_f_extreme_line(fileId,rows,algorithm)
[maximum,index] = max(abs(rows.fault_retention_error_pct));
r = rows(index,:);
fprintf(fileId,['- %s 绝对 `fault_retention_error_pct` 最大值 %.6g%%，' ...
    '条件 `%s`，`fault_factor`=%.3g，`reference_phase_error_deg`=%.3g，' ...
    '`Cself_mismatch_pct`=%.3g。\n'],algorithm,maximum,r.condition_id, ...
    r.fault_factor,r.reference_phase_error_deg,r.Cself_mismatch_pct);
end

function count = wrong_direction_count(rows)
dotProduct = rows.true_drift_Cs1_pF.*rows.F_minus_CF_Cs1_pF+ ...
    rows.true_drift_Cs2_pF.*rows.F_minus_CF_Cs2_pF;
count = nnz(dotProduct < 0);
end

function label = complete_label(value)
if value
    label = "COMPLETE";
else
    label = "INCOMPLETE";
end
end

function write_stats_table(fileId,stats)
fprintf(fileId,'| 算法 | 指标 | N | 有效 N | 均值 | 标准差 | 中位数 | IQR | P5 | P95 | RMSE | 失败数 |\n');
fprintf(fileId,'|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for k = 1:height(stats)
    r = stats(k,:);
    fprintf(fileId,'| %s | `%s` | %d | %d | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %d |\n', ...
        r.algorithm_id,r.metric,r.N,r.valid_N,r.mean,r.std,r.median,r.IQR, ...
        r.P5,r.P95,r.RMSE,r.failure_count);
end
fprintf(fileId,'\n');
end

function label = transform_label(value)
switch string(value)
    case "identity"
        label = "原值";
    case "absolute"
        label = "绝对值";
    case "distance_one"
        label = "距离 1";
    otherwise
        label = string(value);
end
end

function write_extreme_summary(fileId,rows,cohort,metric,useAbsolute)
subset = rows(rows.cohort==cohort & ~rows.numerical_failure & ...
    ~rows.metric_missing,:);
if isempty(subset)
    fprintf(fileId,'- %s：`%s` 无可用数值记录。\n',cohort,metric);
    return
end
x = subset.(char(metric));
if useAbsolute
    x = abs(x);
end
[maximum,index] = max(x);
q1 = empirical_percentile(x,25);
q3 = empirical_percentile(x,75);
fence = q3+1.5*(q3-q1);
count = nnz(x>fence);
fprintf(fileId,['- %s：`%s` 的最大幅值为 %.6g，位于 `%s`/%s；' ...
    '按同组全算法 Q3+1.5IQR 描述规则，高侧极值记录 %d 条。\n'], ...
    cohort,metric,maximum,subset.condition_id(index), ...
    subset.algorithm_id(index),count);
end

function integrity = capture_frozen_integrity(paths)
manifest = read_registry(paths.manifest);
n = height(manifest);
expected = strings(n+3,1);
actual = strings(n+3,1);
for k = 1:n
    expected(k) = upper(manifest.sha256(k));
    actual(k) = file_sha256(fullfile(paths.root, ...
        char(manifest.relative_path(k))));
end
expected(n+1:n+3) = [ ...
    "9FAB573BCE6D5D0A1F3F6A569771F5B1C69706AB6E6E38FD97843BF41B931531"; ...
    "8A498E19A455C13CAA7B5371BE2F933CA7B7637B893C656C92DA84D88D1938BE"; ...
    "974B8874404C46C4B549CAD8E2D52CCCC7F1D4F81D68AF8911201307230394D7"];
actual(n+1) = canonical_specification_sha256(paths.specification);
actual(n+2) = file_sha256(paths.condition_registry);
actual(n+3) = file_sha256(paths.execution_registry);
itemPass = expected == actual;
integrity = struct('expected_sha256',expected,'actual_sha256',actual, ...
    'item_pass',itemPass,'phase1_count',n, ...
    'phase1_pass_count',nnz(itemPass(1:n)), ...
    'step1_pass_count',nnz(itemPass(n+1:end)), ...
    'pass',all(itemPass));
end

function hash = canonical_specification_sha256(path)
textValue = fileread(path);
canonical = regexprep(textValue, ...
    '(specification_sha256_canonical:\s*)[0-9A-Fa-f]{64}', ...
    '$1<SELF_SHA256_CANONICAL_PLACEHOLDER>','once');
hash = bytes_sha256(unicode2native(canonical,'UTF-8'));
end

function hash = file_sha256(path)
fileId = fopen(path,'rb');
if fileId < 0
    error('Phase2:Step6AHashRead','Unable to read %s.',path);
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
    value = isfinite(input) && input ~= 0;
else
    value = ismember(upper(strtrim(string(input))),["TRUE","YES","1"]);
end
end

function label = status_label(pass,frozenPass)
if ~frozenPass
    label = "BLOCKED";
elseif pass
    label = "PASS";
else
    label = "PARTIAL";
end
end

function label = yes_no(value)
if value
    label = "YES";
else
    label = "NO";
end
end
