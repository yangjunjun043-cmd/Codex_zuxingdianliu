function results = run_gating_ablation()
%RUN_GATING_ABLATION Phase 2 故障门控消融：唯一变量为 enableGate。
cfg = patent_default_config();
cfg.model = 'AI6109_MOA_AutoComp9';
outdir = fullfile(fileparts(mfilename('fullpath')), ...
    'results_phase2','gating_ablation');
if ~exist(outdir,'dir'), mkdir(outdir); end
self_pF = repmat(cfg.Cself_pF,1,3);

% 与 Phase 2 完全相同的工况、seed、故障轨迹和噪声实现。
scenario = 'fault_with_drift';
seed = 105;
[data,~] = simulate_phase2_case(cfg,scenario,seed);
ref = reconstruct_refs_from_b(data.t,data.ub,cfg.f, ...
    cfg.init_start,cfg.init_end,cfg.phase_error_deg);
noGate = track_coupling_cvff_rls(data,ref,cfg,self_pF,false);
gated = track_coupling_cvff_rls(data,ref,cfg,self_pF,true);
irNoGate = extract_resistive_current(data,ref,self_pF,noGate.hist);
irGated = extract_resistive_current(data,ref,self_pF,gated.hist);

pre = data.t>=2.60 & data.t<2.90;
post = data.t>=3.40 & data.t<3.80;
parameterChange = [parameter_row('Cs1',data.Cs1,noGate.hist(:,1), ...
    gated.hist(:,1),pre,post); parameter_row('Cs2',data.Cs2, ...
    noGate.hist(:,2),gated.hist(:,2),pre,post)];

trueFactor = fault_factor(data.t,data.irB,cfg.f);
noGateFactor = fault_factor(data.t,irNoGate.B,cfg.f);
gatedFactor = fault_factor(data.t,irGated.B,cfg.f);
faultSummary = table(trueFactor,noGateFactor, ...
    100*(noGateFactor-trueFactor)/trueFactor,gatedFactor, ...
    100*(gatedFactor-trueFactor)/trueFactor, ...
    sum(gated.cycle.time_s>=3.0 & gated.cycle.gate>0), ...
    'VariableNames',{'true_fault_factor','no_gate_estimated_factor', ...
    'no_gate_retention_error_pct','gated_estimated_factor', ...
    'gated_retention_error_pct','gated_cycles_after_fault'});

idx = data.t>=cfg.metric_start;
trackingSummary = table( ...
    sqrt(mean((noGate.hist(idx,1)-data.Cs1(idx)).^2)), ...
    sqrt(mean((noGate.hist(idx,2)-data.Cs2(idx)).^2)), ...
    sqrt(mean((gated.hist(idx,1)-data.Cs1(idx)).^2)), ...
    sqrt(mean((gated.hist(idx,2)-data.Cs2(idx)).^2)), ...
    'VariableNames',{'Cs1_RMSE_NoGate_pF','Cs2_RMSE_NoGate_pF', ...
    'Cs1_RMSE_Gated_pF','Cs2_RMSE_Gated_pF'});

evidence = struct('t',data.t,'Cs1_true',data.Cs1,'Cs2_true',data.Cs2, ...
    'Cs1_no_gate',noGate.hist(:,1),'Cs2_no_gate',noGate.hist(:,2), ...
    'Cs1_gated',gated.hist(:,1),'Cs2_gated',gated.hist(:,2), ...
    'iB_R_true',data.irB,'iB_R_no_gate',irNoGate.B, ...
    'iB_R_gated',irGated.B,'gate_cycle_log',gated.cycle);

make_comparison_figure(outdir,evidence);
writetable(parameterChange,fullfile(outdir,'cs_parameter_change.csv'));
writetable(faultSummary,fullfile(outdir,'fault_retention_summary.csv'));
writetable(trackingSummary,fullfile(outdir,'tracking_rmse_summary.csv'));
save(fullfile(outdir,'gating_ablation_evidence.mat'), ...
    'cfg','scenario','seed','evidence','parameterChange', ...
    'faultSummary','trackingSummary');
results = struct('parameterChange',parameterChange, ...
    'faultSummary',faultSummary,'trackingSummary',trackingSummary);
disp(parameterChange); disp(faultSummary); disp(trackingSummary);
end

function row = parameter_row(name,truth,noGate,gated,pre,post)
truePre=mean(truth(pre)); truePost=mean(truth(post));
noGatePre=mean(noGate(pre)); noGatePost=mean(noGate(post));
gatedPre=mean(gated(pre)); gatedPost=mean(gated(post));
row=table(string(name),truePre,truePost,truePost-truePre, ...
    noGatePre,noGatePost,noGatePost-noGatePre, ...
    gatedPre,gatedPost,gatedPost-gatedPre, ...
    abs(noGatePost-truePost),abs(gatedPost-truePost), ...
    'VariableNames',{'parameter','true_pre_pF','true_post_pF', ...
    'true_change_pF','no_gate_pre_pF','no_gate_post_pF', ...
    'no_gate_change_pF','gated_pre_pF','gated_post_pF', ...
    'gated_change_pF','no_gate_post_abs_error_pF', ...
    'gated_post_abs_error_pF'});
end

function make_comparison_figure(outdir,e)
f=figure('Color','w','Position',[100 80 1050 850]);
tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
nexttile; plot(e.t,e.Cs1_true,'k','LineWidth',1.8); hold on;
plot(e.t,e.Cs1_no_gate,'Color',[0.15 0.42 0.82],'LineWidth',1.2);
plot(e.t,e.Cs1_gated,'r--','LineWidth',1.4); xline(3.0,'k:');
grid on; ylabel('Cs1 / pF'); title('故障门控消融：相间耦合参数与B相阻性电流');
legend('真值','无门控','有门控','故障开始','Location','best');
nexttile; plot(e.t,e.Cs2_true,'k','LineWidth',1.8); hold on;
plot(e.t,e.Cs2_no_gate,'Color',[0.15 0.42 0.82],'LineWidth',1.2);
plot(e.t,e.Cs2_gated,'r--','LineWidth',1.4); xline(3.0,'k:');
grid on; ylabel('Cs2 / pF');
legend('真值','无门控','有门控','故障开始','Location','best');
nexttile; plot(e.t,1e3*e.iB_R_true,'k','LineWidth',1.7); hold on;
plot(e.t,1e3*e.iB_R_no_gate,'Color',[0.15 0.42 0.82],'LineWidth',1.0);
plot(e.t,1e3*e.iB_R_gated,'r--','LineWidth',1.2); xline(3.0,'k:');
xlim([2.85 3.25]); grid on; xlabel('时间 / s'); ylabel('B相阻性电流 / mA');
legend('真实阻性电流','无门控提取','有门控提取','故障开始','Location','best');
exportgraphics(f,fullfile(outdir,'gating_ablation_comparison.png'), ...
    'Resolution',300); close(f);
end

function value = fault_factor(t,x,f)
pre=t>=2.60 & t<2.90; post=t>=3.40 & t<3.80;
value=fund_rms(t(post),x(post),f)/(fund_rms(t(pre),x(pre),f)+eps);
end

function value = fund_rms(t,x,f)
w=2*pi*f; b=[sin(w*t),cos(w*t),ones(size(t))]\x;
value=hypot(b(1),b(2))/sqrt(2);
end
