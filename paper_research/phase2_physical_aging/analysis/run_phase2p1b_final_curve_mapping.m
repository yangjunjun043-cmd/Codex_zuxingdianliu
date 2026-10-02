function result = run_phase2p1b_final_curve_mapping()
%RUN_PHASE2P1B_FINAL_CURVE_MAPPING Digitize Fu 2024 Sample B E-J curves.
%
% This function is deliberately limited to source-image qualification,
% axis calibration, raw Sample-B digitization, and coverage qualification.
% It does not load Simulink or run M0/M2/M3/M4. If the literature curves
% do not cover the full frozen xi interval, execution stops before q_lit,
% aged-waveform construction, or harmonic qualification.

scriptDir = fileparts(mfilename('fullpath'));
phaseDir = fileparts(scriptDir);
sourcePath = fullfile(phaseDir,'source','Fu2024_Figure1.png');
outputDir = fullfile(phaseDir,'analysis_outputs');
derivedDir = fullfile(phaseDir,'derived');
if ~isfolder(outputDir), mkdir(outputDir); end
if ~isfolder(derivedDir), mkdir(derivedDir); end

expectedHash = "319E21A82E73D47B82DEE27B68A8C8C964A45B5A5BF6E592D34EAF291193DD3D";
assert(isfile(sourcePath),'Phase2P1B:MissingSource', ...
    'Missing frozen source image: %s',sourcePath);
sourceHash = sha256_file(sourcePath);
assert(sourceHash == expectedHash,'Phase2P1B:SourceHashMismatch', ...
    'Source image hash differs from the frozen user-provided image.');

imageData = imread(sourcePath);
assert(isequal(size(imageData,1),484) && isequal(size(imageData,2),909), ...
    'Phase2P1B:SourceDimensions','Expected source dimensions 909 x 484 px.');
imageData = imageData(:,:,1:3);

% Main decade ticks read from the two panels. Calibration is performed as
% pixel = pixelsPerDecade * log10(value) + intercept.
beforeX = fit_axis("A","J",[65 126 187 248 309 370 431],-9:-3,0.75);
afterX = fit_axis("B","J",[508 569 631 692 753 815 876],-9:-3,0.75);
beforeY = fit_axis("A","E",[37 181],[3 2],0.75);
afterY = fit_axis("B","E",[37 181],[3 2],0.75);

calibration = [axis_row(beforeX,sourceHash); axis_row(afterX,sourceHash); ...
    axis_row(beforeY,sourceHash); axis_row(afterY,sourceHash)];
writetable(calibration,fullfile(phaseDir,'figure_axis_calibration.csv'));

% Color prototypes are sampled from the four legend traces in the source.
% Classification measures distance to each prototype-to-white segment so
% antialiased pixels remain attributable without brightness thresholding.
prototypes = [47 156 114; ...   % A: dark green solid
              142 221 187; ... % B: light green dashed
              153 250 246; ... % C: cyan dotted/short dash
              241 169 253];    % D: magenta dash-dot
classMap = classify_antialiased_colors(imageData,prototypes);

beforeSpec = struct('panel',"A",'state',"before", ...
    'xRange',[108 429],'yRange',[90 281], ...
    'legendBox',[338 421 151 252],'xAxis',beforeX,'yAxis',beforeY);
afterSpec = struct('panel',"B",'state',"after", ...
    'xRange',[551 874],'yRange',[90 281], ...
    'legendBox',[782 864 151 252],'xAxis',afterX,'yAxis',afterY);

beforeCurve = extract_sample_b(imageData,classMap,beforeSpec,prototypes);
afterCurve = extract_sample_b(imageData,classMap,afterSpec,prototypes);
assert(height(beforeCurve) >= 30 && height(afterCurve) >= 30, ...
    'Phase2P1B:InsufficientTracePixels', ...
    'Too few uniquely classified Sample B trace columns.');

beforeCurve.sample(:) = "B";
beforeCurve.aging_state(:) = "before";
afterCurve.sample(:) = "B";
afterCurve.aging_state(:) = "after";

variables = ["E_V_per_mm","J_A_per_cm2","source_panel","sample", ...
    "aging_state","pixel_x","pixel_y","digitization_uncertainty_E", ...
    "digitization_uncertainty_J"];
