function metrics = m5_step4_direction_metrics(estimate,truth,index)
%M5_STEP4_DIRECTION_METRICS Fixed-direction parameter tracking metrics.

arguments
    estimate (:,2) double {mustBeReal,mustBeFinite}
    truth (:,2) double {mustBeReal,mustBeFinite}
    index (:,1) logical
end

if size(estimate,1) ~= size(truth,1) || numel(index) ~= size(truth,1)
    error('M5Step4:DirectionMetricSize', ...
        'Estimate, truth, and index lengths must match.');
end
if ~any(index)
    error('M5Step4:DirectionMetricWindow', ...
        'Direction-resolved metric window is empty.');
end

faultDirection = [1;-1]/sqrt(2);
faultProjector = faultDirection*faultDirection.';
perpendicularProjector = eye(2)-faultProjector;
errorVector = estimate(index,:)-truth(index,:);
parallelError = errorVector*faultProjector;
perpendicularError = errorVector*perpendicularProjector;
reconstructed = parallelError+perpendicularError;
totalEnergy = sum(errorVector.^2,2);
parallelEnergy = sum(parallelError.^2,2);
perpendicularEnergy = sum(perpendicularError.^2,2);

metrics = struct( ...
    'fault_direction',faultDirection, ...
    'P_f',faultProjector, ...
    'P_perp',perpendicularProjector, ...
    'RMSE_total_pF',sqrt(mean(totalEnergy)), ...
    'RMSE_parallel_pF',sqrt(mean(parallelEnergy)), ...
    'RMSE_perp_pF',sqrt(mean(perpendicularEnergy)), ...
    'decomposition_max_abs_pF', ...
        max(abs(errorVector-reconstructed),[],'all'), ...
    'energy_closure_max_abs_pF2', ...
        max(abs(totalEnergy-parallelEnergy-perpendicularEnergy)));
end
