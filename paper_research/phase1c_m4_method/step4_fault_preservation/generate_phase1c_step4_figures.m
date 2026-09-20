function figurePaths = generate_phase1c_step4_figures( ...
        figuresRoot,summaryTable,caseDetails)
%GENERATE_PHASE1C_STEP4_FIGURES Create formal Step 4 figures A-G.

figurePaths = strings(7,2);
figurePaths(1,:) = parameter_figure(figuresRoot, ...
    caseDetails.Case05_fault_only,"Figure_A_Case05_parameter_trajectory", ...
    "Figure A — Case05 parameter trajectory");
figurePaths(2,:) = response_figure(figuresRoot, ...
    caseDetails.Case05_fault_only,"Figure_B_Case05_fault_response", ...
    "Figure B — Case05 continuous and hard-gate fault response");
figurePaths(3,:) = current_factor_figure(figuresRoot, ...
    caseDetails.Case05_fault_only,summaryTable, ...
    "Case05_fault_only","Figure_C_Case05_retention", ...
    "Figure C — Case05 resistive-current and fault-factor retention");
figurePaths(4,:) = parameter_figure(figuresRoot, ...
    caseDetails.Case06_drift_then_fault, ...
    "Figure_D_Case06_parameter_trajectory", ...
    "Figure D — Case06 drift-then-fault parameter trajectory");
figurePaths(5,:) = response_figure(figuresRoot, ...
    caseDetails.Case06_drift_then_fault, ...
    "Figure_E_Case06_fault_response", ...
    "Figure E — Case06 continuous and hard-gate fault response");
figurePaths(6,:) = delta_cs_figure(figuresRoot,summaryTable);
figurePaths(7,:) = retention_figure(figuresRoot,summaryTable);
end

function paths = parameter_figure(root,detail,stem,figureTitle)
fig = new_figure();
layout = tiledlayout(fig,2,1,'TileSpacing','compact', ...
    'Padding','compact');
plot_parameter(nexttile(layout),detail,1,"Cs1 (pF)");
plot_parameter(nexttile(layout),detail,2,"Cs2 (pF)");
title(layout,figureTitle);
paths = save_pair(fig,root,stem);
close(fig);
end

function paths = response_figure(root,detail,stem,figureTitle)
fig = new_figure();
layout = tiledlayout(fig,4,1,'TileSpacing','compact', ...
    'Padding','compact');
m4 = detail.M4_cycle;
m3 = detail.M3_cycle;

ax = nexttile(layout);
yyaxis(ax,'left');
plot(ax,m4.time_s,m4.update_weight,'LineWidth',1.3);
ylabel(ax,"M4 g"); ylim(ax,[0,1.04]);
yyaxis(ax,'right');
stairs(ax,m3.time_s,double(m3.gate > 0),'LineWidth',1.1);
ylabel(ax,"M3 gate"); ylim(ax,[-0.04,1.04]);
fault_line(ax);
grid(ax,'on');

ax = nexttile(layout);
plot(ax,m4.time_s,m4.fault_evidence_score,'LineWidth',1.3);
ylabel(ax,"Evidence s"); fault_line(ax); grid(ax,'on');

ax = nexttile(layout);
yyaxis(ax,'left');
plot(ax,m4.time_s,m4.evidence_ratio_base,'LineWidth',1.2);
ylabel(ax,"E_{in}/baseIn");
yyaxis(ax,'right');
plot(ax,m4.time_s,m4.evidence_ratio_quad,'LineWidth',1.2);
ylabel(ax,"E_{in}/E_{quad}");
legend(ax,{"E_{in}/baseIn","E_{in}/E_{quad}"},'Location','best');
fault_line(ax); grid(ax,'on');

ax = nexttile(layout);
plot(ax,m4.time_s,m4.evidence_background_excess,'LineWidth',1.2);
hold(ax,'on');
plot(ax,m4.time_s,m4.evidence_phase_weight,'LineWidth',1.2);
ylabel(ax,"Evidence terms"); xlabel(ax,"Time (s)");
legend(ax,{"e_b","p_q"},'Location','best');
fault_line(ax); grid(ax,'on');
set_all_xlimits(layout,[2.5,4.0]);
title(layout,figureTitle);
paths = save_pair(fig,root,stem);
close(fig);
end

function paths = current_factor_figure( ...
        root,detail,summary,caseName,stem,figureTitle)
fig = new_figure();
layout = tiledlayout(fig,2,1,'TileSpacing','compact', ...
    'Padding','compact');
ax = nexttile(layout);
index = detail.t >= 2.5 & detail.t < 3.8;
stride = max(1,ceil(nnz(index)/6000));
sample = find(index);
sample = sample(1:stride:end);
plot(ax,detail.t(sample),1e3*detail.irB_true(sample),'k', ...
    'LineWidth',1.4);
