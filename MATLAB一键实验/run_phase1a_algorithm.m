function result = run_phase1a_algorithm(algorithm_mode,data,ref,cfg,self_pF)
%RUN_PHASE1A_ALGORITHM Dispatch one existing Phase 1A baseline algorithm.

mode = normalize_algorithm_mode(algorithm_mode);
registry = phase1a_algorithm_registry();
match = registry.enabled & registry.algorithm_mode == mode;
if nnz(match) ~= 1
    error('Phase1A:UnknownAlgorithmMode', ...
        'Unsupported Phase 1A algorithm_mode: "%s".',mode);
end

c0 = initial_coupling_estimate(data,ref,cfg,self_pF);
tracker = struct();
switch mode
    case "M0"
        cHist = repmat(c0(:).',numel(data.t),1);
    case "M2"
        tracker = track_coupling_cvff_rls(data,ref,cfg,self_pF,false);
        cHist = tracker.hist;
    case "M3"
        tracker = track_coupling_cvff_rls(data,ref,cfg,self_pF,true);
        cHist = tracker.hist;
    case "M4"
        tracker = track_coupling_m4_weighted_rls( ...
            data,ref,cfg,self_pF);
        cHist = tracker.hist;
end

ir = extract_resistive_current(data,ref,self_pF,cHist);
result = struct( ...
    'algorithm_mode',mode, ...
    'algorithm_name',registry.algorithm_name(match), ...
    'c0',c0, ...
    'cHist',cHist, ...
    'ir',ir, ...
    'tracker',tracker);
end

function mode = normalize_algorithm_mode(algorithm_mode)
if ~(ischar(algorithm_mode) || isstring(algorithm_mode))
    error('Phase1A:UnknownAlgorithmMode', ...
        'algorithm_mode must identify one enabled Phase 1A algorithm.');
end
mode = upper(strtrim(string(algorithm_mode)));
if ~isscalar(mode) || ismissing(mode) || strlength(mode) == 0
    error('Phase1A:UnknownAlgorithmMode', ...
        'algorithm_mode must identify one enabled Phase 1A algorithm.');
end
end
