classdef M5Step4ReadinessTest < matlab.unittest.TestCase
    %M5STEP4READINESSTEST Readiness-only tests; no performance execution.

    properties (Constant)
        AbsTol = 1e-12
    end

    methods (TestClassSetup)
        function addProjectPaths(testCase)
            testRoot = fileparts(mfilename('fullpath'));
            matlabRoot = fileparts(testRoot);
            projectRoot = fileparts(matlabRoot);
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                matlabRoot));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(projectRoot,'paper_research', ...
                'phase_m5_directional_update','step3_preregistration')));
        end
    end

    methods (Test)
        function directionDecompositionIdentity(testCase)
            estimate = [2 4;5 -1;0.25 0.75];
            truth = [1 3;4 1;0 0];
            metrics = m5_step4_direction_metrics( ...
                estimate,truth,true(3,1));

            testCase.verifyLessThanOrEqual( ...
                metrics.decomposition_max_abs_pF,testCase.AbsTol);
            testCase.verifyLessThanOrEqual( ...
                metrics.energy_closure_max_abs_pF2,testCase.AbsTol);
        end

        function analyticDirectionMetrics(testCase)
            estimate = [1 -1;1 1];
            truth = zeros(2,2);
            metrics = m5_step4_direction_metrics( ...
                estimate,truth,true(2,1));

            testCase.verifyEqual(metrics.RMSE_total_pF,sqrt(2), ...
                AbsTol=testCase.AbsTol);
            testCase.verifyEqual(metrics.RMSE_parallel_pF,1, ...
                AbsTol=testCase.AbsTol);
            testCase.verifyEqual(metrics.RMSE_perp_pF,1, ...
                AbsTol=testCase.AbsTol);
        end

        function registeredMatrixIsComplete(testCase)
            path = M5Step4ReadinessTest.matrixPath();
            audit = m5_step4_validate_matrix(path);

            testCase.verifyTrue(audit.pass);
            testCase.verifyEqual(audit.row_count,98);
            testCase.verifyEqual(audit.case_count,14);
            testCase.verifyEqual(audit.reuse_counts,[24 6 68]);
            testCase.verifyEqual(audit.expected_sim_calls,34);
        end

        function fixedGeometryNorms(testCase)
            audit = m5_step4_validate_matrix( ...
                M5Step4ReadinessTest.matrixPath());

            testCase.verifyTrue(audit.geometry_pass);
            testCase.verifyEqual(audit.block_case_counts,[2 6 6]);
        end

        function m5CycleSchemaMapping(testCase)
            cfg = patent_default_config();
            cycle = M5Step4ReadinessTest.syntheticM5Cycle();
            diagnostics = m5_step4_cycle_diagnostics( ...
                "M5_FULL",cycle,0,1,cfg);

            testCase.verifyEqual(diagnostics.schema_mapping, ...
                "M5_STEP2_EXPLICIT_FIELDS");
            testCase.verifyEqual(diagnostics.cycle_count,2);
            testCase.verifyEqual(diagnostics.near_zero_update_cycles,1);
            testCase.verifyTrue(isfinite( ...
                diagnostics.raw_parallel_update_energy_pF2));
        end
    end

    methods (Static, Access=private)
        function path = matrixPath()
            matlabRoot = fileparts(fileparts(mfilename('fullpath')));
            projectRoot = fileparts(matlabRoot);
            path = fullfile(projectRoot,'paper_research', ...
                'phase_m5_directional_update','step3_preregistration', ...
                'M5_STEP3_EXPERIMENT_MATRIX.csv');
        end

        function cycle = syntheticM5Cycle()
            time_s = [0.25;0.75];
            gate = [0;1]; w_REW = [1;0.2]; selected_weight = w_REW;
            rate_limit_active = [false;true];
            projection_active = [false;false];
            parallel_norm = [1;0]; perp_norm = [0;2];
            raw_angle_to_df_deg = [0;NaN];
            protected_angle_to_df_deg = [0;90];
            post_rate_angle_to_df_deg = [0;90];
            post_projection_angle_to_df_deg = [0;90];
            delta_after_projection_Cs1 = [1;1];
            delta_after_projection_Cs2 = [-1;1];
            cycle = table(time_s,gate,w_REW,selected_weight, ...
                rate_limit_active,projection_active,parallel_norm, ...
                perp_norm,raw_angle_to_df_deg, ...
                protected_angle_to_df_deg,post_rate_angle_to_df_deg, ...
                post_projection_angle_to_df_deg, ...
                delta_after_projection_Cs1, ...
                delta_after_projection_Cs2);
        end
    end
end