beforeCurve = beforeCurve(:,variables);
afterCurve = afterCurve(:,variables);
writetable(beforeCurve,fullfile(phaseDir,'literature_vi_before.csv'));
writetable(afterCurve,fullfile(phaseDir,'literature_vi_after.csv'));

plotPath = fullfile(derivedDir,'Fu2024_SampleB_digitized_EJ.png');
make_digitization_figure(imageData,beforeCurve,afterCurve,plotPath);

% Frozen model coordinate and literature coverage gate.
ErefLit = 305.82;
requiredXi = [0.514 1.099];
beforeXi = beforeCurve.E_V_per_mm ./ ErefLit;
afterXi = afterCurve.E_V_per_mm ./ ErefLit;
beforeXiUpper = (beforeCurve.E_V_per_mm + ...
    beforeCurve.digitization_uncertainty_E) ./ ErefLit;
afterXiUpper = (afterCurve.E_V_per_mm + ...
    afterCurve.digitization_uncertainty_E) ./ ErefLit;
beforeXiLower = max(beforeCurve.E_V_per_mm - ...
    beforeCurve.digitization_uncertainty_E,eps) ./ ErefLit;
afterXiLower = max(afterCurve.E_V_per_mm - ...
    afterCurve.digitization_uncertainty_E,eps) ./ ErefLit;

commonXiNominal = [max(min(beforeXi),min(afterXi)), ...
                   min(max(beforeXi),max(afterXi))];
commonXiWithEndpointUncertainty = [ ...
    max(min(beforeXiLower),min(afterXiLower)), ...
    min(max(beforeXiUpper),max(afterXiUpper))];
coveragePass = commonXiWithEndpointUncertainty(1) <= requiredXi(1) && ...
    commonXiWithEndpointUncertainty(2) >= requiredXi(2);

if coveragePass
    mappingStatus = "DIGITIZED_CURVES_PRESENT_COVERAGE_PASS_PENDING_Q_MAPPING";
    p1bStatus = "PENDING_Q_MAPPING";
else
    mappingStatus = "FAIL_INSUFFICIENT_COVERAGE";
    p1bStatus = "FAIL";
end

qualification = table( ...
    sourceHash,909,484,height(beforeCurve),height(afterCurve), ...
    min(beforeXi),max(beforeXi),min(afterXi),max(afterXi), ...
    commonXiNominal(1),commonXiNominal(2), ...
    commonXiWithEndpointUncertainty(1),commonXiWithEndpointUncertainty(2), ...
    requiredXi(1),requiredXi(2),coveragePass,mappingStatus,p1bStatus, ...
    'VariableNames',{ ...
    'source_sha256','source_width_px','source_height_px', ...
    'before_raw_points','after_raw_points', ...
    'before_xi_min','before_xi_max','after_xi_min','after_xi_max', ...
    'common_xi_min_nominal','common_xi_max_nominal', ...
    'common_xi_min_with_endpoint_uncertainty', ...
    'common_xi_max_with_endpoint_uncertainty', ...
    'required_xi_min','required_xi_max','coverage_pass', ...
    'mapping_status','p1b_curve_mapping'});
writetable(qualification,fullfile(outputDir,'p1b_digitization_qualification.csv'));

result = struct( ...
    'figure_identity_check',"PASS", ...
    'source_sha256',sourceHash, ...
    'source_size_px',[909 484], ...
    'before_raw_points',height(beforeCurve), ...
    'after_raw_points',height(afterCurve), ...
    'common_xi_nominal',commonXiNominal, ...
    'common_xi_with_endpoint_uncertainty',commonXiWithEndpointUncertainty, ...
    'required_xi',requiredXi, ...
    'coverage_pass',coveragePass, ...
    'mapping_status',mappingStatus, ...
    'p1b_curve_mapping',p1bStatus, ...
    'q_lit_created',false, ...
    'aged_waveform_created',false, ...
    'algorithm_runs',0);
write_status(fullfile(outputDir,'vi_mapping_status.txt'),result);

fprintf('FIGURE_IDENTITY_CHECK = PASS\n');
fprintf('SOURCE_SHA256 = %s\n',sourceHash);
fprintf('BEFORE_RAW_POINTS = %d\n',height(beforeCurve));
fprintf('AFTER_RAW_POINTS = %d\n',height(afterCurve));
fprintf('COMMON_XI_NOMINAL = %.9f .. %.9f\n',commonXiNominal);
fprintf('COMMON_XI_WITH_ENDPOINT_UNCERTAINTY = %.9f .. %.9f\n', ...
    commonXiWithEndpointUncertainty);
