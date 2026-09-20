function frozen = freeze_phase1c_case08_specification()
%FREEZE_PHASE1C_CASE08_SPECIFICATION Freeze Case08 before any result run.

step5bRoot = fileparts(mfilename('fullpath'));
phase1cRoot = fileparts(step5bRoot);
step5Root = fullfile(phase1cRoot,'step5_simultaneous_drift_fault');
workspaceRoot = fullfile(step5bRoot,'workspace');
if ~isfolder(workspaceRoot)
    mkdir(workspaceRoot);
end
addpath(step5Root);

specPath = fullfile(step5bRoot,'CASE08_SPECIFICATION.md');
snapshotPath = fullfile(workspaceRoot,'case08_configuration_snapshot.mat');
hashPath = fullfile(step5bRoot,'CASE08_SPECIFICATION.sha256');
definitionPath = fullfile(step5bRoot,'phase1c_case08_definition.m');
builderPath = fullfile(step5bRoot,'build_phase1c_case08_signals.m');
case07SpecPath = fullfile(step5Root,'CASE07_SPECIFICATION.md');
case07SnapshotPath = fullfile(step5Root,'workspace', ...
    'case07_configuration_snapshot.mat');

definition = phase1c_case08_definition();
sourceDefinition = phase1c_case07_definition();
assert_only_fault_factor_changed(sourceDefinition,definition);
assert_source_hash(case07SpecPath, ...
    definition.provenance.case07_specification_sha256);
assert_source_hash(case07SnapshotPath, ...
    definition.provenance.case07_snapshot_sha256);

existing = isfile(specPath) || isfile(snapshotPath) || isfile(hashPath);
if existing
    if ~(isfile(specPath) && isfile(snapshotPath) && isfile(hashPath))
        error('Phase1C:Step5BPartialFreeze', ...
            'Case08 freeze artifacts are incomplete; refusing overwrite.');
    end
    saved = load(snapshotPath,'definition','sourceDefinition');
    if ~isequaln(saved.definition,definition) || ...
            ~isequaln(saved.sourceDefinition,sourceDefinition)
        error('Phase1C:Step5BFrozenDefinitionChanged', ...
            'Current Case08 or source Case07 definition differs from snapshot.');
    end
    frozen = verify_manifest(hashPath,specPath,snapshotPath, ...
        definitionPath,builderPath);
    return
end

save(snapshotPath,'definition','sourceDefinition','-v7');
write_specification(specPath,definition);
specSha = step5b_file_sha256(specPath);
snapshotSha = step5b_file_sha256(snapshotPath);
definitionSha = step5b_file_sha256(definitionPath);
builderSha = step5b_file_sha256(builderPath);
write_hash_manifest(hashPath,specPath,specSha,snapshotPath,snapshotSha, ...
    definitionPath,definitionSha,builderPath,builderSha);
frozen = verify_manifest(hashPath,specPath,snapshotPath, ...
    definitionPath,builderPath);
fprintf('CASE08_FROZEN_BEFORE_RESULTS=PASS\n');
fprintf('CASE08_SPECIFICATION_SHA256=%s\n',specSha);
fprintf('CASE08_CONFIG_SHA256=%s\n',snapshotSha);
fprintf('CASE08_BUILDER_SHA256=%s\n',builderSha);
end

function assert_only_fault_factor_changed(source,target)
if source.fault.factor ~= 1.30 || target.fault.factor ~= 1.60
    error('Phase1C:Step5BFaultFactor', ...
        'Expected the pre-registered fault-factor change 1.30 -> 1.60.');
end
source.fault.factor = target.fault.factor;
source.schema_version = target.schema_version;
source.case_name = target.case_name;
source.source_case = target.source_case;
source.assessment = target.assessment;
source.provenance = target.provenance;
if ~isequaln(source,target)
    error('Phase1C:Step5BCaseDelta', ...
        'Case08 differs from Case07 outside the allowed fault factor.');
end
end

function assert_source_hash(path,expected)
actual = step5b_file_sha256(path);
if actual ~= expected
    error('Phase1C:Step5BSourceHash', ...
        'Protected Case07 source hash mismatch: %s.',path);
end
end

function write_specification(path,d)
fileId = fopen(path,'wt');
if fileId < 0
    error('Phase1C:Step5BSpecificationWrite', ...
        'Unable to write %s.',path);
end
cleanupObject = onCleanup(@() fclose(fileId));
fprintf(fileId,'# Case08 Frozen Specification\n\n');
fprintf(fileId,'**CASE08 FROZEN BEFORE RESULTS.**\n\n');
fprintf(fileId,'## Provenance and sole physical change\n\n');
fprintf(fileId,'- source Case07: `%s`\n',d.source_case);
fprintf(fileId,'- source Case07 specification SHA-256: `%s`\n', ...
    d.provenance.case07_specification_sha256);
