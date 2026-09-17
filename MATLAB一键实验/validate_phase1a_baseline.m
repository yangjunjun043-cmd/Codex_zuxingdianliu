function validation = validate_phase1a_baseline(resultsTable,cfg, ...
        caseRegistry,algorithmRegistry,resultSchema,historicalReference, ...
        runMetadata,caseData,algorithmResults,frozenIntegrity,projectRoot)
%VALIDATE_PHASE1A_BASELINE Apply the frozen Step 6 checks A through S.

checks = table('Size',[0,4], ...
    'VariableTypes',{'string','string','logical','string'}, ...
    'VariableNames',{'check_id','check_name','pass','details'});

expectedModelHash = phase1a_baseline_metadata().baseline_model_sha256;
checks = add_check(checks,"A","AutoComp9 SHA correct", ...
    runMetadata.model_sha256 == expectedModelHash,runMetadata.model_sha256);

caseNames = caseRegistry.case_name;
algorithmModes = algorithmRegistry.algorithm_mode;
caseFields = string(fieldnames(caseData));
algorithmCaseFields = string(fieldnames(algorithmResults));
allCasesPresent = numel(caseFields) == 6 && ...
    all(ismember(caseNames,caseFields)) && ...
    all(ismember(caseNames,algorithmCaseFields));
checks = add_check(checks,"B","All six cases completed", ...
    allCasesPresent,sprintf('%d caseData entries',numel(caseFields)));

oneDataPerCase = runMetadata.case_level_simulator_calls == 6 && ...
    numel(caseFields) == 6;
checks = add_check(checks,"C","One formal data set per case", ...
    oneDataPerCase,sprintf('%d case-level calls', ...
    runMetadata.case_level_simulator_calls));

sharedData = runMetadata.shared_data_per_case && ...
    algorithms_complete(algorithmResults,caseNames,algorithmModes);
checks = add_check(checks,"D","M0/M2/M3 share case data",sharedData, ...
    "One simulation precedes all three dispatcher calls in each case loop");

checks = add_check(checks,"E","Result row count",height(resultsTable) == 18, ...
    sprintf('%d rows',height(resultsTable)));
checks = add_check(checks,"F","Six unique cases", ...
    numel(unique(resultsTable.case_name)) == 6, ...
    sprintf('%d unique cases',numel(unique(resultsTable.case_name))));
checks = add_check(checks,"G","Three unique algorithms", ...
    numel(unique(resultsTable.algorithm_mode)) == 3, ...
    sprintf('%d unique algorithms', ...
    numel(unique(resultsTable.algorithm_mode))));

pairs = resultsTable.case_name+"|"+resultsTable.algorithm_mode;
pairCountsCorrect = numel(unique(pairs)) == 18 && ...
    all(groupcounts(resultsTable.case_name) == 3) && ...
    all(groupcounts(resultsTable.algorithm_mode) == 6);
checks = add_check(checks,"H","Unique and complete case-algorithm pairs", ...
    pairCountsCorrect,sprintf('%d unique pairs',numel(unique(pairs))));

actualNames = string(resultsTable.Properties.VariableNames).';
actualTypes = strings(width(resultsTable),1);
for k = 1:width(resultsTable)
    actualTypes(k) = string(class(resultsTable.(actualNames(k))));
end
schemaCorrect = isequal(actualNames,resultSchema.variable_names) && ...
    isequal(actualTypes,resultSchema.variable_types);
checks = add_check(checks,"I","Frozen schema exact",schemaCorrect, ...
    sprintf('%d fields in frozen order and type',width(resultsTable)));

[nanRulesCorrect,nanDetails] = validate_nan_rules(resultsTable);
checks = add_check(checks,"J","Frozen NaN rules", ...
    nanRulesCorrect,nanDetails);

[numericValid,numericDetails] = validate_numeric_values(resultsTable);
checks = add_check(checks,"K","No Inf or complex values", ...
    numericValid,numericDetails);

[metadataValid,metadataDetails] = validate_metadata( ...
    resultsTable,caseRegistry,runMetadata);
checks = add_check(checks,"L","Metadata complete", ...
    metadataValid,metadataDetails);

case04 = caseData.Case04_random_drift;
tInput = (0:cfg.Ts:cfg.StopTime).';
randomA = generate_coupling_signals(tInput,"Case04_random_drift",104);
randomB = generate_coupling_signals(tInput,"Case04_random_drift",104);
case04Valid = case04.seed == 104 && ...
    isequal(randomA.Cs1_pF,randomB.Cs1_pF) && ...
    isequal(randomA.Cs2_pF,randomB.Cs2_pF) && ...
    max(abs(case04.Cs1_true-randomA.Cs1_pF)) <= 1e-10 && ...
    max(abs(case04.Cs2_true-randomA.Cs2_pF)) <= 1e-10;
checks = add_check(checks,"M","Case04 seed and determinism",case04Valid, ...
    "seed=104; regenerated trajectory is sample-identical");

