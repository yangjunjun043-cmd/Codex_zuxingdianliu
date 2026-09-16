%% MOA Simulink 统一运行入口
% 固定使用已验证的 AI6109_MOA_AutoComp10.slx。
% 本脚本只完成路径初始化、输入准备、模型检查和一次确定性仿真。

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));
cd(rootDir);

modelName = 'AI6109_MOA_AutoComp11';
modelFile = fullfile(rootDir,[modelName '.slx']);
scenario = 'static';
seed = 101;

fprintf('\n=== MOA Simulink 统一运行入口 ===\n');
fprintf('工程目录：%s\n',rootDir);
fprintf('目标模型：%s\n',modelFile);

try
    assert(isfile(modelFile), ...
        'run_main:ModelMissing','找不到目标模型：%s',modelFile);
    assert(~isempty(ver('simulink')), ...
        'run_main:SimulinkMissing','当前 MATLAB 未安装 Simulink。');

    cfg = patent_default_config();
    cfg.model = modelName;
    requiredFields = {'StopTime','f','Ts','Un_LL','C0','C_moa', ...
        'C1','C2','Cself_pF','moa_Vref_V','moa_Iref_A', ...
        'moa_alpha','h3_ratio','phi3_deg','Vneg_pu'};
    missingFields = requiredFields(~isfield(cfg,requiredFields));
    assert(isempty(missingFields), ...
        'run_main:ConfigMissing','配置缺少字段：%s', ...
        strjoin(missingFields,', '));
    assert(cfg.StopTime>0 && cfg.Ts>0 && cfg.f>0, ...
        'run_main:InvalidConfig','StopTime、Ts 和 f 必须为正数。');

    load_system(modelName);
    open_system(modelName);

    expectedInputs = {'Cs1_true_pF','Cs2_true_pF','B_fault_scale', ...
        'noiseA_A','noiseB_A','noiseC_A'};
    inputBlocks = find_system(modelName,'SearchDepth',1, ...
        'BlockType','Inport');
    inputPorts = cellfun(@(block)str2double(get_param(block,'Port')), ...
        inputBlocks);
    [~,order] = sort(inputPorts);
    actualInputs = cellfun(@(block)get_param(block,'Name'), ...
        inputBlocks(order),'UniformOutput',false);
    assert(isequal(actualInputs(:).',expectedInputs), ...
        'run_main:InputMismatch', ...
        '模型根输入端口与预期不一致。实际顺序：%s', ...
        strjoin(actualInputs,', '));

    tInput = (0:cfg.Ts:cfg.StopTime).';
    signals = generate_coupling_signals(tInput,scenario,seed);
    zeroNoise = zeros(size(tInput));
    assert(numel(signals.Cs1_pF)==numel(tInput) && ...
        numel(signals.Cs2_pF)==numel(tInput) && ...
        numel(signals.fault_scale)==numel(tInput), ...
        'run_main:InputLengthMismatch','外部输入信号长度不一致。');

    vars = struct('StopTime',cfg.StopTime, ...
        'h3_ratio',cfg.h3_ratio,'phi3_deg',cfg.phi3_deg, ...
        'Vneg_pu',cfg.Vneg_pu,'f',cfg.f,'Un_LL',cfg.Un_LL, ...
        'C0',cfg.C0,'C_moa',cfg.C_moa,'C1',cfg.C1,'C2',cfg.C2, ...
        'Vref_moa',cfg.moa_Vref_V,'Iref_moa',cfg.moa_Iref_A, ...
        'alpha_moa',cfg.moa_alpha,'Ts',cfg.Ts,'Ts_model',cfg.Ts, ...
        'Cself_pF',cfg.Cself_pF,'Ccoupling_disabled_F',1e-18);
    variableNames = fieldnames(vars);
    assert(all(structfun(@(value)isnumeric(value) && isscalar(value) && ...
        isfinite(value),vars)), ...
        'run_main:InvalidVariable','模型参数中存在非有限数或非标量。');

    in = Simulink.SimulationInput(modelName);
    for k = 1:numel(variableNames)
        in = in.setVariable(variableNames{k},vars.(variableNames{k}));
    end

    dataset = Simulink.SimulationData.Dataset;
    dataset{1} = timeseries(signals.Cs1_pF,tInput);
    dataset{2} = timeseries(signals.Cs2_pF,tInput);
    dataset{3} = timeseries(signals.fault_scale,tInput);
    dataset{4} = timeseries(zeroNoise,tInput);
    dataset{5} = timeseries(zeroNoise,tInput);
    dataset{6} = timeseries(zeroNoise,tInput);
    assert(dataset.numElements==numel(expectedInputs), ...
        'run_main:DatasetMismatch','外部输入数据集必须包含 6 路信号。');

    in = in.setExternalInput(dataset);
    in = in.setModelParameter('StopTime',num2str(cfg.StopTime));

    fprintf('初始化完成：%d 个模型参数、%d 路外部输入。\n', ...
        numel(variableNames),dataset.numElements);
    fprintf('启动仿真：静态耦合、无故障、零附加噪声，StopTime = %.3f s。\n', ...
        cfg.StopTime);
    runTimer = tic;
    out = sim(in);
    elapsedTime = toc(runTimer);

    assert(isa(out,'Simulink.SimulationOutput'), ...
        'run_main:InvalidOutput','仿真未返回 Simulink.SimulationOutput。');
    fprintf('SUCCESS：%s 仿真成功，耗时 %.2f s。\n',modelName,elapsedTime);
    fprintf('仿真输出保存在工作区变量 out 中。\n\n');
catch ME
    fprintf(2,'FAILURE：%s 仿真失败。\n',modelName);
    fprintf(2,'原因：%s\n',ME.message);
    fprintf(2,'错误标识：%s\n\n',ME.identifier);
    rethrow(ME);
end
