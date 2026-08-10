function run_all_patent_experiments()
% 一键运行全部实验。预计耗时取决于电脑性能和Simulink版本。
clc; close all;
root=fileparts(mfilename('fullpath')); addpath(genpath(root)); cd(root);
fprintf('1/2 正在运行动态跟踪与故障门控实验...\n');
run_patent_dynamic_experiments();
fprintf('2/2 正在运行鲁棒性扫描...\n');
run_patent_robustness_sweep();
fprintf('实验完成。结果目录：%s\n',fullfile(root,'results'));
end
