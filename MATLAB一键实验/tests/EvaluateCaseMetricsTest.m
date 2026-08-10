classdef EvaluateCaseMetricsTest < matlab.unittest.TestCase
    %EvaluateCaseMetricsTest 验证幅值、相位与波形指标的定义。

    methods (Test)
        function testKnownHarmonicErrors(testCase)
            cfg = patent_default_config();
            cfg.metric_start = 0.2;
            t = (0:cfg.Ts:1).';
            w = 2*pi*cfg.f;
            truth = sin(w*t)+0.2*sin(3*w*t);
            estimate = 1.1*sin(w*t+deg2rad(5))+0.16*sin(3*w*t+deg2rad(7));
            data = struct('t',t,'irA',truth,'irB',truth,'irC',truth, ...
                'Cs1',10*ones(size(t)),'Cs2',10*ones(size(t)));
            ir = struct('A',estimate,'B',estimate,'C',estimate);
            cHist = repmat([10,10],numel(t),1);
            metric = evaluate_case_metrics(data,ir,cHist,'test','test',cfg);
            testCase.verifyEqual(metric.A_FundErr_pct,10,AbsTol=1e-8);
            testCase.verifyEqual(metric.A_FundPhaseErr_deg,5,AbsTol=1e-8);
            testCase.verifyEqual(metric.A_H3Err_pct,-20,AbsTol=1e-8);
            testCase.verifyEqual(metric.A_H3PhaseErr_deg,7,AbsTol=1e-8);
            testCase.verifyGreaterThan(metric.A_WaveRMSE_A,0);
        end

        function testMonteCarloSeedCount(testCase)
            cfg = patent_default_config();
            testCase.verifyGreaterThanOrEqual(numel(cfg.monte_carlo_seeds),30);
            testCase.verifyEqual(numel(unique(cfg.monte_carlo_seeds)), ...
                numel(cfg.monte_carlo_seeds));
        end
    end
end
