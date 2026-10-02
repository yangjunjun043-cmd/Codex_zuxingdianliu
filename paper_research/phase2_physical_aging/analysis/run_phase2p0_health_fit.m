function result = run_phase2p0_health_fit()
%RUN_PHASE2P0_HEALTH_FIT Read-only Phase 2-P0 healthy-model qualification.
%
% This diagnostic performs one healthy, zero-noise AutoComp9 simulation.
% It does not execute any Phase 1/Phase 2 matrix runner, does not run
% Case05-P or Case06-P, and does not save or modify the Simulink model.

scriptDir = fileparts(mfilename('fullpath'));
phaseDir = fileparts(scriptDir);
projectRoot = fileparts(fileparts(phaseDir));
matlabRoot = fullfile(projectRoot,'MATLAB一键实验');
outputDir = fullfile(phaseDir,'analysis_outputs');
if ~isfolder(outputDir)
    mkdir(outputDir);
end

addpath(matlabRoot);
cleanupPath = onCleanup(@() rmpath(matlabRoot));

cfg = patent_default_config();
cfg.model = 'AI6109_MOA_AutoComp9';
modelPath = fullfile(matlabRoot,[cfg.model '.slx']);
frozen = phase1a_baseline_metadata();
modelSha256 = file_sha256(modelPath);
assert(modelSha256 == frozen.baseline_model_sha256, ...
    'Phase2P0:FrozenModelMismatch', ...
    'AutoComp9 SHA-256 differs from the frozen Phase1A model.');

modelAudit = inspect_model_read_only(cfg.model,modelPath,modelSha256);

diagnosticStopS = 1.20;
tInput = (0:cfg.Ts:diagnosticStopS).';
constantCsPF = 10*ones(size(tInput));
unitFaultScale = ones(size(tInput));
zeroNoise = zeros(size(tInput));

in = Simulink.SimulationInput(cfg.model);
variables = struct( ...
    'StopTime',diagnosticStopS, ...
    'h3_ratio',cfg.h3_ratio, ...
    'phi3_deg',cfg.phi3_deg, ...
    'Vneg_pu',cfg.Vneg_pu, ...
    'f',cfg.f, ...
    'Un_LL',cfg.Un_LL, ...
    'C0',cfg.C0, ...
    'C_moa',cfg.C_moa, ...
    'C1',cfg.C1, ...
    'C2',cfg.C2, ...
    'Vref_moa',cfg.moa_Vref_V, ...
    'Iref_moa',cfg.moa_Iref_A, ...
    'alpha_moa',cfg.moa_alpha, ...
    'Ts',cfg.Ts, ...
    'Ts_model',cfg.Ts, ...
    'Cself_pF',cfg.Cself_pF, ...
    'Ccoupling_disabled_F',1e-18);
names = fieldnames(variables);
for k = 1:numel(names)
    in = in.setVariable(names{k},variables.(names{k}));
end

dataset = Simulink.SimulationData.Dataset;
dataset{1} = timeseries(constantCsPF,tInput);
dataset{2} = timeseries(constantCsPF,tInput);
dataset{3} = timeseries(unitFaultScale,tInput);
dataset{4} = timeseries(zeroNoise,tInput);
dataset{5} = timeseries(zeroNoise,tInput);
dataset{6} = timeseries(zeroNoise,tInput);
in = in.setExternalInput(dataset);
in = in.setModelParameter('StopTime',num2str(diagnosticStopS));

out = sim(in);
[t,uB] = read_signal(out,'uB');
[~,irB] = read_signal(out,'iB_R_true');
[~,irBRaw] = read_signal(out,'iB_R_raw');

analysisStartS = 0.80;
analysisEndS = 1.20;
steady = t >= analysisStartS & t < analysisEndS;
tSteady = t(steady);
uSteady = uB(steady);
iSteady = irB(steady);
assert(numel(tSteady) >= 2 && isuniform(tSteady), ...
    'Phase2P0:NonuniformSampling', ...
    'The selected healthy steady-state window is not uniformly sampled.');

