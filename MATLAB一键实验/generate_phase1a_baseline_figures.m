function outputs = generate_phase1a_baseline_figures()
%GENERATE_PHASE1A_BASELINE_FIGURES Plot frozen Phase 1A workspace data.
% This function does not run a model or algorithm.

matlabRoot = fileparts(mfilename('fullpath'));
projectRoot = fileparts(matlabRoot);
baselineRoot = fullfile(projectRoot,'paper_research', ...
    'phase1a_baseline');
workspacePath = fullfile(baselineRoot,'baseline_workspace.mat');
expectedWorkspaceHash = ...
    "A90632B72479E7B6ADC4E410DB37542E9CA4985CA8381B6BAFC8F71C961E87B5";
workspaceHash = file_sha256(workspacePath);
if workspaceHash ~= expectedWorkspaceHash
    error('Phase1A:FigureWorkspaceIntegrityFailure', ...
        'Formal baseline workspace SHA-256 does not match Step 6.');
end

loaded = load(workspacePath,'caseData','algorithmResults','runMetadata');
figureRoot = fullfile(baselineRoot,'figures');
if ~isfolder(figureRoot)
    mkdir(figureRoot);
end

figure1 = plot_case02_tracking(loaded.caseData,loaded.algorithmResults);
[figure1Png,figure1Fig] = save_figure_pair(figure1,figureRoot, ...
    'figure1_case02_slow_drift_tracking');

figure2 = plot_case06_parameters(loaded.caseData,loaded.algorithmResults);
[figure2Png,figure2Fig] = save_figure_pair(figure2,figureRoot, ...
    'figure2_case06_fault_parameter_tracking');

figure3 = plot_case06_resistive_current( ...
    loaded.caseData,loaded.algorithmResults);
[figure3Png,figure3Fig] = save_figure_pair(figure3,figureRoot, ...
    'figure3_case06_B_resistive_current');

outputs = struct( ...
    'workspace_path',string(workspacePath), ...
    'workspace_sha256',workspaceHash, ...
    'run_timestamp',loaded.runMetadata.run_timestamp, ...
    'figure1_png',string(figure1Png), ...
    'figure1_fig',string(figure1Fig), ...
    'figure2_png',string(figure2Png), ...
    'figure2_fig',string(figure2Fig), ...
    'figure3_png',string(figure3Png), ...
    'figure3_fig',string(figure3Fig));
disp(outputs);
end

function fig = plot_case02_tracking(caseData,algorithmResults)
data = caseData.Case02_slow_drift;
algorithms = algorithmResults.Case02_slow_drift;
fig = new_figure();
layout = tiledlayout(fig,2,1,'TileSpacing','compact', ...
    'Padding','compact');

axes1 = nexttile(layout);
plot(axes1,data.t,data.Cs1_true,'k','LineWidth',1.8);
hold(axes1,'on');
plot(axes1,data.t,algorithms.M0.cHist(:,1),'--', ...
    'Color',[0.45 0.45 0.45],'LineWidth',1.4);
plot(axes1,data.t,algorithms.M2.cHist(:,1),'-', ...
    'Color',[0 0.4470 0.7410],'LineWidth',1.25);
plot(axes1,data.t,algorithms.M3.cHist(:,1),':', ...
    'Color',[0.8500 0.3250 0.0980],'LineWidth',1.8);
ylabel(axes1,'C_{s1} (pF)');
title(axes1,'Case02 Slow Drift: C_{s1} Tracking');
legend(axes1,{'Truth','M0','M2','M3'},'Location','best', ...
    'NumColumns',4);
style_axes(axes1);

axes2 = nexttile(layout);
plot(axes2,data.t,data.Cs2_true,'k','LineWidth',1.8);
hold(axes2,'on');
plot(axes2,data.t,algorithms.M0.cHist(:,2),'--', ...
    'Color',[0.45 0.45 0.45],'LineWidth',1.4);
plot(axes2,data.t,algorithms.M2.cHist(:,2),'-', ...
    'Color',[0 0.4470 0.7410],'LineWidth',1.25);
plot(axes2,data.t,algorithms.M3.cHist(:,2),':', ...
    'Color',[0.8500 0.3250 0.0980],'LineWidth',1.8);
xlabel(axes2,'Time (s)');
ylabel(axes2,'C_{s2} (pF)');
title(axes2,'Case02 Slow Drift: C_{s2} Tracking');
style_axes(axes2);
end

