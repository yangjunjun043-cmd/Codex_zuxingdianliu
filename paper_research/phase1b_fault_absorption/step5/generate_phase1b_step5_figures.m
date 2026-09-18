function figurePaths = generate_phase1b_step5_figures(root,amplitude,phase)
%GENERATE_PHASE1B_STEP5_FIGURES Generate six mechanism-evidence figures.

if ~isfolder(root)
    mkdir(root);
end
figurePaths = strings(6,2);
x = amplitude.excess_fault_amplitude;

fig = figure('Visible','off');
ax = axes(fig);
plot(ax,x,amplitude.DeltaCs1_fault_induced,'o','LineWidth',1.2); hold(ax,'on');
plot(ax,x,amplitude.abs_DeltaCs2_fault_induced,'s','LineWidth',1.2);
plot(ax,x,polyval(polyfit(x,amplitude.DeltaCs1_fault_induced,1),x), ...
    '-','LineWidth',1.1);
plot(ax,x,polyval(polyfit(x,amplitude.abs_DeltaCs2_fault_induced,1),x), ...
    '--','LineWidth',1.1);
xlabel(ax,'Excess fault amplitude, F-1');
ylabel(ax,'Recursive fault-induced Delta Cs magnitude (pF)');
legend(ax,{'Cs1 actual','|Cs2| actual','Cs1 linear fit', ...
    '|Cs2| linear fit'},'Location','best'); grid(ax,'on');
title(ax,'Figure 1 — Fault increment versus recursive false Cs bias');
figurePaths(1,:) = save_pair(fig,root, ...
    'figure1_fault_increment_recursive_delta_cs');

fig = figure('Visible','off');
layout = tiledlayout(fig,1,2,'TileSpacing','compact');
ax = nexttile(layout);
plot_prediction_panel(ax,amplitude.DeltaCs1_LS, ...
    amplitude.DeltaCs1_fault_induced,phase.DeltaCs1_LS, ...
    phase.DeltaCs1_fault_induced,'Cs1');
ax = nexttile(layout);
plot_prediction_panel(ax,amplitude.DeltaCs2_LS, ...
    amplitude.DeltaCs2_fault_induced,phase.DeltaCs2_LS, ...
    phase.DeltaCs2_fault_induced,'Cs2');
title(layout,'Figure 2 — Static LS prediction versus recursive actual bias');
figurePaths(2,:) = save_pair(fig,root, ...
    'figure2_ls_predicted_vs_recursive_actual');

fig = figure('Visible','off');
layout = tiledlayout(fig,2,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,x,amplitude.false_compensation_RMS_mA,'-o','LineWidth',1.2);
ylabel(ax,'False compensation RMS (mA)'); grid(ax,'on');
ax = nexttile(layout);
plot(ax,x,amplitude.lost_increment,'-s','LineWidth',1.2);
xlabel(ax,'Excess fault amplitude, F-1');
ylabel(ax,'Lost fault increment'); grid(ax,'on');
title(layout,'Figure 3 — Fault increment, false compensation and loss');
figurePaths(3,:) = save_pair(fig,root, ...
    'figure3_fault_increment_compensation_loss');

fig = figure('Visible','off');
ax = axes(fig);
plot(ax,phase.reference_phase_error_deg, ...
    phase.Cs1_pre_estimation_bias_pF,'-o','LineWidth',1.2); hold(ax,'on');
plot(ax,phase.reference_phase_error_deg, ...
    phase.Cs2_pre_estimation_bias_pF,'-s','LineWidth',1.2);
xlabel(ax,'Reference phase error (deg)');
ylabel(ax,'Pre-fault parameter bias (pF)');
legend(ax,{'Cs1','Cs2'},'Location','best'); grid(ax,'on');
title(ax,'Figure 4 — Phase error versus pre-fault Cs bias');
figurePaths(4,:) = save_pair(fig,root,'figure4_phase_error_pre_fault_bias');

fig = figure('Visible','off');
ax = axes(fig);
plot(ax,phase.reference_phase_error_deg,phase.fault_retention_error, ...
    '-o','LineWidth',1.2); hold(ax,'on');
plot(ax,phase.reference_phase_error_deg, ...
    phase.counterfactual_retention_error_pct,'-s','LineWidth',1.2);
xlabel(ax,'Reference phase error (deg)'); ylabel(ax,'Retention error (%)');
legend(ax,{'M2 fault path','Counterfactual parameters'},'Location','best');
grid(ax,'on');
title(ax,'Figure 5 — Phase error versus fault retention');
figurePaths(5,:) = save_pair(fig,root, ...
    'figure5_phase_error_retention');

fig = figure('Visible','off');
layout = tiledlayout(fig,2,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,phase.reference_phase_error_deg,phase.eta_geom_post, ...
    '-o','LineWidth',1.2);
ylabel(ax,'eta geom, post'); grid(ax,'on');
ax = nexttile(layout);
plot(ax,phase.reference_phase_error_deg,phase.false_compensation_phase, ...
    '-s','LineWidth',1.2);
xlabel(ax,'Reference phase error (deg)');
ylabel(ax,'False compensation phase (deg)'); grid(ax,'on');
title(layout,'Figure 6 — Phase error, geometry and compensation rotation');
figurePaths(6,:) = save_pair(fig,root, ...
    'figure6_phase_error_eta_and_compensation_phase');
end

function plot_prediction_panel(ax,predAmp,actualAmp,predPhase,actualPhase,label)
plot(ax,predAmp,actualAmp,'o','LineWidth',1.2); hold(ax,'on');
plot(ax,predPhase,actualPhase,'s','LineWidth',1.2);
limits = [min([predAmp;actualAmp;predPhase;actualPhase]), ...
    max([predAmp;actualAmp;predPhase;actualPhase])];
padding = max(0.03*(max(limits)-min(limits)),1e-3);
limits = limits + [-padding,padding];
plot(ax,limits,limits,'--','LineWidth',1.0);
xlim(ax,limits); ylim(ax,limits); axis(ax,'square'); grid(ax,'on');
xlabel(ax,['Static LS predicted ' label ' (pF)']);
ylabel(ax,['Recursive actual ' label ' (pF)']);
legend(ax,{'Amplitude sweep','Phase-error sweep','Identity'}, ...
    'Location','best');
end

function paths = save_pair(fig,root,name)
pngPath = fullfile(root,[name '.png']);
figPath = fullfile(root,[name '.fig']);
exportgraphics(fig,pngPath,'Resolution',200);
savefig(fig,figPath);
close(fig);
paths = [string(pngPath),string(figPath)];
end
