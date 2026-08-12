function comparison = validate_auto_comp10_layout()
%VALIDATE_AUTO_COMP10_LAYOUT 复跑两个 Phase 2 工况并验证仅布局变化。
cfg = patent_default_config();
cfg.model = 'AI6109_MOA_AutoComp10';
outdir = fullfile(fileparts(mfilename('fullpath')),'results_phase2','model_layout_validation');
self_pF = repmat(cfg.Cself_pF,1,3);

slow = run_case(cfg,'slow_drift',102,self_pF,'缓慢耦合漂移');
fault = run_case(cfg,'fault_with_drift',105,self_pF,'阻性故障+耦合漂移');
after = [slow.metrics;fault.metrics];
faultAfter = table(fault.trueFactor,fault.estimatedFactor,fault.retentionError, ...
    'VariableNames',{'true_fault_factor','cvff_rls_estimated_factor', ...
    'cvff_rls_retention_error_pct'});

before = readtable(fullfile(outdir,'before_key_metrics.csv'));
beforeFault = readtable(fullfile(outdir,'before_fault_retention.csv'));
comparison = table(string(after.scene), ...
    before.Cs1_RMSE_pF,after.Cs1_RMSE_pF,after.Cs1_RMSE_pF-before.Cs1_RMSE_pF, ...
    before.Cs2_RMSE_pF,after.Cs2_RMSE_pF,after.Cs2_RMSE_pF-before.Cs2_RMSE_pF, ...
    before.B_FundErr_CVFF_RLS_pct,after.B_FundErr_CVFF_RLS_pct, ...
    after.B_FundErr_CVFF_RLS_pct-before.B_FundErr_CVFF_RLS_pct, ...
    'VariableNames',{'scene','Cs1_before_pF','Cs1_after_pF','Cs1_delta_pF', ...
    'Cs2_before_pF','Cs2_after_pF','Cs2_delta_pF', ...
    'B_FundErr_before_pct','B_FundErr_after_pct','B_FundErr_delta_pct'});
faultDelta = faultAfter.cvff_rls_retention_error_pct- ...
    beforeFault.cvff_rls_retention_error_pct;

tol = 1e-10;
assert(all(abs(comparison.Cs1_delta_pF)<tol) && ...
    all(abs(comparison.Cs2_delta_pF)<tol) && ...
    all(abs(comparison.B_FundErr_delta_pct)<tol) && abs(faultDelta)<tol, ...
    'validate_auto_comp10_layout:Regression','AutoComp10 结果与 AutoComp9 不一致。');
writetable(after,fullfile(outdir,'after_key_metrics.csv'));
writetable(faultAfter,fullfile(outdir,'after_fault_retention.csv'));
writetable(comparison,fullfile(outdir,'before_after_comparison.csv'));
writetable(table(faultDelta,'VariableNames',{'fault_retention_error_delta_pct'}), ...
    fullfile(outdir,'fault_comparison.csv'));
disp(comparison); disp(faultAfter); fprintf('故障保持误差差值：%.16g %%\n',faultDelta);
end

function result = run_case(cfg,scenario,seed,self_pF,sceneName)
[data,~] = simulate_phase2_case(cfg,scenario,seed);
ref = reconstruct_refs_from_b(data.t,data.ub,cfg.f, ...
    cfg.init_start,cfg.init_end,cfg.phase_error_deg);
rls = track_coupling_cvff_rls(data,ref,cfg,self_pF,true);
ir = extract_resistive_current(data,ref,self_pF,rls.hist);
metric = evaluate_case_metrics(data,ir,rls.hist,'CVFF-RLS',sceneName,cfg);
idx = data.t>=cfg.metric_start;
metrics = table(string(sceneName), ...
    sqrt(mean((rls.hist(idx,1)-data.Cs1(idx)).^2)), ...
    sqrt(mean((rls.hist(idx,2)-data.Cs2(idx)).^2)),metric.B_FundErr_pct, ...
    'VariableNames',{'scene','Cs1_RMSE_pF','Cs2_RMSE_pF','B_FundErr_CVFF_RLS_pct'});
result = struct('metrics',metrics,'trueFactor',NaN,'estimatedFactor',NaN,'retentionError',NaN);
if strcmp(scenario,'fault_with_drift')
    result.trueFactor = fault_factor(data.t,data.irB,cfg.f);
    result.estimatedFactor = fault_factor(data.t,ir.B,cfg.f);
    result.retentionError = 100*(result.estimatedFactor-result.trueFactor)/result.trueFactor;
end
end

function value = fault_factor(t,x,f)
pre=t>=2.60 & t<2.90; post=t>=3.40 & t<3.80;
value=fund_rms(t(post),x(post),f)/(fund_rms(t(pre),x(pre),f)+eps);
end

function value = fund_rms(t,x,f)
w=2*pi*f; b=[sin(w*t),cos(w*t),ones(size(t))]\x;
value=hypot(b(1),b(2))/sqrt(2);
end
