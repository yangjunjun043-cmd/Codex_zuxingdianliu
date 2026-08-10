function expected = baseline_expected()
%BASELINE_EXPECTED Phase 0 未修改基线的关键回归数值。

expected.autoComp7Sha256 = ...
    '7BBBB729FF91F457D8A9B221055B69123588E6EE28CAF93DE2613B3FF9974CD1';
expected.scene = ["固定耦合基准";"缓慢漂移";"平滑阶跃";"随机波动";"阻性故障与漂移"];
expected.bFundErrPct = [-0.029800;0.32467;0.14364;-0.12368;-0.32494];
expected.bFundAbsTolPct = 0.02;
expected.trueFaultFactor = 1.6;
expected.estimatedFaultFactor = 1.5770;
expected.faultFactorAbsTol = 0.005;
expected.unbalancePu = [0;0.01;0.03;0.05];
expected.unbalanceBFundErrPct = [0.48139;11.193;35.030;61.991];
expected.unbalanceAbsTolPct = 0.05;
end
