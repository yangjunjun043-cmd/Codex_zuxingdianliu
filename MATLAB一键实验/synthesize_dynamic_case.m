function data = synthesize_dynamic_case(base, cfg, scenario, seed)
%SYNTHESIZE_DYNAMIC_CASE  用Simulink电压和非线性阻性电流构造动态耦合工况。
% 采用准静态关系 i_C = C(t)·du/dt。耦合变化时间尺度远慢于工频周期。

if nargin < 4, seed = 1; end
rng(seed);
t = base.t; dt = median(diff(t));
dua = gradient(base.ua, dt); dub = gradient(base.ub, dt); duc = gradient(base.uc, dt);

Ca = cfg.Cself_pF*ones(size(t));
Cb = cfg.Cself_pF*ones(size(t));
Cc = cfg.Cself_pF*ones(size(t));
Cs1 = 10*ones(size(t));
Cs2 = 10*ones(size(t));

switch scenario
    case 'static'
    case 'fault_only'
    case 'slow_drift'
        s = smooth_step(t, 1.0, 3.0);
        Cs1 = 10 + 4*s; Cs2 = 10 - 3*s;
    case 'smooth_step'
        s = smooth_step(t, 1.45, 1.65);
        Cs1 = 10 + 5*s; Cs2 = 10 - 4*s;
    case 'random_drift'
        s = smooth_step(t, 0.5, 1.0);
        r = movmean(randn(size(t)), max(3,round(0.30/dt)));
        r = (r-mean(r))/(std(r)+eps);
        Cs1 = 10 + s.*(1.5*sin(2*pi*0.25*t) + 0.5*r);
        Cs2 = 10 + s.*(-1.2*sin(2*pi*0.20*t+0.7) + 0.4*r);
    case 'fault_with_drift'
        s = smooth_step(t, 0.8, 2.2);
        Cs1 = 10 + 3*s; Cs2 = 10 - 2*s;
    otherwise
        error('未知场景：%s', scenario);
end

irA = base.irA; irB = base.irB; irC = base.irC;
if strcmp(scenario, 'fault_with_drift')
    sf = smooth_step(t, 3.0, 3.06);
    irB = irB .* (1 + 0.6*sf);  % B相阻性电流提高60%
elseif strcmp(scenario, 'fault_only')
    sf = smooth_step(t, 3.0, 3.06);
    irB = irB .* (1 + 0.6*sf);  % 与fault_with_drift使用相同故障曲线
end

ia = Ca*1e-12.*dua + Cs1*1e-12.*(dua-dub) + irA;
ib = Cb*1e-12.*dub + Cs1*1e-12.*(dub-dua) + Cs2*1e-12.*(dub-duc) + irB;
ic = Cc*1e-12.*duc + Cs2*1e-12.*(duc-dub) + irC;

if isfinite(cfg.SNR_dB)
    ia = add_white_noise(ia, cfg.SNR_dB);
    ib = add_white_noise(ib, cfg.SNR_dB);
    ic = add_white_noise(ic, cfg.SNR_dB);
end

data = struct('t',t,'ua',base.ua,'ub',base.ub,'uc',base.uc, ...
    'ia',ia,'ib',ib,'ic',ic,'irA',irA,'irB',irB,'irC',irC, ...
    'Ca',Ca,'Cb',Cb,'Cc',Cc,'Cs1',Cs1,'Cs2',Cs2,'scenario',scenario);
end

function y = smooth_step(t,t0,t1)
x = min(max((t-t0)/(t1-t0),0),1);
y = x.^2.*(3-2*x);
end

function y = add_white_noise(x, snrDB)
sigma = sqrt(mean(x.^2))/10^(snrDB/20);
y = x + sigma*randn(size(x));
end
