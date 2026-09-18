function figurePaths = generate_phase1b_step2_figures( ...
        figuresRoot,data,signals,originalM2,instrumented, ...
        cycleTable,observationBlocks,analysis)
%GENERATE_PHASE1B_STEP2_FIGURES Generate the seven formal Case05 figures.

if ~isfolder(figuresRoot)
    mkdir(figuresRoot);
end
figurePaths = strings(7,2);
t = data.t;
tc = cycleTable.time_end_s;

% Figure 1 — false Cs drift.
fig = figure('Visible','off');
layout = tiledlayout(fig,2,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,t,data.Cs1,'LineWidth',1.4); hold(ax,'on');
plot(ax,t,originalM2.hist(:,1),'LineWidth',1.2);
mark_fault(ax); ylabel(ax,'Cs1 (pF)');
legend(ax,{'truth','M2'},'Location','best'); grid(ax,'on');
ax = nexttile(layout);
plot(ax,t,data.Cs2,'LineWidth',1.4); hold(ax,'on');
plot(ax,t,originalM2.hist(:,2),'LineWidth',1.2);
mark_fault(ax); ylabel(ax,'Cs2 (pF)'); xlabel(ax,'Time (s)');
legend(ax,{'truth','M2'},'Location','best'); grid(ax,'on');
title(layout,'Figure 1 — Case05 false Cs drift');
figurePaths(1,:) = save_pair(fig,figuresRoot, ...
    'figure1_case05_false_cs_drift');

% Figure 2 — representative full-observation geometry, displayed by phase.
representative = find(cycleTable.time_start_s >= 3.40,1,'first');
block = observationBlocks(representative);
n = cycleTable.n_samples(representative);
sample = (1:n).';
fig = figure('Visible','off');
layout = tiledlayout(fig,3,1,'TileSpacing','compact');
phaseNames = ["A","B","C"];
for p = 1:3
    idx = (p-1)*n+(1:n);
    ax = nexttile(layout);
    plot(ax,sample,1e3*block.r_fault(idx),'LineWidth',1.2); hold(ax,'on');
    plot(ax,sample,1e3*block.r_parallel(idx),'LineWidth',1.1);
    plot(ax,sample,1e3*block.r_perp(idx),'LineWidth',1.1);
    ylabel(ax,phaseNames(p)+" (mA)"); grid(ax,'on');
    if p == 1
        legend(ax,{'r fault','r parallel','r perp'},'Location','best');
    end
end
xlabel(nexttile_handle(layout,3),'Sample in cycle');
title(layout,sprintf( ...
    'Figure 2 — Fault geometry at %.5f–%.5f s, eta=%.4f', ...
    cycleTable.time_start_s(representative), ...
    cycleTable.time_end_s(representative), ...
    cycleTable.eta_geom(representative)));
figurePaths(2,:) = save_pair(fig,figuresRoot, ...
    'figure2_case05_fault_geometric_decomposition');

% Figure 3 — eta and static LS bias.
fig = figure('Visible','off');
layout = tiledlayout(fig,2,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,tc,cycleTable.eta_geom,'LineWidth',1.2); hold(ax,'on');
yyaxis(ax,'right');
plot(ax,tc,cycleTable.fault_factor_true,'LineWidth',1.0);
yyaxis(ax,'left'); ylabel(ax,'eta geom'); ylim(ax,[0 1]);
yyaxis(ax,'right'); ylabel(ax,'Fault factor');
mark_fault(ax); grid(ax,'on');
ax = nexttile(layout);
plot(ax,tc,cycleTable.delta_Cs1_LS_pred_pF,'LineWidth',1.2); hold(ax,'on');
plot(ax,tc,cycleTable.delta_Cs2_LS_pred_pF,'LineWidth',1.2);
mark_fault(ax); grid(ax,'on');
ylabel(ax,'Static bias (pF)'); xlabel(ax,'Time (s)');
legend(ax,{'Delta Cs1 LS','Delta Cs2 LS'},'Location','best');
title(layout,'Figure 3 — Geometric absorbability and static LS bias');
figurePaths(3,:) = save_pair(fig,figuresRoot, ...
    'figure3_case05_eta_geom_static_bias');

