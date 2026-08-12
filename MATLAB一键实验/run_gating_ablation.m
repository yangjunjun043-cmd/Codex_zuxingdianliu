function results = run_gating_ablation()
%RUN_GATING_ABLATION 单一故障门控消融实验。
cfg = patent_default_config();
cfg.model = 'AI6109_MOA_AutoComp9';
outdir = fullfile(fileparts(mfilename('fullpath')),'results_phase2','gating_ablation');
if ~exist(outdir,'dir'), mkdir(outdir); end
self_pF = repmat(cfg.Cself_pF,1,3);

% 只生成一次完全相同的 Simulink 故障+漂移数据。
[data,~] = simulate_phase2_case(cfg,'fault_with_drift',105);
ref = reconstruct_refs_from_b(data.t,data.ub,cfg.f, ...
    cfg.init_start,cfg.init_end,cfg.phase_error_deg);
c0 = initial_coupling_estimate(data,ref,cfg,self_pF);
fixedHist = repmat(c0(:).',numel(data.t),1);
rlsNoGate = track_coupling_cvff_rls(data,ref,cfg,self_pF,false);
rlsGate = track_coupling_cvff_rls(data,ref,cfg,self_pF,true);

irFixed = extract_resistive_current(data,ref,self_pF,fixedHist);
irNoGate = extract_resistive_current(data,ref,self_pF,rlsNoGate.hist);
irGate = extract_resistive_current(data,ref,self_pF,rlsGate.hist);

pre = data.t>=2.60 & data.t<2.90;
post = data.t>=3.40 & data.t<3.80;
parameterChange = [parameter_row('Cs1',data.Cs1,rlsNoGate.hist(:,1),rlsGate.hist(:,1),pre,post); ...
    parameter_row('Cs2',data.Cs2,rlsNoGate.hist(:,2),rlsGate.hist(:,2),pre,post)];

trueFactor = fault_factor(data.t,data.irB,cfg.f);
fixedFactor = fault_factor(data.t,irFixed.B,cfg.f);
noGateFactor = fault_factor(data.t,irNoGate.B,cfg.f);
gateFactor = fault_factor(data.t,irGate.B,cfg.f);
faultRetention = table(trueFactor,fixedFactor,noGateFactor,gateFactor, ...
    100*(noGateFactor-trueFactor)/trueFactor,100*(gateFactor-trueFactor)/trueFactor, ...
    sum(rlsGate.cycle.time_s>=3.0 & rlsGate.cycle.gate>0), ...
    'VariableNames',{'true_fault_factor','fixed_estimated_factor', ...
    'no_gate_estimated_factor','gated_estimated_factor', ...
    'no_gate_retention_error_pct','gated_retention_error_pct','gated_cycles_after_fault'});

idx = data.t>=cfg.metric_start;
tracking = table( ...
    sqrt(mean((rlsNoGate.hist(idx,1)-data.Cs1(idx)).^2)), ...
    sqrt(mean((rlsNoGate.hist(idx,2)-data.Cs2(idx)).^2)), ...
    sqrt(mean((rlsGate.hist(idx,1)-data.Cs1(idx)).^2)), ...
    sqrt(mean((rlsGate.hist(idx,2)-data.Cs2(idx)).^2)), ...
    'VariableNames',{'Cs1_RMSE_NoGate_pF','Cs2_RMSE_NoGate_pF', ...
    'Cs1_RMSE_Gated_pF','Cs2_RMSE_Gated_pF'});

make_figures(outdir,data,rlsNoGate,rlsGate,irFixed,irNoGate,irGate);
writetable(parameterChange,fullfile(outdir,'cs_parameter_change.csv'));
writetable(faultRetention,fullfile(outdir,'fault_retention.csv'));
writetable(tracking,fullfile(outdir,'tracking_rmse.csv'));
save(fullfile(outdir,'gating_ablation_results.mat'), ...
    'cfg','parameterChange','faultRetention','tracking');
results = struct('parameterChange',parameterChange, ...
    'faultRetention',faultRetention,'tracking',tracking);
disp(parameterChange); disp(faultRetention); disp(tracking);
end

function row = parameter_row(name,truth,noGate,gate,pre,post)
truePre=mean(truth(pre)); truePost=mean(truth(post));
noGatePre=mean(noGate(pre)); noGatePost=mean(noGate(post));
gatePre=mean(gate(pre)); gatePost=mean(gate(post));
row=table(string(name),truePre,truePost,truePost-truePre, ...
    noGatePre,noGatePost,noGatePost-noGatePre, ...
    gatePre,gatePost,gatePost-gatePre, ...
    abs(noGatePost-truePost),abs(gatePost-truePost), ...
    'VariableNames',{'parameter','true_pre_pF','true_post_pF','true_change_pF', ...
    'no_gate_pre_pF','no_gate_post_pF','no_gate_change_pF', ...
    'gated_pre_pF','gated_post_pF','gated_change_pF', ...
    'no_gate_post_abs_error_pF','gated_post_abs_error_pF'});
end

function make_figures(outdir,data,noGate,gate,irFixed,irNoGate,irGate)
f=figure('Color','w','Position',[100 100 950 680]);
tiledlayout(2,1,'TileSpacing','compact');
nexttile; plot(data.t,data.Cs1,'k','LineWidth',1.8); hold on;
plot(data.t,noGate.hist(:,1),'Color',[0.2 0.45 0.85],'LineWidth',1.2);
plot(data.t,gate.hist(:,1),'r--','LineWidth',1.4); xline(3.0,'k:','故障开始');
grid on; ylabel('Cs1 / pF'); title('故障门控消融：耦合参数估计');
legend('真值','无门控','有门控','Location','best');
nexttile; plot(data.t,data.Cs2,'k','LineWidth',1.8); hold on;
plot(data.t,noGate.hist(:,2),'Color',[0.2 0.45 0.85],'LineWidth',1.2);
plot(data.t,gate.hist(:,2),'r--','LineWidth',1.4); xline(3.0,'k:','故障开始');
grid on; xlabel('时间 / s'); ylabel('Cs2 / pF');
legend('真值','无门控','有门控','Location','best');
exportgraphics(f,fullfile(outdir,'figure1_gating_ablation_cs.png'),'Resolution',240); close(f);

f=figure('Color','w','Position',[100 100 1050 540]);
plot(data.t,1e3*data.irB,'k','LineWidth',1.8); hold on;
plot(data.t,1e3*irFixed.B,'Color',[0.55 0.55 0.55],'LineWidth',0.9);
plot(data.t,1e3*irNoGate.B,'Color',[0.2 0.45 0.85],'LineWidth',1.0);
plot(data.t,1e3*irGate.B,'r--','LineWidth',1.2); xline(3.0,'k:','故障开始');
xlim([2.85 3.25]); grid on; xlabel('时间 / s'); ylabel('B 相阻性电流 / mA');
title('故障门控消融：B 相阻性电流提取');
legend('真实值','固定补偿','无门控 CVFF-RLS','有门控 CVFF-RLS','Location','best');
exportgraphics(f,fullfile(outdir,'figure2_gating_ablation_current.png'),'Resolution',240); close(f);
end

function value = fault_factor(t,x,f)
pre=t>=2.60 & t<2.90; post=t>=3.40 & t<3.80;
value=fund_rms(t(post),x(post),f)/(fund_rms(t(pre),x(pre),f)+eps);
end

function value = fund_rms(t,x,f)
w=2*pi*f; b=[sin(w*t),cos(w*t),ones(size(t))]\x;
value=hypot(b(1),b(2))/sqrt(2);
end
