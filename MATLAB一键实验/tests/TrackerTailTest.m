classdef TrackerTailTest < matlab.unittest.TestCase
    %TrackerTailTest 验证不足整周期的尾部样本继承最后有效参数。

    methods (Test)
        function testNlmsTailUsesLastValidEstimate(testCase)
            [data,ref,cfg,self_pF] = TrackerTailTest.makeCase();
            out = track_coupling_block_nlms(data,ref,cfg,self_pF);
            lastIdx = find(data.t<=out.cycle.time_s(end),1,'last');
            tail = data.t>out.cycle.time_s(end);
            expected = repmat(out.hist(lastIdx,:),sum(tail),1);
            testCase.verifyEqual(out.hist(tail,:),expected,AbsTol=0);
        end

        function testRlsTailUsesLastValidEstimate(testCase)
            [data,ref,cfg,self_pF] = TrackerTailTest.makeCase();
            out = track_coupling_cvff_rls(data,ref,cfg,self_pF,true);
            lastIdx = find(data.t<=out.cycle.time_s(end),1,'last');
            tail = data.t>out.cycle.time_s(end);
            expected = repmat(out.hist(lastIdx,:),sum(tail),1);
            testCase.verifyEqual(out.hist(tail,:),expected,AbsTol=0);
        end
    end

    methods (Static, Access=private)
        function [data,ref,cfg,self_pF] = makeCase()
            cfg = patent_default_config();
            cfg.Ts = 2e-4;
            cfg.StopTime = 0.105;
            cfg.init_start = 0.002;
            cfg.init_end = 0.040;
            cfg.SNR_dB = Inf;
            t = (0:cfg.Ts:cfg.StopTime).';
            w = 2*pi*cfg.f;
            base.t = t;
            base.ua = cfg.Uph*sin(w*t+2*pi/3);
            base.ub = cfg.Uph*sin(w*t);
            base.uc = cfg.Uph*sin(w*t-2*pi/3);
            base.irA = cfg.moa_Iref_A*sign(base.ua).*(abs(base.ua)/cfg.moa_Vref_V).^cfg.moa_alpha;
            base.irB = cfg.moa_Iref_A*sign(base.ub).*(abs(base.ub)/cfg.moa_Vref_V).^cfg.moa_alpha;
            base.irC = cfg.moa_Iref_A*sign(base.uc).*(abs(base.uc)/cfg.moa_Vref_V).^cfg.moa_alpha;
            data = synthesize_dynamic_case(base,cfg,'slow_drift',1234);
            ref = reconstruct_refs_from_b(data.t,data.ub,cfg.f, ...
                cfg.init_start,cfg.init_end,cfg.phase_error_deg);
            self_pF = [cfg.Cself_pF,cfg.Cself_pF,cfg.Cself_pF];
        end
    end
end
