function run_m5_step0_direction_analysis()
%RUN_M5_STEP0_DIRECTION_ANALYSIS Analyze frozen fault-bias directions only.
% This function does not call Simulink and does not run or modify any tracker.

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(scriptDir)));
figureDir = fullfile(scriptDir,'figures');
if ~isfolder(figureDir)
    mkdir(figureDir);
end

nearZeroThresholdPF = 1e-9;
dDiff = [1;-1]/sqrt(2);
samples = repmat(empty_sample(),0,1);

%% Phase 1B development data: frozen recursive fault-induced bias.
case05File = fullfile(projectRoot,'paper_research','phase1b_fault_absorption', ...
    'step2','case05_key_metrics.csv');
case05 = readtable(case05File,TextType='string',VariableNamingRule='preserve');
samples(end+1) = make_sample( ...
    'P1B_CASE05_NOMINAL','PHASE1B_CASE05','Case05_fault_only', ...
    'Case05_nominal_f160_phase0',case05.true_fault_factor(1),'M2', ...
    case05.recursive_fault_induced_Delta_Cs1_pF(1), ...
    case05.recursive_fault_induced_Delta_Cs2_pF(1),'DEVELOPMENT','FORMAL', ...
    relative_path(case05File,projectRoot), ...
    'direct frozen recursive_fault_induced_Delta_Cs1/2_pF', ...
    'Case05 frozen nominal anchor; also the 1.60/0-deg anchor of Step4.');

case06File = fullfile(projectRoot,'paper_research','phase1b_fault_absorption', ...
    'step3','case06_key_metrics.csv');
case06 = readtable(case06File,TextType='string',VariableNamingRule='preserve');
samples(end+1) = make_sample( ...
    'P1B_CASE06_NOMINAL','PHASE1B_CASE06','Case06_drift_then_fault', ...
    'Case06_nominal_f160',case06.true_fault_factor(1),'M2', ...
    case06.recursive_fault_induced_Delta_Cs1_pF(1), ...
    case06.recursive_fault_induced_Delta_Cs2_pF(1),'DEVELOPMENT','FORMAL', ...
    relative_path(case06File,projectRoot), ...
    'direct frozen recursive_fault_induced_Delta_Cs1/2_pF', ...
    'Case06 frozen drift-then-fault anchor.');

factorFile = fullfile(projectRoot,'paper_research','phase1b_fault_absorption', ...
    'step4','controlled_factor_summary.csv');
factorTable = readtable(factorFile,TextType='string',VariableNamingRule='preserve');
duplicateAnchor = factorTable.condition_id == 'fault_factor_1p60_phase_0deg';
for k = find(~duplicateAnchor).'
    if factorTable.factor_type(k) == 'fault_amplitude'
        dataset = 'PHASE1B_FAULT_AMPLITUDE';
    else
        dataset = 'PHASE1B_REFERENCE_PHASE';
    end
    samples(end+1) = make_sample( ...
        'P1B_STEP4_' + factorTable.condition_id(k),dataset,'Case05_fault_only', ...
        factorTable.condition_id(k),factorTable.fault_factor_true(k),'M2', ...
        factorTable.DeltaCs1_fault_induced(k), ...
        factorTable.DeltaCs2_fault_induced(k),'DEVELOPMENT','FORMAL', ...
        relative_path(factorFile,projectRoot), ...
        'direct frozen DeltaCs1/2_fault_induced', ...
        'Unique controlled-factor condition; the duplicated 1.60/0-deg anchor is represented by Case05.');
end

T = struct2table(samples);
developmentMask = T.data_role == 'DEVELOPMENT' & T.analysis_scope == 'FORMAL';
devNorm = hypot(T.delta_Cs1_fault_pF(developmentMask), ...
    T.delta_Cs2_fault_pF(developmentMask));
devValid = isfinite(devNorm) & devNorm > nearZeroThresholdPF;
if nnz(devValid) < 2
    error('M5:InsufficientDevelopmentData', ...
        'At least two nonzero Phase1B development vectors are required.');
