function result = run_patent_robustness_sweep()
%RUN_PATENT_ROBUSTNESS_SWEEP  噪声、相位、三次谐波及负序不平衡敏感性实验。

cfg=patent_default_config();
if ~exist(cfg.output_dir,'dir'), mkdir(cfg.output_dir); end
rows=cell(25,1); rowNo=0;

% 1) 噪声和相位误差：复用同一基准模型
base=simulate_moa_base(cfg);
for snr=[Inf,40,30,20]
    c=cfg;c.SNR_dB=snr;
    rowNo=rowNo+1; rows{rowNo}=run_one(base,c,'SNR_dB',snr);
end
for pe=[0,0.33,0.5,1,2,3]
    c=cfg;c.phase_error_deg=pe;
    rowNo=rowNo+1; rows{rowNo}=run_one(base,c,'phase_error_deg',pe);
end

% 2) 需要重新运行电源模型的工况
for h=[0.005,0.02,0.05,0.08,0.10]
    c=cfg;c.h3_ratio=h;base2=simulate_moa_base(c);
    rowNo=rowNo+1; rows{rowNo}=run_one(base2,c,'h3_ratio',h);
end
for ph=[0,1,3,5,10]
    c=cfg;c.phi3_deg=ph;base2=simulate_moa_base(c);
    rowNo=rowNo+1; rows{rowNo}=run_one(base2,c,'phi3_deg',ph);
end
for vn=[0,0.01,0.03,0.05]
    c=cfg;c.Vneg_pu=vn;base2=simulate_moa_base(c);
    rowNo=rowNo+1; rows{rowNo}=run_one(base2,c,'Vneg_pu',vn);
end

result=vertcat(rows{1:rowNo});
outFile=fullfile(cfg.output_dir,'robustness_summary.xlsx');
if exist(outFile,'file'), delete(outFile); end
writetable(result,outFile,'Sheet','全部工况');
write_subset(result,outFile,'SNR_dB','噪声');
write_subset(result,outFile,'phase_error_deg','相位误差');
write_subset(result,outFile,'h3_ratio','三次谐波幅值');
write_subset(result,outFile,'phi3_deg','三次谐波相位');
write_subset(result,outFile,'Vneg_pu','电压不平衡');
save(fullfile(cfg.output_dir,'robustness_workspace.mat'),'result','cfg');
make_robustness_plots(result,cfg.output_dir);
end

function write_subset(result,outFile,param,sheet)
q=result.parameter==param;
writetable(result(q,:),outFile,'Sheet',sheet);
end

function row=run_one(base,cfg,paramName,paramValue)
self_pF=[cfg.Cself_pF,cfg.Cself_pF,cfg.Cself_pF];
data=synthesize_dynamic_case(base,cfg,'slow_drift',2026);
ref=reconstruct_refs_from_b(data.t,data.ub,cfg.f,cfg.init_start,cfg.init_end,cfg.phase_error_deg);
rls=track_coupling_cvff_rls(data,ref,cfg,self_pF,true);
ir=extract_resistive_current(data,ref,self_pF,rls.hist);
m=evaluate_case_metrics(data,ir,rls.hist,'CVFF-RLS','缓慢漂移',cfg);
row=table(string(paramName),paramValue,m.Cs1_MAE_pF,m.Cs2_MAE_pF,m.A_FundErr_pct,m.B_FundErr_pct,m.C_FundErr_pct, ...
    'VariableNames',{'parameter','value','Cs1_MAE_pF','Cs2_MAE_pF','A_FundErr_pct','B_FundErr_pct','C_FundErr_pct'});
end

function make_robustness_plots(result,outdir)
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
