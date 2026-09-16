function registry = phase1a_algorithm_registry()
%PHASE1A_ALGORITHM_REGISTRY Phase 1A 基线算法编号与现有实现映射。
% 本文件不复制或改变任何 RLS、门控、投影及变化率限制公式。

algorithmMode = ["M0"; "M2"; "M3"];
algorithmName = [
    "Fixed coupling compensation"
    "VFF-RLS without fault gate"
    "VFF-RLS with existing hard fault gate"
    ];
enabled = true(3,1);
implementationSource = [
    "initial_coupling_estimate.m + frozen c0 history in existing runners"
    "track_coupling_cvff_rls.m(..., false)"
    "track_coupling_cvff_rls.m(..., true)"
    ];
gateEnabled = [false; false; true];
notes = [
    "在初始化窗口用 LS 得到 Cs1/Cs2，随后全程冻结。"
    "保留现有 VFF、变化率限制和物理范围投影，仅关闭故障门控。"
    "与 M2 使用同一现有函数和参数，仅启用既有硬故障门控。"
    ];

registry = table(algorithmMode,algorithmName,enabled, ...
    implementationSource,gateEnabled,notes, ...
    'VariableNames',{'algorithm_mode','algorithm_name','enabled', ...
    'implementation_source','gate_enabled','notes'});
end
