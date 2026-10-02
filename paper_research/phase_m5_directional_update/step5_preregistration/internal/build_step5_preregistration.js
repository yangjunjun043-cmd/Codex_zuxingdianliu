const fs = require("node:fs/promises");
const path = require("node:path");
const crypto = require("node:crypto");
const { Workbook, SpreadsheetFile } = require("@oai/artifact-tool");

const root = process.cwd();
const sourcePath = path.join(
  root,
  "paper_research",
  "phase2_full_validation",
  "step1_matrix_spec",
  "phase2_condition_registry.csv"
);
const outputDir = path.join(
  root,
  "paper_research",
  "phase_m5_directional_update",
  "step5_preregistration"
);
const outputCsv = path.join(outputDir, "M5_STEP5_ROBUSTNESS_MATRIX.csv");
const internalDir = path.join(outputDir, "internal");

const SOURCE_REGISTRY_SHA256 = "8A498E19A455C13CAA7B5371BE2F933CA7B7637B893C656C92DA84D88D1938BE";
const MODEL_SHA256 = "56067ADAADF59B5921D7156A2ABB61777C4E98B69CB4150759C3CB1D4D6A2A70";
const CONFIG_SHA256 = "D9F3E6894F51C3D978421C9E1E93828A9205F418C77D01AC449B994A3D789726";
const TRACKER_SHA256 = "8B580215A6268F4AC3BF27FB357DB6A4A01027DD2410C7FF59EA3C4B46DA4DDB";
const PROJECTOR_SHA256 = "47D2C12DB80F4BBFE7CE296841074DB6F3FF641CD769907666292E4398E06CA7";
const REGRESSOR_SHA256 = "7582F66875A1099DF9656F9A89FE12D8FF6972C55D4A034736527A7DB00E03D5";

const geometries = [
  {
    id: "ORTHOGONAL",
    order: 1,
    unit1: 1 / Math.sqrt(2),
    unit2: 1 / Math.sqrt(2),
    delta1: Math.sqrt(13 / 2),
    delta2: Math.sqrt(13 / 2),
    role: "PRIMARY_ROBUSTNESS_GEOMETRY",
    continuousRule: "GO_IF_MEDIAN_DELTA_PERP_CONT_LT_0_AND_FRACTION_LT_0_GT_0.5",
    hardRule: "REPORT_SAME_SUMMARIES_NOT_SOLE_M5_FULL_SURVIVAL_GATE",
  },
  {
    id: "MIXED",
    order: 2,
    unit1: 3 / Math.sqrt(13),
    unit2: -2 / Math.sqrt(13),
    delta1: 3,
    delta2: -2,
    role: "MECHANISM_EXTERNAL_VALIDATION",
    continuousRule: "NO_UNIVERSAL_IMPROVEMENT_REQUIRED;FLAG_IF_GT_75PCT_DELTA_PERP_CONT_GT_0_WITHOUT_PREREGISTERED_BOUNDARY_EXPLANATION",
    hardRule: "DESCRIPTIVE_MATCHED_HARD_ANALYSIS",
  },
  {
    id: "PARALLEL",
    order: 3,
    unit1: 1 / Math.sqrt(2),
    unit2: -1 / Math.sqrt(2),
    delta1: Math.sqrt(13 / 2),
    delta2: -Math.sqrt(13 / 2),
    role: "IDENTIFIABILITY_VALIDITY_BOUNDARY",
    continuousRule: "NO_SUPERIORITY_THRESHOLD;RETAIN_ALL_ROWS",
    hardRule: "NO_SUPERIORITY_THRESHOLD;RETAIN_ALL_ROWS",
  },
];

const algorithms = [
  { id: "GH", order: 1, scope: "GLOBAL", weight: "HARD", role: "MATCHED_GLOBAL_HARD_CONTROL" },
  { id: "GC", order: 2, scope: "GLOBAL", weight: "CONTINUOUS", role: "MATCHED_GLOBAL_CONTINUOUS_CONTROL" },
  { id: "M5_DH", order: 3, scope: "DIRECTIONAL", weight: "HARD", role: "DIRECTIONAL_HARD_CANDIDATE" },
  { id: "M5_FULL", order: 4, scope: "DIRECTIONAL", weight: "CONTINUOUS", role: "PRIMARY_DIRECTIONAL_CONTINUOUS_CANDIDATE" },
];