end
devRows = find(developmentMask);
devRows = devRows(devValid);
D = [T.delta_Cs1_fault_pF(devRows)./devNorm(devValid), ...
     T.delta_Cs2_fault_pF(devRows)./devNorm(devValid)];
[~,S,V] = svd(D,'econ');
dF = V(:,1);
if dot(dF,dDiff) < 0
    dF = -dF;
end
developmentEnergyRatio = S(1,1)^2/sum(diag(S).^2);
angleDfDiffDeg = acosd(clamp(abs(dot(dF,dDiff)),0,1));

%% Phase 2 validation and context-only algorithm diagnostics.
detFile = fullfile(projectRoot,'paper_research','phase2_full_validation', ...
    'step2b2_deterministic_core','step2b2_deterministic_results.csv');
det = readtable(detFile,TextType='string',VariableNamingRule='preserve');
for algorithm = ["M2","M3","M4"]
    rows = find(det.algorithm_id == algorithm & ...
        isfinite(det.DeltaCs1_fault_induced_pF) & ...
        isfinite(det.DeltaCs2_fault_induced_pF));
    for k = rows.'
        scope = scope_for_algorithm(algorithm);
        samples(end+1) = make_sample( ...
            'P2_DET_' + det.condition_id(k) + '_' + algorithm, ...
            'PHASE2_DETERMINISTIC',infer_case(det.condition_id(k),det.notes(k)), ...
            det.condition_id(k),det.fault_factor_true(k),algorithm, ...
            det.DeltaCs1_fault_induced_pF(k), ...
            det.DeltaCs2_fault_induced_pF(k),'VALIDATION',scope, ...
            relative_path(detFile,projectRoot), ...
            'direct frozen DeltaCs1/2_fault_induced_pF', ...
            'Phase2 deterministic core.');
    end
end

overlapFile = fullfile(projectRoot,'paper_research','phase2_full_validation', ...
    'step4_overlap_matrix','step4_overlap_results.csv');
overlap = readtable(overlapFile,TextType='string',VariableNamingRule='preserve');
for algorithm = ["M2","M3","M4"]
    rows = find(overlap.record_type == 'MAIN' & overlap.algorithm_id == algorithm & ...
        isfinite(overlap.F_minus_CF_Cs1_pF) & ...
        isfinite(overlap.F_minus_CF_Cs2_pF));
    for k = rows.'
        scope = scope_for_algorithm(algorithm);
        samples(end+1) = make_sample( ...
            'P2_OV_' + overlap.condition_id(k) + '_' + algorithm, ...
            'PHASE2_OVERLAP',overlap.condition_id(k),overlap.condition_id(k), ...
            overlap.fault_factor(k),algorithm, ...
            overlap.F_minus_CF_Cs1_pF(k),overlap.F_minus_CF_Cs2_pF(k), ...
            'VALIDATION',scope,relative_path(overlapFile,projectRoot), ...
            'calculated source: frozen F_movement minus CF_movement; stored as F_minus_CF_Cs1/2_pF', ...
            'Phase2 overlap main record.');
    end
end

mcFile = fullfile(projectRoot,'paper_research','phase2_full_validation', ...
    'step6_monte_carlo_full','step6_monte_carlo_full_results.csv');
