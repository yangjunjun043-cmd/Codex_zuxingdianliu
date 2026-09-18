function [summaryRow,cycleTable,validation,details] = ...
        evaluate_step4_condition(data,signals,ref,cfg,selfPF,condition)
%EVALUATE_STEP4_CONDITION Evaluate one frozen-mechanism Step 4 condition.

originalM2 = track_coupling_cvff_rls(data,ref,cfg,selfPF,false);
[instrumented,~] = instrument_phase1b_vff_rls( ...
    data,ref,cfg,selfPF,signals.fault_scale,condition.condition_id);

cycleTable = instrumented.mechanism_cycle_table;
c0 = instrumented.c0(:).';
originalBefore = [c0; ...
    originalM2.cycle.Cs1_pF(1:end-1), ...
    originalM2.cycle.Cs2_pF(1:end-1)];
originalAfter = [originalM2.cycle.Cs1_pF,originalM2.cycle.Cs2_pF];
actualDeltaPerCycle = originalAfter-originalBefore;
cycleTable.delta_Cs1_actual_pF = actualDeltaPerCycle(:,1);
cycleTable.delta_Cs2_actual_pF = actualDeltaPerCycle(:,2);
cycleTable.prediction_error_Cs1_pF = ...
    cycleTable.delta_Cs1_RLS_pred_pF-actualDeltaPerCycle(:,1);
cycleTable.prediction_error_Cs2_pF = ...
    cycleTable.delta_Cs2_RLS_pred_pF-actualDeltaPerCycle(:,2);

conditionId = repmat(string(condition.condition_id),height(cycleTable),1);
conditionOrder = repmat(condition.condition_order,height(cycleTable),1);
factorType = repmat(string(condition.factor_type),height(cycleTable),1);
factorValue = repmat(condition.factor_value,height(cycleTable),1);
faultFactorTarget = repmat(condition.fault_factor_target,height(cycleTable),1);
referencePhaseErrorDeg = repmat( ...
    condition.reference_phase_error_deg,height(cycleTable),1);
cycleTable = addvars(cycleTable,conditionId,conditionOrder,factorType,factorValue, ...
    faultFactorTarget,referencePhaseErrorDeg,'Before',1, ...
    'NewVariableNames',{'condition_id','condition_order','factor_type','factor_value', ...
    'fault_factor_target','reference_phase_error_deg'});

t = data.t;
preIdx = t >= 2.60 & t < 2.90;
postIdx = t >= 3.40 & t < 3.80;
preCycle = cycleTable.time_start_s >= 2.60 & cycleTable.time_end_s < 2.90;
rampCycle = cycleTable.r_fault_norm_A > 0 & ...
    cycleTable.time_start_s < 3.06 & cycleTable.time_end_s > 3.00;
postCycle = cycleTable.time_start_s >= 3.06;
steadyCycle = cycleTable.time_start_s >= 3.40 & ...
    cycleTable.time_end_s < 3.80;
faultCycle = cycleTable.r_fault_norm_A > 0;

faultHist = instrumented.fault.hist;
counterfactualHist = instrumented.counterfactual.hist;
lambdaNeutralHist = instrumented.lambda_neutral.hist;
actualChange = parameter_change(originalM2.hist,preIdx,postIdx);
counterfactualChange = parameter_change(counterfactualHist,preIdx,postIdx);
faultInducedChange = parameter_change(faultHist,preIdx,postIdx) - ...
    counterfactualChange;
lambdaNeutralChange = parameter_change(lambdaNeutralHist,preIdx,postIdx);
lambdaContribution = parameter_change(faultHist,preIdx,postIdx) - ...
    lambdaNeutralChange;

irM2 = extract_resistive_current(data,ref,selfPF,originalM2.hist);
irCounterfactual = extract_resistive_current( ...
    data,ref,selfPF,counterfactualHist);
trueFactor = fault_factor(t,data.irB,preIdx,postIdx,cfg.f);
estimatedFactor = fault_factor(t,irM2.B,preIdx,postIdx,cfg.f);
counterfactualFactor = fault_factor( ...
    t,irCounterfactual.B,preIdx,postIdx,cfg.f);

deltaC = faultHist-counterfactualHist;
deltaCouplingB = deltaC(:,1)*1e-12.*(ref.dub-ref.dua) + ...
    deltaC(:,2)*1e-12.*(ref.dub-ref.duc);
rFaultB = (1-1./signals.fault_scale).*data.irB;
[rFaultRms,rFaultPhase] = fundamental_properties( ...
    t(postIdx),rFaultB(postIdx),cfg.f);
[deltaCouplingRms,deltaCouplingPhase] = fundamental_properties( ...
    t(postIdx),deltaCouplingB(postIdx),cfg.f);
correlationMatrix = corrcoef(rFaultB(postIdx),deltaCouplingB(postIdx));
if numel(correlationMatrix) == 4
    falseCompCorrelation = correlationMatrix(1,2);
else
    falseCompCorrelation = NaN;
end

truePre = mean([data.Cs1(preIdx),data.Cs2(preIdx)],1);
estimatePre = mean(originalM2.hist(preIdx,:),1);
preBias = estimatePre-truePre;

