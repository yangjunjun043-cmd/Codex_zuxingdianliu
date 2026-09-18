function figurePaths = generate_phase1b_step3_figures( ...
        figuresRoot,data,originalM2,instrumented,cycleTable, ...
        analysis,case05Cycles,comparisonTable)
%GENERATE_PHASE1B_STEP3_FIGURES Generate six Case06 verification figures.

if ~isfolder(figuresRoot)
    mkdir(figuresRoot);
end
figurePaths = strings(6,2);
t = data.t;
tc = cycleTable.time_end_s;

% Figure 1 — true drift tracking followed by fault-induced departure.
fig = figure('Visible','off');
layout = tiledlayout(fig,2,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,t,data.Cs1,'LineWidth',1.4); hold(ax,'on');
plot(ax,t,originalM2.hist(:,1),'LineWidth',1.2);
mark_intervals(ax); ylabel(ax,'Cs1 (pF)'); grid(ax,'on');
legend(ax,{'truth','M2'},'Location','best');
ax = nexttile(layout);
plot(ax,t,data.Cs2,'LineWidth',1.4); hold(ax,'on');
plot(ax,t,originalM2.hist(:,2),'LineWidth',1.2);
mark_intervals(ax); ylabel(ax,'Cs2 (pF)'); xlabel(ax,'Time (s)');
grid(ax,'on'); legend(ax,{'truth','M2'},'Location','best');
title(layout,'Figure 1 — Case06 true drift tracking and fault response');
figurePaths(1,:) = save_pair(fig,figuresRoot, ...
    'figure1_case06_truth_m2_cs_tracking');

% Figure 2 — isolate physical drift from fault-induced estimator bias.
fig = figure('Visible','off');
layout = tiledlayout(fig,3,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,t,data.Cs1,'LineWidth',1.3); hold(ax,'on');
plot(ax,t,instrumented.counterfactual.hist(:,1),'LineWidth',1.1);
plot(ax,t,instrumented.fault.hist(:,1),'LineWidth',1.1);
mark_intervals(ax); ylabel(ax,'Cs1 (pF)'); grid(ax,'on');
legend(ax,{'truth','counterfactual','fault'},'Location','best');
ax = nexttile(layout);
plot(ax,t,data.Cs2,'LineWidth',1.3); hold(ax,'on');
plot(ax,t,instrumented.counterfactual.hist(:,2),'LineWidth',1.1);
plot(ax,t,instrumented.fault.hist(:,2),'LineWidth',1.1);
mark_intervals(ax); ylabel(ax,'Cs2 (pF)'); grid(ax,'on');
ax = nexttile(layout);
plot(ax,t,instrumented.fault.hist(:,1)- ...
    instrumented.counterfactual.hist(:,1),'LineWidth',1.1); hold(ax,'on');
plot(ax,t,instrumented.fault.hist(:,2)- ...
    instrumented.counterfactual.hist(:,2),'LineWidth',1.1);
mark_intervals(ax); ylabel(ax,'Fault-CF (pF)'); xlabel(ax,'Time (s)');
grid(ax,'on'); legend(ax,{'Cs1 false bias','Cs2 false bias'}, ...
    'Location','best');
title(layout,'Figure 2 — True drift versus fault-induced false bias');
figurePaths(2,:) = save_pair(fig,figuresRoot, ...
    'figure2_case06_true_drift_vs_fault_bias');

% Figure 3 — geometric absorbability aligned to fault onset.
fig = figure('Visible','off');
ax = axes(fig);
plot(ax,tc-3.0,cycleTable.eta_geom,'LineWidth',1.2);
hold(ax,'on');
plot(ax,case05Cycles.time_end_s-3.0,case05Cycles.eta_geom, ...
    '--o','MarkerIndices',1:10:height(case05Cycles),'LineWidth',1.1);
xline(ax,0,':','HandleVisibility','off');
xline(ax,0.06,':','HandleVisibility','off');
xlim(ax,[-0.10 1.0]); ylim(ax,[0 1]);
xlabel(ax,'Time from fault onset (s)'); ylabel(ax,'eta geom');
grid(ax,'on'); legend(ax,{'Case06','Case05'},'Location','best');
title(ax,'Figure 3 — Case05 and Case06 geometric absorbability');
figurePaths(3,:) = save_pair(fig,figuresRoot, ...
    'figure3_case05_case06_eta_geom');

