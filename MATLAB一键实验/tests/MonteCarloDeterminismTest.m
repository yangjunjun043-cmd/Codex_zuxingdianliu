classdef MonteCarloDeterminismTest < matlab.unittest.TestCase
    %MonteCarloDeterminismTest 验证固定 seed 的噪声与估计结果完全可重复。

    methods (Test)
        function testSameSeedIsExactlyRepeatable(testCase)
            [base,cfg] = MonteCarloDeterminismTest.makeBase();
            data1 = synthesize_dynamic_case(base,cfg,'slow_drift',777);
            data2 = synthesize_dynamic_case(base,cfg,'slow_drift',777);
            ref1 = reconstruct_refs_from_b(data1.t,data1.ub,cfg.f, ...
                cfg.init_start,cfg.init_end,cfg.phase_error_deg);
            ref2 = reconstruct_refs_from_b(data2.t,data2.ub,cfg.f, ...
                cfg.init_start,cfg.init_end,cfg.phase_error_deg);
            self_pF = [cfg.Cself_pF,cfg.Cself_pF,cfg.Cself_pF];
            out1 = track_coupling_cvff_rls(data1,ref1,cfg,self_pF,true);
            out2 = track_coupling_cvff_rls(data2,ref2,cfg,self_pF,true);
            testCase.verifyEqual(data1.ia,data2.ia,AbsTol=0);
            testCase.verifyEqual(data1.ib,data2.ib,AbsTol=0);
            testCase.verifyEqual(data1.ic,data2.ic,AbsTol=0);
            testCase.verifyEqual(out1.hist,out2.hist,AbsTol=0);
        end
    end

    methods (Static, Access=private)
        function [base,cfg] = makeBase()
            cfg = patent_default_config();
            cfg.Ts = 2e-4;
            cfg.StopTime = 0.105;
            cfg.init_start = 0.002;
            cfg.init_end = 0.040;
            cfg.SNR_dB = 30;
            t = (0:cfg.Ts:cfg.StopTime).';
            w = 2*pi*cfg.f;
            base.t = t;
            base.ua = cfg.Uph*sin(w*t+2*pi/3);
            base.ub = cfg.Uph*sin(w*t);
            base.uc = cfg.Uph*sin(w*t-2*pi/3);
            base.irA = cfg.moa_Iref_A*sign(base.ua).*(abs(base.ua)/cfg.moa_Vref_V).^cfg.moa_alpha;
            base.irB = cfg.moa_Iref_A*sign(base.ub).*(abs(base.ub)/cfg.moa_Vref_V).^cfg.moa_alpha;
            base.irC = cfg.moa_Iref_A*sign(base.uc).*(abs(base.uc)/cfg.moa_Vref_V).^cfg.moa_alpha;
        end
    end
end
