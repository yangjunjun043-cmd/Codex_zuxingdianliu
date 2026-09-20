function tableOut = prefault_tracking_table(caseDetails)
%PREFAULT_TRACKING_TABLE Summarize frozen pre-fault tracking windows.

caseNames = ["Case05_fault_only","Case06_drift_then_fault"];
modes = ["M2","M3","M4"];
rows = cell(numel(caseNames)*numel(modes),1);
rowIndex = 0;
for caseIndex = 1:numel(caseNames)
    caseName = caseNames(caseIndex);
    detail = caseDetails.(char(caseName));
    pre = detail.t >= 2.60 & detail.t < 2.90;
    drift = detail.t >= 0.80 & detail.t <= 2.20;
    truth = [detail.Cs1_true,detail.Cs2_true];
    for mode = modes
        rowIndex = rowIndex+1;
        hist = detail.(char(mode+"_cHist"));
        bias = mean(hist(pre,:)-truth(pre,:),1);
        driftRmse = sqrt(mean((hist(drift,:)-truth(drift,:)).^2,1));
        rows{rowIndex} = table(caseName,mode,bias(1),bias(2), ...
            driftRmse(1),driftRmse(2),'VariableNames', ...
            {'case_name','algorithm_mode','pre_Cs1_bias_pF', ...
            'pre_Cs2_bias_pF','drift_window_Cs1_RMSE_pF', ...
            'drift_window_Cs2_RMSE_pF'});
    end
end
tableOut = vertcat(rows{:});
end