fprintf('REQUIRED_XI = %.3f .. %.3f\n',requiredXi);
fprintf('MAPPING_STATUS = %s\n',mappingStatus);
fprintf('P1B_CURVE_MAPPING = %s\n',p1bStatus);
fprintf('Q_LIT_CREATED = NO\n');
fprintf('M0_M2_M3_M4_RUN = NO\n');
fprintf('HISTORICAL_MATRIX_RERUN = NO\n');
end

function axisFit = fit_axis(panel,axisName,pixelTicks,logTicks,tickUncertainty)
coeff = polyfit(double(logTicks(:)),double(pixelTicks(:)),1);
predictedPixels = polyval(coeff,double(logTicks(:)));
residual = double(pixelTicks(:)) - predictedPixels;
axisFit = struct( ...
    'panel',panel,'axis',axisName, ...
    'pixelsPerDecade',coeff(1),'intercept',coeff(2), ...
    'tickPixels',double(pixelTicks(:))', ...
    'tickLogValues',double(logTicks(:))', ...
    'rmsePx',sqrt(mean(residual.^2)), ...
    'maxResidualPx',max(abs(residual)), ...
    'tickUncertaintyPx',tickUncertainty);
end

function row = axis_row(axisFit,sourceHash)
row = table(axisFit.panel,axisFit.axis,axisFit.pixelsPerDecade, ...
    axisFit.intercept,join(string(axisFit.tickPixels),";"), ...
    join(string(axisFit.tickLogValues),";"),axisFit.rmsePx, ...
    axisFit.maxResidualPx,axisFit.tickUncertaintyPx,sourceHash, ...
    'VariableNames',{'source_panel','axis','pixels_per_decade', ...
    'pixel_intercept','tick_pixels','tick_log10_values', ...
    'calibration_rmse_px','calibration_max_residual_px', ...
    'tick_reading_uncertainty_px','source_sha256'});
end

function classMap = classify_antialiased_colors(imageData,prototypes)
pixels = double(reshape(imageData,[],3));
white = 255 * ones(size(pixels));
distance = inf(size(pixels,1),size(prototypes,1));
alpha = zeros(size(distance));
for k = 1:size(prototypes,1)
    direction = double(prototypes(k,:)) - 255;
    thisAlpha = sum((pixels-white).*direction,2) ./ sum(direction.^2);
    thisAlpha = min(max(thisAlpha,0),1.25);
    fitted = white + thisAlpha .* direction;
    distance(:,k) = sqrt(sum((pixels-fitted).^2,2));
    alpha(:,k) = thisAlpha;
end
[bestDistance,bestClass] = min(distance,[],2);
isColored = bestDistance <= 16 & max(alpha,[],2) >= 0.14;
bestClass(~isColored) = 0;
classMap = reshape(uint8(bestClass),size(imageData,1),size(imageData,2));
end

function curve = extract_sample_b(imageData,classMap,spec,prototypes)
mask = classMap == 2;
roi = false(size(mask));
roi(spec.yRange(1):spec.yRange(2),spec.xRange(1):spec.xRange(2)) = true;
mask = mask & roi;
box = spec.legendBox;
mask(box(3):box(4),box(1):box(2)) = false;

pixelX = [];
pixelY = [];
identificationPx = [];
for x = spec.xRange(1):spec.xRange(2)
    ys = find(mask(:,x));
    if isempty(ys), continue; end
    % The curve line is only a few pixels thick. A median represents its
    % center and is retained only when the classified pixels form one
    % compact vertical cluster.
    if max(ys)-min(ys) > 5, continue; end
    y = median(double(ys));
    p = squeeze(double(imageData(round(y),x,:)))';
    [~,margin] = color_identity_margin(p,prototypes);
    if margin < 1.0, continue; end
    pixelX(end+1,1) = x; %#ok<AGROW>
    pixelY(end+1,1) = y; %#ok<AGROW>
    if margin < 4
        identificationPx(end+1,1) = 2.0; %#ok<AGROW>
    elseif margin < 9
        identificationPx(end+1,1) = 1.25; %#ok<AGROW>
    else
        identificationPx(end+1,1) = 0.75; %#ok<AGROW>
    end
