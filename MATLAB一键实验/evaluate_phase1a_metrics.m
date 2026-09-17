function metrics = evaluate_phase1a_metrics( ...
        caseInfo,algorithmResult,data,cfg,metadata)
%EVALUATE_PHASE1A_METRICS Evaluate one Phase 1A case-algorithm result.
% This function only evaluates existing data and does not run an algorithm.

caseName = scalar_string(required_value(caseInfo,"case_name"), ...
    'Phase1A:InvalidCaseInfo','case_name');
caseRegistry = phase1a_case_registry();
if ~any(caseRegistry.case_name == caseName)
    error('Phase1A:UnknownCase','Unknown Phase 1A case: "%s".',caseName);
end

algorithmMode = scalar_string( ...
    required_value(algorithmResult,"algorithm_mode"), ...
    'Phase1A:UnknownAlgorithmMode','algorithm_mode');
algorithmMode = upper(algorithmMode);
algorithmRegistry = phase1a_algorithm_registry();
if ~any(algorithmRegistry.enabled & ...
        algorithmRegistry.algorithm_mode == algorithmMode)
    error('Phase1A:UnknownAlgorithmMode', ...
        'Unknown Phase 1A algorithm_mode: "%s".',algorithmMode);
end

t = column_vector(required_value(data,"t"));
Cs1True = column_vector(required_value(data,"Cs1"));
Cs2True = column_vector(required_value(data,"Cs2"));
column_vector(required_value(data,"irA"));
irBTrue = column_vector(required_value(data,"irB"));
column_vector(required_value(data,"irC"));
cHist = required_value(algorithmResult,"cHist");
ir = required_value(algorithmResult,"ir");
validate_series_sizes(t,Cs1True,Cs2True,irBTrue,cHist,ir);

metricStart = scalar_numeric(required_value(cfg,"metric_start"), ...
    'metric_start');
fundamentalFrequency = scalar_numeric(required_value(cfg,"f"),'f');
metricIdx = t >= metricStart;
if ~any(metricIdx)
    error('Phase1A:EmptyMetricWindow', ...
        'No samples exist at or after cfg.metric_start.');
end

Cs1Rmse = sqrt(mean((cHist(metricIdx,1)-Cs1True(metricIdx)).^2));
Cs2Rmse = sqrt(mean((cHist(metricIdx,2)-Cs2True(metricIdx)).^2));
legacyMetrics = evaluate_case_metrics(data,ir,cHist, ...
    algorithmMode,caseName,cfg);
bFundamentalError = legacyMetrics.B_FundErr_pct;

faultFactorTrue = NaN;
faultFactorEst = NaN;
faultRetentionError = NaN;
Cs1PrePostChange = NaN;
Cs2PrePostChange = NaN;
isFaultCase = any(caseName == ...
    ["Case05_fault_only","Case06_drift_then_fault"]);
if isFaultCase
    [preIdx,postIdx] = fault_windows(t);
    faultFactorTrue = fault_factor(t,irBTrue,preIdx,postIdx, ...
        fundamentalFrequency);
    faultFactorEst = fault_factor(t,column_vector(ir.B), ...
        preIdx,postIdx,fundamentalFrequency);
    faultRetentionError = ...
        (faultFactorEst-faultFactorTrue)/faultFactorTrue*100;
    Cs1PrePostChange = mean(cHist(postIdx,1))-mean(cHist(preIdx,1));
    Cs2PrePostChange = mean(cHist(postIdx,2))-mean(cHist(preIdx,2));
end

[firstGateTrigger,gateDurationCycles,gateDurationS] = ...
    gate_metrics(algorithmMode,algorithmResult,fundamentalFrequency);

randomSeed = scalar_numeric(required_value(caseInfo,"seed"),'seed');
modelFile = scalar_string(required_value(caseInfo,"model"), ...
    'Phase1A:InvalidCaseInfo','model');
modelSha256 = scalar_string(required_value(metadata,"model_sha256"), ...
    'Phase1A:InvalidMetadata','model_sha256');
runTimestamp = scalar_string(required_value(metadata,"run_timestamp"), ...
    'Phase1A:InvalidMetadata','run_timestamp');
gitCommit = scalar_string(required_value(metadata,"git_commit"), ...
    'Phase1A:InvalidMetadata','git_commit');
gitBranch = scalar_string(required_value(metadata,"git_branch"), ...
    'Phase1A:InvalidMetadata','git_branch');
gitDirtyStatus = scalar_string( ...
    required_value(metadata,"git_dirty_status"), ...
    'Phase1A:InvalidMetadata','git_dirty_status');