mc = readtable(mcFile,TextType='string',VariableNamingRule='preserve');
for algorithm = ["M2","M3","M4"]
    scope = scope_for_algorithm(algorithm);
    rowsF = find(mc.cohort == 'F' & mc.algorithm_id == algorithm & ...
        isfinite(mc.DeltaCs1_fault_induced_pF) & ...
        isfinite(mc.DeltaCs2_fault_induced_pF));
    for k = rowsF.'
        samples(end+1) = make_sample( ...
            'P2_MCF_' + mc.condition_id(k) + '_' + algorithm, ...
            'PHASE2_MC_F','MonteCarlo_F',mc.condition_id(k), ...
            mc.fault_factor(k),algorithm,mc.DeltaCs1_fault_induced_pF(k), ...
            mc.DeltaCs2_fault_induced_pF(k),'VALIDATION',scope, ...
            relative_path(mcFile,projectRoot), ...
            'direct frozen DeltaCs1/2_fault_induced_pF', ...
            'Phase2 Monte-Carlo fault-only cohort.');
    end
    rowsO = find(mc.cohort == 'O' & mc.algorithm_id == algorithm & ...
        isfinite(mc.F_minus_CF_Cs1_pF) & isfinite(mc.F_minus_CF_Cs2_pF));
    for k = rowsO.'
        samples(end+1) = make_sample( ...
            'P2_MCO_' + mc.condition_id(k) + '_' + algorithm, ...
            'PHASE2_MC_O','MonteCarlo_O',mc.condition_id(k), ...
            mc.fault_factor(k),algorithm,mc.F_minus_CF_Cs1_pF(k), ...
            mc.F_minus_CF_Cs2_pF(k),'VALIDATION',scope, ...
            relative_path(mcFile,projectRoot), ...
            'calculated source: frozen F_movement minus CF_movement; stored as F_minus_CF_Cs1/2_pF', ...
            'Phase2 Monte-Carlo overlap cohort.');
    end
end

% Frozen sensitivity results are retained as context only. They deliberately
% vary protection parameters and are not independent physical validation.
sensitivityFile = fullfile(projectRoot,'paper_research','phase2_full_validation', ...
    'step5_sensitivity_validity','step5_sensitivity_results.csv');
sensitivity = readtable(sensitivityFile,TextType='string',VariableNamingRule='preserve');
registryFile = fullfile(projectRoot,'paper_research','phase2_full_validation', ...
    'step1_matrix_spec','phase2_condition_registry.csv');
registry = readtable(registryFile,TextType='string',VariableNamingRule='preserve');
sensRows = find(sensitivity.record_type == 'SENSITIVITY' & ...
    isfinite(sensitivity.fault_induced_Cs1_movement_pF) & ...
    isfinite(sensitivity.fault_induced_Cs2_movement_pF));
for k = sensRows.'
    regIdx = find(registry.condition_id == sensitivity.physical_condition_id(k),1);
    if isempty(regIdx)
        faultFactor = NaN;
    else
        faultFactor = registry.fault_factor(regIdx);
    end
    samples(end+1) = make_sample( ...
        'P2_SENS_' + sensitivity.sensitivity_id(k), ...
        'PHASE2_SENSITIVITY_CONTEXT',sensitivity.physical_condition_id(k), ...
        sensitivity.sensitivity_id(k),faultFactor,sensitivity.algorithm_id(k), ...
        sensitivity.fault_induced_Cs1_movement_pF(k), ...
        sensitivity.fault_induced_Cs2_movement_pF(k),'VALIDATION','CONTEXT_ONLY', ...
        relative_path(sensitivityFile,projectRoot), ...
        'direct frozen fault_induced_Cs1/2_movement_pF', ...
        'Frozen protection-parameter sensitivity; retained as context, excluded from d_f and formal validation.');
end

%% Normalize and align every finite sample to the development direction.
T = struct2table(samples);
T.bias_norm_pF = hypot(T.delta_Cs1_fault_pF,T.delta_Cs2_fault_pF);
finiteBias = isfinite(T.delta_Cs1_fault_pF) & isfinite(T.delta_Cs2_fault_pF);
nearZero = finiteBias & T.bias_norm_pF <= nearZeroThresholdPF;
validDirection = finiteBias & ~nearZero;
T.normalized_d1 = nan(height(T),1);
T.normalized_d2 = nan(height(T),1);
T.alignment_to_df = nan(height(T),1);
T.angle_to_df_deg = nan(height(T),1);
T.normalized_d1(validDirection) = ...
    T.delta_Cs1_fault_pF(validDirection)./T.bias_norm_pF(validDirection);
T.normalized_d2(validDirection) = ...
    T.delta_Cs2_fault_pF(validDirection)./T.bias_norm_pF(validDirection);
alignment = abs(T.normalized_d1(validDirection)*dF(1) + ...
    T.normalized_d2(validDirection)*dF(2));
