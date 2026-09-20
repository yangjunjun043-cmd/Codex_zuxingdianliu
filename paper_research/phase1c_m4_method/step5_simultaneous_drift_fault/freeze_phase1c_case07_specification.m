function frozen = freeze_phase1c_case07_specification()
%FREEZE_PHASE1C_CASE07_SPECIFICATION Freeze Case07 before any algorithm run.

step5Root = fileparts(mfilename('fullpath'));
workspaceRoot = fullfile(step5Root,'workspace');
if ~isfolder(workspaceRoot)
    mkdir(workspaceRoot);
end
specPath = fullfile(step5Root,'CASE07_SPECIFICATION.md');
snapshotPath = fullfile(workspaceRoot,'case07_configuration_snapshot.mat');
hashPath = fullfile(step5Root,'CASE07_SPECIFICATION.sha256');
definitionPath = fullfile(step5Root,'phase1c_case07_definition.m');
builderPath = fullfile(step5Root,'build_phase1c_case07_signals.m');
definition = phase1c_case07_definition();

existing = isfile(specPath) || isfile(snapshotPath) || isfile(hashPath);
if existing
    if ~(isfile(specPath) && isfile(snapshotPath) && isfile(hashPath))
        error('Phase1C:Step5PartialFreeze', ...
            'Case07 freeze artifacts are incomplete; refusing overwrite.');
    end
    saved = load(snapshotPath,'definition');
    if ~isequaln(saved.definition,definition)
        error('Phase1C:Step5FrozenDefinitionChanged', ...
            'Current Case07 definition differs from frozen snapshot.');
    end
    frozen = verify_manifest(hashPath,specPath,snapshotPath, ...
        definitionPath,builderPath);
    return
end

save(snapshotPath,'definition','-v7');
write_specification(specPath,definition);
specSha = step5_file_sha256(specPath);
snapshotSha = step5_file_sha256(snapshotPath);
definitionSha = step5_file_sha256(definitionPath);
builderSha = step5_file_sha256(builderPath);
write_hash_manifest(hashPath,specPath,specSha,snapshotPath,snapshotSha, ...
    definitionPath,definitionSha,builderPath,builderSha);
frozen = verify_manifest(hashPath,specPath,snapshotPath, ...
    definitionPath,builderPath);
fprintf('CASE07_SPECIFICATION_SHA256=%s\n',specSha);
fprintf('CASE07_SNAPSHOT_SHA256=%s\n',snapshotSha);
end

function write_specification(path,d)
fileId = fopen(path,'wt');
if fileId < 0
    error('Phase1C:Step5SpecificationWrite','Unable to write %s.',path);
end
cleanupObject = onCleanup(@() fclose(fileId));
fprintf(fileId,'# Case07 Frozen Specification\n\n');
fprintf(fileId,'This specification was frozen before running M2/M3/M4.\n\n');
fprintf(fileId,'## Identity\n\n');
fprintf(fileId,'- schema: `%s`\n',d.schema_version);
fprintf(fileId,'- case: `%s`\n',d.case_name);
fprintf(fileId,'- source case: `%s`\n',d.source_case);
fprintf(fileId,'- seed: `%d`\n',d.seed);
fprintf(fileId,'- model: `%s`\n',d.model);
fprintf(fileId,'- simulation duration: `%.2f s`\n',d.simulation_duration_s);
fprintf(fileId,'- sample time: `%.9g s`\n',d.sample_time_s);
fprintf(fileId,'- fundamental frequency: `%.1f Hz`\n\n', ...
    d.fundamental_frequency_hz);
fprintf(fileId,'## True Cs trajectory\n\n');
fprintf(fileId,'For `s=smoothstep(t; %.2f, %.2f)`, using `x^2(3-2x)`:\n\n', ...
    d.drift.start_s,d.drift.end_s);
fprintf(fileId,'- `Cs1 = %.1f + %.1f s pF`\n', ...
    d.drift.Cs1_initial_pF,d.drift.Cs1_change_pF);
fprintf(fileId,'- `Cs2 = %.1f %.1f s pF`\n\n', ...
    d.drift.Cs2_initial_pF,d.drift.Cs2_change_pF);
fprintf(fileId,'## Temporary B-phase resistive fault\n\n');
fprintf(fileId,'- factor: `%.2f`\n',d.fault.factor);
fprintf(fileId,'- onset: `%.2f s`\n',d.fault.onset_s);
fprintf(fileId,'- ramp-up: `%.2f-%.2f s`\n', ...
    d.fault.onset_s,d.fault.ramp_up_end_s);
fprintf(fileId,'- plateau: `%.2f-%.2f s`\n', ...
    d.fault.ramp_up_end_s,d.fault.plateau_end_s);