% Figure 4 — static, direct recursive and accumulated recursive bias.
fig = figure('Visible','off');
layout = tiledlayout(fig,2,1,'TileSpacing','compact');
recursiveCs1 = cycleTable.Cs1_est_pF-cycleTable.Cs1_cf_est_pF;
recursiveCs2 = cycleTable.Cs2_est_pF-cycleTable.Cs2_cf_est_pF;
ax = nexttile(layout);
plot(ax,tc,cycleTable.delta_Cs1_LS_pred_pF,'LineWidth',1.1); hold(ax,'on');
plot(ax,tc,cycleTable.delta_Cs1_RLS_direct_raw_pF,'LineWidth',1.1);
plot(ax,tc,recursiveCs1,'LineWidth',1.1);
mark_fault(ax); ylabel(ax,'Cs1 bias (pF)'); grid(ax,'on');
legend(ax,{'static LS','direct RLS','recursive fault-CF'},'Location','best');
ax = nexttile(layout);
plot(ax,tc,cycleTable.delta_Cs2_LS_pred_pF,'LineWidth',1.1); hold(ax,'on');
plot(ax,tc,cycleTable.delta_Cs2_RLS_direct_raw_pF,'LineWidth',1.1);
plot(ax,tc,recursiveCs2,'LineWidth',1.1);
mark_fault(ax); ylabel(ax,'Cs2 bias (pF)'); xlabel(ax,'Time (s)');
grid(ax,'on');
title(layout,'Figure 4 — Static, direct and recursive fault-induced bias');
figurePaths(4,:) = save_pair(fig,figuresRoot, ...
    'figure4_case06_static_direct_recursive_bias');

% Figure 5 — pre/post waveform windows show fault-retention recovery.
preShow = t >= 2.60 & t < 2.66;
postShow = t >= 3.40 & t < 3.46;
fig = figure('Visible','off');
layout = tiledlayout(fig,2,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,t(preShow),1e3*data.irB(preShow),'LineWidth',1.3); hold(ax,'on');
plot(ax,t(preShow),1e3*analysis.irM2.B(preShow),'LineWidth',1.0);
plot(ax,t(preShow),1e3*analysis.irCounterfactualParameters.B(preShow), ...
    'LineWidth',1.0);
grid(ax,'on'); ylabel(ax,'Pre-fault (mA)');
legend(ax,{'truth','M2 fault path','counterfactual-parameter path'}, ...
    'Location','best');
ax = nexttile(layout);
plot(ax,t(postShow),1e3*data.irB(postShow),'LineWidth',1.3); hold(ax,'on');
plot(ax,t(postShow),1e3*analysis.irM2.B(postShow),'LineWidth',1.0);
plot(ax,t(postShow),1e3*analysis.irCounterfactualParameters.B(postShow), ...
    'LineWidth',1.0);
grid(ax,'on'); xlabel(ax,'Time (s)'); ylabel(ax,'Post-fault (mA)');
key = analysis.key_metrics;
title(layout,sprintf(['Figure 5 — Recovery: truth %.4f / ' ...
    'M2 %.4f / CF %.4f'], ...
    key.true_fault_factor,key.M2_actual_fault_factor, ...
    key.counterfactual_parameter_fault_factor),'FontSize',12);
figurePaths(5,:) = save_pair(fig,figuresRoot, ...
    'figure5_case06_fault_retention_recovery');

% Figure 6 — compact quantitative comparison of the shared mechanism.
fig = figure('Visible','off');
layout = tiledlayout(fig,2,2,'TileSpacing','compact');
plot_metric_pair(nexttile(layout),comparisonTable, ...
    'eta_geom_post_mean','eta geom','Post-fault geometry');
plot_metric_pair(nexttile(layout),comparisonTable, ...
    'recursive_fault_induced_Delta_Cs1','pF','Fault-induced Delta Cs1');
plot_metric_pair(nexttile(layout),comparisonTable, ...
    'recursive_fault_induced_Delta_Cs2','pF','Fault-induced Delta Cs2');
plot_metric_pair(nexttile(layout),comparisonTable, ...
    'false_compensation_amplitude_ratio','ratio', ...
    'False-compensation/fault RMS');
title(layout,'Figure 6 — Case05 versus Case06 mechanism comparison');
figurePaths(6,:) = save_pair(fig,figuresRoot, ...
    'figure6_case05_case06_mechanism_comparison');
end

function plot_metric_pair(ax,comparisonTable,metricName,yLabelText,titleText)
row = comparisonTable(comparisonTable.Metric == metricName,:);
bar(ax,[row.Case05,row.Case06]);
xticks(ax,1:2); xticklabels(ax,{'Case05','Case06'});
ylabel(ax,yLabelText); title(ax,titleText); grid(ax,'on');
end

function paths = save_pair(fig,root,name)
pngPath = fullfile(root,[name '.png']);
figPath = fullfile(root,[name '.fig']);
exportgraphics(fig,pngPath,'Resolution',200);
savefig(fig,figPath);
close(fig);
paths = [string(pngPath),string(figPath)];
end

function mark_intervals(ax)
xline(ax,0.80,':','HandleVisibility','off');
xline(ax,2.20,':','HandleVisibility','off');
mark_fault(ax);
end

function mark_fault(ax)
xline(ax,3.00,':','HandleVisibility','off');
xline(ax,3.06,':','HandleVisibility','off');
end