alignment = clamp(alignment,0,1);
T.alignment_to_df(validDirection) = alignment;
T.angle_to_df_deg(validDirection) = acosd(alignment);
T.opposite_sign = finiteBias & ...
    (T.delta_Cs1_fault_pF.*T.delta_Cs2_fault_pF < 0);
T.direction_status = repmat("VALID",height(T),1);
T.direction_status(nearZero) = "NEAR_ZERO_EXCLUDED_FROM_ANGLE";
T.direction_status(~finiteBias) = "UNAVAILABLE";
T.near_zero_threshold_pF = repmat(nearZeroThresholdPF,height(T),1);

sampleColumns = ["sample_id","dataset","case","condition_id", ...
    "fault_factor","algorithm","delta_Cs1_fault_pF", ...
    "delta_Cs2_fault_pF","bias_norm_pF","normalized_d1", ...
    "normalized_d2","alignment_to_df","angle_to_df_deg", ...
    "opposite_sign","data_role","analysis_scope","direction_status", ...
    "near_zero_threshold_pF","source_file","calculation_source","notes"];
writetable(T(:,sampleColumns),fullfile(scriptDir,'m5_fault_direction_samples.csv'));

%% Requested summary statistics, always referenced to frozen Phase1B d_f.
summaryRows = repmat(empty_summary(),0,1);
devFormal = T.data_role == 'DEVELOPMENT' & T.analysis_scope == 'FORMAL';
summaryRows(end+1) = summarize_rows(T,devFormal,'DEVELOPMENT_ALL','ALL',dF);
summaryRows(end+1) = summarize_rows(T,devFormal & T.case == 'Case05_fault_only', ...
    'DEVELOPMENT_CASE','Case05_fault_only',dF);
summaryRows(end+1) = summarize_rows(T,devFormal & T.case == 'Case06_drift_then_fault', ...
    'DEVELOPMENT_CASE','Case06_drift_then_fault',dF);
ampMask = devFormal & (T.dataset == 'PHASE1B_FAULT_AMPLITUDE' | ...
    T.sample_id == 'P1B_CASE05_NOMINAL');
phaseMask = devFormal & (T.dataset == 'PHASE1B_REFERENCE_PHASE' | ...
    T.sample_id == 'P1B_CASE05_NOMINAL');
summaryRows(end+1) = summarize_rows(T,ampMask, ...
    'DEVELOPMENT_SWEEP','fault_amplitude_1.05_to_1.60',dF);
summaryRows(end+1) = summarize_rows(T,phaseMask, ...
    'DEVELOPMENT_SWEEP','reference_phase_0_to_3deg',dF);
for factor = unique(T.fault_factor(ampMask & isfinite(T.fault_factor))).'
    summaryRows(end+1) = summarize_rows(T,ampMask & T.fault_factor == factor, ...
        'DEVELOPMENT_FAULT_FACTOR',sprintf('fault_factor_%.2f',factor),dF);
end

formalValidation = T.data_role == 'VALIDATION' & T.analysis_scope == 'FORMAL';
summaryRows(end+1) = summarize_rows(T,formalValidation, ...
    'VALIDATION_M2_ALL','ALL',dF);
validationDatasets = unique(T.dataset(formalValidation),'stable');
for dataset = validationDatasets.'
    summaryRows(end+1) = summarize_rows(T,formalValidation & T.dataset == dataset, ...
        char(dataset),char(dataset),dF);
end
for algorithm = ["M3","M4"]
    mask = T.data_role == 'VALIDATION' & T.analysis_scope == 'CONTEXT_ONLY' & ...
        T.algorithm == algorithm & T.dataset ~= 'PHASE2_SENSITIVITY_CONTEXT';
    summaryRows(end+1) = summarize_rows(T,mask, ...
        'VALIDATION_CONTEXT_' + algorithm,'ALL_CORE_DATA',dF);
end
sensitivityMask = T.dataset == 'PHASE2_SENSITIVITY_CONTEXT';
summaryRows(end+1) = summarize_rows(T,sensitivityMask, ...
    'VALIDATION_CONTEXT_SENSITIVITY','ALL',dF);