uThresholdFraction = 0.01;
iThresholdFraction = 0.01;
uPeak = max(abs(uSteady));
iPeak = max(abs(iSteady));
fitMask = abs(uSteady) >= uThresholdFraction*uPeak & ...
    abs(iSteady) >= iThresholdFraction*iPeak & ...
    sign(uSteady) == sign(iSteady);
assert(nnz(fitMask) > 100, ...
    'Phase2P0:InsufficientFitSamples', ...
    'Too few healthy steady-state samples remain after zero exclusion.');

logVoltage = log(abs(uSteady(fitMask)));
logCurrent = log(abs(iSteady(fitMask)));
coefficient = [ones(nnz(fitMask),1),logVoltage]\logCurrent;
K0 = exp(coefficient(1));
alpha0 = coefficient(2);
irFit = sign(uSteady).*K0.*abs(uSteady).^alpha0;

residual = iSteady-irFit;
sse = sum(residual.^2);
sst = sum((iSteady-mean(iSteady)).^2);
rSquared = 1-sse/sst;
rmseA = sqrt(mean(residual.^2));
nrmseRmsPct = 100*rmseA/rms(iSteady);
maxAbsErrorA = max(abs(residual));
maxErrorPeakPct = 100*maxAbsErrorA/iPeak;
signAgreementPct = 100*mean(sign(uSteady) == sign(iSteady));
fittedUrefV = (cfg.moa_Iref_A/K0)^(1/alpha0);
theoreticalK = cfg.moa_Iref_A/cfg.moa_Vref_V^cfg.moa_alpha;

sampleFrequencyHz = 1/median(diff(tSteady));
harmonicOrders = (1:25).';
harmonics = harmonic_table(uSteady,iSteady,irFit, ...
    sampleFrequencyHz,cfg.f,harmonicOrders);
key = ismember(harmonics.harmonic_order,[1;3;5]);
keyHarmonics = harmonics(key,:);
keyRelativeErrorPct = 100*abs( ...
    keyHarmonics.ir_fit_rms_A-keyHarmonics.ir_original_rms_A) ./ ...
    max(keyHarmonics.ir_original_rms_A,realmin);
maxKeyHarmonicErrorPct = max(keyRelativeErrorPct);

healthFitPass = rSquared >= 0.999 && ...
    nrmseRmsPct <= 0.1 && ...
    maxErrorPeakPct <= 0.1 && ...
    maxKeyHarmonicErrorPct <= 0.1;

metrics = table( ...
    string(modelSha256),analysisStartS,analysisEndS,numel(tSteady), ...
    nnz(fitMask),100*nnz(fitMask)/numel(tSteady), ...
    uThresholdFraction,iThresholdFraction,K0,alpha0,fittedUrefV, ...
    rSquared,rmseA,nrmseRmsPct,maxAbsErrorA,maxErrorPeakPct, ...
    signAgreementPct,sampleFrequencyHz,rms(uSteady),uPeak, ...
    rms(iSteady),iPeak,rms(uSteady)/cfg.Uph,uPeak/cfg.Uph, ...
    rms(iSteady)/cfg.moa_Iref_A,iPeak/cfg.moa_Iref_A, ...
    theoreticalK,100*(K0-theoreticalK)/theoreticalK, ...
    maxKeyHarmonicErrorPct,healthFitPass, ...
    'VariableNames',{ ...
    'model_sha256','analysis_start_s','analysis_end_s', ...
    'steady_sample_count','fit_sample_count','fit_sample_fraction_pct', ...
    'u_exclusion_fraction_of_peak','i_exclusion_fraction_of_peak', ...
    'K0_A_per_V_pow_alpha','alpha0','fitted_Uref0_V', ...
    'R_squared','RMSE_A','NRMSE_rms_pct','max_abs_error_A', ...
    'max_error_pct_of_peak','sign_agreement_pct','sample_frequency_Hz', ...
    'uB_total_rms_V','uB_peak_V','irB_total_rms_A','irB_peak_A', ...
    'uB_total_rms_pu_Uph','uB_peak_pu_Uph', ...
    'irB_total_rms_pu_Iref','irB_peak_pu_Iref', ...
    'K0_from_cfg_A_per_V_pow_alpha','K0_relative_error_pct', ...
    'max_I1_I3_I5_relative_error_pct','health_power_law_fit_pass'});

