function signals = build_phase1c_case07_signals(t,definition,branch)
%BUILD_PHASE1C_CASE07_SIGNALS Build frozen Case07 truth/input schedules.

t = t(:);
branch = upper(string(branch));
if ~isscalar(branch) || ~ismember(branch,definition.branches)
    error('Phase1C:Step5Branch','Branch must be F or CF.');
end

driftProgress = smooth_step(t,definition.drift.start_s, ...
    definition.drift.end_s);
Cs1 = definition.drift.Cs1_initial_pF+ ...
    definition.drift.Cs1_change_pF*driftProgress;
Cs2 = definition.drift.Cs2_initial_pF+ ...
    definition.drift.Cs2_change_pF*driftProgress;

faultScale = ones(size(t));
if branch == "F"
    rampUp = smooth_step(t,definition.fault.onset_s, ...
        definition.fault.ramp_up_end_s);
    rampDown = smooth_step(t,definition.fault.plateau_end_s, ...
        definition.fault.clear_s);
    faultProgress = min(rampUp,1-rampDown);
    faultScale = 1+(definition.fault.factor-1)*faultProgress;
end

signals = struct( ...
    't',t, ...
    'Cs1_pF',Cs1, ...
    'Cs2_pF',Cs2, ...
    'fault_scale',faultScale, ...
    'drift_progress',driftProgress, ...
    'branch',branch);
validate_signals(signals,definition);
end

function y = smooth_step(t,startTime,endTime)
x = min(max((t-startTime)/(endTime-startTime),0),1);
y = x.^2.*(3-2*x);
end

function validate_signals(signals,definition)
t = signals.t;
beforeFault = t < definition.fault.onset_s;
afterClear = t >= definition.fault.clear_s;
if any(signals.Cs1_pF < 10-1e-12) || ...
        any(signals.Cs1_pF > 13+1e-12) || ...
        any(signals.Cs2_pF < 8-1e-12) || ...
        any(signals.Cs2_pF > 10+1e-12)
    error('Phase1C:Step5DriftTruth','Case07 drift truth is invalid.');
end
if signals.branch == "F"
    if any(signals.fault_scale(beforeFault) ~= 1) || ...
            any(abs(signals.fault_scale(afterClear)-1) > 1e-12) || ...
            abs(max(signals.fault_scale)-definition.fault.factor) > 1e-12
        error('Phase1C:Step5FaultTruth','Case07 fault schedule is invalid.');
    end
elseif any(signals.fault_scale ~= 1)
    error('Phase1C:Step5CounterfactualTruth', ...
        'Counterfactual fault scale must remain one.');
end
end
