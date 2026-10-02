const fs = require('node:fs/promises');
const path = require('node:path');
const { SpreadsheetFile, Workbook } = require('@oai/artifact-tool');

async function main() {
  const baseDir = path.resolve(__dirname, '..');
  const csvPath = path.join(baseDir, 'M5_STEP5_MASTER_RESULTS.csv');
  const csvText = await fs.readFile(csvPath, 'utf8');
  const workbook = await Workbook.fromCSV(csvText, { sheetName: 'MasterResults' });
  const dataSheet = workbook.worksheets.getItem('MasterResults');
  const rows = dataSheet.getUsedRange().values;
  const headers = rows[0].map(String);
  const records = rows.slice(1);
  const index = Object.fromEntries(headers.map((name, i) => [name, i]));
  const value = (row, name) => row[index[name]];
  const uniqueCount = (name) => new Set(records.map((row) => String(value(row, name)))).size;
  const countBy = (name) => {
    const counts = new Map();
    for (const row of records) {
      const key = String(value(row, name));
      counts.set(key, (counts.get(key) || 0) + 1);
    }
    return [...counts.entries()].sort((a, b) => a[0].localeCompare(b[0]));
  };
  const countFlag = (name, expected) => records.filter((row) => String(value(row, name)).toLowerCase() !== expected).length;

  const audit = workbook.worksheets.add('Audit');
  const auditRows = [
    ['M5 Step5 master-results audit', 'Value', 'Expected', 'Status'],
    ['Data rows', records.length, 600, records.length === 600 ? 'PASS' : 'FAIL'],
    ['Columns', headers.length, 109, headers.length === 109 ? 'PASS' : 'FAIL'],
    ['Unique physical conditions', uniqueCount('physical_condition_id'), 150, uniqueCount('physical_condition_id') === 150 ? 'PASS' : 'FAIL'],
    ['Unique evaluations', uniqueCount('evaluation_id'), 600, uniqueCount('evaluation_id') === 600 ? 'PASS' : 'FAIL'],
    ['Unique geometry pairs', uniqueCount('geometry_pair_id'), 50, uniqueCount('geometry_pair_id') === 50 ? 'PASS' : 'FAIL'],
    ['Registry mismatches', countFlag('registry_match', '1'), 0, countFlag('registry_match', '1') === 0 ? 'PASS' : 'FAIL'],
    ['Seed mismatches', countFlag('seed_match', '1'), 0, countFlag('seed_match', '1') === 0 ? 'PASS' : 'FAIL'],
    ['Shared-data failures', countFlag('shared_data_pass', '1'), 0, countFlag('shared_data_pass', '1') === 0 ? 'PASS' : 'FAIL'],
    ['Required-output failures', countFlag('required_outputs_pass', '1'), 0, countFlag('required_outputs_pass', '1') === 0 ? 'PASS' : 'FAIL'],
    ['Numerical failures', countFlag('numerical_failure', '0'), 0, countFlag('numerical_failure', '0') === 0 ? 'PASS' : 'FAIL'],
    ['Metric-missing rows', countFlag('metric_missing', '0'), 0, countFlag('metric_missing', '0') === 0 ? 'PASS' : 'FAIL'],
    ['Simulation-abort rows', countFlag('simulation_abort', '0'), 0, countFlag('simulation_abort', '0') === 0 ? 'PASS' : 'FAIL'],
  ];

  audit.getRange(`A1:D${auditRows.length}`).values = auditRows;
  let rowCursor = auditRows.length + 2;
  for (const [label, field, expectedEach] of [
    ['Algorithm allocation', 'algorithm_id', 150],
    ['Geometry allocation', 'geometry', 200],
    ['Weight allocation', 'weight_mode', 300],
  ]) {
    audit.getRange(`A${rowCursor}:D${rowCursor}`).values = [[label, 'Count', 'Expected each', 'Status']];
    rowCursor += 1;
    for (const [name, count] of countBy(field)) {
      audit.getRange(`A${rowCursor}:D${rowCursor}`).values = [[name, count, expectedEach, count === expectedEach ? 'PASS' : 'FAIL']];
      rowCursor += 1;
    }
    rowCursor += 1;
  }

  audit.getRange(`A1:D${rowCursor}`).format.font = { name: 'Arial', size: 10 };
  for (let r = 1; r <= rowCursor; r += 1) {
    const text = String(audit.getRange(`A${r}`).values[0][0] || '');
    if (text.includes('audit') || text.includes('allocation')) {
      audit.getRange(`A${r}:D${r}`).format = {
        fill: '#1F4E78',
        font: { name: 'Arial', size: 10, bold: true, color: '#FFFFFF' },
      };
    }
  }
  audit.getRange(`D2:D${rowCursor}`).conditionalFormats.add('containsText', {
    text: 'FAIL',
    format: { fill: '#FECACA', font: { bold: true, color: '#991B1B' } },
  });
  audit.getRange(`D2:D${rowCursor}`).conditionalFormats.add('containsText', {
    text: 'PASS',
    format: { fill: '#DCFCE7', font: { bold: true, color: '#166534' } },
  });
  audit.getRange(`A1:D${rowCursor}`).format.borders = { preset: 'all', style: 'thin', color: '#D9E2F3' };
  audit.getRange(`A1:D${rowCursor}`).format.autofitColumns();
  audit.getRange(`A1:D${rowCursor}`).format.autofitRows();
  audit.freezePanes.freezeRows(1);
  audit.showGridLines = false;
  dataSheet.freezePanes.freezeRows(1);
  dataSheet.freezePanes.freezeColumns(6);
  dataSheet.getRange('A1:DE1').format = {
    fill: '#1F4E78',
    font: { name: 'Arial', size: 9, bold: true, color: '#FFFFFF' },
    wrapText: true,
  };

  workbook.recalculate();
  const inspect = await workbook.inspect({
    kind: 'sheet,region',
    sheetId: 'Audit',
    range: `A1:D${rowCursor}`,
    maxChars: 12000,
    tableMaxRows: 40,
    tableMaxCols: 6,
  });
  await fs.writeFile(path.join(__dirname, 'M5_STEP5_MASTER_RESULTS_audit.inspect.ndjson'), inspect.ndjson, 'utf8');
  const preview = await workbook.render({ sheetName: 'Audit', autoCrop: 'all', scale: 1, format: 'png' });
  await fs.writeFile(path.join(__dirname, 'M5_STEP5_MASTER_RESULTS_audit.png'), new Uint8Array(await preview.arrayBuffer()));
  const xlsx = await SpreadsheetFile.exportXlsx(workbook);
  await xlsx.save(path.join(__dirname, 'M5_STEP5_MASTER_RESULTS_audit.xlsx'));
  console.log(inspect.ndjson);
}

main().catch((error) => {
  console.error(error && error.stack ? error.stack : error);
  process.exitCode = 1;
});