hold(ax,'on');
plot(ax,detail.t(sample),1e3*detail.M2_irB(sample),'LineWidth',1.0);
plot(ax,detail.t(sample),1e3*detail.M3_irB(sample),'LineWidth',1.0);
plot(ax,detail.t(sample),1e3*detail.M4_irB(sample),'LineWidth',1.1);
fault_line(ax);
ylabel(ax,"B resistive current (mA)"); xlabel(ax,"Time (s)");
legend(ax,{"True","M2","M3","M4"},'Location','best'); grid(ax,'on');

caseRows = summary(summary.case_name == string(caseName),:);
factor = [caseRows.fault_factor_true(1); ...
    factor_for(caseRows,"M2");factor_for(caseRows,"M3"); ...
    factor_for(caseRows,"M4")];
ax = nexttile(layout);
bar(ax,factor);
set(ax,'XTick',1:4,'XTickLabel',{'True','M2','M3','M4'});
ylabel(ax,"Fault factor"); ylim(ax,[0,1.1*max(factor)]); grid(ax,'on');
title(layout,figureTitle);
paths = save_pair(fig,root,stem);
close(fig);
end

function paths = delta_cs_figure(root,summary)
caseOrder = ["Case05_fault_only","Case06_drift_then_fault"];
modeOrder = ["M2","M3","M4"];
cs1 = metric_matrix(summary,caseOrder,modeOrder, ...
    "DeltaCs1_fault_induced_pF");
cs2 = metric_matrix(summary,caseOrder,modeOrder, ...
    "DeltaCs2_fault_induced_pF");
fig = new_figure();
layout = tiledlayout(fig,2,1,'TileSpacing','compact', ...
    'Padding','compact');
ax = nexttile(layout);
bar(ax,cs1); yline(ax,0,'k-'); ylabel(ax,"Fault-induced ΔCs1 (pF)");
set(ax,'XTick',1:2,'XTickLabel',{'Case05','Case06'}); grid(ax,'on');
legend(ax,cellstr(modeOrder),'Location','best');
ax = nexttile(layout);
bar(ax,cs2); yline(ax,0,'k-'); ylabel(ax,"Fault-induced ΔCs2 (pF)");
set(ax,'XTick',1:2,'XTickLabel',{'Case05','Case06'}); grid(ax,'on');
xlabel(ax,"Fault case");
title(layout,"Figure F — Fault-induced parameter absorption");
paths = save_pair(fig,root,"Figure_F_fault_induced_DeltaCs");
close(fig);
end

function paths = retention_figure(root,summary)
caseOrder = ["Case05_fault_only","Case06_drift_then_fault"];
modeOrder = ["M2","M3","M4"];
matrix = NaN(2,4);
for k = 1:2
    caseRows = summary(summary.case_name == caseOrder(k),:);
    matrix(k,1) = caseRows.fault_factor_true(1);
    for j = 1:3
        matrix(k,j+1) = factor_for(caseRows,modeOrder(j));
    end
end
fig = new_figure();
ax = axes(fig);
bar(ax,matrix);
set(ax,'XTick',1:2,'XTickLabel',{'Case05','Case06'});
legend(ax,{'True','M2','M3','M4'},'Location','best');
ylabel(ax,"Fault factor"); xlabel(ax,"Fault case");
ylim(ax,[0,1.1*max(matrix,[],'all')]); grid(ax,'on');
title(ax,"Figure G — Fault-retention comparison");
paths = save_pair(fig,root,"Figure_G_fault_retention_comparison");
close(fig);
end

function plot_parameter(ax,detail,columnIndex,yLabelText)
sampleCount = numel(detail.t);
stride = max(1,ceil(sampleCount/5000));
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
fault_line(ax);
ylabel(ax,yLabelText); xlabel(ax,"Time (s)"); grid(ax,'on');
legend(ax,{"True","M2","M3","M4"},'Location','best');
end

function value = factor_for(rows,mode)
selected = rows.algorithm_mode == mode;
value = rows.fault_factor_est(selected);
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

function fault_line(ax)
xline(ax,3.0,'k--','Fault onset','LabelVerticalAlignment','bottom', ...
    'HandleVisibility','off');
end

function set_all_xlimits(layout,xLimits)
axesHandles = findall(layout.Parent,'Type','axes');
set(axesHandles,'XLim',xLimits);
end

function fig = new_figure()
fig = figure('Visible','off','Color','white', ...
    'Position',[100,100,1100,800]);
end

function paths = save_pair(fig,root,stem)
pngPath = fullfile(root,stem+".png");
figPath = fullfile(root,stem+".fig");
exportgraphics(fig,pngPath,'Resolution',200);
savefig(fig,figPath);
paths = [string(pngPath),string(figPath)];
end
