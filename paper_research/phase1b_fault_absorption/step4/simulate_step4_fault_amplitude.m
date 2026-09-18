function [data,signals,noiseInfo] = simulate_step4_fault_amplitude( ...
        cfg,seed,finalFaultFactor)
%SIMULATE_STEP4_FAULT_AMPLITUDE Run AutoComp9 with a controlled fault factor.
% The wrapper preserves the frozen Case05 timing, Cs truth, seed, SNR and
% input ordering. Only the terminal value of fault_scale is changed.

arguments
    cfg (1,1) struct
    seed (1,1) double {mustBeInteger}
    finalFaultFactor (1,1) double {mustBeGreaterThanOrEqual(finalFaultFactor,1)}
end

tInput = (0:cfg.Ts:cfg.StopTime).';
signals = controlled_signals(tInput,finalFaultFactor);
zeroNoise = zeros(size(tInput));
data0 = run_once(cfg,signals,zeroNoise,zeroNoise,zeroNoise);

% Reproduce synthesize_dynamic_case('fault_only') exactly, generalized only
% in the final fault factor. The raw MOA currents precede fault scaling.
base = struct('t',data0.t,'ua',data0.ua,'ub',data0.ub,'uc',data0.uc, ...
    'irA',-data0.irA_raw,'irB',-data0.irB_raw,'irC',-data0.irC_raw);
ideal = synthesize_controlled_reference(base,cfg,signals);

% Reset for every condition: identical standardized random realization.
rng(seed+10000);
noiseA = noise_for_snr(ideal.ia,cfg.SNR_dB);
noiseB = noise_for_snr(ideal.ib,cfg.SNR_dB);
noiseC = noise_for_snr(ideal.ic,cfg.SNR_dB);
data = run_once(cfg,signals,noiseA,noiseB,noiseC);
data.Ca = cfg.Cself_pF*ones(size(data.t));
data.Cb = data.Ca;
data.Cc = data.Ca;
data.scenario = "fault_only_controlled";
data.current_source = "simulink";

noiseInfo = struct( ...
    'noiseA',noiseA,'noiseB',noiseB,'noiseC',noiseC, ...
    'normalizedA',normalize_noise(noiseA), ...
    'normalizedB',normalize_noise(noiseB), ...
    'normalizedC',normalize_noise(noiseC), ...
    'configured_SNR_dB',cfg.SNR_dB, ...
    'realized_SNR_A_dB',snr_from_noise(ideal.ia,noiseA), ...
    'realized_SNR_B_dB',snr_from_noise(ideal.ib,noiseB), ...
    'realized_SNR_C_dB',snr_from_noise(ideal.ic,noiseC));
end

function signals = controlled_signals(t,finalFaultFactor)
sf = smooth_step(t,3.00,3.06);
signals = struct( ...
    't',t, ...
    'Cs1_pF',10*ones(size(t)), ...
    'Cs2_pF',10*ones(size(t)), ...
    'fault_scale',1+(finalFaultFactor-1)*sf);
end

function ideal = synthesize_controlled_reference(base,cfg,signals)
t = base.t;
dt = median(diff(t));
dua = gradient(base.ua,dt);
dub = gradient(base.ub,dt);
duc = gradient(base.uc,dt);
Ca = cfg.Cself_pF*ones(size(t));
Cs1 = signals.Cs1_pF;
Cs2 = signals.Cs2_pF;
irA = base.irA;
irB = base.irB.*signals.fault_scale;
irC = base.irC;
ideal = struct( ...
    'ia',Ca*1e-12.*dua + Cs1*1e-12.*(dua-dub) + irA, ...
    'ib',Ca*1e-12.*dub + Cs1*1e-12.*(dub-dua) + ...
        Cs2*1e-12.*(dub-duc) + irB, ...
    'ic',Ca*1e-12.*duc + Cs2*1e-12.*(duc-dub) + irC);
end

function data = run_once(cfg,signals,noiseA,noiseB,noiseC)
in = Simulink.SimulationInput(cfg.model);
vars = struct('StopTime',cfg.StopTime,'h3_ratio',cfg.h3_ratio, ...
    'phi3_deg',cfg.phi3_deg,'Vneg_pu',cfg.Vneg_pu,'f',cfg.f, ...
    'Un_LL',cfg.Un_LL,'C0',cfg.C0,'C_moa',cfg.C_moa, ...
    'C1',cfg.C1,'C2',cfg.C2,'Vref_moa',cfg.moa_Vref_V, ...
    'Iref_moa',cfg.moa_Iref_A,'alpha_moa',cfg.moa_alpha, ...
    'Ts',cfg.Ts,'Ts_model',cfg.Ts,'Cself_pF',cfg.Cself_pF, ...
    'Ccoupling_disabled_F',1e-18);
names = fieldnames(vars);
for k = 1:numel(names)
    in = in.setVariable(names{k},vars.(names{k}));
end
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
[~,data.ub] = read_signal(out,'uB');
[~,data.uc] = read_signal(out,'uC');
[~,data.ia] = read_signal(out,'iA_total');
[~,data.ib] = read_signal(out,'iB_total');
[~,data.ic] = read_signal(out,'iC_total');
[~,data.irA] = read_signal(out,'iA_R_true');
[~,data.irB] = read_signal(out,'iB_R_true');
[~,data.irC] = read_signal(out,'iC_R_true');
[~,data.irA_raw] = read_signal(out,'iA_R_raw');
[~,data.irB_raw] = read_signal(out,'iB_R_raw');
[~,data.irC_raw] = read_signal(out,'iC_R_raw');
[~,data.Cs1] = read_signal(out,'Cs1_true');
[~,data.Cs2] = read_signal(out,'Cs2_true');
end

function noise = noise_for_snr(x,snrDB)
if isfinite(snrDB)
    noise = rms(x)/10^(snrDB/20)*randn(size(x));
else
    noise = zeros(size(x));
end
end

function value = normalize_noise(noise)
value = noise/(rms(noise)+eps);
end

function value = snr_from_noise(signal,noise)
value = 20*log10(rms(signal)/(rms(noise)+eps));
end

function y = smooth_step(t,t0,t1)
x = min(max((t-t0)/(t1-t0),0),1);
y = x.^2.*(3-2*x);
end

function [t,x] = read_signal(out,name)
s = out.get(name);
if isa(s,'timeseries')
    t = s.Time;
    x = s.Data;
else
    t = s.time;
    x = s.signals.values;
end
t = t(:);
x = squeeze(x);
x = x(:);
end
