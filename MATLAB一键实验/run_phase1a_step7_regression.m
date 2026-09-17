function verification = run_phase1a_step7_regression()
%RUN_PHASE1A_STEP7_REGRESSION Verify formal CSV against frozen history.
% This function reads existing results only. It does not run any algorithm.

matlabRoot = fileparts(mfilename('fullpath'));
projectRoot = fileparts(matlabRoot);
csvPath = fullfile(projectRoot,'paper_research', ...
    'phase1a_baseline','baseline_summary.csv');
expectedCsvHash = ...
    "E7BEB3ECFEDF521105B67198684752BB32AFAAEFD84ACA80822BA57FBD9D0AB3";
csvHash = file_sha256(csvPath);
if csvHash ~= expectedCsvHash
    error('Phase1A:Step7CsvIntegrityFailure', ...
        'Formal baseline CSV SHA-256 does not match Step 6.');
end

formal = readtable(csvPath,'TextType','string');
reference = phase1a_historical_reference();
caseName = [ ...
    repmat("Case02_slow_drift",4,1)
    repmat("Case06_drift_then_fault",7,1)
    ];
algorithmMode = ["M0";"M3";"M3";"M3"; ...
    "TRUTH";"M2";"M2";"M2";"M3";"M3";"M3"];
metricName = [ ...
    "B_resistive_fundamental_error_pct"
    "B_resistive_fundamental_error_pct"
    "Cs1_RMSE_pF"
    "Cs2_RMSE_pF"
    "fault_factor_true"
    "Cs1_pre_post_change_pF"
    "Cs2_pre_post_change_pF"
    "fault_factor_est"
    "Cs1_pre_post_change_pF"
    "Cs2_pre_post_change_pF"
    "fault_factor_est"
    ];
historicalValue = [ ...
    reference.Case02_slow_drift.M0. ...
    B_resistive_fundamental_error_pct
    reference.Case02_slow_drift.M3. ...
    B_resistive_fundamental_error_pct
    reference.Case02_slow_drift.M3.Cs1_RMSE_pF
    reference.Case02_slow_drift.M3.Cs2_RMSE_pF
    reference.Case06_drift_then_fault.fault_factor_true
    reference.Case06_drift_then_fault.M2.Cs1_pre_post_change_pF
    reference.Case06_drift_then_fault.M2.Cs2_pre_post_change_pF
    reference.Case06_drift_then_fault.M2.fault_factor_est
    reference.Case06_drift_then_fault.M3.Cs1_pre_post_change_pF
    reference.Case06_drift_then_fault.M3.Cs2_pre_post_change_pF
    reference.Case06_drift_then_fault.M3.fault_factor_est
    ];

formalBaselineValue = zeros(size(historicalValue));
for k = 1:numel(historicalValue)
    lookupMode = algorithmMode(k);
    if lookupMode == "TRUTH"
        lookupMode = "M0";
    end
    row = formal.case_name == caseName(k) & ...
        formal.algorithm_mode == lookupMode;
    if nnz(row) ~= 1
        error('Phase1A:Step7FormalRowFailure', ...
            'Expected one formal row for %s/%s.',caseName(k),lookupMode);
    end
    formalBaselineValue(k) = formal.(metricName(k))(row);
end

absoluteDifference = abs(formalBaselineValue-historicalValue);
relativeDifference = absoluteDifference./(abs(historicalValue)+eps);
absoluteTolerance = repmat(reference.absolute_tolerance, ...
    size(historicalValue));
relativeTolerance = repmat(reference.relative_tolerance, ...
    size(historicalValue));
pass = absoluteDifference <= absoluteTolerance+ ...
    relativeTolerance.*abs(historicalValue);
regression = table(caseName,algorithmMode,metricName,historicalValue, ...
    formalBaselineValue,absoluteDifference,relativeDifference, ...
    absoluteTolerance,relativeTolerance,pass, ...
    'VariableNames',{'case_name','algorithm_mode','metric_name', ...
    'historical_value','formal_baseline_value','absolute_difference', ...
    'relative_difference','absolute_tolerance','relative_tolerance', ...
    'pass'});

case02Pass = all(pass(caseName == "Case02_slow_drift"));
case06Pass = all(pass(caseName == "Case06_drift_then_fault"));
overallPass = height(regression) == 11 && case02Pass && case06Pass;
verification = struct( ...
    'formal_csv_path',string(csvPath), ...
    'formal_csv_sha256',csvHash, ...
    'historical_reference_source', ...
    "MATLAB一键实验/phase1a_historical_reference.m", ...
    'regression',regression, ...
    'case02_pass_count',nnz(pass(caseName == "Case02_slow_drift")), ...
    'case06_pass_count',nnz(pass(caseName == "Case06_drift_then_fault")), ...
    'total_pass_count',nnz(pass), ...
    'historical_results_reproduced',overallPass, ...
    'overall_pass',overallPass);

disp(regression);
fprintf('CASE02_HISTORICAL_REGRESSION=%d/4 PASS\n', ...
    verification.case02_pass_count);
fprintf('CASE06_HISTORICAL_REGRESSION=%d/7 PASS\n', ...
    verification.case06_pass_count);
fprintf('TOTAL_HISTORICAL_REGRESSION=%d/11 PASS\n', ...
    verification.total_pass_count);
fprintf('HISTORICAL_RESULTS_REPRODUCED=%s\n', ...
    pass_label(verification.historical_results_reproduced));
fprintf('STEP7_HISTORICAL_REGRESSION=%s\n', ...
    pass_label(verification.overall_pass));
if ~verification.overall_pass
    error('Phase1A:Step7HistoricalRegressionFailure', ...
        'Formal historical regression did not pass 11/11 checks.');
end
end

function hash = file_sha256(path)
fileId = fopen(path,'rb');
if fileId < 0
    error('Phase1A:HashFailure','Unable to compute SHA-256 for %s.',path);
end
cleanup = onCleanup(@() fclose(fileId));
bytes = fread(fileId,Inf,'*uint8');
digester = java.security.MessageDigest.getInstance('SHA-256');
digester.update(bytes);
hashBytes = typecast(digester.digest(),'uint8');
hash = upper(string(reshape(dec2hex(hashBytes,2).',1,[])));
end

function label = pass_label(value)
if value
    label = "PASS";
else
    label = "FAIL";
end
end