summaryRow = struct();
summaryRow.condition_id = string(condition.condition_id);
summaryRow.condition_order = condition.condition_order;
summaryRow.factor_type = string(condition.factor_type);
summaryRow.factor_value = condition.factor_value;
summaryRow.fault_factor_target = condition.fault_factor_target;
summaryRow.reference_phase_error_deg = condition.reference_phase_error_deg;
summaryRow.amplitude_sweep_member = condition.amplitude_sweep_member;
summaryRow.phase_sweep_member = condition.phase_sweep_member;
summaryRow.seed = condition.seed;
summaryRow.SNR_dB = cfg.SNR_dB;
summaryRow.Cs1_true_pre_pF = truePre(1);
summaryRow.Cs2_true_pre_pF = truePre(2);
summaryRow.Cs1_est_pre_pF = estimatePre(1);
summaryRow.Cs2_est_pre_pF = estimatePre(2);
summaryRow.Cs1_pre_estimation_bias_pF = preBias(1);
summaryRow.Cs2_pre_estimation_bias_pF = preBias(2);
summaryRow.eta_geom_ramp = mean(cycleTable.eta_geom(rampCycle));
summaryRow.eta_geom_post = mean(cycleTable.eta_geom(postCycle));
summaryRow.eta_geom_fault_min = min(cycleTable.eta_geom(faultCycle));
summaryRow.eta_geom_fault_max = max(cycleTable.eta_geom(faultCycle));
summaryRow.rank_X_min = min(cycleTable.rank_X);
summaryRow.rank_X_max = max(cycleTable.rank_X);
summaryRow.cond2_X_mean = mean(cycleTable.cond2_X);
summaryRow.DeltaCs1_LS = mean( ...
    cycleTable.delta_Cs1_LS_pred_pF(steadyCycle));
summaryRow.DeltaCs2_LS = mean( ...
    cycleTable.delta_Cs2_LS_pred_pF(steadyCycle));
summaryRow.DeltaCs1_fault_induced = faultInducedChange(1);
summaryRow.DeltaCs2_fault_induced = faultInducedChange(2);
summaryRow.DeltaCs1_actual_M2 = actualChange(1);
summaryRow.DeltaCs2_actual_M2 = actualChange(2);
summaryRow.DeltaCs1_counterfactual_background = counterfactualChange(1);
summaryRow.DeltaCs2_counterfactual_background = counterfactualChange(2);
summaryRow.LS_prediction_error_Cs1_pF = ...
    summaryRow.DeltaCs1_LS-summaryRow.DeltaCs1_fault_induced;
summaryRow.LS_prediction_error_Cs2_pF = ...
    summaryRow.DeltaCs2_LS-summaryRow.DeltaCs2_fault_induced;
summaryRow.LS_prediction_relative_error_Cs1_pct = ...
    100*summaryRow.LS_prediction_error_Cs1_pF / ...
    (abs(summaryRow.DeltaCs1_fault_induced)+eps);
summaryRow.LS_prediction_relative_error_Cs2_pct = ...
    100*summaryRow.LS_prediction_error_Cs2_pF / ...
    (abs(summaryRow.DeltaCs2_fault_induced)+eps);
summaryRow.fault_factor_true = trueFactor;
summaryRow.fault_factor_est = estimatedFactor;
summaryRow.fault_factor_counterfactual_parameters = counterfactualFactor;
summaryRow.fault_retention_error = ...
    100*(estimatedFactor-trueFactor)/(trueFactor+eps);
summaryRow.counterfactual_retention_error_pct = ...
    100*(counterfactualFactor-trueFactor)/(trueFactor+eps);
summaryRow.r_fault_fundamental_RMS_A = rFaultRms;
summaryRow.false_compensation_fundamental_RMS_A = deltaCouplingRms;
summaryRow.false_compensation_ratio = deltaCouplingRms/(rFaultRms+eps);
summaryRow.false_compensation_phase = ...
    wrap_to_180(deltaCouplingPhase-rFaultPhase);
summaryRow.false_compensation_correlation = falseCompCorrelation;
summaryRow.lambda_pre_mean = mean(cycleTable.lambda(preCycle));
summaryRow.lambda_ramp_mean = mean(cycleTable.lambda(rampCycle));
summaryRow.lambda_counterfactual_ramp_mean = ...
    mean(cycleTable.lambda_cf(rampCycle));
summaryRow.lambda_post_mean = mean(cycleTable.lambda(steadyCycle));
summaryRow.lambda_contribution_Cs1_pct = 100*abs(lambdaContribution(1)) / ...
    (abs(faultInducedChange(1))+eps);
summaryRow.lambda_contribution_Cs2_pct = 100*abs(lambdaContribution(2)) / ...
    (abs(faultInducedChange(2))+eps);
summaryRow.rate_limit_cycles = sum( ...
    (cycleTable.rate_limit_active_Cs1 | ...
    cycleTable.rate_limit_active_Cs2) & faultCycle);
