function results = run_phase1_validation()
%RUN_PHASE1_VALIDATION 构建模型、运行 Phase 1 全量实验并执行自动回归。

root=fileparts(mfilename('fullpath'));
addpath(genpath(root));
cd(root);
build_or_patch_model();
run_all_patent_experiments();
results=runtests(fullfile(root,'tests'),'IncludeSubfolders',true);
disp(results);
assert(all([results.Passed]),'run_phase1_validation:TestFailure', ...
    'Phase 1 自动回归存在失败项。');
fprintf('Phase 1 自动回归全部通过：%d 项。\n',numel(results));
end