end

% Retain the physically monotone trace and remove isolated color aliases.
if numel(pixelX) >= 5
    localMedian = movmedian(pixelY,5,'omitmissing');
    keep = abs(pixelY-localMedian) <= 4;
    pixelX = pixelX(keep);
    pixelY = pixelY(keep);
    identificationPx = identificationPx(keep);

    % E=f(J) is monotone increasing, hence pixel y must be monotone
    % non-increasing with x on log-log axes. Allow 2.5 px for line width
    % and antialiasing, but reject reverse jumps into the A/C/D traces.
    keep = false(size(pixelY));
    runningMinimumY = inf;
    for k = 1:numel(pixelY)
        if pixelY(k) <= runningMinimumY + 2.5
            keep(k) = true;
            runningMinimumY = min(runningMinimumY,pixelY(k));
        end
    end
    pixelX = pixelX(keep);
    pixelY = pixelY(keep);
    identificationPx = identificationPx(keep);
end

logJ = (pixelX-spec.xAxis.intercept) ./ spec.xAxis.pixelsPerDecade;
logE = (pixelY-spec.yAxis.intercept) ./ spec.yAxis.pixelsPerDecade;
J = 10.^logJ;
E = 10.^logE;

lineHalfWidthPx = 1.5;
calibrationXPx = hypot(spec.xAxis.tickUncertaintyPx,spec.xAxis.rmsePx);
calibrationYPx = hypot(spec.yAxis.tickUncertaintyPx,spec.yAxis.rmsePx);
uncertaintyXPx = sqrt(lineHalfWidthPx^2 + calibrationXPx^2 + identificationPx.^2);
uncertaintyYPx = sqrt(lineHalfWidthPx^2 + calibrationYPx^2 + identificationPx.^2);
JUpper = 10.^(logJ + uncertaintyXPx./abs(spec.xAxis.pixelsPerDecade));
JLower = 10.^(logJ - uncertaintyXPx./abs(spec.xAxis.pixelsPerDecade));
EUpper = 10.^(logE + uncertaintyYPx./abs(spec.yAxis.pixelsPerDecade));
ELower = 10.^(logE - uncertaintyYPx./abs(spec.yAxis.pixelsPerDecade));

sourcePanel = repmat(spec.panel,numel(E),1);
sample = repmat("B",numel(E),1);
agingState = repmat(spec.state,numel(E),1);
curve = table(E,J,sourcePanel,sample,agingState,pixelX,pixelY, ...
    (EUpper-ELower)./2,(JUpper-JLower)./2, ...
    'VariableNames',{'E_V_per_mm','J_A_per_cm2','source_panel','sample', ...
    'aging_state','pixel_x','pixel_y','digitization_uncertainty_E', ...
    'digitization_uncertainty_J'});
curve = sortrows(curve,'pixel_x');
end

function [bestClass,margin] = color_identity_margin(pixel,prototypes)
white = 255 * ones(1,3);
distance = zeros(size(prototypes,1),1);
for k = 1:size(prototypes,1)
    direction = double(prototypes(k,:)) - 255;
    alpha = sum((double(pixel)-white).*direction) ./ sum(direction.^2);
    alpha = min(max(alpha,0),1.25);
    fitted = white + alpha .* direction;
    distance(k) = norm(double(pixel)-fitted);
end
[sortedDistance,order] = sort(distance);
bestClass = order(1);
margin = sortedDistance(2)-sortedDistance(1);
end

function make_digitization_figure(imageData,beforeCurve,afterCurve,path)
fig = figure('Visible','off','Color','w','Position',[100 100 1300 780]);
tiledlayout(fig,2,2,'Padding','compact','TileSpacing','compact');

nexttile;
image(imageData); axis image; xlim([55 440]); ylim([25 292]); set(gca,'YDir','reverse');
hold on; scatter(beforeCurve.pixel_x,beforeCurve.pixel_y,18,'r','filled');
title('Panel A: accepted Sample B pixels'); xlabel('pixel x'); ylabel('pixel y');

nexttile;
image(imageData); axis image; xlim([498 885]); ylim([25 292]); set(gca,'YDir','reverse');
hold on; scatter(afterCurve.pixel_x,afterCurve.pixel_y,18,'r','filled');
title('Panel B: accepted Sample B pixels'); xlabel('pixel x'); ylabel('pixel y');