fprintf(fileId,'- source Case07 configuration SHA-256: `%s`\n', ...
    d.provenance.case07_snapshot_sha256);
fprintf(fileId,'- sole allowed physical change: `%s`\n\n', ...
    d.provenance.allowed_physical_change);
fprintf(fileId,'All other fields are inherited directly from the frozen Case07 definition.\n\n');
fprintf(fileId,'## Identity\n\n');
fprintf(fileId,'- schema: `%s`\n',d.schema_version);
fprintf(fileId,'- case: `%s`\n',d.case_name);
fprintf(fileId,'- seed: `%d`\n',d.seed);
fprintf(fileId,'- model: `%s`\n',d.model);
fprintf(fileId,'- duration: `%.2f s`\n',d.simulation_duration_s);
fprintf(fileId,'- sample time: `%.9g s`\n',d.sample_time_s);
fprintf(fileId,'- fundamental frequency: `%.1f Hz`\n', ...
    d.fundamental_frequency_hz);
fprintf(fileId,'- SNR: `%.1f dB`\n\n',d.snr_db);
fprintf(fileId,'## True Cs trajectory\n\n');
fprintf(fileId,'- drift interval: `%.2f-%.2f s`\n', ...
    d.drift.start_s,d.drift.end_s);
fprintf(fileId,'- profile: `%s`\n',d.drift.profile);
fprintf(fileId,'- `Cs1 = %.1f + %.1f*smoothstep pF`\n', ...
    d.drift.Cs1_initial_pF,d.drift.Cs1_change_pF);
fprintf(fileId,'- `Cs2 = %.1f %+.1f*smoothstep pF`\n\n', ...
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
fprintf(fileId,'- clear: `%.2f s`\n\n',d.fault.clear_s);
fprintf(fileId,'## Reference and noise\n\n');
fprintf(fileId,'- reference source: `%s`\n',d.reference.source);
fprintf(fileId,'- reconstruction: `%s`\n', ...
    d.reference.reconstruction_function);
fprintf(fileId,'- phase error: `%.2f deg`\n',d.reference.phase_error_deg);
fprintf(fileId,'- initialization: `[%.2f, %.2f) s`\n', ...
    d.reference.initialization_start_s,d.reference.initialization_end_s);
fprintf(fileId,'- noise source: `%s`\n',d.noise.source);
fprintf(fileId,'- noise RNG seed: `%d`\n',d.noise.rng_seed);
fprintf(fileId,'- F/CF policy: `%s`\n\n',d.noise.branch_policy);
fprintf(fileId,'## Matched branches\n\n');
fprintf(fileId,'- `F`: shared drift/reference/noise plus factor-1.60 fault.\n');
fprintf(fileId,'- `CF`: identical drift/reference/noise with no fault.\n');
fprintf(fileId,'- required pre-fault and non-fault input difference: exactly zero.\n\n');
fprintf(fileId,'## Frozen analysis windows\n\n');
fprintf(fileId,'All windows use `[start,end)` boundaries.\n\n');
fprintf(fileId,'| Window | Start (s) | End (s) | Description |\n');
fprintf(fileId,'|---|---:|---:|---|\n');
for k = 1:height(d.windows)
    fprintf(fileId,'| %s | %.2f | %.2f | %s |\n', ...
        d.windows.window(k),d.windows.start_s(k), ...
        d.windows.end_s(k),d.windows.description(k));
end
fprintf(fileId,'\n## Pre-registered trade-off rule\n\n');
fprintf(fileId,'- A: `%s`\n',d.assessment.criterion_A);
fprintf(fileId,'- B: `%s`\n',d.assessment.criterion_B);
fprintf(fileId,'- C: `%s`\n',d.assessment.criterion_C);
fprintf(fileId,'- demonstrated: `%s`\n',d.assessment.demonstrated_rule);
fprintf(fileId,'- mixed: `%s`\n',d.assessment.mixed_rule);
fprintf(fileId,'- not demonstrated: `%s`\n', ...
    d.assessment.not_demonstrated_rule);
end

function write_hash_manifest(path,specPath,specSha,snapshotPath, ...
        snapshotSha,definitionPath,definitionSha,builderPath,builderSha)
fileId = fopen(path,'wt');
if fileId < 0
    error('Phase1C:Step5BHashWrite','Unable to write %s.',path);
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
expected = strings(4,1);
actual = strings(4,1);
for k = 1:4
    tokens = split(lines(k));
    expected(k) = tokens(1);
    actual(k) = step5b_file_sha256(paths(k));
end
if any(actual ~= expected)
    error('Phase1C:Step5BFrozenHashMismatch', ...
        'Case08 frozen artifacts no longer match the SHA manifest.');
end
frozen = table(paths,expected,actual,actual == expected, ...
    'VariableNames',{'path','expected_sha256','actual_sha256','pass'});
end
