function base = simulate_moa_base(cfg)
%SIMULATE_MOA_BASE  运行用户的 Simulink 模型并提取三相电压、真实阻性电流。

model = cfg.model;
load_system(model);

simIn = Simulink.SimulationInput(model);
vars = struct( ...
    'StopTime', cfg.StopTime, ...
    'h3_ratio', cfg.h3_ratio, ...
    'phi3_deg', cfg.phi3_deg, ...
    'Vneg_pu', cfg.Vneg_pu, ...
    'f', cfg.f, ...
    'Un_LL', cfg.Un_LL, ...
    'C0', cfg.C0, ...
    'C_moa', cfg.C_moa, ...
    'C1', cfg.C1, ...
    'C2', cfg.C2, ...
    'Vref_moa', cfg.moa_Vref_V, ...
    'Iref_moa', cfg.moa_Iref_A, ...
    'alpha_moa', cfg.moa_alpha, ...
    'Ts', cfg.Ts);

names = fieldnames(vars);
for k = 1:numel(names)
    simIn = simIn.setVariable(names{k}, vars.(names{k}));
end
simIn = simIn.setModelParameter('StopTime', num2str(cfg.StopTime));
simOut = sim(simIn);

[t, base.ua] = read_structure_signal(simOut, 'uA');
[~, base.ub] = read_structure_signal(simOut, 'uB');
[~, base.uc] = read_structure_signal(simOut, 'uC');
[~, base.irA] = read_structure_signal(simOut, 'iA_R_true');
[~, base.irB] = read_structure_signal(simOut, 'iB_R_true');
[~, base.irC] = read_structure_signal(simOut, 'iC_R_true');

base.t = t(:);
base.ua = base.ua(:); base.ub = base.ub(:); base.uc = base.uc(:);
base.irA = base.irA(:); base.irB = base.irB(:); base.irC = base.irC(:);

% 自动统一真实阻性电流方向。
Vref = cfg.moa_Vref_V;
Iref = cfg.moa_Iref_A;
alpha = cfg.moa_alpha;
refA = Iref.*sign(base.ua).*(abs(base.ua)./Vref).^alpha;
refB = Iref.*sign(base.ub).*(abs(base.ub)./Vref).^alpha;
refC = Iref.*sign(base.uc).*(abs(base.uc)./Vref).^alpha;
if corr_sign(base.irA,refA)<0, base.irA=-base.irA; end
if corr_sign(base.irB,refB)<0, base.irB=-base.irB; end
if corr_sign(base.irC,refC)<0, base.irC=-base.irC; end
end

function [t, x] = read_structure_signal(simOut, name)
try
    s = simOut.get(name);
catch
    s = evalin('base', name);
end
if isa(s, 'timeseries')
    t = s.Time;
    x = s.Data;
else
    t = s.time;
    x = s.signals.values;
end
x = squeeze(x);
end

function r=corr_sign(x,y)
x=x(:)-mean(x); y=y(:)-mean(y);
r=sum(x.*y)/sqrt((sum(x.^2)+eps)*(sum(y.^2)+eps));
end
