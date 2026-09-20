function paths = generate_phase1c_step5_figures( ...
        figuresRoot,definition,dataF,resultsF,resultsCF,evaluated)
%GENERATE_PHASE1C_STEP5_FIGURES Create the formal Step 5 figures A-H.

if ~isfolder(figuresRoot)
    mkdir(figuresRoot);
end
colors = lines(3);
modes = definition.algorithms;
time = dataF.t;

figureA = figure('Visible','off','Color','w','Position',[100 100 1100 720]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
for parameterIndex = 1:2
    nexttile;
    truth = dataF.(sprintf('Cs%d',parameterIndex));
    plot(time,truth,'k','LineWidth',2,'DisplayName','true'); hold on;
    for k = 1:numel(modes)
        mode = modes(k);
        plot(time,resultsF.(char(mode)).cHist(:,parameterIndex), ...
            'Color',colors(k,:),'LineWidth',1.2,'DisplayName',mode);
    end
    add_event_lines(definition);
    ylabel(sprintf('Cs%d (pF)',parameterIndex));
    grid on;
    if parameterIndex == 1
        title('Case07 true and estimated coupling parameters (Fault branch)');
        legend('Location','best','NumColumns',4);
    else
        xlabel('Time (s)');
    end
end
paths.A = save_pair(figureA,figuresRoot,'Figure_A_Case07_Cs_tracking');

figureB = figure('Visible','off','Color','w','Position',[100 100 1100 760]);
tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
nexttile;
plot(time,build_fault_scale(definition,time),'k','LineWidth',1.5);
ylabel('Fault scale'); grid on; add_event_lines(definition);
title('Temporary fault and protection response');
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
paths.B = save_pair(figureB,figuresRoot,'Figure_B_M3_gate_vs_M4_g');

figureC = figure('Visible','off','Color','w','Position',[100 100 1100 720]);
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
    add_event_lines(definition);
    ylabel(sprintf('\\delta Cs%d fault (pF)',parameterIndex)); grid on;
    if parameterIndex == 1
        title('Matched fault-induced parameter deviation: c_F-c_{CF}');
        legend('Location','best');
    else
        xlabel('Time (s)');
    end
end
paths.C = save_pair(figureC,figuresRoot, ...
    'Figure_C_fault_induced_parameter_deviation');

figureD = figure('Visible','off','Color','w','Position',[100 100 1100 860]);
tiledlayout(3,1,'TileSpacing','compact','Padding','compact');
for k = 1:numel(modes)
    mode = modes(k);
    nexttile;
    plot(time,1e3*resultsF.(char(mode)).ir.B, ...
        'Color',colors(k,:),'LineWidth',0.8,'DisplayName',mode+'-F'); hold on;
    plot(time,1e3*resultsCF.(char(mode)).ir.B,'k--', ...
        'LineWidth',0.8,'DisplayName',mode+'-CF');
    xlim([1.2 2.4]); grid on; ylabel('i_{R,B} (mA)');
    add_event_lines(definition); title(mode); legend('Location','best');
end
xlabel('Time (s)');
paths.D = save_pair(figureD,figuresRoot, ...
    'Figure_D_B_phase_resistive_current_matched');

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

figureF = figure('Visible','off','Color','w','Position',[100 100 1050 560]);
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
paths.F = save_pair(figureF,figuresRoot,'Figure_F_post_fault_memory');

figureG = figure('Visible','off','Color','w','Position',[100 100 760 620]);
hold on;
for k = 1:numel(modes)
    row = evaluated.tradeoff.algorithm_mode == modes(k);
    x = evaluated.tradeoff.overlap_parameter_tracking_error_pF(row);
    y = evaluated.tradeoff.mean_abs_retention_ratio_error(row);
    if modes(k) == "M2"
        scatter(x,y,130,'o','MarkerEdgeColor',colors(k,:), ...
            'LineWidth',1.8,'DisplayName',modes(k));
        text(x,y+0.0007,"  M2",'FontWeight','bold');
    elseif modes(k) == "M3"
        scatter(x,y,130,'x','MarkerEdgeColor',colors(k,:), ...
            'LineWidth',1.8,'DisplayName',modes(k));
        text(x,y-0.0007,"  M3",'FontWeight','bold');
    else
        scatter(x,y,110,colors(k,:),'filled','DisplayName',modes(k));
        text(x,y,"  M4",'FontWeight','bold');
    end
end
xlabel('Overlap parameter tracking RMS norm (pF)');
ylabel('Mean |fault-increment retention error|');
grid on; legend('Location','best');
title('Two-objective trade-off (no composite score)');
paths.G = save_pair(figureG,figuresRoot,'Figure_G_two_objective_tradeoff');

figureH = figure('Visible','off','Color','w','Position',[100 100 1100 720]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
driftDirection = evaluated.true_drift_direction;
nexttile; hold on;
for k = 1:numel(modes)
    mode = modes(k);
    delta = resultsF.(char(mode)).cHist-resultsCF.(char(mode)).cHist;
    parallel = delta*driftDirection;
    plot(time,parallel,'Color',colors(k,:),'LineWidth',1.3, ...
        'DisplayName',mode);
end
add_event_lines(definition); ylabel('Parallel signed (pF)'); grid on;
title('Fault bias projection onto true drift direction');
legend('Location','best');
nexttile; hold on;
for k = 1:numel(modes)
    mode = modes(k);
    delta = resultsF.(char(mode)).cHist-resultsCF.(char(mode)).cHist;
    parallel = delta*driftDirection;
    perpendicular = delta-parallel*driftDirection.';
    plot(time,vecnorm(perpendicular,2,2),'Color',colors(k,:), ...
        'LineWidth',1.3,'DisplayName',mode);
end
add_event_lines(definition); ylabel('Orthogonal norm (pF)');
xlabel('Time (s)'); grid on;
paths.H = save_pair(figureH,figuresRoot, ...
    'Figure_H_fault_bias_drift_projection');
end

function scale = build_fault_scale(definition,time)
signals = build_phase1c_case07_signals(time,definition,"F");
scale = signals.fault_scale;
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