summaryRow.projection_cycles = sum( ...
    (cycleTable.projection_active_Cs1 | ...
    cycleTable.projection_active_Cs2) & faultCycle);
summaryRow.state_mismatch_pre_mean = mean( ...
    cycleTable.state_mismatch_rel_after(preCycle));
summaryRow.state_mismatch_ramp_mean = mean( ...
    cycleTable.state_mismatch_rel_after(rampCycle));
summaryRow.state_mismatch_post_mean = mean( ...
    cycleTable.state_mismatch_rel_after(steadyCycle));
summaryRow.E_in_pre_mean_A = mean(cycleTable.E_in_A(preCycle));
summaryRow.E_in_ramp_mean_A = mean(cycleTable.E_in_A(rampCycle));
summaryRow.E_in_post_mean_A = mean(cycleTable.E_in_A(steadyCycle));
summaryRow.E_quad_pre_mean_A = mean(cycleTable.E_quad_A(preCycle));
summaryRow.E_quad_ramp_mean_A = mean(cycleTable.E_quad_A(rampCycle));
summaryRow.E_quad_post_mean_A = mean(cycleTable.E_quad_A(steadyCycle));

validation = validate_condition( ...
    data,originalM2,instrumented,cycleTable);
summaryRow.instrumentation_replay_max = validation.instrumentation_replay_max;
summaryRow.counterfactual_identity_max_A = ...
    validation.counterfactual_identity_max_A;
summaryRow.projection_energy_closure_max = ...
    validation.projection_energy_closure_max;
summaryRow.recursive_update_replay_max_pF = ...
    validation.recursive_update_replay_max_pF;
summaryRow.pre_fault_branch_difference_max_pF = ...
    validation.pre_fault_branch_difference_max_pF;
summaryRow.condition_validation_pass = validation.overall_pass;

details = struct( ...
    'originalM2',originalM2, ...
    'instrumented',instrumented, ...
    'irM2',irM2, ...
    'irCounterfactual',irCounterfactual, ...
    'rFaultB',rFaultB, ...
    'deltaCouplingB',deltaCouplingB);
end

function validation = validate_condition( ...
        data,originalM2,instrumented,cycleTable)
errors = [ ...
    max(abs(originalM2.hist(:,1)-instrumented.fault.hist(:,1))), ...
    max(abs(originalM2.hist(:,2)-instrumented.fault.hist(:,2))), ...
    max(abs(originalM2.cycle.lambda-instrumented.fault.cycle.lambda)), ...
    max(abs(originalM2.cycle.E_in-instrumented.fault.cycle.E_in)), ...
    max(abs(originalM2.cycle.E_quad-instrumented.fault.cycle.E_quad)), ...
    max(abs(originalM2.cycle.base_in-instrumented.fault.cycle.base_in)), ...
    max(abs(originalM2.cycle.gate-instrumented.fault.cycle.gate))];
preFault = data.t < 3.00;
validation = struct();
validation.instrumentation_replay_max = max(errors);
validation.counterfactual_identity_max_A = ...
    max(cycleTable.counterfactual_identity_max_abs_A);
validation.projection_energy_closure_max = ...
    max(cycleTable.projection_energy_closure_relerr);
validation.recursive_update_replay_max_pF = max(abs([ ...
    cycleTable.prediction_error_Cs1_pF; ...
    cycleTable.prediction_error_Cs2_pF]));
validation.pre_fault_branch_difference_max_pF = max(abs( ...
    instrumented.fault.hist(preFault,:) - ...
    instrumented.counterfactual.hist(preFault,:)),[],'all');
validation.observation_alignment = all(cycleTable.n_samples == 1000) && ...
    all(cycleTable.rank_X == 2);
validation.overall_pass = ...
    validation.instrumentation_replay_max <= 1e-12 && ...
    validation.counterfactual_identity_max_A <= 1e-12 && ...
    validation.projection_energy_closure_max <= 1e-10 && ...
    validation.recursive_update_replay_max_pF <= 1e-12 && ...
    validation.pre_fault_branch_difference_max_pF <= 1e-12 && ...
    validation.observation_alignment;
end

function change = parameter_change(cHist,preIdx,postIdx)
change = mean(cHist(postIdx,:),1)-mean(cHist(preIdx,:),1);
end

function value = fault_factor(t,x,preIdx,postIdx,f)
value = fundamental_rms(t(postIdx),x(postIdx),f) / ...
    (fundamental_rms(t(preIdx),x(preIdx),f)+eps);
end

function value = fundamental_rms(t,x,f)
w = 2*pi*f;
coefficients = [sin(w*t),cos(w*t),ones(size(t))]\x;
value = hypot(coefficients(1),coefficients(2))/sqrt(2);
end

function [value,phaseDeg] = fundamental_properties(t,x,f)
w = 2*pi*f;
coefficients = [sin(w*t),cos(w*t),ones(size(t))]\x;
value = hypot(coefficients(1),coefficients(2))/sqrt(2);
phaseDeg = rad2deg(atan2(coefficients(2),coefficients(1)));
end

function value = wrap_to_180(value)
value = mod(value+180,360)-180;
end