const headers = [
  "matrix_version",
  "preregistration_state",
  "simulation_status",
  "physical_condition_id",
  "evaluation_id",
  "geometry_pair_id",
  "source_condition_id",
  "source_registry_index",
  "source_mc_cohort",
  "geometry",
  "geometry_order",
  "geometry_role",
  "algorithm_id",
  "algorithm_order",
  "algorithm_scope",
  "weight_mode",
  "algorithm_role",
  "truth_seed",
  "noise_seed",
  "SNR_dB",
  "noise_mode",
  "noise_pairing_rule",
  "reference_phase_error_deg",
  "fault_mode",
  "fault_factor",
  "fault_start_s",
  "fault_ramp_up_s",
  "fault_ramp_end_s",
  "fault_plateau_end_s",
  "fault_ramp_down_s",
  "fault_end_s",
  "relative_fault_onset",
  "drift_rate_multiplier",
  "drift_start_s",
  "drift_end_s",
  "drift_duration_s",
  "h3_ratio",
  "h3_phase_deg",
  "negative_sequence_pu",
  "Cself_truth_pF",
  "Cself_algorithm_pF",
  "Cself_mismatch_pct",
  "CsAC_truth_pF",
  "evaluation_window_set_id",
  "simulation_stop_s",
  "Cs1_initial_pF",
  "Cs2_initial_pF",
  "drift_direction_Cs1",
  "drift_direction_Cs2",
  "drift_delta_Cs1_pF",
  "drift_delta_Cs2_pF",
  "drift_norm_pF",
  "Cs1_final_pF",
  "Cs2_final_pF",
  "fault_direction_Cs1",
  "fault_direction_Cs2",
  "paired_endpoint",
  "paired_delta_definition",
  "secondary_deltas",
  "orthogonal_summary_statistics",
  "stratification_fields",
  "saved_direction_diagnostics",
  "fixed_direction_policy",
  "row_level_superiority_threshold",
  "geometry_decision_rule",
  "hard_geometry_rule",
  "p_value_go_gate",
  "data_sharing_rule",
  "expected_sim_calls_per_physical_condition",
  "expected_tracker_branches_per_evaluation",
  "base_nuisance_signature_sha256",
  "source_registry_sha256",
  "model_sha256",
  "config_sha256",
  "tracker_sha256",
  "projector_sha256",
  "regressor_sha256",
  "notes",
];

