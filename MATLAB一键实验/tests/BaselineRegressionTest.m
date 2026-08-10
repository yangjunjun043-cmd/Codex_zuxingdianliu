classdef BaselineRegressionTest < matlab.unittest.TestCase
    %BaselineRegressionTest 检查 Phase 1 主指标未无解释漂移。

    properties (SetAccess=private)
        Dynamic
        Fault
        Robustness
        Expected
    end

    methods (TestClassSetup)
        function loadResults(testCase)
            cfg = patent_default_config();
            dynamicFile = fullfile(cfg.output_dir,'dynamic_summary.xlsx');
            robustnessFile = fullfile(cfg.output_dir,'robustness_summary.xlsx');
            testCase.Dynamic = readtable(dynamicFile,'Sheet','动态场景汇总');
            testCase.Fault = readtable(dynamicFile,'Sheet','故障门控汇总');
            testCase.Robustness = readtable(robustnessFile,'Sheet','全部原始工况');
            testCase.Expected = baseline_expected();
        end
    end

    methods (Test)
        function testDynamicFundamentalBaseline(testCase)
            q = string(testCase.Dynamic.method)=="CVFF-RLS";
            actual = testCase.Dynamic(q,:);
            testCase.verifyEqual(string(actual.scene),testCase.Expected.scene);
            testCase.verifyEqual(actual.B_FundErr_pct, ...
                testCase.Expected.bFundErrPct,AbsTol=testCase.Expected.bFundAbsTolPct);
        end

        function testFaultRetentionBaseline(testCase)
            q = string(testCase.Fault.method)=="CVFF-RLS";
            actual = testCase.Fault(q,:);
            testCase.verifyEqual(actual.true_fault_factor, ...
                testCase.Expected.trueFaultFactor,AbsTol=1e-10);
            testCase.verifyEqual(actual.estimated_fault_factor, ...
                testCase.Expected.estimatedFaultFactor, ...
                AbsTol=testCase.Expected.faultFactorAbsTol);
        end

        function testUnbalanceBaseline(testCase)
            q = string(testCase.Robustness.parameter)=="Vneg_pu";
            actual = testCase.Robustness(q,:);
            testCase.verifyEqual(actual.value,testCase.Expected.unbalancePu,AbsTol=0);
            testCase.verifyEqual(actual.B_FundErr_pct, ...
                testCase.Expected.unbalanceBFundErrPct, ...
                AbsTol=testCase.Expected.unbalanceAbsTolPct);
        end
    end
end
