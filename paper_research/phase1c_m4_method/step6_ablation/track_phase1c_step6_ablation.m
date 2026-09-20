function out = track_phase1c_step6_ablation( ...
        data,ref,cfg,self_pF,variant)
%TRACK_PHASE1C_STEP6_ABLATION Isolated M4 component-removal variants.
% Only A_BACKGROUND_ONLY and A_FIXED_LAMBDA are accepted. This function
% never becomes the production method and does not change frozen M4-v0.

variant = upper(string(variant));
if ~isscalar(variant) || ...
        ~ismember(variant,["A_BACKGROUND_ONLY","A_FIXED_LAMBDA"])
    error('Phase1C:Step6Variant','Unsupported Step 6 variant: %s.',variant);
end

t = data.t;
sampleCount = numel(t);
sampleRate = 1/median(diff(t));
samplesPerCycle = round(sampleRate/cfg.f);
regularization = 1e-10;
c = initial_coupling_estimate(data,ref,cfg,self_pF);
hist = repmat(c(:).',sampleCount,1);
initializationIndex = t >= cfg.init_start & t < cfg.init_end;
[X0,~] = coupling_regressor(data,ref,initializationIndex,self_pF);
J = 0.05*(X0'*X0)+1e-8*eye(2);
h = J*c;
initialState = struct('J',J,'h',h,'c',c);
baseIn = NaN;
rows = struct([]);
startIndex = find(t >= cfg.init_end,1);
startIndex = floor((startIndex-1)/samplesPerCycle)*samplesPerCycle+1;
lastFilled = startIndex-1;

for cycleStart = startIndex:samplesPerCycle: ...
        (sampleCount-samplesPerCycle+1)
    index = cycleStart:(cycleStart+samplesPerCycle-1);
    [X,y] = coupling_regressor(data,ref,index,self_pF);
    R = X'*X;
    z = X'*y;
    localLs = (R+regularization*eye(2))\z;
    cPrevious = c;
    JPrevious = J;
    hPrevious = h;
    innovation = norm((localLs-cPrevious)./[5;5]);
    if variant == "A_FIXED_LAMBDA"
        lambda = cfg.lambda_max;
    else
        lambda = cfg.lambda_max-(cfg.lambda_max-cfg.lambda_min)* ...
            min(max(innovation/0.20,0),1);
    end

    [Ein,Equad] = residual_components( ...
        data,ref,index,cPrevious,self_pF,cfg.f);
    if isnan(baseIn), baseIn = Ein; end
    baseInPrevious = baseIn;
    evidence = m4_fault_evidence( ...
        Ein,Equad,baseInPrevious,cfg.gate_ratio,cfg.gate_quad_ratio);
    if variant == "A_BACKGROUND_ONLY"
        phaseWeight = 1;
        score = evidence.background_excess;
        updateWeight = 1/(1+score);
    else
        phaseWeight = evidence.phase_weight;
        score = evidence.score;
        updateWeight = evidence.update_weight;
    end

    JStar = lambda*JPrevious+R;
    hStar = lambda*hPrevious+z;
    JIncrementRaw = JStar-JPrevious;
    hIncrementRaw = hStar-hPrevious;
    cM2Raw = (JStar+regularization*eye(2))\hStar;
    deltaM2Raw = cM2Raw-cPrevious;
    J = JPrevious+updateWeight*JIncrementRaw;
    h = hPrevious+updateWeight*hIncrementRaw;
    cRaw = (J+regularization*eye(2))\h;
    deltaRaw = cRaw-cPrevious;
    rateLimitedDelta = max(min(deltaRaw,cfg.rate_limit_pF_per_cycle), ...
        -cfg.rate_limit_pF_per_cycle);
    cAfterRate = cPrevious+rateLimitedDelta;
    c = min(max(cAfterRate,cfg.coupling_bounds_pF(1)), ...
        cfg.coupling_bounds_pF(2));
    deltaApplied = c-cPrevious;
    rateSuppression = deltaRaw-rateLimitedDelta;
    projectionSuppression = rateLimitedDelta-deltaApplied;

    if Ein < 1.08*baseInPrevious
        baseInStar = 0.985*baseInPrevious+0.015*Ein;
    else
        baseInStar = baseInPrevious;
    end
    baseIncrementCandidate = baseInStar-baseInPrevious;
    baseIn = baseInPrevious+updateWeight*baseIncrementCandidate;

    hist(index,:) = repmat(c(:).',numel(index),1);
    lastFilled = index(end);
    row = struct( ...
        'time_s',t(index(end)), ...
        'Cs1_pF',c(1),'Cs2_pF',c(2), ...
        'lambda',lambda,'innovation_scalar',innovation, ...
        'E_in',Ein,'E_quad',Equad,'base_in',baseIn, ...
        'evidence_ratio_base',evidence.ratio_base, ...
        'evidence_ratio_quad',evidence.ratio_quad, ...
        'evidence_background_excess',evidence.background_excess, ...
        'evidence_phase_weight',phaseWeight, ...
        'fault_evidence_score',score,'update_weight',updateWeight, ...
        'delta_c_m2_raw_1',deltaM2Raw(1), ...
        'delta_c_m2_raw_2',deltaM2Raw(2), ...
        'delta_c_raw_1',deltaRaw(1),'delta_c_raw_2',deltaRaw(2), ...
        'delta_c_applied_1',deltaApplied(1), ...
        'delta_c_applied_2',deltaApplied(2), ...
        'J_increment_norm_raw',norm(JIncrementRaw,'fro'), ...
        'J_increment_norm_applied', ...
            norm(updateWeight*JIncrementRaw,'fro'), ...
        'h_increment_norm_raw',norm(hIncrementRaw), ...
        'h_increment_norm_applied',norm(updateWeight*hIncrementRaw), ...
        'rate_limit_active',logical(any(rateSuppression ~= 0)), ...
        'projection_active',logical(any(projectionSuppression ~= 0)), ...
        'base_in_increment_candidate',baseIncrementCandidate, ...
        'base_in_increment_applied',updateWeight*baseIncrementCandidate);
    if isempty(rows), rows = row; else, rows(end+1,1) = row; end %#ok<AGROW>
end
if lastFilled < sampleCount
    hist(lastFilled+1:sampleCount,:) = ...
        repmat(c(:).',sampleCount-lastFilled,1);
end
out = struct('hist',hist,'cycle',struct2table(rows), ...
    'initial_state',initialState, ...
    'final_state',struct('J',J,'h',h,'c',c,'baseIn',baseIn), ...
    'ablation_variant',variant);
end

function [Ein,Equad] = residual_components( ...
        data,ref,index,c,self_pF,f)
[X,y] = coupling_regressor(data,ref,index,self_pF);
residual = y-X*c;
pointsPerPhase = numel(index);
time = data.t(index);
omega = 2*pi*f;
phase = [2*pi/3,0,-2*pi/3];
EinPerPhase = zeros(3,1);
EquadPerPhase = zeros(3,1);
for phaseIndex = 1:3
    rows = (phaseIndex-1)*pointsPerPhase+1:phaseIndex*pointsPerPhase;
    phaseResidual = residual(rows);
    inPhaseBasis = [ ...
        sin(omega*time+ref.phi1+phase(phaseIndex)), ...
        sin(3*omega*time+ref.phi3)];
    quadratureBasis = [ ...
        cos(omega*time+ref.phi1+phase(phaseIndex)), ...
        cos(3*omega*time+ref.phi3)];
    basis = [inPhaseBasis,quadratureBasis,ones(pointsPerPhase,1)];
    coefficients = basis\phaseResidual;
    EinPerPhase(phaseIndex) = ...
        sqrt(mean((inPhaseBasis*coefficients(1:2)).^2));
    EquadPerPhase(phaseIndex) = ...
        sqrt(mean((quadratureBasis*coefficients(3:4)).^2));
end
Ein = sqrt(mean(EinPerPhase.^2));
Equad = sqrt(mean(EquadPerPhase.^2));
end
