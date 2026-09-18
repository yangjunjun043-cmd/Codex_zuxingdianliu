function figurePaths = generate_phase1b_step4_figures(figuresRoot,summaryTable)
%GENERATE_PHASE1B_STEP4_FIGURES Generate four controlled-factor figures.

if ~isfolder(figuresRoot)
    mkdir(figuresRoot);
end
figurePaths = strings(4,2);
amplitude = sortrows(summaryTable(summaryTable.amplitude_sweep_member,:), ...
    'fault_factor_target');
phase = sortrows(summaryTable(summaryTable.phase_sweep_member,:), ...
    'reference_phase_error_deg');

% Figure 1 — amplitude versus geometric absorbability.
fig = figure('Visible','off');
ax = axes(fig);
plot(ax,amplitude.fault_factor_target,amplitude.eta_geom_ramp, ...
    '-o','LineWidth',1.2); hold(ax,'on');
plot(ax,amplitude.fault_factor_target,amplitude.eta_geom_post, ...
    '-s','LineWidth',1.2);
xlabel(ax,'Final fault factor'); ylabel(ax,'eta geom'); grid(ax,'on');
legend(ax,{'fault-ramp mean','post-fault mean'},'Location','best');
title(ax,'Figure 1 — Fault amplitude versus geometric absorbability');
figurePaths(1,:) = save_pair(fig,figuresRoot, ...
    'figure1_fault_amplitude_vs_eta_geom');

% Figure 2 — amplitude versus fault-induced bias and retention loss.
fig = figure('Visible','off');
layout = tiledlayout(fig,2,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,amplitude.fault_factor_target, ...
    amplitude.DeltaCs1_fault_induced,'-o','LineWidth',1.2); hold(ax,'on');
plot(ax,amplitude.fault_factor_target, ...
    amplitude.DeltaCs2_fault_induced,'-s','LineWidth',1.2);
ylabel(ax,'Fault-induced Delta Cs (pF)'); grid(ax,'on');
legend(ax,{'Cs1','Cs2'},'Location','best');
ax = nexttile(layout);
plot(ax,amplitude.fault_factor_target, ...
    amplitude.fault_retention_error,'-o','LineWidth',1.2);
xlabel(ax,'Final fault factor'); ylabel(ax,'Retention error (%)');
grid(ax,'on');
title(layout,'Figure 2 — Fault amplitude, false Cs bias and retention loss');
figurePaths(2,:) = save_pair(fig,figuresRoot, ...
    'figure2_fault_amplitude_bias_retention');

% Figure 3 — phase error versus geometry and parameter bias.
fig = figure('Visible','off');
layout = tiledlayout(fig,2,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,phase.reference_phase_error_deg,phase.eta_geom_ramp, ...
    '-o','LineWidth',1.2); hold(ax,'on');
plot(ax,phase.reference_phase_error_deg,phase.eta_geom_post, ...
    '-s','LineWidth',1.2);
ylabel(ax,'eta geom'); grid(ax,'on');
legend(ax,{'fault-ramp mean','post-fault mean'},'Location','best');
ax = nexttile(layout);
plot(ax,phase.reference_phase_error_deg, ...
    phase.DeltaCs1_fault_induced,'-o','LineWidth',1.2); hold(ax,'on');
plot(ax,phase.reference_phase_error_deg, ...
    phase.DeltaCs2_fault_induced,'-s','LineWidth',1.2);
plot(ax,phase.reference_phase_error_deg,phase.DeltaCs1_LS,'--o', ...
    'LineWidth',1.0);
plot(ax,phase.reference_phase_error_deg,phase.DeltaCs2_LS,'--s', ...
    'LineWidth',1.0);
xlabel(ax,'Reference phase error (deg)'); ylabel(ax,'Delta Cs (pF)');
grid(ax,'on');
legend(ax,{'recursive Cs1','recursive Cs2','static LS Cs1', ...
    'static LS Cs2'},'Location','best');
title(layout,'Figure 3 — Reference phase error, geometry and false Cs bias');
figurePaths(3,:) = save_pair(fig,figuresRoot, ...
    'figure3_phase_error_eta_bias');

% Figure 4 — phase error versus retention and false compensation.
fig = figure('Visible','off');
layout = tiledlayout(fig,2,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,phase.reference_phase_error_deg, ...
    phase.fault_retention_error,'-o','LineWidth',1.2); hold(ax,'on');
plot(ax,phase.reference_phase_error_deg, ...
    phase.counterfactual_retention_error_pct,'-s','LineWidth',1.2);
ylabel(ax,'Retention error (%)'); grid(ax,'on');
legend(ax,{'M2 fault path','counterfactual parameters'},'Location','best');
ax = nexttile(layout);
yyaxis(ax,'left');
plot(ax,phase.reference_phase_error_deg, ...
    phase.false_compensation_ratio,'-o','LineWidth',1.2);
ylabel(ax,'False compensation/fault RMS');
yyaxis(ax,'right');
plot(ax,phase.reference_phase_error_deg, ...
    phase.false_compensation_phase,'-s','LineWidth',1.2);
ylabel(ax,'Phase difference (deg)');
xlabel(ax,'Reference phase error (deg)'); grid(ax,'on');
title(layout,'Figure 4 — Phase error, fault retention and false compensation');
figurePaths(4,:) = save_pair(fig,figuresRoot, ...
    'figure4_phase_error_retention_false_compensation');
end

function paths = save_pair(fig,root,name)
pngPath = fullfile(root,[name '.png']);
figPath = fullfile(root,[name '.fig']);
exportgraphics(fig,pngPath,'Resolution',200);
savefig(fig,figPath);
close(fig);
paths = [string(pngPath),string(figPath)];
end
