classdef Phase1AAlgorithmDispatcherTest < matlab.unittest.TestCase
    %PHASE1AALGORITHMDISPATCHERTEST Phase 1A Step 3 dispatcher tests.

    properties (TestParameter)
        illegalMode = struct( ...
            'reservedLowerMode',"M1", ...
            'reservedHigherMode',"M5", ...
            'unknownMode',"UNKNOWN", ...
            'emptyMode',"")
    end

    methods (TestClassSetup)
        function addProjectPath(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture( ...
                matlab.unittest.fixtures.PathFixture(root));
        end
    end

    methods (Test)
        function testRegistryContainsFrozenModesAndM4Extension(testCase)
            registry = phase1a_algorithm_registry();

            testCase.verifyEqual( ...
                registry.algorithm_mode,["M0";"M2";"M3";"M4"]);
            testCase.verifyTrue(all(registry.enabled));
            testCase.verifyEqual(registry.algorithm_mode( ...
                registry.include_in_frozen_baseline),["M0";"M2";"M3"]);
            testCase.verifyTrue( ...
                registry.continuous_update_weight(4));
            testCase.verifyTrue(registry.direction_diagnostics(4));
            testCase.verifyFalse(registry.hard_fault_gate(4));
            testCase.verifyEqual(height(registry),4);
        end

        function testM0UsesInitialEstimateAndFrozenHistory(testCase)
            [data,ref,cfg,self_pF] = ...
                Phase1AAlgorithmDispatcherTest.fixtureData();
            expectedC0 = initial_coupling_estimate(data,ref,cfg,self_pF);

            result = run_phase1a_algorithm("M0",data,ref,cfg,self_pF);

            testCase.verifyEqual(result.algorithm_mode,"M0");
            testCase.verifyEqual(result.c0,expectedC0,'AbsTol',0);
            testCase.verifyEqual(result.cHist, ...
                repmat(expectedC0(:).',numel(data.t),1),'AbsTol',0);
            testCase.verifyEqual(result.tracker,struct());
            Phase1AAlgorithmDispatcherTest.verifyResultShape(testCase,result,data);
        end

        function testM2ReturnsExistingTrackerAndCurrent(testCase)
            [data,ref,cfg,self_pF] = ...
                Phase1AAlgorithmDispatcherTest.fixtureData();

            result = run_phase1a_algorithm("M2",data,ref,cfg,self_pF);

            testCase.verifyEqual(result.algorithm_mode,"M2");
            testCase.verifyEqual(result.cHist,result.tracker.hist,'AbsTol',0);
            testCase.verifyTrue(istable(result.tracker.cycle));
            Phase1AAlgorithmDispatcherTest.verifyResultShape(testCase,result,data);
        end

        function testM3ReturnsExistingTrackerAndCurrent(testCase)
            [data,ref,cfg,self_pF] = ...
                Phase1AAlgorithmDispatcherTest.fixtureData();

            result = run_phase1a_algorithm("M3",data,ref,cfg,self_pF);

            testCase.verifyEqual(result.algorithm_mode,"M3");
            testCase.verifyEqual(result.cHist,result.tracker.hist,'AbsTol',0);
            testCase.verifyTrue(istable(result.tracker.cycle));
            Phase1AAlgorithmDispatcherTest.verifyResultShape(testCase,result,data);
        end

        function testM4ReturnsIndependentTrackerAndCurrent(testCase)
            [data,ref,cfg,self_pF] = ...
                Phase1AAlgorithmDispatcherTest.fixtureData();

            result = run_phase1a_algorithm("M4",data,ref,cfg,self_pF);

            testCase.verifyEqual(result.algorithm_mode,"M4");
            testCase.verifyEqual(result.cHist,result.tracker.hist,'AbsTol',0);
            testCase.verifyTrue(istable(result.tracker.cycle));
            testCase.verifyTrue(ismember( ...
                'update_weight', ...
                result.tracker.cycle.Properties.VariableNames));
            Phase1AAlgorithmDispatcherTest.verifyResultShape(testCase,result,data);
        end

        function testDispatcherIsThinAndUsesExactMappings(testCase)
            source = fileread(which('run_phase1a_algorithm'));

            testCase.verifyNotEmpty(regexp(source, ...
                'initial_coupling_estimate\(data,ref,cfg,self_pF\)', ...
                'once'));
            testCase.verifyNotEmpty(regexp(source, ...
                'track_coupling_cvff_rls\(data,ref,cfg,self_pF,false\)', ...
                'once'));
            testCase.verifyNotEmpty(regexp(source, ...
                'track_coupling_cvff_rls\(data,ref,cfg,self_pF,true\)', ...
                'once'));
            testCase.verifyNotEmpty(regexp(source, ...
                'track_coupling_m4_weighted_rls', 'once'));
            testCase.verifyEqual(numel(regexp(source, ...
                'extract_resistive_current\(data,ref,self_pF,cHist\)', ...
                'match')),1);
            forbiddenMath = [ ...
                '\<(lambda_min|lambda_max|gate_ratio|gate_quad_ratio|' ...
                'gate_hold_cycles|rate_limit_pF_per_cycle|' ...
                'coupling_bounds_pF|E_in|E_quad|baseIn)\>|' ...
                '(?m)^\s*[Jh]\s*='];
            testCase.verifyEmpty(regexp(source,forbiddenMath,'once'));
        end

        function testIllegalModeIsRejected(testCase,illegalMode)
            testCase.verifyError(@() run_phase1a_algorithm( ...
                illegalMode,struct(),struct(),struct(),[]), ...
                'Phase1A:UnknownAlgorithmMode');
        end
    end

    methods (Static, Access=private)
        function [data,ref,cfg,self_pF] = fixtureData()
            cfg = patent_default_config();
            t = (0:2e-4:1.2).';
            w = 2*pi*cfg.f;
            voltageAmplitude = sqrt(2)*cfg.Uph;
            phase = [2*pi/3,0,-2*pi/3];
            ref = struct();
            ref.ua = voltageAmplitude*sin(w*t+phase(1));
            ref.ub = voltageAmplitude*sin(w*t+phase(2));
            ref.uc = voltageAmplitude*sin(w*t+phase(3));
            ref.dua = w*voltageAmplitude*cos(w*t+phase(1));
            ref.dub = w*voltageAmplitude*cos(w*t+phase(2));
            ref.duc = w*voltageAmplitude*cos(w*t+phase(3));
            ref.phi1 = 0;
            ref.phi3 = 0;
            self_pF = repmat(cfg.Cself_pF,1,3);
            cTrue = [12,8];
            resistiveAmplitude = sqrt(2)*cfg.moa_Iref_A;
            irA = resistiveAmplitude*sin(w*t+phase(1));
            irB = resistiveAmplitude*sin(w*t+phase(2));
            irC = resistiveAmplitude*sin(w*t+phase(3));
            ia = self_pF(1)*1e-12.*ref.dua + ...
                cTrue(1)*1e-12.*(ref.dua-ref.dub) + irA;
            ib = self_pF(2)*1e-12.*ref.dub + ...
                cTrue(1)*1e-12.*(ref.dub-ref.dua) + ...
                cTrue(2)*1e-12.*(ref.dub-ref.duc) + irB;
            ic = self_pF(3)*1e-12.*ref.duc + ...
                cTrue(2)*1e-12.*(ref.duc-ref.dub) + irC;
            data = struct('t',t,'ia',ia,'ib',ib,'ic',ic);
        end

        function verifyResultShape(testCase,result,data)
            expectedFields = { ...
                'algorithm_mode','algorithm_name','c0', ...
                'cHist','ir','tracker'};
            testCase.verifyEqual(fieldnames(result),expectedFields.');
            testCase.verifySize(result.c0,[2,1]);
            testCase.verifySize(result.cHist,[numel(data.t),2]);
            testCase.verifyEqual(fieldnames(result.ir),{'A';'B';'C'});
            testCase.verifySize(result.ir.A,size(data.t));
            testCase.verifySize(result.ir.B,size(data.t));
            testCase.verifySize(result.ir.C,size(data.t));
        end
    end
end