oneCycle = tSteady >= 1.00 & tSteady < 1.00+1/cfg.f;
waveform = table(tSteady(oneCycle),uSteady(oneCycle), ...
    iSteady(oneCycle),irFit(oneCycle), ...
    iSteady(oneCycle)-irFit(oneCycle), ...
    'VariableNames',{'time_s','uB_V','irB_original_A','irB_fit_A', ...
    'fit_residual_A'});

writetable(metrics,fullfile(outputDir,'health_power_law_metrics.csv'));
writetable(harmonics,fullfile(outputDir,'health_harmonics.csv'));
writetable(waveform,fullfile(outputDir,'health_waveform_one_cycle.csv'));
write_model_audit(fullfile(outputDir,'model_generation_audit.txt'), ...
    modelAudit,cfg,irBRaw,irB,unitFaultScale);

figureHandle = create_qualification_figure(waveform,harmonics, ...
    logVoltage,logCurrent,coefficient,cfg.f);
exportgraphics(figureHandle, ...
    fullfile(outputDir,'health_power_law_qualification.png'), ...
    'Resolution',220);
savefig(figureHandle, ...
    fullfile(outputDir,'health_power_law_qualification.fig'));
close(figureHandle);

save(fullfile(outputDir,'health_power_law_qualification.mat'), ...
    'metrics','harmonics','waveform','modelAudit','cfg', ...
    'keyHarmonics','keyRelativeErrorPct','healthFitPass');

result = struct('metrics',metrics,'harmonics',harmonics, ...
    'keyHarmonics',keyHarmonics,'keyRelativeErrorPct', ...
    keyRelativeErrorPct,'modelAudit',modelAudit, ...
    'healthFitPass',healthFitPass,'outputDir',string(outputDir));

disp(metrics);
disp(keyHarmonics);
fprintf('HEALTH_POWER_LAW_FIT=%s\n',pass_label(healthFitPass));
fprintf('OUTPUT_DIR=%s\n',outputDir);
clear cleanupPath;
end

function audit = inspect_model_read_only(modelName,modelPath,modelSha256)
load_system(modelPath);
cleanupModel = onCleanup(@() close_system(modelName,0));

rootObject = sfroot;
charts = rootObject.find('-isa','Stateflow.EMChart');
charts = charts(arrayfun(@(x) startsWith(x.Path,[modelName '/']),charts));
chartPaths = strings(numel(charts),1);
chartScripts = strings(numel(charts),1);
for k = 1:numel(charts)
    chartPaths(k) = string(charts(k).Path);
    chartScripts(k) = string(charts(k).Script);
end

voltageSource = [modelName '/Three-Phase Programmable Voltage Source'];
maskNames = string(get_param(voltageSource,'MaskNames')).';
maskValues = string(get_param(voltageSource,'MaskValues')).';

audit = struct( ...
    'model_name',string(modelName), ...
    'model_path',string(modelPath), ...
    'model_sha256',string(modelSha256), ...
    'chart_paths',chartPaths, ...
    'chart_scripts',chartScripts, ...
    'voltage_source_mask_names',maskNames, ...
    'voltage_source_mask_values',maskValues, ...
    'uB_source',workspace_sink_source(modelName,'uB'), ...
    'irB_true_source',workspace_sink_source(modelName,'iB_R_true'), ...
    'irB_raw_source',workspace_sink_source(modelName,'iB_R_raw'));

