function signals = generate_coupling_signals(t,scenario,seed)
%GENERATE_COUPLING_SIGNALS 复用原合成器的 Cs1/Cs2 与故障轨迹。
if nargin < 3, seed = 1; end
rng(seed);
t = t(:);
Cs1 = 10*ones(size(t));
Cs2 = 10*ones(size(t));
faultScale = ones(size(t));
switch scenario
    case 'static'
    case 'slow_drift'
        s = smooth_step(t,1.0,3.0);
        Cs1 = 10+4*s; Cs2 = 10-3*s;
    case 'fault_with_drift'
        s = smooth_step(t,0.8,2.2);
        Cs1 = 10+3*s; Cs2 = 10-2*s;
        faultScale = 1+0.6*smooth_step(t,3.0,3.06);
    otherwise
        error('generate_coupling_signals:UnknownScenario','本阶段未启用场景：%s',scenario);
end
signals = struct('t',t,'Cs1_pF',Cs1,'Cs2_pF',Cs2,'fault_scale',faultScale);
end

function y = smooth_step(t,t0,t1)
x = min(max((t-t0)/(t1-t0),0),1);
y = x.^2.*(3-2*x);
end