nexttile([1 2]);
loglog(beforeCurve.J_A_per_cm2,beforeCurve.E_V_per_mm,'o', ...
    'Color',[0.15 0.65 0.42],'MarkerFaceColor',[0.55 0.86 0.72], ...
    'MarkerSize',4,'DisplayName','Before aging, Sample B');
hold on;
loglog(afterCurve.J_A_per_cm2,afterCurve.E_V_per_mm,'s', ...
    'Color',[0.05 0.45 0.75],'MarkerFaceColor',[0.45 0.80 0.95], ...
    'MarkerSize',4,'DisplayName','After aging, Sample B');
grid on; xlabel('J (A/cm^2)'); ylabel('E (V/mm)');
title('Raw digitized points (no interpolated points)'); legend('Location','southeast');
exportgraphics(fig,path,'Resolution',220);
close(fig);
end

function hash = sha256_file(path)
fileId = fopen(path,'rb');
assert(fileId >= 0,'Phase2P1B:HashRead','Unable to read source: %s',path);
cleanup = onCleanup(@() fclose(fileId));
bytesIn = fread(fileId,inf,'*uint8');
digest = java.security.MessageDigest.getInstance('SHA-256');
digest.update(typecast(bytesIn,'int8'));
bytes = typecast(digest.digest(),'uint8');
hash = string(upper(sprintf('%02X',bytes)));
clear cleanup;
end

function write_status(path,result)
fileId = fopen(path,'wt','n','UTF-8');
assert(fileId >= 0,'Phase2P1B:StatusWrite','Unable to write status: %s',path);
cleanup = onCleanup(@() fclose(fileId));
fprintf(fileId,'FIGURE_IDENTITY_CHECK=%s\n',result.figure_identity_check);
fprintf(fileId,'SOURCE_IMAGE_FILE=source/Fu2024_Figure1.png\n');
fprintf(fileId,'SOURCE_IMAGE_SHA256=%s\n',result.source_sha256);
fprintf(fileId,'SOURCE_IMAGE_WIDTH_PX=%d\n',result.source_size_px(1));
fprintf(fileId,'SOURCE_IMAGE_HEIGHT_PX=%d\n',result.source_size_px(2));
fprintf(fileId,'BEFORE_DIGITIZED_ROWS=%d\n',result.before_raw_points);
fprintf(fileId,'AFTER_DIGITIZED_ROWS=%d\n',result.after_raw_points);
fprintf(fileId,'COMMON_XI_MIN_NOMINAL=%.12g\n',result.common_xi_nominal(1));
fprintf(fileId,'COMMON_XI_MAX_NOMINAL=%.12g\n',result.common_xi_nominal(2));
fprintf(fileId,'COMMON_XI_MIN_WITH_ENDPOINT_UNCERTAINTY=%.12g\n', ...
    result.common_xi_with_endpoint_uncertainty(1));
fprintf(fileId,'COMMON_XI_MAX_WITH_ENDPOINT_UNCERTAINTY=%.12g\n', ...
    result.common_xi_with_endpoint_uncertainty(2));
fprintf(fileId,'REQUIRED_XI_MIN=%.12g\n',result.required_xi(1));
fprintf(fileId,'REQUIRED_XI_MAX=%.12g\n',result.required_xi(2));
fprintf(fileId,'COVERAGE_PASS=%s\n',yes_no(result.coverage_pass));
fprintf(fileId,'MAPPING_STATUS=%s\n',result.mapping_status);
fprintf(fileId,'P1B_CURVE_MAPPING=%s\n',result.p1b_curve_mapping);
fprintf(fileId,'Q_LIT_CREATED=NO\n');
fprintf(fileId,'AGING_SHAPE_MAPPING=NOT_FROZEN\n');
fprintf(fileId,'AGED_MODEL_FROZEN=NO\n');
fprintf(fileId,'EXTERNAL_VALIDATION_8_GROUPS_AUTHORIZED=NO\n');
fprintf(fileId,'M0_M2_M3_M4_RUN=NO\n');
fprintf(fileId,'CASE05P_CASE06P_RUN=NO\n');
fprintf(fileId,'HISTORICAL_MATRIX_RERUN=NO\n');
clear cleanup;
end

function value = yes_no(flag)
if flag, value = 'YES'; else, value = 'NO'; end
end
