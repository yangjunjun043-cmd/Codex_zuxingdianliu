function results = run_phase2_simulink_dynamic()
%RUN_PHASE2_SIMULINK_DYNAMIC 精简 Phase 2：静态检查与两个关键实验。
cfg = patent_default_config();
cfg.model = 'AI6109_MOA_AutoComp9';
cfg.output_dir = fullfile(fileparts(mfilename('fullpath')),'results_phase2');
if ~exist(cfg.output_dir,'dir'), mkdir(cfg.output_dir); end
self_pF = repmat(cfg.Cself_pF,1,3);

% 固定 Cs：只检查 Simulink 与原 MATLAB 合成总电流的波形差异。
[staticData,staticRef] = simulate_phase2_case(cfg,'static',101);
% 原 MATLAB gradient 在最后一个端点退化为一阶单边差分；只从一致性最大值中排除该终止点。
idx = staticData.t>=cfg.init_start & staticData.t<=staticData.t(end)-cfg.Ts;
staticCheck = table(["A";"B";"C"], ...
    [wave_rmse(staticData.ia,staticRef.ia,idx);wave_rmse(staticData.ib,staticRef.ib,idx);wave_rmse(staticData.ic,staticRef.ic,idx)], ...
    [wave_max(staticData.ia,staticRef.ia,idx);wave_max(staticData.ib,staticRef.ib,idx);wave_max(staticData.ic,staticRef.ic,idx)], ...
    'VariableNames',{'phase','WaveRMSE_A','MaxAbsErr_A'});
assert(all(staticCheck.WaveRMSE_A<2e-6) && all(staticCheck.MaxAbsErr_A<5e-6), ...
    'run_phase2_simulink_dynamic:StaticMismatch','固定 Cs 的新旧链路差异超过基本一致性阈值。');

slow = run_algorithm_case(cfg,'slow_drift',102,self_pF);
fault = run_algorithm_case(cfg,'fault_with_drift',105,self_pF);
make_phase2_figures(cfg.output_dir,slow,fault);

summary = [case_row(slow,'缓慢耦合漂移');case_row(fault,'阻性故障+耦合漂移')];
faultFactors = table(1.6, ...
    fault_factor(fault.data.t,fault.data.irB,cfg.f), ...
    fault_factor(fault.data.t,fault.fixedIr.B,cfg.f), ...
    fault_factor(fault.data.t,fault.rlsIr.B,cfg.f), ...
    'VariableNames',{'nominal_fault_factor','true_fault_factor', ...
    'fixed_estimated_factor','cvff_rls_estimated_factor'});
faultFactors.cvff_rls_retention_error_pct = ...
    (faultFactors.cvff_rls_estimated_factor-faultFactors.true_fault_factor) ...
    /faultFactors.true_fault_factor*100;
faultFactors.gated_cycles_after_fault = sum(fault.rls.cycle.time_s>=3.0 & fault.rls.cycle.gate>0);

writetable(staticCheck,fullfile(cfg.output_dir,'static_consistency.csv'));
writetable(summary,fullfile(cfg.output_dir,'phase2_key_metrics.csv'));
writetable(faultFactors,fullfile(cfg.output_dir,'fault_retention.csv'));
save(fullfile(cfg.output_dir,'phase2_workspace.mat'),'cfg','staticCheck','summary','faultFactors');
results = struct('staticCheck',staticCheck,'summary',summary,'faultFactors',faultFactors);
disp(staticCheck); disp(summary); disp(faultFactors);
end

