classdef Phase1AFaultOnlyCompatibilityTest < matlab.unittest.TestCase
    %PHASE1AFAULTONLYCOMPATIBILITYTEST Pure MATLAB Step 6A checks.

    properties (TestParameter)
        legacyScenario = struct( ...
            'static','static', ...
            'slowDrift','slow_drift', ...
            'smoothStep','smooth_step', ...
            'randomDrift','random_drift', ...
            'faultWithDrift','fault_with_drift')
    end

    methods (TestClassSetup)
        function addProjectPath(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(root));
        end
    end

    methods (TestMethodSetup)
        function preserveRandomState(testCase)
            originalState = rng;
            testCase.addTeardown(@() rng(originalState));
        end
    end

    methods (Test)
        function testFaultOnlyReturns(testCase)
            [base,cfg] = ...
                Phase1AFaultOnlyCompatibilityTest.syntheticInputs();

            data = synthesize_dynamic_case(base,cfg,'fault_only',106);

            testCase.verifyEqual(data.scenario,'fault_only');
            testCase.verifySize(data.Cs1,size(base.t));
            testCase.verifySize(data.Cs2,size(base.t));
            testCase.verifyTrue(all(isfinite(data.ib)));
        end

        function testFaultOnlyCs1IsFixed(testCase)
            [base,cfg] = ...
                Phase1AFaultOnlyCompatibilityTest.syntheticInputs();

            data = synthesize_dynamic_case(base,cfg,'fault_only',106);

            testCase.verifyEqual(data.Cs1,10*ones(size(base.t)), ...
                'AbsTol',0);
        end

        function testFaultOnlyCs2IsFixed(testCase)
            [base,cfg] = ...
                Phase1AFaultOnlyCompatibilityTest.syntheticInputs();

            data = synthesize_dynamic_case(base,cfg,'fault_only',106);

            testCase.verifyEqual(data.Cs2,10*ones(size(base.t)), ...
                'AbsTol',0);
        end

        function testFaultOnlyProfileEndpoints(testCase)
            [base,cfg] = ...
                Phase1AFaultOnlyCompatibilityTest.syntheticInputs();

            data = synthesize_dynamic_case(base,cfg,'fault_only',106);

            testCase.verifyEqual(data.irB(base.t<=3.0), ...
                ones(sum(base.t<=3.0),1),'AbsTol',0);
            testCase.verifyEqual(data.irB(base.t>=3.06), ...
                1.6*ones(sum(base.t>=3.06),1),'AbsTol',0);
        end

        function testFaultOnlyAndCase06ProfilesMatch(testCase)
            [base,cfg] = ...
                Phase1AFaultOnlyCompatibilityTest.syntheticInputs();
            faultOnly = synthesize_dynamic_case( ...
                base,cfg,'fault_only',106);

            driftThenFault = synthesize_dynamic_case( ...
                base,cfg,'fault_with_drift',105);

            testCase.verifyEqual(faultOnly.irB,driftThenFault.irB, ...
                'AbsTol',0);
        end

        function testFaultOnlyMatchesFrozenGenerator(testCase)
            [base,cfg] = ...
                Phase1AFaultOnlyCompatibilityTest.syntheticInputs();
            synthetic = synthesize_dynamic_case( ...
                base,cfg,'fault_only',106);

            generated = generate_coupling_signals( ...
                base.t,'fault_only',106);

            testCase.verifyEqual(synthetic.Cs1,generated.Cs1_pF, ...
                'AbsTol',0);
            testCase.verifyEqual(synthetic.Cs2,generated.Cs2_pF, ...
                'AbsTol',0);
            testCase.verifyEqual(synthetic.irB,generated.fault_scale, ...
                'AbsTol',0);
        end

        function testLegacyScenarioStillGenerates(testCase,legacyScenario)
            [base,cfg] = ...
                Phase1AFaultOnlyCompatibilityTest.syntheticInputs();

            data = synthesize_dynamic_case(base,cfg,legacyScenario,105);

            testCase.verifySize(data.Cs1,size(base.t));
            testCase.verifySize(data.Cs2,size(base.t));
            testCase.verifyTrue(all(isfinite(data.ia)));
            testCase.verifyTrue(all(isfinite(data.ib)));
            testCase.verifyTrue(all(isfinite(data.ic)));
        end

        function testCase06MatchesFrozenFormula(testCase)
            [base,cfg] = ...
                Phase1AFaultOnlyCompatibilityTest.syntheticInputs();
            drift = Phase1AFaultOnlyCompatibilityTest.smoothStep( ...
                base.t,0.8,2.2);
            fault = 1+0.6*Phase1AFaultOnlyCompatibilityTest.smoothStep( ...
                base.t,3.0,3.06);

            data = synthesize_dynamic_case( ...
                base,cfg,'fault_with_drift',105);

            testCase.verifyEqual(data.Cs1,10+3*drift,'AbsTol',0);
            testCase.verifyEqual(data.Cs2,10-2*drift,'AbsTol',0);
            testCase.verifyEqual(data.irB,fault,'AbsTol',0);
        end
    end

    methods (Static, Access=private)
        function [base,cfg] = syntheticInputs()
            t = (0:2e-5:4.0).';
            ua = sin(2*pi*50*t);
            ub = sin(2*pi*50*t-2*pi/3);
            uc = sin(2*pi*50*t+2*pi/3);
            zero = zeros(size(t));
            base = struct('t',t,'ua',ua,'ub',ub,'uc',uc, ...
                'irA',zero,'irB',ones(size(t)),'irC',zero);
            cfg = struct('Cself_pF',400,'SNR_dB',Inf);
        end

        function y = smoothStep(t,t0,t1)
            x = min(max((t-t0)/(t1-t0),0),1);
            y = x.^2.*(3-2*x);
        end
    end
end