case05 = caseData.Case05_fault_only;
case05Valid = case05.seed == 106 && ...
    all(abs(case05.Cs1_true-10) <= 1e-10) && ...
    all(abs(case05.Cs2_true-10) <= 1e-10);
checks = add_check(checks,"N","Case05 fixed coupling",case05Valid, ...
    "seed=106; Cs1=Cs2=10 pF throughout");

case06 = caseData.Case06_drift_then_fault;
faultProfilesMatch = isequal(case05.fault_scale,case06.fault_scale);
checks = add_check(checks,"O","Case05/06 fault profiles match", ...
    faultProfilesMatch,"Sample-identical fault_scale vectors");

[historicalPass,historicalSanity] = historical_sanity( ...
    resultsTable,historicalReference);
checks = add_check(checks,"P","Case02/06 Step 5 sanity", ...
    historicalPass,sprintf('%d/%d frozen values within tolerance', ...
    nnz(historicalSanity.pass),height(historicalSanity)));

modelHashAfter = file_sha256(runMetadata.model_path);
checks = add_check(checks,"Q","AutoComp9 unchanged by run", ...
    modelHashAfter == runMetadata.model_sha256,modelHashAfter);

[frozenFilesPass,frozenIntegrityAfter] = ...
    validate_frozen_files(frozenIntegrity,fileparts(runMetadata.model_path));
checks = add_check(checks,"R","Frozen algorithm core unchanged", ...
    frozenFilesPass,sprintf('%d/%d hashes unchanged', ...
    nnz(frozenIntegrityAfter.unchanged),height(frozenIntegrityAfter)));

[historyStatus,historyOutput] = system(sprintf( ...
    ['git -C "%s" status --porcelain --untracked-files=all -- ' ...
    'results results_phase1 results_phase2'],projectRoot));
historyUntouched = historyStatus == 0 && ...
    strlength(strtrim(string(historyOutput))) == 0;
checks = add_check(checks,"S","Historical result directories untouched", ...
    historyUntouched,empty_label(historyOutput));

case03 = caseData.Case03_smooth_step;
case03TransitionValid = abs(case03.Cs1_true(1)-10) <= 1e-10 && ...
    abs(case03.Cs1_true(end)-15) <= 1e-10 && ...
    abs(case03.Cs2_true(1)-10) <= 1e-10 && ...
    abs(case03.Cs2_true(end)-6) <= 1e-10 && ...
    any(case03.Cs1_true > 10 & case03.Cs1_true < 15) && ...
    any(case03.Cs2_true < 10 & case03.Cs2_true > 6);
if ~case03TransitionValid
    checks.pass(checks.check_id == "M") = false;
    checks.details(checks.check_id == "M") = ...
        checks.details(checks.check_id == "M")+ ...
        "; Case03 smooth transition invalid";
end

validation = struct();
validation.checks = checks;
validation.overall_pass = all(checks.pass) && case03TransitionValid;
validation.case03_smooth_transition_pass = case03TransitionValid;
validation.case03_endpoints_pF = [case03.Cs1_true(1), ...
    case03.Cs1_true(end),case03.Cs2_true(1),case03.Cs2_true(end)];
validation.historical_sanity = historicalSanity;
validation.frozen_integrity_after = frozenIntegrityAfter;
validation.model_sha256_after = modelHashAfter;
validation.history_git_status = strtrim(string(historyOutput));
end

function value = algorithms_complete(results,caseNames,algorithmModes)
value = true;
for caseIndex = 1:numel(caseNames)
    caseField = char(caseNames(caseIndex));
    if ~isfield(results,caseField)
        value = false;
        return
    end
    fields = string(fieldnames(results.(caseField)));
    if numel(fields) ~= numel(algorithmModes) || ...
            ~all(ismember(algorithmModes,fields))
        value = false;
        return
    end
end
end

function [passed,details] = validate_nan_rules(results)
faultFields = ["fault_factor_true","fault_factor_est", ...
    "fault_retention_error_pct","Cs1_pre_post_change_pF", ...
    "Cs2_pre_post_change_pF"];
gateFields = ["first_gate_trigger_s","gate_duration_cycles", ...
    "gate_duration_s"];
nonFault = ismember(results.case_name,["Case01_static", ...
    "Case02_slow_drift","Case03_smooth_step", ...
    "Case04_random_drift"]);
fault = ~nonFault;
passed = true;
for name = faultFields
    passed = passed && all(isnan(results.(name)(nonFault))) && ...
        all(isfinite(results.(name)(fault)));
end
for mode = ["M0","M2"]
    rows = results.algorithm_mode == mode;
    for name = gateFields
        passed = passed && all(isnan(results.(name)(rows)));
    end
end
m3Rows = find(results.algorithm_mode == "M3");
for row = m3Rows.'
    gateValues = [results.first_gate_trigger_s(row), ...
        results.gate_duration_cycles(row),results.gate_duration_s(row)];
    passed = passed && (all(isnan(gateValues)) || all(isfinite(gateValues)));
end
coreFields = ["Cs1_RMSE_pF","Cs2_RMSE_pF", ...
    "B_resistive_fundamental_error_pct","random_seed"];
