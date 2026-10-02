function result = run_phase2p1a_direct_ratio_rejection()
%RUN_PHASE2P1A_DIRECT_RATIO_REJECTION Audit a rejected aging mapping.
%
% This calculation reads the frozen Phase 2-P0 one-cycle healthy waveform.
% It does not load or simulate a Simulink model, invoke M0/M2/M3/M4, or run
% Case05-P/Case06-P. The mapped parameters are diagnostic candidates only.

scriptDir = fileparts(mfilename('fullpath'));
phaseDir = fileparts(scriptDir);
inputPath = fullfile(phaseDir,'analysis_outputs', ...
    'health_waveform_one_cycle.csv');
outputDir = fullfile(phaseDir,'analysis_outputs');
assert(isfile(inputPath),'Phase2P1A:MissingP0Waveform', ...
    'Frozen Phase 2-P0 waveform is missing: %s',inputPath);

waveform = readtable(inputPath);
requiredVariables = ["uB_V","irB_original_A"];
assert(all(ismember(requiredVariables,string(waveform.Properties.VariableNames))), ...
    'Phase2P1A:InvalidP0Waveform', ...
    'Phase 2-P0 waveform does not contain the required variables.');

% Frozen source-level values: Fu et al. (2024), Sample B, Table 2.
sourceBeforeE1mAVPerMm = 305.82;
sourceAfterE1mAVPerMm = 300.38;
sourceBeforeAlpha = 63.54;
sourceAfterAlpha = 53.71;
sourceBeforeLeakageUA = 1.50;
sourceAfterLeakageUA = 1.70;

rhoE = sourceAfterE1mAVPerMm/sourceBeforeE1mAVPerMm;
rhoAlpha = sourceAfterAlpha/sourceBeforeAlpha;
rhoLeakage = sourceAfterLeakageUA/sourceBeforeLeakageUA;

% Current healthy model baseline fixed by Phase 2-P0.
alpha0 = 6.0;
Uref0V = 63.5085296e3;
IrefA = 0.3e-3;

% Rejected diagnostic candidate. These values are not model parameters.
candidateAlphaA = alpha0*rhoAlpha;
candidateUrefAV = Uref0V*rhoE;

absVoltage = abs(waveform.uB_V);
absCurrent = abs(waveform.irB_original_A);
voltagePeakV = max(absVoltage);
currentPeakA = max(absCurrent);
qualificationMask = absVoltage >= 0.01*voltagePeakV & ...
    absCurrent >= 0.01*currentPeakA & ...
    waveform.uB_V.*waveform.irB_original_A > 0;
assert(any(qualificationMask),'Phase2P1A:EmptyQualificationRange', ...
    'No samples remain under the frozen Phase 2-P0 zero-exclusion rule.');
qualifiedVoltageMinV = min(absVoltage(qualificationMask));
qualifiedVoltageMaxV = voltagePeakV;

crossingVoltageV = exp((candidateAlphaA*log(candidateUrefAV) - ...
    alpha0*log(Uref0V))/(candidateAlphaA-alpha0));
qAtPeak = voltage_ratio(voltagePeakV,alpha0,Uref0V, ...
    candidateAlphaA,candidateUrefAV);
qAtQualifiedMin = voltage_ratio(qualifiedVoltageMinV,alpha0,Uref0V, ...
    candidateAlphaA,candidateUrefAV);

qualifiedVoltageV = linspace(qualifiedVoltageMinV, ...
    qualifiedVoltageMaxV,2001).';
qualifiedQ = voltage_ratio(qualifiedVoltageV,alpha0,Uref0V, ...
    candidateAlphaA,candidateUrefAV);
qQualifiedMin = min(qualifiedQ);
qQualifiedMax = max(qualifiedQ);

% Include V=0 in the exported actual range. q(0) is undefined because both
% currents are zero; with alpha_a < alpha_0, lim_{V->0+} q(V) = Inf.
voltageV = linspace(0,voltagePeakV,4001).';
healthyCurrentA = current_magnitude(voltageV,IrefA,Uref0V,alpha0);
agedCandidateCurrentA = current_magnitude(voltageV,IrefA, ...
    candidateUrefAV,candidateAlphaA);
