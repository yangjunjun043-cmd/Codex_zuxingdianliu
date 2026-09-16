classdef Phase1ACaseSignalTest < matlab.unittest.TestCase
    %PHASE1ACASESIGNALTEST Phase 1A Step 2 的纯信号级回归测试。

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
        function testRegistryMappingsAndSeeds(testCase)
            expectedCases = [
                "Case01_static"
                "Case02_slow_drift"
                "Case03_smooth_step"
                "Case04_random_drift"
                "Case05_fault_only"
                "Case06_drift_then_fault"
                ];
            expectedLegacy = [
                "static"
                "slow_drift"
                "smooth_step"
                "random_drift"
                "fault_only"
                "fault_with_drift"
                ];
            registry = phase1a_case_registry();

            testCase.verifyEqual(registry.case_name,expectedCases);
            testCase.verifyEqual(registry.legacy_scenario_name,expectedLegacy);
            testCase.verifyEqual(registry.seed,[101;102;103;104;106;105], ...
                'AbsTol',0);
            testCase.verifyEqual(height(registry),6);
        end

        function testStaticLegacyAndAlias(testCase)
            t = Phase1ACaseSignalTest.timeVector();
            legacy = generate_coupling_signals(t,'static',101);
            formal = generate_coupling_signals(t,'Case01_static',101);

            testCase.verifyEqual(legacy.Cs1_pF,10*ones(size(t)),'AbsTol',0);
            testCase.verifyEqual(legacy.Cs2_pF,10*ones(size(t)),'AbsTol',0);
            testCase.verifyEqual(legacy.fault_scale,ones(size(t)),'AbsTol',0);
            Phase1ACaseSignalTest.verifySignalsEqual(testCase,formal,legacy);
        end

        function testSlowDriftLegacyAndAlias(testCase)
            t = Phase1ACaseSignalTest.timeVector();
            s = Phase1ACaseSignalTest.smoothStep(t,1.0,3.0);
            legacy = generate_coupling_signals(t,'slow_drift',102);
            formal = generate_coupling_signals(t,'Case02_slow_drift',102);

            testCase.verifyEqual(legacy.Cs1_pF,10+4*s,'AbsTol',0);
            testCase.verifyEqual(legacy.Cs2_pF,10-3*s,'AbsTol',0);
            testCase.verifyEqual(legacy.fault_scale,ones(size(t)),'AbsTol',0);
            Phase1ACaseSignalTest.verifySignalsEqual(testCase,formal,legacy);
        end

        function testSmoothStepMigration(testCase)
            t = Phase1ACaseSignalTest.timeVector();
            s = Phase1ACaseSignalTest.smoothStep(t,1.45,1.65);
            legacy = generate_coupling_signals(t,'smooth_step',103);
            formal = generate_coupling_signals(t,'Case03_smooth_step',103);

            testCase.verifyEqual(legacy.Cs1_pF,10+5*s,'AbsTol',0);
            testCase.verifyEqual(legacy.Cs2_pF,10-4*s,'AbsTol',0);
            testCase.verifyEqual(legacy.Cs1_pF(t<=1.45), ...
                10*ones(sum(t<=1.45),1),'AbsTol',0);
            testCase.verifyEqual(legacy.Cs1_pF(t>=1.65), ...
                15*ones(sum(t>=1.65),1),'AbsTol',0);
            testCase.verifyEqual(legacy.Cs2_pF(t>=1.65), ...
                6*ones(sum(t>=1.65),1),'AbsTol',0);
            Phase1ACaseSignalTest.verifySignalsEqual(testCase,formal,legacy);
        end

        function testRandomDriftMigrationAndDeterminism(testCase)
            t = Phase1ACaseSignalTest.timeVector();
            expected = Phase1ACaseSignalTest.historicalRandomDrift(t,104);
            first = generate_coupling_signals(t,'random_drift',104);
            second = generate_coupling_signals(t,'Case04_random_drift',104);
            repeated = generate_coupling_signals(t,'random_drift',104);

            testCase.verifyEqual(first.Cs1_pF,expected.Cs1_pF,'AbsTol',0);
            testCase.verifyEqual(first.Cs2_pF,expected.Cs2_pF,'AbsTol',0);
            Phase1ACaseSignalTest.verifySignalsEqual(testCase,second,first);
            Phase1ACaseSignalTest.verifySignalsEqual(testCase,repeated,first);
        end

        function testFaultWithDriftLegacyAndAlias(testCase)
            t = Phase1ACaseSignalTest.timeVector();
            drift = Phase1ACaseSignalTest.smoothStep(t,0.8,2.2);
            fault = 1+0.6*Phase1ACaseSignalTest.smoothStep(t,3.0,3.06);
            legacy = generate_coupling_signals(t,'fault_with_drift',105);
            formal = generate_coupling_signals(t,'Case06_drift_then_fault',105);

            testCase.verifyEqual(legacy.Cs1_pF,10+3*drift,'AbsTol',0);
            testCase.verifyEqual(legacy.Cs2_pF,10-2*drift,'AbsTol',0);
            testCase.verifyEqual(legacy.fault_scale,fault,'AbsTol',0);
            Phase1ACaseSignalTest.verifySignalsEqual(testCase,formal,legacy);
        end

        function testFaultOnlyDefinitionAndSharedProfile(testCase)
            t = Phase1ACaseSignalTest.timeVector();
            faultOnly = generate_coupling_signals(t,'fault_only',106);
            formal = generate_coupling_signals(t,'Case05_fault_only',106);
            driftThenFault = generate_coupling_signals( ...
                t,'Case06_drift_then_fault',105);

            testCase.verifyEqual(faultOnly.Cs1_pF,10*ones(size(t)),'AbsTol',0);
            testCase.verifyEqual(faultOnly.Cs2_pF,10*ones(size(t)),'AbsTol',0);
            testCase.verifyEqual(faultOnly.fault_scale(t<=3.0), ...
                ones(sum(t<=3.0),1),'AbsTol',0);
            testCase.verifyEqual(faultOnly.fault_scale(t>=3.06), ...
                1.6*ones(sum(t>=3.06),1),'AbsTol',0);
            testCase.verifyEqual(faultOnly.fault_scale, ...
                driftThenFault.fault_scale,'AbsTol',0);
            Phase1ACaseSignalTest.verifySignalsEqual(testCase,formal,faultOnly);
        end
    end

    methods (Static, Access=private)
        function t = timeVector()
            t = (0:2e-5:4.0).';
        end

        function y = smoothStep(t,t0,t1)
            x = min(max((t-t0)/(t1-t0),0),1);
            y = x.^2.*(3-2*x);
        end

        function signals = historicalRandomDrift(t,seed)
            rng(seed);
            dt = median(diff(t));
            s = Phase1ACaseSignalTest.smoothStep(t,0.5,1.0);
            r = movmean(randn(size(t)),max(3,round(0.30/dt)));
            r = (r-mean(r))/(std(r)+eps);
            Cs1 = 10+s.*(1.5*sin(2*pi*0.25*t)+0.5*r);
            Cs2 = 10+s.*(-1.2*sin(2*pi*0.20*t+0.7)+0.4*r);
            signals = struct('Cs1_pF',Cs1,'Cs2_pF',Cs2);
        end

        function verifySignalsEqual(testCase,actual,expected)
            testCase.verifyEqual(actual.t,expected.t,'AbsTol',0);
            testCase.verifyEqual(actual.Cs1_pF,expected.Cs1_pF,'AbsTol',0);
            testCase.verifyEqual(actual.Cs2_pF,expected.Cs2_pF,'AbsTol',0);
            testCase.verifyEqual(actual.fault_scale,expected.fault_scale, ...
                'AbsTol',0);
        end
    end
end