for name = coreFields
    passed = passed && all(isfinite(results.(name)));
end
details = "NaN appears only in frozen not-applicable fields";
end

function [passed,details] = validate_numeric_values(results)
passed = true;
numericCount = 0;
for k = 1:width(results)
    variableName = results.Properties.VariableNames{k};
    value = results.(variableName);
    if isnumeric(value)
        numericCount = numericCount+numel(value);
        passed = passed && isreal(value) && ~any(isinf(value),'all');
    end
end
details = sprintf('%d numeric cells checked',numericCount);
end

function [passed,details] = validate_metadata(results,registry,metadata)
stringFields = ["case_name","algorithm_mode","model_file", ...
    "model_sha256","run_timestamp","git_commit","git_branch", ...
    "git_dirty_status"];
passed = true;
for name = stringFields
    value = results.(name);
    passed = passed && all(~ismissing(value)) && ...
        all(strlength(strtrim(value)) > 0);
end
passed = passed && all(results.model_file == "AI6109_MOA_AutoComp9.slx") && ...
    all(results.model_sha256 == metadata.model_sha256) && ...
    all(results.run_timestamp == metadata.run_timestamp) && ...
    all(results.git_commit == metadata.git_commit) && ...
    all(results.git_branch == metadata.git_branch) && ...
    all(results.git_dirty_status == metadata.git_dirty_status);
for k = 1:height(registry)
    rows = results.case_name == registry.case_name(k);
    passed = passed && nnz(rows) == 3 && ...
        all(results.random_seed(rows) == registry.seed(k));
end
details = "Row metadata is nonempty and consistent with run metadata/registry";
end

function [passed,tableOut] = historical_sanity(results,reference)
spec = {
    "Case02_slow_drift","M0","B_resistive_fundamental_error_pct",reference.Case02_slow_drift.M0.B_resistive_fundamental_error_pct
    "Case02_slow_drift","M3","B_resistive_fundamental_error_pct",reference.Case02_slow_drift.M3.B_resistive_fundamental_error_pct
    "Case02_slow_drift","M3","Cs1_RMSE_pF",reference.Case02_slow_drift.M3.Cs1_RMSE_pF
    "Case02_slow_drift","M3","Cs2_RMSE_pF",reference.Case02_slow_drift.M3.Cs2_RMSE_pF
    "Case06_drift_then_fault","M0","fault_factor_true",reference.Case06_drift_then_fault.fault_factor_true
    "Case06_drift_then_fault","M2","Cs1_pre_post_change_pF",reference.Case06_drift_then_fault.M2.Cs1_pre_post_change_pF
    "Case06_drift_then_fault","M2","Cs2_pre_post_change_pF",reference.Case06_drift_then_fault.M2.Cs2_pre_post_change_pF
    "Case06_drift_then_fault","M2","fault_factor_est",reference.Case06_drift_then_fault.M2.fault_factor_est
    "Case06_drift_then_fault","M3","Cs1_pre_post_change_pF",reference.Case06_drift_then_fault.M3.Cs1_pre_post_change_pF
    "Case06_drift_then_fault","M3","Cs2_pre_post_change_pF",reference.Case06_drift_then_fault.M3.Cs2_pre_post_change_pF
    "Case06_drift_then_fault","M3","fault_factor_est",reference.Case06_drift_then_fault.M3.fault_factor_est
    };
caseName = string(spec(:,1));
algorithmMode = string(spec(:,2));
metricName = string(spec(:,3));
historicalValue = cell2mat(spec(:,4));
newValue = zeros(size(historicalValue));
for k = 1:numel(newValue)
    row = results.case_name == caseName(k) & ...
        results.algorithm_mode == algorithmMode(k);
    newValue(k) = results.(metricName(k))(row);
end
absoluteDifference = abs(newValue-historicalValue);
tolerance = reference.absolute_tolerance+ ...
    reference.relative_tolerance*abs(historicalValue);
pass = absoluteDifference <= tolerance;
tableOut = table(caseName,algorithmMode,metricName,historicalValue, ...
    newValue,absoluteDifference,tolerance,pass);
passed = all(pass);
end

function [passed,tableOut] = validate_frozen_files(before,matlabRoot)
tableOut = before;
tableOut.sha256_after_run = strings(height(before),1);
tableOut.unchanged = false(height(before),1);
for k = 1:height(before)
    tableOut.sha256_after_run(k) = file_sha256( ...
        fullfile(matlabRoot,before.file_name(k)));
    tableOut.unchanged(k) = tableOut.sha256_after_run(k) == ...
        tableOut.sha256_before_run(k);
end
passed = all(tableOut.unchanged);
end

function checks = add_check(checks,id,name,passed,details)
checks = [checks;table(string(id),string(name),logical(passed), ...
    string(details),'VariableNames',checks.Properties.VariableNames)];
end

function label = empty_label(value)
value = strtrim(string(value));
if strlength(value) == 0
    label = "No changes under results/, results_phase1/, or results_phase2/";
else
    label = value;
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
