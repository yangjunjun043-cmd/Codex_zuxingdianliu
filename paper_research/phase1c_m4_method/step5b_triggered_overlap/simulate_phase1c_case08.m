function data = simulate_phase1c_case08(cfg,signals,noise)
%SIMULATE_PHASE1C_CASE08 Run one independent Case08 branch on AutoComp9.

requiredNoise = {'A','B','C'};
for k = 1:numel(requiredNoise)
    name = requiredNoise{k};
    if ~isfield(noise,name) || numel(noise.(name)) ~= numel(signals.t)
        error('Phase1C:Step5BNoise','Invalid shared noise vector %s.',name);
    end
end

in = Simulink.SimulationInput(cfg.model);
variables = struct( ...
    'StopTime',cfg.StopTime, ...
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
dataset{1} = timeseries(signals.Cs1_pF,signals.t);
dataset{2} = timeseries(signals.Cs2_pF,signals.t);
dataset{3} = timeseries(signals.fault_scale,signals.t);
dataset{4} = timeseries(noise.A,signals.t);
dataset{5} = timeseries(noise.B,signals.t);
dataset{6} = timeseries(noise.C,signals.t);
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
[~,data.Cs1] = read_signal(out,'Cs1_true');
[~,data.Cs2] = read_signal(out,'Cs2_true');
data.Ca = cfg.Cself_pF*ones(size(data.t));
data.Cb = data.Ca;
data.Cc = data.Ca;
data.scenario = char(definition_name());
data.branch = char(signals.branch);
data.current_source = "simulink";

if max(abs(data.Cs1-signals.Cs1_pF)) > 1e-10 || ...
        max(abs(data.Cs2-signals.Cs2_pF)) > 1e-10
    error('Phase1C:Step5BModelTruth', ...
        'Simulink Case08 Cs outputs do not match frozen truth.');
end
end

function name = definition_name()
name = "Case08_overlap_drift_fault_f160";
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
