function summary = run_patent_dynamic_experiments()
%RUN_PATENT_DYNAMIC_EXPERIMENTS  完成基准、慢漂移、阶跃、随机变化及故障门控实验。

cfg=patent_default_config();
if ~exist(cfg.output_dir,'dir'), mkdir(cfg.output_dir); end
base=simulate_moa_base(cfg);
self_pF=[cfg.Cself_pF,cfg.Cself_pF,cfg.Cself_pF];
scenes={'static','slow_drift','smooth_step','random_drift','fault_with_drift'};
sceneCN={'固定耦合基准','缓慢漂移','平滑阶跃','随机波动','阻性故障与漂移'};
summaryRows=cell(numel(scenes)*3,1); rowNo=0;
faultRows=cell(3,1); faultNo=0;

for k=1:numel(scenes)
    data=synthesize_dynamic_case(base,cfg,scenes{k},100+k);
    ref=reconstruct_refs_from_b(data.t,data.ub,cfg.f,cfg.init_start,cfg.init_end,cfg.phase_error_deg);
    c0=initial_coupling_estimate(data,ref,cfg,self_pF);
    fixedHist=repmat(c0(:).',numel(data.t),1);
    nlms=track_coupling_block_nlms(data,ref,cfg,self_pF);
    rls=track_coupling_cvff_rls(data,ref,cfg,self_pF,true);
    methods={'固定补偿',fixedHist;'NLMS',nlms.hist;'CVFF-RLS',rls.hist};

    for m=1:size(methods,1)
        ir=extract_resistive_current(data,ref,self_pF,methods{m,2});
        rowNo=rowNo+1;
        summaryRows{rowNo}=evaluate_case_metrics(data,ir,methods{m,2},methods{m,1},sceneCN{k},cfg);
        if strcmp(scenes{k},'fault_with_drift')
            faultNo=faultNo+1;
            faultRows{faultNo}=fault_factor_row(data,ir,methods{m,1},cfg.f);
        end
    end

    fs=1/median(diff(data.t)); Nc=round(fs/cfg.f); ids=1:Nc:numel(data.t);
    trace=table(data.t(ids),data.Cs1(ids),data.Cs2(ids),fixedHist(ids,1),fixedHist(ids,2), ...
        nlms.hist(ids,1),nlms.hist(ids,2),rls.hist(ids,1),rls.hist(ids,2), ...
        'VariableNames',{'time_s','Cs1_true_pF','Cs2_true_pF','Cs1_fixed_pF','Cs2_fixed_pF', ...
        'Cs1_NLMS_pF','Cs2_NLMS_pF','Cs1_CVFF_RLS_pF','Cs2_CVFF_RLS_pF'});
    writetable(trace,fullfile(cfg.output_dir,[scenes{k},'_trace.csv']));
    writetable(rls.cycle,fullfile(cfg.output_dir,[scenes{k},'_rls_cycle.csv']));
end

summary=vertcat(summaryRows{1:rowNo});
faultSummary=vertcat(faultRows{1:faultNo});
outFile=fullfile(cfg.output_dir,'dynamic_summary.xlsx');
if exist(outFile,'file'), delete(outFile); end
writetable(summary,outFile,'Sheet','动态场景汇总');
writetable(faultSummary,outFile,'Sheet','故障门控汇总');
save(fullfile(cfg.output_dir,'dynamic_experiment_workspace.mat'),'summary','faultSummary','cfg');
make_dynamic_plots(cfg.output_dir,summary,faultSummary);
end

function row=fault_factor_row(data,ir,methodName,f)
pre=data.t>=2.60 & data.t<2.90;
post=data.t>=3.40 & data.t<3.80;
truePre=fund_rms(data.t(pre),data.irB(pre),f);
truePost=fund_rms(data.t(post),data.irB(post),f);
estPre=fund_rms(data.t(pre),ir.B(pre),f);
estPost=fund_rms(data.t(post),ir.B(post),f);
trueFactor=truePost/(truePre+eps);
estFactor=estPost/(estPre+eps);
keepErr=(estFactor-trueFactor)/(trueFactor+eps)*100;
row=table(string(methodName),trueFactor,estFactor,keepErr,truePre,truePost,estPre,estPost, ...
    'VariableNames',{'method','true_fault_factor','estimated_fault_factor','factor_retention_error_pct', ...
    'true_pre_rms_A','true_post_rms_A','estimated_pre_rms_A','estimated_post_rms_A'});
end

function r=fund_rms(t,x,f)
w=2*pi*f; H=[sin(w*t),cos(w*t),ones(size(t))]; b=H\x;
r=hypot(b(1),b(2))/sqrt(2);
end

function make_dynamic_plots(outdir,summary,faultSummary)
T=readtable(fullfile(outdir,'slow_drift_trace.csv'));
figure('Color','w'); plot(T.time_s,T.Cs1_true_pF,'LineWidth',1.8); hold on;
plot(T.time_s,T.Cs1_fixed_pF,'--'); plot(T.time_s,T.Cs1_NLMS_pF,'-.'); plot(T.time_s,T.Cs1_CVFF_RLS_pF,':','LineWidth',1.5);
grid on; xlabel('时间 / s'); ylabel('Cs1 / pF'); title('缓慢漂移工况下Cs1动态跟踪');
legend('真实','固定补偿','NLMS','CVFF-RLS','Location','best');
exportgraphics(gcf,fullfile(outdir,'slow_drift_Cs1.png'),'Resolution',200); close(gcf);

T=readtable(fullfile(outdir,'fault_with_drift_trace.csv'));
figure('Color','w'); plot(T.time_s,T.Cs1_true_pF,'LineWidth',1.8); hold on;
plot(T.time_s,T.Cs1_NLMS_pF,'--'); plot(T.time_s,T.Cs1_CVFF_RLS_pF,':','LineWidth',1.5); xline(3.0,'--');
grid on; xlabel('时间 / s'); ylabel('Cs1 / pF'); title('阻性故障发生时的更新门控');
legend('真实','NLMS','带门控CVFF-RLS','故障时刻','Location','best');
exportgraphics(gcf,fullfile(outdir,'fault_gate_Cs1.png'),'Resolution',200); close(gcf);

sel=summary.scene~="固定耦合基准" & summary.scene~="阻性故障与漂移";
P=summary(sel,:);
sc=unique(P.scene,'stable'); methods=unique(P.method,'stable'); Y=nan(numel(sc),numel(methods));
for i=1:numel(sc)
    for j=1:numel(methods)
        q=P.scene==sc(i) & P.method==methods(j); Y(i,j)=abs(P.B_FundErr_pct(q));
    end
end
figure('Color','w'); bar(Y); grid on; ylabel('B相基波幅值误差 / %'); title('动态耦合工况的阻性电流提取误差');
set(gca,'XTickLabel',cellstr(sc)); legend(cellstr(methods),'Location','best');
exportgraphics(gcf,fullfile(outdir,'dynamic_B_error.png'),'Resolution',200); close(gcf);

figure('Color','w'); bar(categorical(cellstr(faultSummary.method)),[faultSummary.true_fault_factor,faultSummary.estimated_fault_factor]);
grid on; ylabel('故障前后基波有效值增幅倍数'); title('故障门控对真实阻性变化的保持能力');
legend('真实增幅','估计增幅','Location','best');
exportgraphics(gcf,fullfile(outdir,'fault_factor_retention.png'),'Resolution',200); close(gcf);
end
