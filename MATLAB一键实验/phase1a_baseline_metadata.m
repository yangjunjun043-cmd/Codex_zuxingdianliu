function metadata = phase1a_baseline_metadata()
%PHASE1A_BASELINE_METADATA Phase 1A 论文基线的冻结元数据。
% 本函数只返回 Step 1 冻结时记录的事实，不修改模型或运行仿真。

metadata = struct();
metadata.metadata_version = "phase1a_step1_v1";
metadata.baseline_model = "AI6109_MOA_AutoComp9";
metadata.baseline_model_path = ...
    "MATLAB一键实验/AI6109_MOA_AutoComp9.slx";
metadata.baseline_model_absolute_path = ...
    "D:/Codex/MOA_Arrester/MATLAB一键实验/AI6109_MOA_AutoComp9.slx";
metadata.baseline_model_sha256 = ...
    "56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70";
metadata.baseline_integrity = "PASS";
metadata.git_branch = "main";
metadata.git_commit = "fc9d2a99ec06dd8c236258804986b17b35c64e1c";
metadata.git_dirty_status = "CLEAN";
metadata.freeze_timestamp = "2026-09-16T16:22:02+08:00";
metadata.output_root = "paper_research/phase1a_baseline";
end
