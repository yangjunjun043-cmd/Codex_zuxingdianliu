function signals = generate_coupling_signals(t,scenario,seed)
%GENERATE_COUPLING_SIGNALS 复用原合成器的 Cs1/Cs2 与故障轨迹。
if nargin < 3, seed = 1; end
rng(seed);
t = t(:);
scenario = legacy_scenario_name(scenario);
Cs1 = 10*ones(size(t));
Cs2 = 10*ones(size(t));
faultScale = ones(size(t));
switch scenario
    case 'static'
    case 'slow_drift'
        s = smooth_step(t,1.0,3.0);
        Cs1 = 10+4*s; Cs2 = 10-3*s;
    case 'smooth_step'
        s = smooth_step(t,1.45,1.65);
        Cs1 = 10+5*s; Cs2 = 10-4*s;
    case 'random_drift'
        dt = median(diff(t));
        s = smooth_step(t,0.5,1.0);
        r = movmean(randn(size(t)),max(3,round(0.30/dt)));
        r = (r-mean(r))/(std(r)+eps);
        Cs1 = 10+s.*(1.5*sin(2*pi*0.25*t)+0.5*r);
        Cs2 = 10+s.*(-1.2*sin(2*pi*0.20*t+0.7)+0.4*r);
    case 'fault_only'
        faultScale = fault_profile(t);
    case 'fault_with_drift'
        s = smooth_step(t,0.8,2.2);
        Cs1 = 10+3*s; Cs2 = 10-2*s;
        faultScale = fault_profile(t);
    otherwise
        error('generate_coupling_signals:UnknownScenario','本阶段未启用场景：%s',scenario);
end
signals = struct('t',t,'Cs1_pF',Cs1,'Cs2_pF',Cs2,'fault_scale',faultScale);
end

function scenario = legacy_scenario_name(scenario)
scenario = char(scenario);
switch scenario
    case 'Case01_static', scenario = 'static';
    case 'Case02_slow_drift', scenario = 'slow_drift';
    case 'Case03_smooth_step', scenario = 'smooth_step';
    case 'Case04_random_drift', scenario = 'random_drift';
    case 'Case05_fault_only', scenario = 'fault_only';
    case 'Case06_drift_then_fault', scenario = 'fault_with_drift';
end
end

function faultScale = fault_profile(t)
faultScale = 1+0.6*smooth_step(t,3.0,3.06);
end

function y = smooth_step(t,t0,t1)
x = min(max((t-t0)/(t1-t0),0),1);
y = x.^2.*(3-2*x);
end
