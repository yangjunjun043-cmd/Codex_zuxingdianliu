function cfg = patent_default_config()

% 参数与 AI6109_MOA_AutoComp7.slx 及原 bianliang3.m 保持一致。

cfg.model = 'AI6109_MOA_AutoComp7';
cfg.StopTime = 4.0;
cfg.f = 50;
cfg.Ts = 2e-5;
cfg.Un_LL = 110e3;
cfg.Uph = cfg.Un_LL/sqrt(3);
cfg.C0 = 100e-12;
cfg.C_moa = 300e-12;
cfg.Cself_pF = (cfg.C0 + cfg.C_moa)*1e12;
cfg.C1 = 10e-12;
cfg.C2 = 10e-12;
cfg.IR_rms = 0.3e-3;
cfg.R_moa = cfg.Uph/cfg.IR_rms;
cfg.Rs_src = 0.1;

% 电压工况
cfg.h3_ratio = 0.05;
cfg.phi3_deg = 0;
cfg.Vneg_pu = 0;

% 测量与算法参数
cfg.SNR_dB = 30;
cfg.phase_error_deg = 0;
cfg.init_start = 0.10;
cfg.init_end = 0.70;
cfg.nlms_mu = 0.18;
cfg.lambda_min = 0.55;
cfg.lambda_max = 0.995;
cfg.coupling_bounds_pF = [0, 40];
cfg.rate_limit_pF_per_cycle = 1.2;
cfg.gate_ratio = 1.12;
cfg.gate_quad_ratio = 1.20;
cfg.gate_hold_cycles = 25;

cfg.output_dir = fullfile(fileparts(mfilename('fullpath')), 'results');
end