summaryTable = struct2table(summaryRows);
writetable(summaryTable,fullfile(scriptDir,'m5_fault_direction_summary.csv'));

%% Internal analysis figures only.
make_parameter_space_plot(T,dF,formalValidation,devFormal,figureDir);
make_angle_factor_plot(T,formalValidation,devFormal,figureDir);
make_alignment_histogram(T,formalValidation,devFormal,figureDir);
make_case_plot(T,dF,devFormal,figureDir);

%% Console summary used for the evidence report.
devSummary = summaryTable(summaryTable.dataset == 'DEVELOPMENT_ALL',:);
valSummary = summaryTable(summaryTable.dataset == 'VALIDATION_M2_ALL',:);
fprintf('M5_STEP0_ANALYSIS_COMPLETE\n');
fprintf('NEAR_ZERO_THRESHOLD_PF=%.17g\n',nearZeroThresholdPF);
fprintf('DEVELOPMENT_VALID_N=%d\n',devSummary.n_samples);
fprintf('DF=[%.17g,%.17g]\n',dF(1),dF(2));
fprintf('DEVELOPMENT_DIRECTIONAL_ENERGY_RATIO=%.17g\n',developmentEnergyRatio);
fprintf('DF_TO_DDIFF_ANGLE_DEG=%.17g\n',angleDfDiffDeg);
fprintf('DEVELOPMENT_ANGLE_MEAN_MEDIAN_P90_MAX_DEG=%.17g,%.17g,%.17g,%.17g\n', ...
    devSummary.mean_angle_deg,devSummary.median_angle_deg, ...
    devSummary.p90_angle_deg,devSummary.max_angle_deg);
fprintf('VALIDATION_M2_VALID_N=%d\n',valSummary.n_samples);
fprintf('VALIDATION_M2_NEAR_ZERO_N=%d\n',valSummary.n_near_zero);
fprintf('VALIDATION_M2_ANGLE_MEAN_MEDIAN_P90_MAX_DEG=%.17g,%.17g,%.17g,%.17g\n', ...
    valSummary.mean_angle_deg,valSummary.median_angle_deg, ...
    valSummary.p90_angle_deg,valSummary.max_angle_deg);
fprintf('VALIDATION_M2_DIRECTIONAL_ENERGY_RATIO=%.17g\n', ...
    valSummary.directional_energy_ratio);

formalValidRows = find(formalValidation & T.direction_status == 'VALID');
[~,order] = sort(T.angle_to_df_deg(formalValidRows),'descend');
topRows = formalValidRows(order(1:min(10,numel(order))));
fprintf('TOP_FORMAL_VALIDATION_COUNTEREXAMPLES\n');
for idx = topRows.'
    fprintf('%s,%s,%.17g,%.17g,%.17g\n',T.condition_id(idx), ...
        T.dataset(idx),T.delta_Cs1_fault_pF(idx), ...
        T.delta_Cs2_fault_pF(idx),T.angle_to_df_deg(idx));
end
end

function s = empty_sample()
s = struct('sample_id',"",'dataset',"",'case',"",'condition_id',"", ...
    'fault_factor',NaN,'algorithm',"",'delta_Cs1_fault_pF',NaN, ...
    'delta_Cs2_fault_pF',NaN,'data_role',"",'analysis_scope',"", ...
    'source_file',"",'calculation_source',"",'notes',"");
end

function s = make_sample(sampleId,dataset,caseName,conditionId,faultFactor, ...
    algorithm,delta1,delta2,dataRole,analysisScope,sourceFile,calculationSource,notes)
s = empty_sample();
s.sample_id = string(sampleId);
s.dataset = string(dataset);
s.case = string(caseName);
s.condition_id = string(conditionId);
s.fault_factor = double(faultFactor);
s.algorithm = string(algorithm);
s.delta_Cs1_fault_pF = double(delta1);
s.delta_Cs2_fault_pF = double(delta2);
s.data_role = string(dataRole);
s.analysis_scope = string(analysisScope);
s.source_file = string(sourceFile);
s.calculation_source = string(calculationSource);
s.notes = string(notes);
end