clear cleanupModel;
end

function description = workspace_sink_source(modelName,variableName)
block = find_system(modelName,'SearchDepth',1,'BlockType','ToWorkspace', ...
    'VariableName',variableName);
assert(isscalar(block),'Phase2P0:WorkspaceSink', ...
    'Unable to locate unique To Workspace sink for %s.',variableName);
lineHandles = get_param(block{1},'LineHandles');
sourceBlock = get_param(lineHandles.Inport,'SrcBlockHandle');
sourcePort = get_param(lineHandles.Inport,'SrcPortHandle');
description = string(sprintf('%s port %d',getfullname(sourceBlock), ...
    get_param(sourcePort,'PortNumber')));
end

function harmonics = harmonic_table(u,iOriginal,iFit,fs,f0,orders)
n = numel(u);
assert(numel(iOriginal) == n && numel(iFit) == n, ...
    'Phase2P0:HarmonicLength','Harmonic input lengths differ.');
u = u-mean(u);
iOriginal = iOriginal-mean(iOriginal);
iFit = iFit-mean(iFit);
U = fft(u);
IOriginal = fft(iOriginal);
IFit = fft(iFit);
frequencyResolution = fs/n;

uRms = zeros(size(orders));
iOriginalRms = zeros(size(orders));
iFitRms = zeros(size(orders));
binFrequency = zeros(size(orders));
for k = 1:numel(orders)
    targetFrequency = orders(k)*f0;
    bin = round(targetFrequency/frequencyResolution)+1;
    binFrequency(k) = (bin-1)*frequencyResolution;
    uRms(k) = 2*abs(U(bin))/n/sqrt(2);
    iOriginalRms(k) = 2*abs(IOriginal(bin))/n/sqrt(2);
    iFitRms(k) = 2*abs(IFit(bin))/n/sqrt(2);
end
relativeErrorPct = 100*abs(iFitRms-iOriginalRms) ./ ...
    max(iOriginalRms,realmin);
harmonics = table(orders,binFrequency,uRms,iOriginalRms,iFitRms, ...
    relativeErrorPct, ...
    'VariableNames',{'harmonic_order','frequency_Hz','uB_rms_V', ...
    'ir_original_rms_A','ir_fit_rms_A','ir_relative_error_pct'});
end

function figureHandle = create_qualification_figure( ...
        waveform,harmonics,logVoltage,logCurrent,coefficient,f0)
figureHandle = figure('Color','w','Position',[100 100 1180 820]);
layout = tiledlayout(2,2,'Padding','compact','TileSpacing','compact');

nexttile(layout,[1 2]);
plot(waveform.time_s,1e3*waveform.irB_original_A, ...
    'k','LineWidth',1.5);
hold on;
plot(waveform.time_s,1e3*waveform.irB_fit_A, ...
    '--','Color',[0.85 0.2 0.1],'LineWidth',1.2);
xlabel('Time (s)');
ylabel('B-phase resistive current (mA)');
legend({'AutoComp9 healthy ir_B','Fitted power law'}, ...
    'Location','best');
title('Healthy steady-state waveform comparison');
grid on;

nexttile(layout);
sample = 1:max(1,floor(numel(logVoltage)/3000)):numel(logVoltage);
scatter(logVoltage(sample),logCurrent(sample),8,[0.2 0.45 0.8], ...
    'filled','MarkerFaceAlpha',0.30);
hold on;
xLine = linspace(min(logVoltage),max(logVoltage),200).';
plot(xLine,coefficient(1)+coefficient(2)*xLine, ...
    'Color',[0.85 0.2 0.1],'LineWidth',1.5);
xlabel('log |u_B|');
ylabel('log |i_{rB}|');
title('Log-domain healthy V-I fit');
grid on;

nexttile(layout);
show = harmonics.harmonic_order <= 15 & ...
    mod(harmonics.harmonic_order,2) == 1;