function fig = plot_case06_parameters(caseData,algorithmResults)
data = caseData.Case06_drift_then_fault;
algorithms = algorithmResults.Case06_drift_then_fault;
fig = new_figure();
layout = tiledlayout(fig,2,1,'TileSpacing','compact', ...
    'Padding','compact');

axes1 = nexttile(layout);
plot(axes1,data.t,data.Cs1_true,'k','LineWidth',1.8);
hold(axes1,'on');
plot(axes1,data.t,algorithms.M2.cHist(:,1),'-', ...
    'Color',[0 0.4470 0.7410],'LineWidth',1.25);
plot(axes1,data.t,algorithms.M3.cHist(:,1),'-', ...
    'Color',[0.8500 0.3250 0.0980],'LineWidth',1.25);
mark_fault_transition(axes1);
ylabel(axes1,'C_{s1} (pF)');
title(axes1,'Case06 Drift Then Fault: C_{s1} Tracking');
legend(axes1,{'Truth','M2: no gate','M3: hard gate'}, ...
    'Location','northwest');
style_axes(axes1);

axes2 = nexttile(layout);
plot(axes2,data.t,data.Cs2_true,'k','LineWidth',1.8);
hold(axes2,'on');
plot(axes2,data.t,algorithms.M2.cHist(:,2),'-', ...
    'Color',[0 0.4470 0.7410],'LineWidth',1.25);
plot(axes2,data.t,algorithms.M3.cHist(:,2),'-', ...
    'Color',[0.8500 0.3250 0.0980],'LineWidth',1.25);
mark_fault_transition(axes2);
xlabel(axes2,'Time (s)');
ylabel(axes2,'C_{s2} (pF)');
title(axes2,'Case06 Drift Then Fault: C_{s2} Tracking');
style_axes(axes2);
end

function fig = plot_case06_resistive_current(caseData,algorithmResults)
data = caseData.Case06_drift_then_fault;
algorithms = algorithmResults.Case06_drift_then_fault;
fig = new_figure();
layout = tiledlayout(fig,2,1,'TileSpacing','compact', ...
    'Padding','compact');

axes1 = nexttile(layout);
plot_resistive_currents(axes1,data,algorithms);
mark_fault_transition(axes1);
ylabel(axes1,'i_{R,B} (mA)');
title(axes1,'Case06 B-Phase Resistive Current: Fault-Window Overview');
legend(axes1,{'Truth','M0','M2','M3'},'Location','best', ...
    'NumColumns',4);
style_axes(axes1);
xlim(axes1,[2.5 4]);

axes2 = nexttile(layout);
plot_resistive_currents(axes2,data,algorithms);
mark_fault_transition(axes2);
xlabel(axes2,'Time (s)');
ylabel(axes2,'i_{R,B} (mA)');
title(axes2,'Fault-Transition Detail');
style_axes(axes2);
xlim(axes2,[2.96 3.14]);
end

function plot_resistive_currents(axesHandle,data,algorithms)
plot(axesHandle,data.t,1e3*data.irB_true,'k','LineWidth',1.5);
hold(axesHandle,'on');
plot(axesHandle,data.t,1e3*algorithms.M0.irB,'--', ...
    'Color',[0.45 0.45 0.45],'LineWidth',1.1);
plot(axesHandle,data.t,1e3*algorithms.M2.irB,'-', ...
    'Color',[0 0.4470 0.7410],'LineWidth',1.0);
plot(axesHandle,data.t,1e3*algorithms.M3.irB,'-', ...
    'Color',[0.8500 0.3250 0.0980],'LineWidth',1.0);
end

function mark_fault_transition(axesHandle)
xline(axesHandle,3.00,'--','Fault start', ...
    'Color',[0.35 0.35 0.35],'LabelVerticalAlignment','bottom');
xline(axesHandle,3.06,':','Fault 1.6x', ...
    'Color',[0.35 0.35 0.35],'LabelVerticalAlignment','top');
end

function fig = new_figure()
fig = figure('Visible','off','Color','w', ...
    'Position',[100 100 1100 720]);
end

function style_axes(axesHandle)
grid(axesHandle,'on');
box(axesHandle,'on');
xlim(axesHandle,[0 4]);
set(axesHandle,'FontName','Times New Roman','FontSize',11, ...
    'LineWidth',0.8,'Layer','top');
end

function [pngPath,figPath] = save_figure_pair(fig,figureRoot,baseName)
pngPath = fullfile(figureRoot,[baseName '.png']);
figPath = fullfile(figureRoot,[baseName '.fig']);
exportgraphics(fig,pngPath,'Resolution',300);
savefig(fig,figPath);
close(fig);
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
