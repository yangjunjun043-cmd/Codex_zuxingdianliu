function ir = extract_resistive_current(data,ref,self_pF,cHist)
dua=ref.dua; dub=ref.dub; duc=ref.duc;
Cs1=cHist(:,1); Cs2=cHist(:,2);
capA=self_pF(1)*1e-12.*dua + Cs1*1e-12.*(dua-dub);
capB=self_pF(2)*1e-12.*dub + Cs1*1e-12.*(dub-dua) + Cs2*1e-12.*(dub-duc);
capC=self_pF(3)*1e-12.*duc + Cs2*1e-12.*(duc-dub);
ir.A=data.ia-capA; ir.B=data.ib-capB; ir.C=data.ic-capC;
end
