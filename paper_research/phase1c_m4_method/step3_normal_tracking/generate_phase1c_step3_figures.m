function figurePaths = generate_phase1c_step3_figures( ...
        figuresRoot,summaryTable,correlationTable,caseDetails)
%GENERATE_PHASE1C_STEP3_FIGURES Create the formal Step 3 figure set.

figurePaths = strings(7,2);
figurePaths(1,:) = static_case_figure(figuresRoot,caseDetails.Case01_static);
figurePaths(2,:) = tracking_case_figure(figuresRoot, ...
    caseDetails.Case02_slow_drift,"Figure_B_Case02_slow_drift", ...
    "Case02 slow drift tracking",[0.8,4.0]);
figurePaths(3,:) = evidence_figure(figuresRoot, ...
    caseDetails.Case02_slow_drift,"Figure_B2_Case02_weight_evidence", ...
    "Case02 update weight and evidence",[0.8,4.0]);
figurePaths(4,:) = transition_figure(figuresRoot, ...
    caseDetails.Case03_smooth_step);
figurePaths(5,:) = tracking_case_figure(figuresRoot, ...
    caseDetails.Case04_random_drift,"Figure_D_Case04_random_drift", ...
    "Case04 random drift tracking",[0.8,4.0]);
figurePaths(6,:) = rmse_summary_figure(figuresRoot,summaryTable);
figurePaths(7,:) = correlation_figure( ...
    figuresRoot,correlationTable,caseDetails);
end

function paths = static_case_figure(root,detail)
fig = new_figure();
layout = tiledlayout(fig,3,1,'TileSpacing','compact', ...
    'Padding','compact');
plot_capacitance(nexttile(layout),detail,1,"Cs1 (pF)");
plot_capacitance(nexttile(layout),detail,2,"Cs2 (pF)");
ax = nexttile(layout);
cycle = detail.M4_cycle;
plot(ax,cycle.time_s,cycle.update_weight,'LineWidth',1.3);
ylabel(ax,"g"); xlabel(ax,"Time (s)"); ylim(ax,[0,1.04]); grid(ax,'on');
title(layout,"Figure A — Case01 static coupling and M4 update weight");
paths = save_pair(fig,root,"Figure_A_Case01_static");
close(fig);
end

function paths = tracking_case_figure(root,detail,stem,figureTitle,xLimits)
fig = new_figure();
layout = tiledlayout(fig,3,1,'TileSpacing','compact', ...
    'Padding','compact');
plot_capacitance(nexttile(layout),detail,1,"Cs1 (pF)");
plot_capacitance(nexttile(layout),detail,2,"Cs2 (pF)");
ax = nexttile(layout);
cycle = detail.M4_cycle;
yyaxis(ax,'left');
plot(ax,cycle.time_s,cycle.update_weight,'LineWidth',1.25);
ylabel(ax,"Update weight g"); ylim(ax,[0,1.04]);
yyaxis(ax,'right');
plot(ax,cycle.time_s,cycle.fault_evidence_score,'LineWidth',1.1);
ylabel(ax,"Fault evidence");
xlabel(ax,"Time (s)"); grid(ax,'on');
set_all_xlimits(layout,xLimits);
title(layout,figureTitle);
paths = save_pair(fig,root,stem);
close(fig);
end

function paths = evidence_figure(root,detail,stem,figureTitle,xLimits)
fig = new_figure();
layout = tiledlayout(fig,3,1,'TileSpacing','compact', ...
    'Padding','compact');
cycle = detail.M4_cycle;
ax = nexttile(layout);
plot(ax,cycle.time_s,cycle.update_weight,'LineWidth',1.3);
ylabel(ax,"g"); ylim(ax,[0,1.04]); grid(ax,'on');
ax = nexttile(layout);
plot(ax,cycle.time_s,cycle.fault_evidence_score,'LineWidth',1.2);
ylabel(ax,"Evidence"); grid(ax,'on');
ax = nexttile(layout);
plot(ax,cycle.time_s,cycle.evidence_ratio_base,'LineWidth',1.1);
hold(ax,'on');
plot(ax,cycle.time_s,cycle.evidence_ratio_quad,'LineWidth',1.1);
ylabel(ax,"Evidence ratio"); xlabel(ax,"Time (s)");
legend(ax,{"Base","Quadrature"},'Location','best'); grid(ax,'on');
set_all_xlimits(layout,xLimits);
title(layout,figureTitle);
paths = save_pair(fig,root,stem);
close(fig);
end

function paths = transition_figure(root,detail)
fig = new_figure();
layout = tiledlayout(fig,3,1,'TileSpacing','compact', ...
    'Padding','compact');
plot_capacitance(nexttile(layout),detail,1,"Cs1 (pF)");
plot_capacitance(nexttile(layout),detail,2,"Cs2 (pF)");
ax = nexttile(layout);
cycle = detail.M4_cycle;
yyaxis(ax,'left');
plot(ax,cycle.time_s,cycle.update_weight,'LineWidth',1.25);
ylabel(ax,"Update weight g"); ylim(ax,[0,1.04]);
yyaxis(ax,'right');
plot(ax,cycle.time_s,cycle.lambda,'LineWidth',1.1);
ylabel(ax,"Forgetting factor lambda");
xlabel(ax,"Time (s)"); grid(ax,'on');
set_all_xlimits(layout,[1.2,2.2]);
title(layout,"Figure C — Case03 transition response");
paths = save_pair(fig,root,"Figure_C_Case03_transition");
close(fig);
end

