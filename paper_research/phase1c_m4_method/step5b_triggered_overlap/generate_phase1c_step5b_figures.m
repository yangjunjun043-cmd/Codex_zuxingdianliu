function paths = generate_phase1c_step5b_figures( ...
        figuresRoot,definition,dataF,resultsF,resultsCF,evaluated)
%GENERATE_PHASE1C_STEP5B_FIGURES Create formal Step 5B figures A-H.

if ~isfolder(figuresRoot)
    mkdir(figuresRoot);
end
colors = lines(3);
modes = definition.algorithms;
time = dataF.t;
gateStart = evaluated.gate_interval.gate_onset_s;
gateEnd = evaluated.gate_interval.gate_end_s;

figureA = figure('Visible','off','Color','w','Position',[100 100 1100 720]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
for parameterIndex = 1:2
    nexttile; hold on;
    plot(time,dataF.(sprintf('Cs%d',parameterIndex)),'k', ...
        'LineWidth',2,'DisplayName','true');
    for k = 1:numel(modes)
        mode = modes(k);
        plot(time,resultsF.(char(mode)).cHist(:,parameterIndex), ...
            'Color',colors(k,:),'LineWidth',1.2,'DisplayName',mode);
    end
    add_event_lines(definition);
    ylabel(sprintf('Cs%d (pF)',parameterIndex)); grid on;
    if parameterIndex == 1
        title('Case08 true and estimated coupling parameters');
        legend('Location','best','NumColumns',4);
    else
        xlabel('Time (s)');
    end
end
paths.A = save_pair(figureA,figuresRoot,'Figure_A_Case08_Cs_tracking');

figureB = figure('Visible','off','Color','w','Position',[100 100 1100 760]);
tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
nexttile;
signals = build_phase1c_case08_signals(time,definition,"F");
plot(time,signals.fault_scale,'k','LineWidth',1.5);
ylabel('Fault scale'); grid on; add_event_lines(definition);
title('Fault schedule, M3 hard gate, and M4 continuous weight');
nexttile;
stairs(resultsF.M3.tracker.cycle.time_s, ...
    resultsF.M3.tracker.cycle.gate,'Color',colors(2,:),'LineWidth',1.5);
ylabel('M3 gate'); ylim([-0.05 1.05]); grid on; add_event_lines(definition);
nexttile;
plot(resultsF.M4.tracker.cycle.time_s, ...
    resultsF.M4.tracker.cycle.update_weight, ...
    'Color',colors(3,:),'LineWidth',1.5);
ylabel('M4 g'); xlabel('Time (s)'); ylim([0 1.05]);
grid on; add_event_lines(definition);
paths.B = save_pair(figureB,figuresRoot,'Figure_B_M3_gate_M4_g_fault');

figureC = figure('Visible','off','Color','w','Position',[100 100 1100 720]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
for parameterIndex = 1:2
    nexttile; hold on;
    plot(time,dataF.(sprintf('Cs%d',parameterIndex)),'k', ...
        'LineWidth',2,'DisplayName','true');
    plot(time,resultsF.M3.cHist(:,parameterIndex), ...
        'Color',colors(2,:),'LineWidth',1.5,'DisplayName','M3-F');
    plot(time,resultsF.M4.cHist(:,parameterIndex), ...
        'Color',colors(3,:),'LineWidth',1.5,'DisplayName','M4-F');
    xline(gateStart,'k--','Gate on','HandleVisibility','off');
    xline(gateEnd,'k-.','Gate off','HandleVisibility','off');
    xlim([gateStart-0.04 gateEnd+0.04]); grid on;
    ylabel(sprintf('Cs%d (pF)',parameterIndex));
    if parameterIndex == 1
        title('Zoom: identical M3 gate-active interval');
        legend('Location','best');
    else
        xlabel('Time (s)');
    end
end
paths.C = save_pair(figureC,figuresRoot,'Figure_C_gate_interval_zoom');

figureD = figure('Visible','off','Color','w','Position',[100 100 1100 720]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
for parameterIndex = 1:2
    nexttile; hold on;
    for k = 1:numel(modes)
        mode = modes(k);
        delta = resultsF.(char(mode)).cHist(:,parameterIndex)- ...
            resultsCF.(char(mode)).cHist(:,parameterIndex);
        plot(time,delta,'Color',colors(k,:),'LineWidth',1.3, ...
            'DisplayName',mode);
    end
    yline(0,'k:','HandleVisibility','off');
    add_event_lines(definition); grid on;
    ylabel(sprintf('Fault-induced Cs%d (pF)',parameterIndex));
    if parameterIndex == 1
        title('Matched fault-induced parameter deviation: c_F-c_{CF}');
        legend('Location','best');
    else
        xlabel('Time (s)');
    end
end
paths.D = save_pair(figureD,figuresRoot, ...
    'Figure_D_fault_induced_parameter_deviation');

figureE = figure('Visible','off','Color','w','Position',[100 100 920 560]);
retentionWide = nan(numel(modes),2);
for k = 1:numel(modes)
    for w = 1:2
        row = evaluated.retention.algorithm_mode == modes(k) & ...
            evaluated.retention.window == "W"+string(w);
        retentionWide(k,w) = ...
            evaluated.retention.fault_increment_retention_ratio(row);
    end
end
bar(categorical(modes),retentionWide);
yline(1,'k--','Ideal','LineWidth',1.2);
ylabel('Fault increment retention ratio'); grid on;
legend({'W1','W2'},'Location','best');
title('Matched fault-increment preservation');
paths.E = save_pair(figureE,figuresRoot,'Figure_E_fault_increment_retention');

figureF = figure('Visible','off','Color','w','Position',[100 100 960 600]);
movement = [evaluated.gate_interval_adaptation.CF_drift_movement_norm_pF, ...
    evaluated.gate_interval_adaptation.fault_induced_movement_norm_pF];
bar(categorical(evaluated.gate_interval_adaptation.algorithm_mode),movement);
ylabel('Parameter movement norm (pF)'); grid on;
legend({'CF drift-associated','F-CF fault-induced'},'Location','best');
title('Gate-interval drift-associated versus fault-induced movement');
paths.F = save_pair(figureF,figuresRoot, ...
    'Figure_F_drift_vs_fault_movement');

figureG = figure('Visible','off','Color','w','Position',[100 100 1050 560]);
hold on;
for k = 1:numel(modes)
    mode = modes(k);
    distance = vecnorm(resultsF.(char(mode)).cHist- ...
        resultsCF.(char(mode)).cHist,2,2);
    plot(time,distance,'Color',colors(k,:),'LineWidth',1.4, ...
        'DisplayName',mode);
end
add_event_lines(definition);
xlim([1.4 2.8]); xlabel('Time (s)'); ylabel('||c_F-c_{CF}||_2 (pF)');
grid on; legend('Location','best'); title('Post-fault parameter memory');
paths.G = save_pair(figureG,figuresRoot,'Figure_G_post_fault_memory');

figureH = figure('Visible','off','Color','w','Position',[100 100 1120 760]);
comparison = evaluated.cross_case;
caseLabels = categorical(["Case07 f=1.30";"Case08 f=1.60"], ...
    ["Case07 f=1.30";"Case08 f=1.60"]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
nexttile;
bar(caseLabels,comparison.M3_overlap_active_ratio); ylim([0 1.05]);
ylabel('M3 active ratio'); grid on; title('Hard-gate engagement');
nexttile;
bar(caseLabels,comparison.M4_overlap_mean_g); ylim([0 1.05]);
ylabel('Mean g'); grid on; title('M4 update weight');
nexttile;
bar(caseLabels,100*comparison.M4_fault_bias_reduction_vs_M2);
ylabel('Reduction vs M2 (%)'); grid on; title('M4 fault-bias reduction');
nexttile;
bar(caseLabels,[comparison.M2_mean_retention, ...
    comparison.M3_mean_retention,comparison.M4_mean_retention]);
yline(1,'k--','Ideal'); ylabel('Mean retention'); grid on;
legend({'M2','M3','M4'},'Location','best');
title('Case07 versus Case08');
paths.H = save_pair(figureH,figuresRoot,'Figure_H_Case07_vs_Case08');
end

function add_event_lines(definition)
xline(definition.fault.onset_s,'k--','Fault onset', ...
    'HandleVisibility','off');
xline(definition.fault.clear_s,'k-.','Fault clear', ...
    'HandleVisibility','off');
xline(definition.drift.end_s,'k:','Drift end', ...
    'HandleVisibility','off');
end

function path = save_pair(figureHandle,root,name)
pngPath = fullfile(root,[name '.png']);
figPath = fullfile(root,[name '.fig']);
exportgraphics(figureHandle,pngPath,'Resolution',180);
savefig(figureHandle,figPath);
close(figureHandle);
path = struct('png',string(pngPath),'fig',string(figPath));
end