orders = harmonics.harmonic_order(show);
values = 1e3*[harmonics.ir_original_rms_A(show), ...
    harmonics.ir_fit_rms_A(show)];
bar(orders,values,'grouped');
xlabel(sprintf('Harmonic order (f_1 = %.0f Hz)',f0));
ylabel('RMS current (mA)');
legend({'AutoComp9','Power-law fit'},'Location','best');
title('Resistive-current harmonic comparison');
grid on;
end

function write_model_audit(path,audit,cfg,irBRaw,irB,faultScale)
fileId = fopen(path,'wt','n','UTF-8');
assert(fileId >= 0,'Phase2P0:AuditWrite','Unable to write %s.',path);
cleanupFile = onCleanup(@() fclose(fileId));
fprintf(fileId,'MODEL=%s\n',audit.model_name);
fprintf(fileId,'MODEL_PATH=%s\n',audit.model_path);
fprintf(fileId,'MODEL_SHA256=%s\n',audit.model_sha256);
fprintf(fileId,'uB_SOURCE=%s\n',audit.uB_source);
fprintf(fileId,'irB_TRUE_SOURCE=%s\n',audit.irB_true_source);
fprintf(fileId,'irB_RAW_SOURCE=%s\n',audit.irB_raw_source);
fprintf(fileId,'CFG_Un_LL_V=%.17g\n',cfg.Un_LL);
fprintf(fileId,'CFG_Uph_V=%.17g\n',cfg.Uph);
fprintf(fileId,'CFG_h3_ratio=%.17g\n',cfg.h3_ratio);
fprintf(fileId,'CFG_phi3_deg=%.17g\n',cfg.phi3_deg);
fprintf(fileId,'CFG_Vneg_pu=%.17g\n',cfg.Vneg_pu);
fprintf(fileId,'CFG_Vref_moa_V=%.17g\n',cfg.moa_Vref_V);
fprintf(fileId,'CFG_Iref_moa_A=%.17g\n',cfg.moa_Iref_A);
fprintf(fileId,'CFG_alpha_moa=%.17g\n',cfg.moa_alpha);
fprintf(fileId,'MAX_ABS_irB_TRUE_PLUS_irB_RAW_A=%.17g\n', ...
    max(abs(irB+irBRaw)));
fprintf(fileId,'FAULT_SCALE_MIN=%.17g\n',min(faultScale));
fprintf(fileId,'FAULT_SCALE_MAX=%.17g\n',max(faultScale));
fprintf(fileId,'\nVOLTAGE_SOURCE_MASK\n');
for k = 1:numel(audit.voltage_source_mask_names)
    fprintf(fileId,'%s=%s\n',audit.voltage_source_mask_names(k), ...
        audit.voltage_source_mask_values(k));
end
fprintf(fileId,'\nSTATEFLOW_CHARTS\n');
for k = 1:numel(audit.chart_paths)
    fprintf(fileId,'===%s===\n%s\n',audit.chart_paths(k), ...
        audit.chart_scripts(k));
end
clear cleanupFile;
end

function [t,x] = read_signal(out,name)
signal = out.get(name);
if isa(signal,'timeseries')
    t = signal.Time;
    x = signal.Data;
else
    t = signal.time;
    x = signal.signals.values;
end
t = t(:);
x = squeeze(x);
x = x(:);
end

function hash = file_sha256(path)
fileId = fopen(path,'rb');
assert(fileId >= 0,'Phase2P0:HashFailure', ...
    'Unable to compute SHA-256 for %s.',path);
cleanupFile = onCleanup(@() fclose(fileId));
bytes = fread(fileId,Inf,'*uint8');
digester = java.security.MessageDigest.getInstance('SHA-256');
digester.update(bytes);
hashBytes = typecast(digester.digest(),'uint8');
hash = upper(string(reshape(dec2hex(hashBytes,2).',1,[])));
end

function label = pass_label(value)
if value
    label = 'PASS';
else
    label = 'FAIL';
end
end