fprintf(fileId,'- ramp-down: `%.2f-%.2f s`\n', ...
    d.fault.plateau_end_s,d.fault.clear_s);
fprintf(fileId,'- cleared after: `%.2f s`\n\n',d.fault.clear_s);
fprintf(fileId,'## Reference and noise\n\n');
fprintf(fileId,'- reference source: `%s`\n',d.reference.source);
fprintf(fileId,'- reconstruction: `%s`\n', ...
    d.reference.reconstruction_function);
fprintf(fileId,'- phase error: `%.2f deg`\n',d.reference.phase_error_deg);
fprintf(fileId,'- initialization window: `[%.2f, %.2f) s`\n', ...
    d.reference.initialization_start_s,d.reference.initialization_end_s);
fprintf(fileId,'- SNR: `%.1f dB`\n',d.noise.snr_db);
fprintf(fileId,'- noise source: `%s`\n',d.noise.source);
fprintf(fileId,'- branch policy: `%s`\n\n',d.noise.branch_policy);
fprintf(fileId,[ ...
    'The exact Case06 seed-105 measurement-noise vectors are reconstructed ' ...
    'by subtracting an `SNR=Inf` Case06 run from its frozen ' ...
    '`SNR=30 dB` run. Those identical vectors are then supplied to ' ...
    'both Case07 branches.\n\n']);
fprintf(fileId,'## Matched branches\n\n');
fprintf(fileId,'- `F`: shared drift/reference/noise plus the temporary fault.\n');
fprintf(fileId,'- `CF`: identical inputs with `fault_scale=1` throughout.\n');
fprintf(fileId,[ ...
    '- Required identity: all branch inputs except fault scale match, ' ...
    'and all observed signals match sample-by-sample before %.2f s.\n\n'], ...
    d.fault.onset_s);
fprintf(fileId,'## Frozen analysis windows\n\n');
fprintf(fileId,'All windows use `[start,end)` boundaries.\n\n');
fprintf(fileId,'| Window | Start (s) | End (s) | Description |\n');
fprintf(fileId,'|---|---:|---:|---|\n');
for k = 1:height(d.windows)
    fprintf(fileId,'| %s | %.2f | %.2f | %s |\n', ...
        d.windows.window(k),d.windows.start_s(k), ...
        d.windows.end_s(k),d.windows.description(k));
end
fprintf(fileId,'\n## Pre-registered comparison rule\n\n');
fprintf(fileId,[ ...
    'No weighted or overall score is used. Drift tracking and fault ' ...
    'increment preservation remain separate objectives.\n\n']);
fprintf(fileId,'- overlap drift metric: `%s`\n',d.assessment.drift_metric);
fprintf(fileId,'- retention metric: `%s`\n',d.assessment.retention_metric);
fprintf(fileId,'- geometric check: `%s`\n',d.assessment.geometric_check);
fprintf(fileId,'- demonstrated: `%s`\n',d.assessment.demonstrated_rule);
fprintf(fileId,'- mixed: `%s`\n',d.assessment.mixed_rule);
fprintf(fileId,'- not demonstrated: `%s`\n', ...
    d.assessment.not_demonstrated_rule);
end

function write_hash_manifest(path,specPath,specSha,snapshotPath, ...
        snapshotSha,definitionPath,definitionSha,builderPath,builderSha)
fileId = fopen(path,'wt');
if fileId < 0
    error('Phase1C:Step5HashWrite','Unable to write %s.',path);
end
cleanupObject = onCleanup(@() fclose(fileId));
fprintf(fileId,'%s *%s\n',specSha,specPath);
fprintf(fileId,'%s *%s\n',snapshotSha,snapshotPath);
fprintf(fileId,'%s *%s\n',definitionSha,definitionPath);
fprintf(fileId,'%s *%s\n',builderSha,builderPath);
end

function frozen = verify_manifest(hashPath,specPath,snapshotPath, ...
        definitionPath,builderPath)
lines = string(splitlines(strtrim(fileread(hashPath))));
paths = [string(specPath);string(snapshotPath); ...
    string(definitionPath);string(builderPath)];
actual = strings(4,1);
expected = strings(4,1);
for k = 1:4
    tokens = split(lines(k));
    expected(k) = tokens(1);
    actual(k) = step5_file_sha256(paths(k));
end
if any(actual ~= expected)
    error('Phase1C:Step5FrozenHashMismatch', ...
        'Case07 frozen artifacts no longer match the SHA manifest.');
end
frozen = table(paths,expected,actual,actual == expected, ...
    'VariableNames',{'path','expected_sha256','actual_sha256','pass'});
end