function scope = scope_for_algorithm(algorithm)
if algorithm == 'M2'
    scope = 'FORMAL';
else
    scope = 'CONTEXT_ONLY';
end
end

function caseName = infer_case(conditionId,notes)
if contains(conditionId,'_FO_') || contains(notes,'Case05')
    caseName = 'Case05_fault_only';
elseif contains(conditionId,'_DF_') || contains(notes,'Case06')
    caseName = 'Case06_drift_then_fault';
else
    caseName = string(conditionId);
end
end

function p = relative_path(filePath,projectRoot)
p = string(strrep(erase(string(filePath),string(projectRoot) + filesep),filesep,'/'));
end

function s = empty_summary()
s = struct('dataset',"",'case',"",'n_samples',0,'n_near_zero',0, ...
    'mean_angle_deg',NaN,'median_angle_deg',NaN,'p90_angle_deg',NaN, ...
    'max_angle_deg',NaN,'directional_energy_ratio',NaN);
end

function s = summarize_rows(T,mask,dataset,caseName,dF)
s = empty_summary();
s.dataset = string(dataset);
s.case = string(caseName);
s.n_near_zero = nnz(mask & T.direction_status == 'NEAR_ZERO_EXCLUDED_FROM_ANGLE');
valid = mask & T.direction_status == 'VALID';
angles = T.angle_to_df_deg(valid);
s.n_samples = numel(angles);
if isempty(angles)
    return;
end
s.mean_angle_deg = mean(angles);
s.median_angle_deg = median(angles);
s.p90_angle_deg = percentile_linear(angles,90);
s.max_angle_deg = max(angles);
directions = [T.normalized_d1(valid),T.normalized_d2(valid)];
s.directional_energy_ratio = mean((directions*dF).^2);
end

function value = percentile_linear(x,p)
x = sort(x(:));
if isempty(x)
    value = NaN;
    return;
end
if numel(x) == 1
    value = x;
    return;
end
position = 1 + (numel(x)-1)*(p/100);
lo = floor(position);
hi = ceil(position);
weight = position-lo;
value = x(lo)*(1-weight) + x(hi)*weight;
end

function y = clamp(x,lo,hi)
y = min(max(x,lo),hi);
end

function make_parameter_space_plot(T,dF,formalValidation,devFormal,figureDir)
fig = figure(Visible='off',Color='w',Position=[100 100 900 700]);
ax = axes(fig); hold(ax,'on'); grid(ax,'on'); box(ax,'on');
dev = devFormal & T.direction_status == 'VALID';
val = formalValidation & T.direction_status == 'VALID';
scatter(ax,T.delta_Cs1_fault_pF(val),T.delta_Cs2_fault_pF(val), ...
    34,[0.20 0.50 0.80],'o','MarkerFaceAlpha',0.25, ...
    'DisplayName','Phase2 M2 validation');
scatter(ax,T.delta_Cs1_fault_pF(dev),T.delta_Cs2_fault_pF(dev), ...
    55,[0.85 0.25 0.15],'filled','DisplayName','Phase1B development');
allNorm = T.bias_norm_pF(dev | val);
lineScale = max(allNorm,[],'omitmissing')*1.08;
plot(ax,[-lineScale*dF(1),lineScale*dF(1)], ...
    [-lineScale*dF(2),lineScale*dF(2)],'k-','LineWidth',1.8, ...
    'DisplayName','Phase1B principal direction');
xline(ax,0,'Color',[0.6 0.6 0.6],'HandleVisibility','off');
yline(ax,0,'Color',[0.6 0.6 0.6],'HandleVisibility','off');
xlabel(ax,'\DeltaC_{s1,fault} (pF)');
ylabel(ax,'\DeltaC_{s2,fault} (pF)');
title(ax,'Internal analysis: fault-induced parameter-bias vectors');
legend(ax,Location='best'); axis(ax,'equal');
exportgraphics(fig,fullfile(figureDir,'parameter_space_scatter.png'),Resolution=180);
close(fig);
end

