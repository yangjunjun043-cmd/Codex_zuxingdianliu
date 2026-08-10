function outputModel = build_or_patch_model()
%BUILD_OR_PATCH_MODEL 从 AutoComp7 可复现构建 Phase 1 的参数化 AutoComp8。
% 仅参数化三个 MOA MATLAB Function，不修改模型连接和物理结构。

root = fileparts(fileparts(mfilename('fullpath')));
sourceFile = fullfile(root,'AI6109_MOA_AutoComp7.slx');
outputFile = fullfile(root,'AI6109_MOA_AutoComp8.slx');
sourceModel = 'AI6109_MOA_AutoComp7';
outputModel = 'AI6109_MOA_AutoComp8';

assert(isfile(sourceFile),'build_or_patch_model:MissingSource', ...
    '缺少基准模型：%s',sourceFile);
if bdIsLoaded(sourceModel), close_system(sourceModel,0); end
if bdIsLoaded(outputModel), close_system(outputModel,0); end

copyfile(sourceFile,outputFile,'f');
load_system(outputModel);
cleanup = onCleanup(@() close_if_loaded(outputModel));

rootObject = sfroot;
charts = rootObject.find('-isa','Stateflow.EMChart');
charts = charts(arrayfun(@(x) startsWith(x.Path,[outputModel '/MATLAB Function']),charts));
assert(numel(charts)==3,'build_or_patch_model:UnexpectedChartCount', ...
    '应找到 3 个 MOA MATLAB Function，实际找到 %d 个。',numel(charts));

scriptText = sprintf([ ...
    'function i = moa_current(v)\n' ...
    '%% 氧化锌避雷器非线性阻性电流模型（参数来自统一 cfg）\n' ...
    'i = Iref_moa * sign(v) * (abs(v)/Vref_moa)^alpha_moa;\n' ...
    'end\n']);
parameterNames = {'Vref_moa','Iref_moa','alpha_moa'};
for k = 1:numel(charts)
    charts(k).Script = scriptText;
    existingData = charts(k).find('-isa','Stateflow.Data');
    for p = 1:numel(parameterNames)
        match = existingData(arrayfun(@(x) strcmp(x.Name,parameterNames{p}),existingData));
        if isempty(match)
            match = Stateflow.Data(charts(k));
            match.Name = parameterNames{p};
        end
        match.Scope = 'Parameter';
    end
end

save_system(outputModel,outputFile);
clear cleanup;
close_system(outputModel,0);
fprintf('已生成参数化模型：%s\n',outputFile);
end

function close_if_loaded(model)
if bdIsLoaded(model), close_system(model,0); end
end
