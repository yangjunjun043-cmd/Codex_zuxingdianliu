function c0 = initial_coupling_estimate(data, ref, cfg, self_pF)
idx = data.t >= cfg.init_start & data.t < cfg.init_end;
[X,y] = coupling_regressor(data, ref, idx, self_pF);
c0 = (X'*X + 1e-10*eye(2)) \ (X'*y);
end
