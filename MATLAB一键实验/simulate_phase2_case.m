function [data,matlabReference] = simulate_phase2_case(cfg,scenario,seed)
%SIMULATE_PHASE2_CASE 运行 AutoComp9，并返回同轨迹 MATLAB 参考电流。
tInput = (0:cfg.Ts:cfg.StopTime).';
signals = generate_coupling_signals(tInput,scenario,seed);
zeroNoise = zeros(size(tInput));
data0 = run_once(cfg,signals,zeroNoise,zeroNoise,zeroNoise);

% SPS 电流测量方向与算法正方向相反；旧合成器使用统一后的正方向。
base = struct('t',data0.t,'ua',data0.ua,'ub',data0.ub,'uc',data0.uc, ...
    'irA',-data0.irA_raw,'irB',-data0.irB_raw,'irC',-data0.irC_raw);
referenceCfg = cfg;
referenceCfg.SNR_dB = Inf;
matlabReference = synthesize_dynamic_case(base,referenceCfg,scenario,seed);

rng(seed+10000);
noiseA = noise_for_snr(matlabReference.ia,cfg.SNR_dB);
noiseB = noise_for_snr(matlabReference.ib,cfg.SNR_dB);
noiseC = noise_for_snr(matlabReference.ic,cfg.SNR_dB);
data = run_once(cfg,signals,noiseA,noiseB,noiseC);
matlabReference.ia = matlabReference.ia+noiseA;
matlabReference.ib = matlabReference.ib+noiseB;
matlabReference.ic = matlabReference.ic+noiseC;
data.Ca = cfg.Cself_pF*ones(size(data.t));
data.Cb = data.Ca; data.Cc = data.Ca;
data.scenario = scenario;
data.current_source = "simulink";
end

function data = run_once(cfg,signals,noiseA,noiseB,noiseC)
in = Simulink.SimulationInput(cfg.model);
vars = struct('StopTime',cfg.StopTime,'h3_ratio',cfg.h3_ratio,'phi3_deg',cfg.phi3_deg, ...
    'Vneg_pu',cfg.Vneg_pu,'f',cfg.f,'Un_LL',cfg.Un_LL, ...
    'C0',cfg.C0,'C_moa',cfg.C_moa,'C1',cfg.C1,'C2',cfg.C2, ...
    'Vref_moa',cfg.moa_Vref_V,'Iref_moa',cfg.moa_Iref_A, ...
    'alpha_moa',cfg.moa_alpha,'Ts',cfg.Ts,'Ts_model',cfg.Ts, ...
    'Cself_pF',cfg.Cself_pF,'Ccoupling_disabled_F',1e-18);
names = fieldnames(vars);
for k = 1:numel(names), in = in.setVariable(names{k},vars.(names{k})); end
dataset = Simulink.SimulationData.Dataset;
dataset{1} = timeseries(signals.Cs1_pF,signals.t);
dataset{2} = timeseries(signals.Cs2_pF,signals.t);
dataset{3} = timeseries(signals.fault_scale,signals.t);
dataset{4} = timeseries(noiseA,signals.t);
dataset{5} = timeseries(noiseB,signals.t);
dataset{6} = timeseries(noiseC,signals.t);
in = in.setExternalInput(dataset);
in = in.setModelParameter('StopTime',num2str(cfg.StopTime));
out = sim(in);
[data.t,data.ua] = read_signal(out,'uA');
[~,data.ub] = read_signal(out,'uB'); [~,data.uc] = read_signal(out,'uC');
[~,data.ia] = read_signal(out,'iA_total'); [~,data.ib] = read_signal(out,'iB_total');
[~,data.ic] = read_signal(out,'iC_total');
[~,data.irA] = read_signal(out,'iA_R_true'); [~,data.irB] = read_signal(out,'iB_R_true');
[~,data.irC] = read_signal(out,'iC_R_true');
[~,data.irA_raw] = read_signal(out,'iA_R_raw'); [~,data.irB_raw] = read_signal(out,'iB_R_raw');
[~,data.irC_raw] = read_signal(out,'iC_R_raw');
[~,data.Cs1] = read_signal(out,'Cs1_true'); [~,data.Cs2] = read_signal(out,'Cs2_true');
end

function noise = noise_for_snr(x,snrDB)
if isfinite(snrDB)
    noise = rms(x)/10^(snrDB/20)*randn(size(x));
else
    noise = zeros(size(x));
end
end

function [t,x] = read_signal(out,name)
s = out.get(name);
if isa(s,'timeseries'), t=s.Time; x=s.Data; else, t=s.time; x=s.signals.values; end
t=t(:); x=squeeze(x); x=x(:);
end
