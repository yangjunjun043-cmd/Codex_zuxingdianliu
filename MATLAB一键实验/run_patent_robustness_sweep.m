function result = run_patent_robustness_sweep()
%RUN_PATENT_ROBUSTNESS_SWEEP  Monte Carlo 噪声及确定性敏感性实验。

cfg=patent_default_config();
if ~exist(cfg.output_dir,'dir'), mkdir(cfg.output_dir); end
totalRows=numel(cfg.snr_levels_dB)*numel(cfg.monte_carlo_seeds)+6+5+5+4;
rows=cell(totalRows,1); rowNo=0;

% 1) 噪声 Monte Carlo 和相位误差：复用同一基准模型
base=simulate_moa_base(cfg);
for snr=cfg.snr_levels_dB
    for seed=cfg.monte_carlo_seeds
        c=cfg;c.SNR_dB=snr;
        rowNo=rowNo+1; rows{rowNo}=run_one(base,c,'SNR_dB',snr,seed);
    end
end
for pe=[0,0.33,0.5,1,2,3]
    c=cfg;c.phase_error_deg=pe;
    rowNo=rowNo+1; rows{rowNo}=run_one(base,c,'phase_error_deg',pe,2026);
end

% 2) 需要重新运行电源模型的工况
for h=[0.005,0.02,0.05,0.08,0.10]
    c=cfg;c.h3_ratio=h;base2=simulate_moa_base(c);
    rowNo=rowNo+1; rows{rowNo}=run_one(base2,c,'h3_ratio',h,2026);
end
for ph=[0,1,3,5,10]
    c=cfg;c.phi3_deg=ph;base2=simulate_moa_base(c);
    rowNo=rowNo+1; rows{rowNo}=run_one(base2,c,'phi3_deg',ph,2026);
end
for vn=[0,0.01,0.03,0.05]
    c=cfg;c.Vneg_pu=vn;base2=simulate_moa_base(c);
    rowNo=rowNo+1; rows{rowNo}=run_one(base2,c,'Vneg_pu',vn,2026);
end

result=vertcat(rows{1:rowNo});
snrSummary=summarize_snr(result);
outFile=fullfile(cfg.output_dir,'robustness_summary.xlsx');
if exist(outFile,'file'), delete(outFile); end
writetable(result,outFile,'Sheet','全部原始工况');
write_subset(result,outFile,'SNR_dB','SNR原始');
writetable(snrSummary,outFile,'Sheet','SNR统计');
write_subset(result,outFile,'phase_error_deg','相位误差');
write_subset(result,outFile,'h3_ratio','三次谐波幅值');
write_subset(result,outFile,'phi3_deg','三次谐波相位');
write_subset(result,outFile,'Vneg_pu','电压不平衡');
save(fullfile(cfg.output_dir,'robustness_workspace.mat'),'result','snrSummary','cfg');
make_robustness_plots(result,snrSummary,cfg.output_dir);
end

function write_subset(result,outFile,param,sheet)
q=result.parameter==param;
writetable(result(q,:),outFile,'Sheet',sheet);
end

function row=run_one(base,cfg,paramName,paramValue,seed)
self_pF=[cfg.Cself_pF,cfg.Cself_pF,cfg.Cself_pF];
data=synthesize_dynamic_case(base,cfg,'slow_drift',seed);
ref=reconstruct_refs_from_b(data.t,data.ub,cfg.f,cfg.init_start,cfg.init_end,cfg.phase_error_deg);
rls=track_coupling_cvff_rls(data,ref,cfg,self_pF,true);
ir=extract_resistive_current(data,ref,self_pF,rls.hist);
m=evaluate_case_metrics(data,ir,rls.hist,'CVFF-RLS','缓慢漂移',cfg);
metricNames=setdiff(m.Properties.VariableNames,{'scene','method'},'stable');
row=addvars(m(:,metricNames),string(paramName),paramValue,string(paramValue),seed, ...
    'Before',1,'NewVariableNames',{'parameter','value','value_label','seed'});
end

function summary=summarize_snr(result)
noise=result(result.parameter=="SNR_dB",:);
metricNames=setdiff(noise.Properties.VariableNames,{'parameter','value','value_label','seed'},'stable');
rows=cell(numel(unique(noise.value))*numel(metricNames),1); rowNo=0;
levels=unique(noise.value,'stable');
for i=1:numel(levels)
    q=noise.value==levels(i);
    for j=1:numel(metricNames)
        values=noise{q,metricNames{j}};
        outputName=string(metricNames{j});
        if contains(outputName,"Err")
            values=abs(values); outputName="abs_"+outputName;
        end
        rowNo=rowNo+1;
        label=string(levels(i));
        if isinf(levels(i)), label="Inf (无噪声)"; end
        rows{rowNo}=table(levels(i),label,outputName,numel(values),mean(values),std(values), ...
            median(values),percentile95(values), ...
            'VariableNames',{'SNR_dB','SNR_label','metric','N','mean','std','median','P95'});
    end
end
summary=vertcat(rows{1:rowNo});
end

function value=percentile95(values)
values=sort(values(:));
value=values(max(1,ceil(0.95*numel(values))));
end

function make_robustness_plots(result,snrSummary,outdir)
q=snrSummary.metric=="abs_B_FundErr_pct"; S=snrSummary(q,:);
figure('Color','w'); errorbar(1:height(S),S.mean,S.std,'-o','LineWidth',1.5); grid on;
labels=S.SNR_label;
set(gca,'XTick',1:height(S),'XTickLabel',labels);
xlabel('电流信噪比 / dB'); ylabel('|B相基波幅值误差| / %');
title('SNR Monte Carlo：均值 ± 标准差（30 seeds）');
exportgraphics(gcf,fullfile(outdir,'snr_monte_carlo.png'),'Resolution',200); close(gcf);
q=result.parameter=="phase_error_deg"; T=result(q,:);
figure('Color','w'); plot(T.value,abs(T.B_FundErr_pct),'-o','LineWidth',1.5); grid on;
xlabel('相位参考误差 / °'); ylabel('B相基波幅值误差 / %'); title('相位参考误差敏感性');
exportgraphics(gcf,fullfile(outdir,'phase_error_sensitivity.png'),'Resolution',200); close(gcf);
q=result.parameter=="h3_ratio"; T=result(q,:);
figure('Color','w'); plot(100*T.value,abs(T.B_FundErr_pct),'-o','LineWidth',1.5); grid on;
xlabel('三次谐波幅值比 / %'); ylabel('B相基波幅值误差 / %'); title('三次谐波幅值鲁棒性');
exportgraphics(gcf,fullfile(outdir,'h3_ratio_robustness.png'),'Resolution',200); close(gcf);
q=result.parameter=="Vneg_pu"; T=result(q,:);
figure('Color','w'); plot(100*T.value,abs(T.B_FundErr_pct),'-o','LineWidth',1.5); grid on;
xlabel('负序电压比例 / %'); ylabel('B相基波幅值误差 / %'); title('电压不平衡敏感性');
exportgraphics(gcf,fullfile(outdir,'voltage_unbalance_sensitivity.png'),'Resolution',200); close(gcf);
end