% Figure 4 — recursive fault and counterfactual states.
fig = figure('Visible','off');
layout = tiledlayout(fig,3,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,t,data.Cs1,'LineWidth',1.3); hold(ax,'on');
plot(ax,t,originalM2.hist(:,1),'LineWidth',1.1);
plot(ax,t,instrumented.counterfactual.hist(:,1),'LineWidth',1.1);
mark_fault(ax); ylabel(ax,'Cs1 (pF)'); grid(ax,'on');
legend(ax,{'truth','M2 fault replay','counterfactual'},'Location','best');
ax = nexttile(layout);
plot(ax,t,data.Cs2,'LineWidth',1.3); hold(ax,'on');
plot(ax,t,originalM2.hist(:,2),'LineWidth',1.1);
plot(ax,t,instrumented.counterfactual.hist(:,2),'LineWidth',1.1);
mark_fault(ax); ylabel(ax,'Cs2 (pF)'); grid(ax,'on');
ax = nexttile(layout);
plot(ax,t,originalM2.hist(:,1)-instrumented.counterfactual.hist(:,1), ...
    'LineWidth',1.1); hold(ax,'on');
plot(ax,t,originalM2.hist(:,2)-instrumented.counterfactual.hist(:,2), ...
    'LineWidth',1.1);
mark_fault(ax); ylabel(ax,'Fault-CF (pF)'); xlabel(ax,'Time (s)');
legend(ax,{'Cs1 difference','Cs2 difference'},'Location','best'); grid(ax,'on');
title(layout,'Figure 4 — Dynamic recursive parameter bias');
figurePaths(4,:) = save_pair(fig,figuresRoot, ...
    'figure4_case05_recursive_parameter_bias');

% Figure 5 — single-cycle and accumulated quantities on separate axes.
fig = figure('Visible','off');
layout = tiledlayout(fig,3,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,tc,cycleTable.delta_Cs1_LS_pred_pF,'LineWidth',1.1); hold(ax,'on');
plot(ax,tc,cycleTable.delta_Cs1_RLS_direct_raw_pF,'LineWidth',1.1);
plot(ax,tc,cycleTable.delta_Cs1_actual_pF,'LineWidth',1.1);
mark_fault(ax); ylabel(ax,'Cs1/cycle (pF)'); grid(ax,'on');
legend(ax,{'static LS fault','direct RLS fault','actual update'},'Location','best');
ax = nexttile(layout);
plot(ax,tc,cycleTable.delta_Cs2_LS_pred_pF,'LineWidth',1.1); hold(ax,'on');
plot(ax,tc,cycleTable.delta_Cs2_RLS_direct_raw_pF,'LineWidth',1.1);
plot(ax,tc,cycleTable.delta_Cs2_actual_pF,'LineWidth',1.1);
mark_fault(ax); ylabel(ax,'Cs2/cycle (pF)'); grid(ax,'on');
ax = nexttile(layout);
plot(ax,tc,cycleTable.Cs1_est_pF-cycleTable.Cs1_cf_est_pF, ...
    'LineWidth',1.1); hold(ax,'on');
plot(ax,tc,cycleTable.Cs2_est_pF-cycleTable.Cs2_cf_est_pF, ...
    'LineWidth',1.1);
mark_fault(ax); ylabel(ax,'Cumulative fault-CF (pF)');
xlabel(ax,'Time (s)'); grid(ax,'on');
legend(ax,{'Cs1','Cs2'},'Location','best');
title(layout,'Figure 5 — LS, direct RLS and recursive accumulation');
figurePaths(5,:) = save_pair(fig,figuresRoot, ...
    'figure5_case05_ls_direct_recursive_relationship');