function make_angle_factor_plot(T,formalValidation,devFormal,figureDir)
fig = figure(Visible='off',Color='w',Position=[100 100 900 650]);
ax = axes(fig); hold(ax,'on'); grid(ax,'on'); box(ax,'on');
dev = devFormal & T.direction_status == 'VALID' & isfinite(T.fault_factor);
val = formalValidation & T.direction_status == 'VALID' & isfinite(T.fault_factor);
scatter(ax,T.fault_factor(val),T.angle_to_df_deg(val),32, ...
    [0.20 0.50 0.80],'o','MarkerFaceAlpha',0.25, ...
    'DisplayName','Phase2 M2 validation');
scatter(ax,T.fault_factor(dev),T.angle_to_df_deg(dev),55, ...
    [0.85 0.25 0.15],'filled','DisplayName','Phase1B development');
xlabel(ax,'Fault factor'); ylabel(ax,'Angle to d_f (deg)');
title(ax,'Internal analysis: direction angle versus fault factor');
legend(ax,Location='best');
exportgraphics(fig,fullfile(figureDir,'angle_vs_fault_factor.png'),Resolution=180);
close(fig);
end

function make_alignment_histogram(T,formalValidation,devFormal,figureDir)
fig = figure(Visible='off',Color='w',Position=[100 100 900 650]);
ax = axes(fig); hold(ax,'on'); grid(ax,'on'); box(ax,'on');
dev = devFormal & T.direction_status == 'VALID';
val = formalValidation & T.direction_status == 'VALID';
edges = 0:0.025:1;
histogram(ax,T.alignment_to_df(val),edges,'Normalization','probability', ...
    'FaceColor',[0.20 0.50 0.80],'FaceAlpha',0.45, ...
    'DisplayName','Phase2 M2 validation');
histogram(ax,T.alignment_to_df(dev),edges,'Normalization','probability', ...
    'FaceColor',[0.85 0.25 0.15],'FaceAlpha',0.55, ...
    'DisplayName','Phase1B development');
xlabel(ax,'|d_i^T d_f|'); ylabel(ax,'Probability');
title(ax,'Internal analysis: alignment distribution');
legend(ax,Location='northwest');
exportgraphics(fig,fullfile(figureDir,'alignment_distribution.png'),Resolution=180);
close(fig);
end

function make_case_plot(T,dF,devFormal,figureDir)
fig = figure(Visible='off',Color='w',Position=[100 100 850 750]);
ax = axes(fig); hold(ax,'on'); grid(ax,'on'); box(ax,'on');
case05 = devFormal & T.case == 'Case05_fault_only' & T.direction_status == 'VALID';
case06 = devFormal & T.case == 'Case06_drift_then_fault' & T.direction_status == 'VALID';
quiver(ax,zeros(nnz(case05),1),zeros(nnz(case05),1), ...
    T.normalized_d1(case05),T.normalized_d2(case05),0, ...
    'Color',[0.85 0.25 0.15],'LineWidth',1.0,'MaxHeadSize',0.18, ...
    'DisplayName','Case05 family');
quiver(ax,zeros(nnz(case06),1),zeros(nnz(case06),1), ...
    T.normalized_d1(case06),T.normalized_d2(case06),0, ...
    'Color',[0.20 0.50 0.80],'LineWidth',2.2,'MaxHeadSize',0.22, ...
    'DisplayName','Case06');
quiver(ax,0,0,dF(1),dF(2),0,'k','LineWidth',2.5, ...
    'MaxHeadSize',0.22,'DisplayName','d_f');
xline(ax,0,'Color',[0.7 0.7 0.7],'HandleVisibility','off');
yline(ax,0,'Color',[0.7 0.7 0.7],'HandleVisibility','off');
xlabel(ax,'Normalized \DeltaC_{s1}');
ylabel(ax,'Normalized \DeltaC_{s2}');
title(ax,'Internal analysis: Case05/Case06 normalized directions');
axis(ax,'equal'); xlim(ax,[-1.05 1.05]); ylim(ax,[-1.05 1.05]);
legend(ax,Location='best');
exportgraphics(fig,fullfile(figureDir,'case05_case06_direction.png'),Resolution=180);
close(fig);
end
