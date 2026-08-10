classdef ModelParameterizationTest < matlab.unittest.TestCase
    %ModelParameterizationTest 验证三项 cfg 参数真实进入 AutoComp8。

    properties (SetAccess=private)
        BaseCfg
        BaseData
    end

    methods (TestClassSetup)
        function simulateDefault(testCase)
            testCase.BaseCfg = patent_default_config();
            testCase.BaseCfg.StopTime = 0.12;
            testCase.BaseData = simulate_moa_base(testCase.BaseCfg);
        end
    end

    methods (Test)
        function testIrefScalesCurrent(testCase)
            cfg = testCase.BaseCfg;
            cfg.moa_Iref_A = 2*cfg.moa_Iref_A;
            changed = simulate_moa_base(cfg);
            ratio = rms(changed.irB)/rms(testCase.BaseData.irB);
            testCase.verifyEqual(ratio,2,RelTol=1e-5);
        end

        function testVrefChangesCurrent(testCase)
            cfg = testCase.BaseCfg;
            cfg.moa_Vref_V = 1.1*cfg.moa_Vref_V;
            changed = simulate_moa_base(cfg);
            ratio = rms(changed.irB)/rms(testCase.BaseData.irB);
            testCase.verifyGreaterThan(abs(ratio-1),0.1);
        end

        function testAlphaChangesCurrent(testCase)
            cfg = testCase.BaseCfg;
            cfg.moa_alpha = 5;
            changed = simulate_moa_base(cfg);
            ratio = rms(changed.irB)/rms(testCase.BaseData.irB);
            testCase.verifyGreaterThan(abs(ratio-1),0.1);
        end
    end
end
