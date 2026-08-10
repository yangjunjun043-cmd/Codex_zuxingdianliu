function cfg = patent_default_config()

% Phase 1 统一配置。所有重要阈值、随机种子和物理参数均在此定义。

cfg.model = 'AI6109_MOA_AutoComp8';       % Phase 1 参数化模型副本
cfg.StopTime = 4.0;                       % 仿真时长，s
cfg.f = 50;                               % 系统基波频率，Hz
cfg.Ts = 2e-5;                            % 离散仿真步长，s
cfg.Un_LL = 110e3;                        % 额定线电压有效值，V
cfg.Uph = cfg.Un_LL/sqrt(3);              % 额定相电压有效值，V（后处理使用）
cfg.C0 = 100e-12;                         % 对地杂散电容，F
cfg.C_moa = 300e-12;                      % MOA 本体等效电容，F
cfg.Cself_pF = (cfg.C0 + cfg.C_moa)*1e12; % 单相自电容标称值，pF
cfg.C1 = 10e-12;                          % A-B 相间耦合电容，F
cfg.C2 = 10e-12;                          % B-C 相间耦合电容，F
cfg.moa_Vref_V = cfg.Uph;                 % MOA 幂律参考电压，V
cfg.moa_Iref_A = 0.3e-3;                  % 参考电压下 MOA 阻性电流，A
cfg.moa_alpha = 6;                        % MOA V-I 幂律非线性指数，无量纲

% 电压工况
cfg.h3_ratio = 0.05;                      % 三次谐波电压幅值/基波幅值，无量纲
cfg.phi3_deg = 0;                         % 三次谐波相位，deg
cfg.Vneg_pu = 0;                          % 负序电压标幺值，无量纲

% 测量与算法参数
cfg.SNR_dB = 30;                           % 单次动态实验的电流信噪比，dB
cfg.snr_levels_dB = [Inf,40,30,20];       % Monte Carlo 噪声等级，dB
cfg.monte_carlo_seeds = 2001:2030;        % 固定随机种子列表，共 30 个
cfg.phase_error_deg = 0;                  % 电压参考相位误差，deg
cfg.init_start = 0.10;                    % 初始辨识窗口起点，s
cfg.init_end = 0.70;                      % 初始辨识窗口终点，s
cfg.metric_start = 0.80;                  % 评价窗口起点，s（保持原窗口不变）
cfg.nlms_mu = 0.18;                       % 块 NLMS 更新系数，无量纲
cfg.lambda_min = 0.55;                    % CVFF-RLS 最小遗忘因子
cfg.lambda_max = 0.995;                   % CVFF-RLS 最大遗忘因子
cfg.coupling_bounds_pF = [0, 40];         % 耦合电容投影范围，pF
cfg.rate_limit_pF_per_cycle = 1.2;        % 单周期参数最大变化量，pF/cycle
cfg.gate_ratio = 1.12;                    % 阻性残差相对基线故障门限
cfg.gate_quad_ratio = 1.20;               % 阻性/正交残差方向判别门限
cfg.gate_hold_cycles = 25;                % 故障触发后的冻结周期数，cycle

cfg.output_dir = fullfile(fileparts(mfilename('fullpath')), 'results_phase1');
end
