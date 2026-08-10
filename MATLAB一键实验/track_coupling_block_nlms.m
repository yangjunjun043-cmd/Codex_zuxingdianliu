function out = track_coupling_block_nlms(data, ref, cfg, self_pF)
%TRACK_COUPLING_BLOCK_NLMS  一周期块归一化LMS，作为对比算法。

t = data.t; N = numel(t); fs = 1/median(diff(t)); Nc = round(fs/cfg.f);
c = initial_coupling_estimate(data,ref,cfg,self_pF);
hist = repmat(c(:).',N,1);
start = find(t >= cfg.init_end,1); start = floor((start-1)/Nc)*Nc+1;
rows = [];
lastFilled = start-1;
for s = start:Nc:(N-Nc+1)
    idx = s:(s+Nc-1);
    [X,y] = coupling_regressor(data,ref,idx,self_pF);
    e = y-X*c;
    dc = (X'*X+1e-10*eye(2))\(X'*e);
    dc = max(min(cfg.nlms_mu*dc,1.5),-1.5);
    c = c+dc;
    c = min(max(c,cfg.coupling_bounds_pF(1)),cfg.coupling_bounds_pF(2));
    hist(idx,:) = repmat(c(:).',numel(idx),1);
    lastFilled = idx(end);
    rows = [rows; t(idx(end)), c(:).']; %#ok<AGROW>
end
if lastFilled < N
    hist(lastFilled+1:N,:) = repmat(c(:).',N-lastFilled,1);
end
out.hist = hist;
out.cycle = array2table(rows,'VariableNames',{'time_s','Cs1_pF','Cs2_pF'});
end