q = NaN(size(voltageV));
positive = voltageV > 0;
q(positive) = voltage_ratio(voltageV(positive),alpha0,Uref0V, ...
    candidateAlphaA,candidateUrefAV);
isQualified = voltageV >= qualifiedVoltageMinV;
agedLessThanHealthy = agedCandidateCurrentA < healthyCurrentA;

curve = table(voltageV,voltageV/Uref0V,healthyCurrentA, ...
    agedCandidateCurrentA,q,isQualified,agedLessThanHealthy, ...
    'VariableNames',{'voltage_V','voltage_pu_Uref0', ...
    'healthy_current_A','aged_candidate_current_A','q', ...
    'in_P0_qualification_range','aged_current_less_than_healthy'});

summary = table(rhoE,rhoAlpha,rhoLeakage,alpha0,Uref0V, ...
    candidateAlphaA,candidateUrefAV,voltagePeakV, ...
    qualifiedVoltageMinV,qualifiedVoltageMaxV,qQualifiedMin, ...
    qQualifiedMax,crossingVoltageV,qAtPeak,qAtQualifiedMin, ...
    double(candidateAlphaA < alpha0), ...
    double(crossingVoltageV < voltagePeakV),1, ...
    'VariableNames',{'rho_E','rho_alpha','rho_IL','alpha0', ...
    'Uref0_V','rejected_candidate_alpha_a', ...
    'rejected_candidate_Uref_a_V','actual_voltage_peak_V', ...
    'qualified_voltage_min_V','qualified_voltage_max_V', ...
    'q_min_qualified','q_max_qualified','q_equals_1_voltage_V', ...
    'q_at_voltage_peak','q_at_qualified_voltage_min', ...
    'alpha_a_less_than_alpha0','aged_below_healthy_at_high_voltage', ...
    'direct_ratio_mapping_rejected'});

writetable(curve,fullfile(outputDir, ...
    'direct_ratio_mapping_rejected_curve.csv'));
writetable(summary,fullfile(outputDir, ...
    'direct_ratio_mapping_rejected_summary.csv'));

figureHandle = create_rejection_figure(voltageV,healthyCurrentA, ...
    agedCandidateCurrentA,qualifiedVoltageV,qualifiedQ, ...
    crossingVoltageV,voltagePeakV);
exportgraphics(figureHandle,fullfile(outputDir, ...
    'direct_ratio_mapping_rejected.png'),'Resolution',220);
savefig(figureHandle,fullfile(outputDir, ...
    'direct_ratio_mapping_rejected.fig'));
close(figureHandle);

write_audit(fullfile(outputDir,'direct_ratio_mapping_rejected_audit.txt'), ...
    inputPath,sourceBeforeE1mAVPerMm,sourceAfterE1mAVPerMm, ...
    sourceBeforeAlpha,sourceAfterAlpha,sourceBeforeLeakageUA, ...
    sourceAfterLeakageUA,summary);

save(fullfile(outputDir,'direct_ratio_mapping_rejected.mat'), ...
    'curve','summary','qualifiedVoltageV','qualifiedQ');

result = struct('summary',summary,'curve',curve, ...
    'outputDir',string(outputDir));
disp(summary);
fprintf('DIRECT_RATIO_MAPPING=REJECTED\n');
fprintf('FORMAL_EXTERNAL_VALIDATION_RUNS=0\n');
fprintf('OUTPUT_DIR=%s\n',outputDir);
end

function q = voltage_ratio(voltageV,alpha0,Uref0V,alphaA,UrefAV)
q = exp(alpha0*log(Uref0V) - alphaA*log(UrefAV) + ...
    (alphaA-alpha0).*log(voltageV));
end

function currentA = current_magnitude(voltageV,IrefA,UrefV,alpha)
currentA = zeros(size(voltageV));
positive = voltageV > 0;
currentA(positive) = IrefA*exp(alpha*log(voltageV(positive)/UrefV));
end

