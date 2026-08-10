function ref = reconstruct_refs_from_b(t, ub, f, init_start, init_end, phase_error_deg)
%RECONSTRUCT_REFS_FROM_B  只利用B相电压构造三相基波/三次谐波正交参考。

t = t(:); ub = ub(:);
w = 2*pi*f;
idx = t >= init_start & t < init_end;
H = [sin(w*t(idx)), cos(w*t(idx)), sin(3*w*t(idx)), cos(3*w*t(idx)), ones(sum(idx),1)];
beta = H \ ub(idx);
A1 = hypot(beta(1), beta(2));
A3 = hypot(beta(3), beta(4));
phi1 = atan2(beta(2), beta(1)) + deg2rad(phase_error_deg);
phi3 = atan2(beta(4), beta(3)) + 3*deg2rad(phase_error_deg);

th1 = w*t + phi1;
th3 = 3*w*t + phi3;
ref.ua = A1*sin(th1 + 2*pi/3) + A3*sin(th3);
ref.ub = A1*sin(th1)          + A3*sin(th3);
ref.uc = A1*sin(th1 - 2*pi/3) + A3*sin(th3);
ref.dua = w*A1*cos(th1 + 2*pi/3) + 3*w*A3*cos(th3);
ref.dub = w*A1*cos(th1)          + 3*w*A3*cos(th3);
ref.duc = w*A1*cos(th1 - 2*pi/3) + 3*w*A3*cos(th3);
ref.A1 = A1; ref.A3 = A3; ref.phi1 = phi1; ref.phi3 = phi3;
end
