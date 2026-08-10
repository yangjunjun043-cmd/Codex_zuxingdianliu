function [X, y] = coupling_regressor(data, ref, idx, self_pF)
%COUPLING_REGRESSOR  构造Cs1、Cs2的三相联合回归矩阵。

dua = ref.dua(idx); dub = ref.dub(idx); duc = ref.duc(idx);
n = numel(dub);
X = zeros(3*n,2);
X(1:n,1) = (dua-dub)*1e-12;
X(n+1:2*n,1) = (dub-dua)*1e-12;
X(n+1:2*n,2) = (dub-duc)*1e-12;
X(2*n+1:3*n,2) = (duc-dub)*1e-12;
y = [data.ia(idx)-self_pF(1)*1e-12.*dua; ...
     data.ib(idx)-self_pF(2)*1e-12.*dub; ...
     data.ic(idx)-self_pF(3)*1e-12.*duc];
end
