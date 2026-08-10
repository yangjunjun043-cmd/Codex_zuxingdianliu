function out = track_coupling_cvff_rls(data, ref, cfg, self_pF, enableGate)
%TRACK_COUPLING_CVFF_RLS  带投影约束、变遗忘因子和故障冻结门控的RLS。
if nargin < 5, enableGate = true; end

t = data.t; N = numel(t); fs = 1/median(diff(t)); Nc = round(fs/cfg.f);
c = initial_coupling_estimate(data,ref,cfg,self_pF);
hist = repmat(c(:).',N,1);
idx0 = t >= cfg.init_start & t < cfg.init_end;
[X0,~] = coupling_regressor(data,ref,idx0,self_pF);
J = 0.05*(X0'*X0)+1e-8*eye(2); h = J*c;
baseIn = NaN; gateHold = 0; rows = [];
start = find(t >= cfg.init_end,1); start = floor((start-1)/Nc)*Nc+1;
lastFilled = start-1;
for s = start:Nc:(N-Nc+1)
    idx = s:(s+Nc-1);
    [X,y] = coupling_regressor(data,ref,idx,self_pF);
    R = X'*X; z = X'*y;
    cls = (R+1e-10*eye(2))\z;
    innovation = norm((cls-c)./[5;5]);
    lambda = cfg.lambda_max-(cfg.lambda_max-cfg.lambda_min)*min(max(innovation/0.20,0),1);
    [Ein,Equad] = residual_components(data,ref,idx,c,self_pF,cfg.f);
    if isnan(baseIn), baseIn = Ein; end
    isFault = enableGate && t(idx(end))>1.0 && Ein>cfg.gate_ratio*baseIn && Ein>cfg.gate_quad_ratio*Equad;
    if isFault, gateHold = max(gateHold,cfg.gate_hold_cycles); end
    if gateHold>0
        gate = 1; gateHold = gateHold-1;
    else
        gate = 0;
        J = lambda*J+R; h = lambda*h+z;
        cNew = (J+1e-10*eye(2))\h;
        dc = max(min(cNew-c,cfg.rate_limit_pF_per_cycle),-cfg.rate_limit_pF_per_cycle);
        c = c+dc;
        c = min(max(c,cfg.coupling_bounds_pF(1)),cfg.coupling_bounds_pF(2));
        if Ein < 1.08*baseIn, baseIn = 0.985*baseIn+0.015*Ein; end
    end
    hist(idx,:) = repmat(c(:).',numel(idx),1);
    lastFilled = idx(end);
    rows = [rows; t(idx(end)),c(:).',lambda,Ein,Equad,gate,baseIn]; %#ok<AGROW>
end
if lastFilled < N
    hist(lastFilled+1:N,:) = repmat(c(:).',N-lastFilled,1);
end
out.hist = hist;
out.cycle = array2table(rows,'VariableNames', ...
    {'time_s','Cs1_pF','Cs2_pF','lambda','E_in','E_quad','gate','base_in'});
end

function [Ein,Equad] = residual_components(data,ref,idx,c,self_pF,f)
[X,y] = coupling_regressor(data,ref,idx,self_pF);
e = y-X*c; n = numel(idx); tt = data.t(idx); w = 2*pi*f;
phase = [2*pi/3,0,-2*pi/3]; EinP=zeros(3,1); EqP=zeros(3,1);
for p=1:3
    ep = e((p-1)*n+1:p*n);
    Bin = [sin(w*tt+ref.phi1+phase(p)), sin(3*w*tt+ref.phi3)];
    Bq  = [cos(w*tt+ref.phi1+phase(p)), cos(3*w*tt+ref.phi3)];
    B = [Bin,Bq,ones(n,1)]; coef = B\ep;
    EinP(p)=sqrt(mean((Bin*coef(1:2)).^2)); EqP(p)=sqrt(mean((Bq*coef(3:4)).^2));
end
Ein=sqrt(mean(EinP.^2)); Equad=sqrt(mean(EqP.^2));
end