function paths = rmse_summary_figure(root,summary)
caseOrder = ["Case01_static","Case02_slow_drift", ...
    "Case03_smooth_step","Case04_random_drift"];
modeOrder = ["M2","M3","M4"];
cs1 = metric_matrix(summary,caseOrder,modeOrder,"Cs1_RMSE_pF");
cs2 = metric_matrix(summary,caseOrder,modeOrder,"Cs2_RMSE_pF");
fig = new_figure();
layout = tiledlayout(fig,2,1,'TileSpacing','compact', ...
    'Padding','compact');
ax = nexttile(layout);
bar(ax,cs1); ylabel(ax,"Cs1 RMSE (pF)"); grid(ax,'on');
set(ax,'XTick',1:4,'XTickLabel',short_case_names(caseOrder));
legend(ax,cellstr(modeOrder),'Location','best');
ax = nexttile(layout);
bar(ax,cs2); ylabel(ax,"Cs2 RMSE (pF)"); grid(ax,'on');
set(ax,'XTick',1:4,'XTickLabel',short_case_names(caseOrder));
xlabel(ax,"No-fault case");
title(layout,"Figure E — Cs tracking RMSE comparison");
paths = save_pair(fig,root,"Figure_E_tracking_RMSE_comparison");
close(fig);
end

function paths = correlation_figure(root,correlationTable,caseDetails)
caseOrder = ["Case02_slow_drift","Case03_smooth_step", ...
    "Case04_random_drift"];
fig = new_figure();
layout = tiledlayout(fig,1,3,'TileSpacing','compact', ...
    'Padding','compact');
for k = 1:numel(caseOrder)
    caseName = caseOrder(k);
    detail = caseDetails.(char(caseName));
    cycle = detail.M4_cycle;
    trueCs1 = interp1(detail.t,detail.Cs1_true,cycle.time_s,'linear');
    trueCs2 = interp1(detail.t,detail.Cs2_true,cycle.time_s,'linear');
    drift = hypot([NaN;diff(trueCs1)],[NaN;diff(trueCs2)]);
    suppression = 1-cycle.update_weight;
    valid = isfinite(drift) & isfinite(suppression);
    ax = nexttile(layout);
    scatter(ax,drift(valid),suppression(valid),22,cycle.time_s(valid), ...
        'filled','MarkerFaceAlpha',0.65);
    row = correlationTable(correlationTable.case_name == caseName & ...
        correlationTable.target_metric == "normal_suppression",:);
    title(ax,sprintf('%s: r=%.3f, rho=%.3f', ...
        short_case_names(caseName),row.pearson_r,row.spearman_rho));
    xlabel(ax,"|Delta Cs true| (pF/cycle)");
    ylabel(ax,"1-g"); grid(ax,'on');
end
title(layout,"Figure F — True drift versus normal-update suppression");
paths = save_pair(fig,root,"Figure_F_drift_suppression_correlation");
close(fig);
end

function plot_capacitance(ax,detail,columnIndex,yLabelText)
sampleCount = numel(detail.t);
stride = max(1,ceil(sampleCount/4000));
index = 1:stride:sampleCount;
if columnIndex == 1
    truth = detail.Cs1_true;
else
    truth = detail.Cs2_true;
end
plot(ax,detail.t(index),truth(index),'k','LineWidth',1.6);
hold(ax,'on');
plot(ax,detail.t(index),detail.M2_cHist(index,columnIndex), ...
    'LineWidth',1.0);
plot(ax,detail.t(index),detail.M3_cHist(index,columnIndex), ...
    'LineWidth',1.0);
plot(ax,detail.t(index),detail.M4_cHist(index,columnIndex), ...
    'LineWidth',1.2);
ylabel(ax,yLabelText); grid(ax,'on');
legend(ax,{"True","M2","M3","M4"},'Location','best');
end

function matrix = metric_matrix(summary,cases,modes,metricName)
matrix = NaN(numel(cases),numel(modes));
for row = 1:numel(cases)
    for column = 1:numel(modes)
        selected = summary.case_name == cases(row) & ...
            summary.algorithm_mode == modes(column);
        matrix(row,column) = summary{selected,metricName};
    end
end
end

function labels = short_case_names(caseNames)
labels = erase(string(caseNames),["_static","_slow_drift", ...
    "_smooth_step","_random_drift"]);
end

function set_all_xlimits(layout,xLimits)
axesHandles = findall(layout.Parent,'Type','axes');
set(axesHandles,'XLim',xLimits);
end

function fig = new_figure()
fig = figure('Visible','off','Color','white', ...
    'Position',[100,100,1100,760]);
end

function paths = save_pair(fig,root,stem)
pngPath = fullfile(root,stem+".png");
figPath = fullfile(root,stem+".fig");
exportgraphics(fig,pngPath,'Resolution',200);
savefig(fig,figPath);
paths = [string(pngPath),string(figPath)];
end