% Figure 6 — innovation, lambda and rate limiting.
fig = figure('Visible','off');
layout = tiledlayout(fig,3,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,tc,cycleTable.innovation,'LineWidth',1.1); hold(ax,'on');
plot(ax,tc,cycleTable.innovation_cf,'LineWidth',1.1);
mark_fault(ax); ylabel(ax,'Innovation'); grid(ax,'on');
legend(ax,{'fault','counterfactual'},'Location','best');
ax = nexttile(layout);
plot(ax,tc,cycleTable.lambda,'LineWidth',1.1); hold(ax,'on');
plot(ax,tc,cycleTable.lambda_cf,'LineWidth',1.1);
mark_fault(ax); ylabel(ax,'Lambda'); grid(ax,'on');
legend(ax,{'fault','counterfactual'},'Location','best');
ax = nexttile(layout);
stairs(ax,tc,double(cycleTable.rate_limit_active_Cs1),'LineWidth',1.1); hold(ax,'on');
stairs(ax,tc,double(cycleTable.rate_limit_active_Cs2),'LineWidth',1.1);
yyaxis(ax,'right');
plot(ax,tc,cycleTable.fault_factor_true,'LineWidth',1.0);
yyaxis(ax,'left'); ylabel(ax,'Rate active'); ylim(ax,[-0.1 1.1]);
yyaxis(ax,'right'); ylabel(ax,'Fault factor');
xlabel(ax,'Time (s)'); mark_fault(ax); grid(ax,'on');
title(layout,'Figure 6 — VFF and rate-limit timeline');
figurePaths(6,:) = save_pair(fig,figuresRoot, ...
    'figure6_case05_lambda_innovation_rate_limit');

% Figure 7 — E_in/E_quad evidence timeline.
fig = figure('Visible','off');
layout = tiledlayout(fig,2,1,'TileSpacing','compact');
ax = nexttile(layout);
plot(ax,tc,1e3*cycleTable.E_in_A,'LineWidth',1.1); hold(ax,'on');
plot(ax,tc,1e3*cycleTable.E_quad_A,'LineWidth',1.1);
plot(ax,tc,1e3*cycleTable.base_in_A,'LineWidth',1.1);
plot(ax,tc,1e3*1.12.*cycleTable.base_in_A,'--','LineWidth',1.0);
plot(ax,tc,1e3*1.20.*cycleTable.E_quad_A,'--','LineWidth',1.0);
mark_fault(ax); ylabel(ax,'Residual metric (mA)'); grid(ax,'on');
legend(ax,{'E in','E quad','baseIn','1.12 baseIn','1.20 E quad'}, ...
    'Location','best');
ax = nexttile(layout);
yyaxis(ax,'left');
plot(ax,t,signals.fault_scale,'LineWidth',1.1); hold(ax,'on');
ylabel(ax,'Fault factor');
yyaxis(ax,'right');
plot(ax,t,1e3*analysis.rFaultB,'LineWidth',1.0);
ylabel(ax,'r fault B (mA)');
xlabel(ax,'Time (s)'); grid(ax,'on');
legend(ax,{'fault factor','r fault B'},'Location','best');
mark_fault(ax);
title(layout,'Figure 7 — E in/E quad fault-evidence timeline');
figurePaths(7,:) = save_pair(fig,figuresRoot, ...
    'figure7_case05_ein_equad_timeline');
end

function paths = save_pair(fig,root,name)
pngPath = fullfile(root,[name '.png']);
figPath = fullfile(root,[name '.fig']);
exportgraphics(fig,pngPath,'Resolution',200);
savefig(fig,figPath);
close(fig);
paths = [string(pngPath),string(figPath)];
end

function mark_fault(ax)
xline(ax,3.00,':','HandleVisibility','off');
xline(ax,3.06,':','HandleVisibility','off');
end

function ax = nexttile_handle(layout,index)
ax = nexttile(layout,index);
end