schema = phase1a_result_schema();
metrics = table(caseName,algorithmMode,Cs1Rmse,Cs2Rmse, ...
    bFundamentalError,faultFactorTrue,faultFactorEst, ...
    faultRetentionError,Cs1PrePostChange,Cs2PrePostChange, ...
    firstGateTrigger,gateDurationCycles,gateDurationS,randomSeed, ...
    modelFile,modelSha256,runTimestamp,gitCommit,gitBranch, ...
    gitDirtyStatus,'VariableNames',cellstr(schema.variable_names));
end

function value = required_value(container,name)
fieldName = char(name);
if istable(container)
    if height(container) ~= 1 || ...
            ~ismember(name,string(container.Properties.VariableNames))
        error('Phase1A:MissingInputField', ...
            'A one-row input table must contain field "%s".',name);
    end
    value = container.(fieldName);
elseif isstruct(container) && isscalar(container) && ...
        isfield(container,fieldName)
    value = container.(fieldName);
else
    error('Phase1A:MissingInputField', ...
        'Required input field "%s" is missing.',name);
end
end

function value = scalar_string(inputValue,errorId,fieldName)
value = string(inputValue);
if ~isscalar(value) || ismissing(value) || strlength(strtrim(value)) == 0
    error(errorId,'Field "%s" must be a nonempty string scalar.',fieldName);
end
value = strtrim(value);
end

function value = scalar_numeric(inputValue,fieldName)
if ~(isnumeric(inputValue) && isscalar(inputValue) && isfinite(inputValue))
    error('Phase1A:InvalidNumericInput', ...
        'Field "%s" must be a finite numeric scalar.',fieldName);
end
value = double(inputValue);
end

function value = column_vector(inputValue)
if ~(isnumeric(inputValue) && isvector(inputValue) && ...
        all(isfinite(inputValue)))
    error('Phase1A:InvalidNumericInput', ...
        'Time-series inputs must be finite numeric vectors.');
end
value = inputValue(:);
end

function validate_series_sizes(t,Cs1True,Cs2True,irBTrue,cHist,ir)
n = numel(t);
if numel(Cs1True) ~= n || numel(Cs2True) ~= n || ...
        numel(irBTrue) ~= n || ~isnumeric(cHist) || ...
        ~isequal(size(cHist),[n,2])
    error('Phase1A:InvalidInputSize', ...
        'Truth signals and cHist must align with data.t.');
end
if ~(isstruct(ir) && isscalar(ir) && ...
        all(isfield(ir,{'A','B','C'})))
    error('Phase1A:MissingInputField', ...
        'algorithmResult.ir must contain A, B, and C.');
end
if numel(ir.A) ~= n || numel(ir.B) ~= n || numel(ir.C) ~= n
    error('Phase1A:InvalidInputSize', ...
        'Extracted resistive-current signals must align with data.t.');
end
end

function [preIdx,postIdx] = fault_windows(t)
preIdx = t >= 2.60 & t < 2.90;
postIdx = t >= 3.40 & t < 3.80;
if ~any(preIdx) || ~any(postIdx)
    error('Phase1A:MissingFaultWindow', ...
        'Fault cases require samples in [2.60,2.90) and [3.40,3.80) s.');
end
end

function value = fault_factor(t,x,preIdx,postIdx,f)
value = fundamental_rms(t(postIdx),x(postIdx),f) / ...
    (fundamental_rms(t(preIdx),x(preIdx),f)+eps);
end

function value = fundamental_rms(t,x,f)
w = 2*pi*f;
coefficients = [sin(w*t),cos(w*t),ones(size(t))]\x;
value = hypot(coefficients(1),coefficients(2))/sqrt(2);
end

function [firstTrigger,durationCycles,durationS] = ...
        gate_metrics(algorithmMode,algorithmResult,f)
firstTrigger = NaN;
durationCycles = NaN;
durationS = NaN;
if algorithmMode ~= "M3"
    return
end
tracker = required_value(algorithmResult,"tracker");
if ~(isstruct(tracker) && isscalar(tracker) && isfield(tracker,'cycle') && ...
        istable(tracker.cycle) && ...
        all(ismember(["time_s","gate"], ...
        string(tracker.cycle.Properties.VariableNames))))
    error('Phase1A:MissingGateLog', ...
        'M3 requires tracker.cycle with time_s and gate columns.');
end
gateActive = tracker.cycle.gate > 0;
if any(gateActive)
    firstTrigger = tracker.cycle.time_s(find(gateActive,1,'first'));
    durationCycles = sum(gateActive);
    durationS = durationCycles/f;
end
end