function csvEscape(value) {
  if (value === null || value === undefined) return "";
  const text = String(value);
  if (/[",\r\n]/.test(text)) return `"${text.replace(/"/g, '""')}"`;
  return text;
}

function sha256(text) {
  return crypto.createHash("sha256").update(text, "utf8").digest("hex").toUpperCase();
}

function mapRow(headersIn, values) {
  const row = {};
  headersIn.forEach((header, index) => {
    row[String(header)] = values[index];
  });
  return row;
}

function number(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed)) throw new Error(`Expected finite number, received ${value}`);
  return parsed;
}

function integer(value) {
  const parsed = number(value);
  if (!Number.isInteger(parsed)) throw new Error(`Expected integer, received ${value}`);
  return parsed;
}

function canonicalNuisance(row) {
  const fields = [
    "condition_id", "registry_index", "mc_cohort", "truth_seed", "noise_seed",
    "SNR_dB", "noise_mode", "reference_phase_error_deg", "fault_mode",
    "fault_factor", "fault_start_s", "fault_ramp_up_s", "fault_ramp_end_s",
    "fault_plateau_end_s", "fault_ramp_down_s", "fault_end_s",
    "relative_fault_onset", "drift_rate_multiplier", "drift_start_s",
    "drift_end_s", "drift_duration_s", "h3_ratio", "h3_phase_deg",
    "negative_sequence_pu", "Cself_truth_pF", "Cself_algorithm_pF",
    "Cself_mismatch_pct", "CsAC_truth_pF", "evaluation_window_set_id",
    "simulation_stop_s", "Cs1_initial_pF", "Cs2_initial_pF",
  ];
  return fields.map((field) => `${field}=${row[field]}`).join("|");
}

function buildOutputRow(source, geometry, algorithm) {
  const sourceIndex = integer(source.registry_index);
  const indexLabel = String(sourceIndex).padStart(3, "0");
  const physicalId = `M5_S5_O${indexLabel}_${geometry.id}`;
  const endpoint = algorithm.weight === "CONTINUOUS" ? "Delta_perp_cont" : "Delta_perp_hard";
  const definition = algorithm.weight === "CONTINUOUS"
    ? "RMSE_perp(M5_FULL)-RMSE_perp(GC)"
    : "RMSE_perp(M5_DH)-RMSE_perp(GH)";
  const initial1 = number(source.Cs1_initial_pF);
  const initial2 = number(source.Cs2_initial_pF);
  const nuisanceSignature = sha256(canonicalNuisance(source));
  return {
    matrix_version: "M5_STEP5_ROBUSTNESS_V1",
    preregistration_state: "FROZEN_PENDING_HUMAN_REVIEW",
    simulation_status: "NOT_RUN",
    physical_condition_id: physicalId,
    evaluation_id: `${physicalId}__${algorithm.id}`,
    geometry_pair_id: `M5_S5_PAIR_O${indexLabel}`,
    source_condition_id: source.condition_id,
    source_registry_index: sourceIndex,
    source_mc_cohort: source.mc_cohort,
    geometry: geometry.id,
    geometry_order: geometry.order,
    geometry_role: geometry.role,
    algorithm_id: algorithm.id,
    algorithm_order: algorithm.order,
    algorithm_scope: algorithm.scope,
    weight_mode: algorithm.weight,
    algorithm_role: algorithm.role,
    truth_seed: integer(source.truth_seed),
    noise_seed: integer(source.noise_seed),
    SNR_dB: number(source.SNR_dB),
    noise_mode: source.noise_mode,
    noise_pairing_rule: "SAME_NOISE_SEED_AND_PHASEWISE_STANDARD_NORMAL_DRAW_SEQUENCE_ACROSS_3_GEOMETRIES;PER_GEOMETRY_SIGMA_USES_FROZEN_SNR_DEFINITION",
    reference_phase_error_deg: number(source.reference_phase_error_deg),
    fault_mode: source.fault_mode,
    fault_factor: number(source.fault_factor),
    fault_start_s: number(source.fault_start_s),
    fault_ramp_up_s: number(source.fault_ramp_up_s),
    fault_ramp_end_s: number(source.fault_ramp_end_s),
    fault_plateau_end_s: number(source.fault_plateau_end_s),
    fault_ramp_down_s: number(source.fault_ramp_down_s),
    fault_end_s: number(source.fault_end_s),
    relative_fault_onset: number(source.relative_fault_onset),
    drift_rate_multiplier: number(source.drift_rate_multiplier),
    drift_start_s: number(source.drift_start_s),
    drift_end_s: number(source.drift_end_s),
    drift_duration_s: number(source.drift_duration_s),
    h3_ratio: number(source.h3_ratio),
    h3_phase_deg: number(source.h3_phase_deg),
    negative_sequence_pu: number(source.negative_sequence_pu),
    Cself_truth_pF: number(source.Cself_truth_pF),
    Cself_algorithm_pF: number(source.Cself_algorithm_pF),
    Cself_mismatch_pct: number(source.Cself_mismatch_pct),
    CsAC_truth_pF: number(source.CsAC_truth_pF),
    evaluation_window_set_id: source.evaluation_window_set_id,
    simulation_stop_s: number(source.simulation_stop_s),
    Cs1_initial_pF: initial1,
    Cs2_initial_pF: initial2,
    drift_direction_Cs1: geometry.unit1,
    drift_direction_Cs2: geometry.unit2,
    drift_delta_Cs1_pF: geometry.delta1,
    drift_delta_Cs2_pF: geometry.delta2,
    drift_norm_pF: Math.sqrt(13),
    Cs1_final_pF: initial1 + geometry.delta1,
    Cs2_final_pF: initial2 + geometry.delta2,
    fault_direction_Cs1: 1 / Math.sqrt(2),
    fault_direction_Cs2: -1 / Math.sqrt(2),
    paired_endpoint: endpoint,
    paired_delta_definition: definition,
    secondary_deltas: "Delta_total;Delta_parallel;Delta_W1_retention;Delta_W2_retention;Delta_bias",
    orthogonal_summary_statistics: "median;P25;P75;P10;P90;fraction_delta_lt_0;paired_raw_values",
    stratification_fields: "reference_phase_error_deg;projection_active;rate_limit_active",
    saved_direction_diagnostics: "pre_constraint_angle_deg;post_rate_angle_deg;post_projection_angle_deg",
    fixed_direction_policy: "d_f=[1,-1]/sqrt(2);ONLINE_ROTATION_PROHIBITED",
    row_level_superiority_threshold: "NONE",
    geometry_decision_rule: geometry.continuousRule,
    hard_geometry_rule: geometry.hardRule,
    p_value_go_gate: "NONE",
    data_sharing_rule: "WITHIN_PHYSICAL_CONDITION_GH_GC_M5_DH_M5_FULL_SHARE_F_AND_CF_DATA_REFERENCE_WINDOWS_AND_TIME_AXIS",
    expected_sim_calls_per_physical_condition: 3,
    expected_tracker_branches_per_evaluation: 2,
    base_nuisance_signature_sha256: nuisanceSignature,
    source_registry_sha256: SOURCE_REGISTRY_SHA256,
    model_sha256: MODEL_SHA256,
    config_sha256: CONFIG_SHA256,
    tracker_sha256: TRACKER_SHA256,
    projector_sha256: PROJECTOR_SHA256,
    regressor_sha256: REGRESSOR_SHA256,
    notes: "M2/M3/M4 are historical Phase2 references only and are not rerun in Step5.",
  };
}

async function main() {
  const sourceText = await fs.readFile(sourcePath, "utf8");
  console.log("artifact_tool_content_start");
  const sourceWorkbook = await Workbook.fromCSV(sourceText, { sheetName: "Phase2Registry" });
  const sourceSheet = sourceWorkbook.worksheets.getItem("Phase2Registry");
  const sourceValues = sourceSheet.getUsedRange().values;
  const sourceHeaders = sourceValues[0].map(String);
  const sourceRows = sourceValues.slice(1).map((row) => mapRow(sourceHeaders, row));
  const baseRows = sourceRows
    .filter((row) => row.registry_kind === "MONTE_CARLO" && row.mc_cohort === "O")
    .sort((a, b) => integer(a.registry_index) - integer(b.registry_index));

  if (baseRows.length !== 50) throw new Error(`Expected 50 O-cohort rows, found ${baseRows.length}`);
  const indexes = baseRows.map((row) => integer(row.registry_index));
  if (indexes.some((value, i) => value !== i + 1)) throw new Error("O-cohort indexes are not exactly 1:50");
  if (new Set(baseRows.map((row) => row.condition_id)).size !== 50) throw new Error("Base condition IDs are not unique");
  if (new Set(baseRows.map((row) => row.truth_seed)).size !== 50) throw new Error("truth_seed values are not unique");
  if (new Set(baseRows.map((row) => row.noise_seed)).size !== 50) throw new Error("noise_seed values are not unique");
  if (baseRows.some((row) => row.truth_seed === row.noise_seed)) throw new Error("truth_seed equals noise_seed for at least one row");
  if (baseRows.some((row) => number(row.drift_total_norm_pF) !== 3.605551275)) throw new Error("Unexpected source drift norm");

  const outputRows = [];
  for (const source of baseRows) {
    for (const geometry of geometries) {
      for (const algorithm of algorithms) {
        outputRows.push(buildOutputRow(source, geometry, algorithm));
      }
    }
  }
  if (outputRows.length !== 600) throw new Error(`Expected 600 evaluations, found ${outputRows.length}`);
  if (new Set(outputRows.map((row) => row.physical_condition_id)).size !== 150) throw new Error("Expected 150 physical conditions");
  if (new Set(outputRows.map((row) => row.evaluation_id)).size !== 600) throw new Error("Evaluation IDs are not unique");

  for (const source of baseRows) {
    const signatureSet = new Set(
      outputRows.filter((row) => row.source_condition_id === source.condition_id)
        .map((row) => row.base_nuisance_signature_sha256)
    );
    if (signatureSet.size !== 1) throw new Error(`Nuisance pairing failed for ${source.condition_id}`);
  }
  for (const physicalId of new Set(outputRows.map((row) => row.physical_condition_id))) {
    const part = outputRows.filter((row) => row.physical_condition_id === physicalId);
    if (part.length !== 4 || part.map((row) => row.algorithm_id).join("|") !== "GH|GC|M5_DH|M5_FULL") {
      throw new Error(`Algorithm pairing failed for ${physicalId}`);
    }
  }

  await fs.mkdir(internalDir, { recursive: true });
  const csvLines = [
    headers.map(csvEscape).join(","),
    ...outputRows.map((row) => headers.map((header) => csvEscape(row[header])).join(",")),
  ];
  await fs.writeFile(outputCsv, `${csvLines.join("\r\n")}\r\n`, "utf8");

  const workbook = Workbook.create();
  const sheet = workbook.worksheets.add("RobustnessMatrix");
  const matrix = [headers, ...outputRows.map((row) => headers.map((header) => row[header]))];
  sheet.getRange("A1").write(matrix);
  sheet.freezePanes.freezeRows(1);
  sheet.getRangeByIndexes(0, 0, 1, headers.length).format = {
    fill: "#17365D",
    font: { bold: true, color: "#FFFFFF" },
    wrapText: true,
    verticalAlignment: "center",
  };
  sheet.getRangeByIndexes(0, 0, matrix.length, headers.length).format.borders = {
    preset: "all",
    style: "thin",
    color: "#D9E2F3",
  };
  sheet.getRangeByIndexes(0, 0, Math.min(17, matrix.length), Math.min(18, headers.length)).format.autofitColumns();
  sheet.getRange("A:A").format.columnWidth = 22;
  sheet.getRange("D:G").format.columnWidth = 28;
  sheet.getRange("J:Q").format.columnWidth = 24;

  const previewSheet = workbook.worksheets.add("Preview");
  const previewHeaders = headers.slice(0, 18);
  const previewRows = outputRows.slice(0, 12).map((row) => previewHeaders.map((header) => row[header]));
  previewSheet.getRange("A1").write([previewHeaders, ...previewRows]);
  previewSheet.getRange("A1:R1").format = {
    fill: "#17365D",
    font: { bold: true, color: "#FFFFFF" },
    wrapText: true,
  };
  previewSheet.getRange("A1:R13").format.borders = { preset: "all", style: "thin", color: "#D9E2F3" };
  previewSheet.getRange("A1:R13").format.autofitColumns();
  previewSheet.getRange("A1:R13").format.autofitRows();
  previewSheet.freezePanes.freezeRows(1);
  previewSheet.showGridLines = false;

  workbook.recalculate();
  const inspection = await workbook.inspect({
    kind: "region",
    sheetId: "Preview",
    range: "A1:R13",
    maxChars: 6000,
  });
  await fs.writeFile(path.join(internalDir, "artifact_tool_inspection.ndjson"), inspection.ndjson, "utf8");
  const preview = await workbook.render({ sheetName: "Preview", autoCrop: "all", scale: 1, format: "png" });
  await fs.writeFile(path.join(internalDir, "M5_STEP5_ROBUSTNESS_MATRIX_preview.png"), new Uint8Array(await preview.arrayBuffer()));
  const xlsx = await SpreadsheetFile.exportXlsx(workbook);
  await xlsx.save(path.join(internalDir, "M5_STEP5_ROBUSTNESS_MATRIX_audit.xlsx"));

  const summary = {
    source_registry_sha256: SOURCE_REGISTRY_SHA256,
    base_conditions: baseRows.length,
    physical_conditions: new Set(outputRows.map((row) => row.physical_condition_id)).size,
    algorithm_evaluations: outputRows.length,
    geometries: geometries.map((item) => item.id),
    algorithms: algorithms.map((item) => item.id),
    expected_sim_calls: 150 * 3,
    expected_tracker_branches: 600 * 2,
    simulation_status: "NOT_RUN",
  };
  await fs.writeFile(path.join(internalDir, "matrix_build_summary.json"), `${JSON.stringify(summary, null, 2)}\n`, "utf8");
  console.log(JSON.stringify(summary));
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exitCode = 1;
});
