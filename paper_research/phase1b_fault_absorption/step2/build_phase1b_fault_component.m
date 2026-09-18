function [rFault,rFaultB] = build_phase1b_fault_component( ...
        faultScale,irBTrue,idx)
%BUILD_PHASE1B_FAULT_COMPONENT Recover the strict Case05 fault increment.

g = faultScale(idx);
if any(~isfinite(g)) || any(g <= 0)
    error('Phase1B:InvalidFaultScale', ...
        'Fault scale must be finite and strictly positive.');
end
irB = irBTrue(idx);
rFaultB = (1-1./g).*irB;
n = numel(idx);
rFault = [zeros(n,1);rFaultB;zeros(n,1)];
end