function figureHandle = create_rejection_figure(voltageV,healthyCurrentA, ...
        agedCandidateCurrentA,qualifiedVoltageV,qualifiedQ, ...
        crossingVoltageV,voltagePeakV)
figureHandle = figure('Color','w','Position',[100 100 1160 480]);
layout = tiledlayout(1,2,'Padding','compact','TileSpacing','compact');

nexttile(layout);
positive = voltageV > 0;
semilogy(1e-3*voltageV(positive),healthyCurrentA(positive), ...
    'k','LineWidth',1.6);
hold on;
semilogy(1e-3*voltageV(positive),agedCandidateCurrentA(positive), ...
    '--','Color',[0.85 0.2 0.1],'LineWidth',1.5);
xline(1e-3*crossingVoltageV,':','q=1 crossing', ...
    'LabelVerticalAlignment','bottom');
xlabel('|V| (kV)');
ylabel('Current magnitude (A)');
title('Rejected direct-ratio candidate');
legend({'Healthy','Mapped aged candidate'},'Location','southwest');
grid on;
xlim([0 1e-3*voltagePeakV]);

nexttile(layout);
plot(1e-3*qualifiedVoltageV,qualifiedQ, ...
    'Color',[0.15 0.45 0.75],'LineWidth',1.7);
hold on;
yline(1,'k--','q=1');
xline(1e-3*crossingVoltageV,':', ...
    sprintf('%.3f kV',1e-3*crossingVoltageV), ...
    'LabelVerticalAlignment','bottom');
xlabel('|V| (kV)');
ylabel('q(V) = I_{aged}/I_{healthy}');
title('q(V) on P0-qualified current-carrying range');
grid on;
xlim(1e-3*[qualifiedVoltageV(1),qualifiedVoltageV(end)]);
end

function write_audit(path,inputPath,beforeE,afterE,beforeAlpha, ...
        afterAlpha,beforeLeakage,afterLeakage,summary)
fileId = fopen(path,'wt','n','UTF-8');
assert(fileId >= 0,'Phase2P1A:AuditWrite','Unable to write %s.',path);
cleanupFile = onCleanup(@() fclose(fileId));
fprintf(fileId,'PHASE=Phase 2-P1A\n');
fprintf(fileId,'INPUT_P0_WAVEFORM=%s\n',inputPath);
fprintf(fileId,'SIMULINK_MODEL_LOADED=NO\n');
fprintf(fileId,'M0_M2_M3_M4_RUN=NO\n');
fprintf(fileId,'CASE05P_CASE06P_RUN=NO\n');
fprintf(fileId,'HISTORICAL_MATRIX_RERUN=NO\n');
fprintf(fileId,'SOURCE_DOI=10.1002/ces2.10235\n');
fprintf(fileId,'SOURCE_SAMPLE=B\n');
fprintf(fileId,'SOURCE_BEFORE_E1mA_V_PER_MM=%.17g\n',beforeE);
fprintf(fileId,'SOURCE_AFTER_E1mA_V_PER_MM=%.17g\n',afterE);
fprintf(fileId,'SOURCE_BEFORE_ALPHA=%.17g\n',beforeAlpha);
fprintf(fileId,'SOURCE_AFTER_ALPHA=%.17g\n',afterAlpha);
fprintf(fileId,'SOURCE_BEFORE_IL_uA=%.17g\n',beforeLeakage);
fprintf(fileId,'SOURCE_AFTER_IL_uA=%.17g\n',afterLeakage);
names = summary.Properties.VariableNames;
for k = 1:numel(names)
    fprintf(fileId,'%s=%.17g\n',upper(names{k}),summary.(names{k})(1));
end
fprintf(fileId,'Q_AT_V_EQUALS_0=UNDEFINED_0_OVER_0\n');
fprintf(fileId,'LIMIT_Q_AS_V_APPROACHES_0_POSITIVE=INFINITY\n');
fprintf(fileId,'DIRECT_RATIO_MAPPING=REJECTED\n');
fprintf(fileId,'MODEL_PARAMETER_FREEZE=PENDING_DIGITIZED_VI_CURVES\n');
clear cleanupFile;
end