function result = run_algorithm_case(cfg,scenario,seed,self_pF)
[data,reference] = simulate_phase2_case(cfg,scenario,seed);
ref = reconstruct_refs_from_b(data.t,data.ub,cfg.f,cfg.init_start,cfg.init_end,cfg.phase_error_deg);
c0 = initial_coupling_estimate(data,ref,cfg,self_pF);
fixedHist = repmat(c0(:).',numel(data.t),1);
rls = track_coupling_cvff_rls(data,ref,cfg,self_pF,true);
fixedIr = extract_resistive_current(data,ref,self_pF,fixedHist);
rlsIr = extract_resistive_current(data,ref,self_pF,rls.hist);
fixedMetrics = evaluate_case_metrics(data,fixedIr,fixedHist,'固定补偿',scenario,cfg);
rlsMetrics = evaluate_case_metrics(data,rlsIr,rls.hist,'CVFF-RLS',scenario,cfg);
result = struct('data',data,'reference',reference,'fixedHist',fixedHist, ...
    'rls',rls,'fixedIr',fixedIr,'rlsIr',rlsIr, ...
    'fixedMetrics',fixedMetrics,'rlsMetrics',rlsMetrics,'cfg',cfg);
end

function row = case_row(result,scene)
idx = result.data.t>=result.cfg.metric_start;
row = table(string(scene), ...
    sqrt(mean((result.rls.hist(idx,1)-result.data.Cs1(idx)).^2)), ...
    sqrt(mean((result.rls.hist(idx,2)-result.data.Cs2(idx)).^2)), ...
    result.fixedMetrics.B_FundErr_pct,result.rlsMetrics.B_FundErr_pct, ...
    'VariableNames',{'scene','Cs1_RMSE_pF','Cs2_RMSE_pF', ...
    'B_FundErr_Fixed_pct','B_FundErr_CVFF_RLS_pct'});
end

function make_phase2_figures(outdir,slow,fault)
f = figure('Color','w','Position',[100 100 900 650]);
tiledlayout(2,1,'TileSpacing','compact');
nexttile; plot(slow.data.t,slow.data.Cs1,'k','LineWidth',1.8); hold on;
plot(slow.data.t,slow.rls.hist(:,1),'r--','LineWidth',1.5); grid on;
ylabel('Cs1 / pF'); legend('真值','CVFF-RLS 估计','Location','best');
title('缓慢耦合漂移下的相间耦合电容跟踪');
nexttile; plot(slow.data.t,slow.data.Cs2,'k','LineWidth',1.8); hold on;
plot(slow.data.t,slow.rls.hist(:,2),'b--','LineWidth',1.5); grid on;
xlabel('时间 / s'); ylabel('Cs2 / pF'); legend('真值','CVFF-RLS 估计','Location','best');
exportgraphics(f,fullfile(outdir,'figure1_dynamic_coupling_tracking.png'),'Resolution',240); close(f);

f = figure('Color','w','Position',[100 100 1000 520]);
plot(fault.data.t,1e3*fault.data.irB,'k','LineWidth',1.8); hold on;
plot(fault.data.t,1e3*fault.fixedIr.B,'Color',[0.2 0.45 0.85],'LineWidth',1.0);
plot(fault.data.t,1e3*fault.rlsIr.B,'r--','LineWidth',1.2); xline(3.0,'k:','故障开始');
xlim([2.85 3.25]); grid on; xlabel('时间 / s'); ylabel('B 相阻性电流 / mA');
title('阻性故障与耦合漂移下的阻性电流提取');
legend('真实阻性电流','固定补偿','CVFF-RLS','Location','best');
exportgraphics(f,fullfile(outdir,'figure2_fault_resistive_current.png'),'Resolution',240); close(f);
end

function value = fault_factor(t,x,f)
pre = t>=2.60 & t<2.90; post = t>=3.40 & t<3.80;
value = fund_rms(t(post),x(post),f)/(fund_rms(t(pre),x(pre),f)+eps);
end

function value = fund_rms(t,x,f)
w=2*pi*f; b=[sin(w*t),cos(w*t),ones(size(t))]\x;
value=hypot(b(1),b(2))/sqrt(2);
end

function value = wave_rmse(x,y,idx)
value=sqrt(mean((x(idx)-y(idx)).^2));
end

function value = wave_max(x,y,idx)
value=max(abs(x(idx)-y(idx)));
end
