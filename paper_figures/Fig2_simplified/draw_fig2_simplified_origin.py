"""Create the simplified two-panel Origin Fig. 2.

The script is deliberately limited to the frozen Phase1B Fig. 2 CSV files.
It does not start MATLAB/Simulink, modify source CSVs, smooth, filter,
interpolate, or resample any data. Display-unit and parameter-bias columns
exist only inside the generated Origin workbook.
"""

from __future__ import annotations

import csv
import hashlib
import logging
import sys
from pathlib import Path

import originpro as op


# ---------------------------------------------------------------------------
# Centralized paths, integrity constraints, and figure parameters
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parents[1]
SOURCE_DIR = PROJECT_ROOT / "paper_figures" / "Fig2"

SOURCE_FILES = {
    "parameter_bias": SOURCE_DIR / "fig2b_case05_cs.csv",
    "waveform": SOURCE_DIR / "fig2c_case05_waveform.csv",
    "summary": SOURCE_DIR / "fig2d_summary.csv",
}
EXPECTED_SHA256 = {
    "parameter_bias": "777CE1BC03E885361EC215D54BF3763D114462094DC9943BE86B4B3FCE9609BB",
    "waveform": "229EBDE1280A5D47CFD6F73938CBEB5E974D6B695E768F5B60598ECC58C79C58",
    "summary": "5FDD97E0F631588A6103588E8E310458D91DD816B1C82983E3236D9031C8312B",
}
EXPECTED_ROWS = {"parameter_bias": 165, "waveform": 2000, "summary": 2}

ARCHIVE_OPJU = SOURCE_DIR / "Fig2.opju"
ARCHIVE_OPJU_SHA256 = "7ACF3302A0CD220AC1A3429AFD61A3EFC041FFA2C680C0815EB3D81A9A0044B8"

OPJU_PATH = SCRIPT_DIR / "Fig2_simplified.opju"
PDF_PATH = SCRIPT_DIR / "Fig2_simplified.pdf"
PREVIEW_PATH = SCRIPT_DIR / "Fig2_simplified_preview.png"
TABLE_PATH = SCRIPT_DIR / "Fig2_fault_factor_table.md"
LOG_PATH = SCRIPT_DIR / "draw_fig2_simplified_origin.log"

PAGE_WIDTH_MM = 178.0
PAGE_HEIGHT_MM = 62.0
PREVIEW_DPI = 300

FONT_LATIN = "Times New Roman"
FONT_CHINESE = "SimSun"
FONT_TICK_PT = 8.0
FONT_AXIS_PT = 9.0
FONT_PANEL_PT = 10.0
FONT_ANNOTATION_PT = 7.5

COLOR_BLACK = "#202020"
COLOR_BLUE = "#2F5D8A"
COLOR_RED = "#9C3F35"
COLOR_REFERENCE = "#B8B8B8"

LINE_WIDTH_MAIN = 1.45
LINE_WIDTH_REFERENCE = 0.80
FAULT_ONSET_S = 3.00

PANEL_A_XLIM = (0.70, 4.00, 0.50)
PANEL_A_YLIM = (-6.0, 6.0, 2.0)
PANEL_B_XLIM = (0.0, 40.0, 10.0)
PANEL_B_YLIM = (-1.2, 1.2, 0.4)

# Percent of page: left, top, width, height. Equal width and height by design.
PANEL_RECTS = ((7.5, 8.5, 40.5, 70.5), (55.5, 8.5, 40.5, 70.5))


def configure_logging() -> logging.Logger:
    logger = logging.getLogger("draw_fig2_simplified_origin")
    logger.setLevel(logging.INFO)
    logger.handlers.clear()
    formatter = logging.Formatter("%(asctime)s | %(levelname)s | %(message)s")
    file_handler = logging.FileHandler(LOG_PATH, mode="w", encoding="utf-8")
    file_handler.setFormatter(formatter)
    stream_handler = logging.StreamHandler(sys.stdout)
    stream_handler.setFormatter(formatter)
    logger.addHandler(file_handler)
    logger.addHandler(stream_handler)
    return logger


LOGGER = configure_logging()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def verify_frozen_inputs() -> None:
    if not ARCHIVE_OPJU.is_file():
        raise FileNotFoundError(f"Archived Fig2 project is missing: {ARCHIVE_OPJU}")
    archive_hash = sha256_file(ARCHIVE_OPJU)
    if archive_hash != ARCHIVE_OPJU_SHA256:
        raise RuntimeError(
            f"Archived Fig2.opju differs from the reviewed archive: {archive_hash}"
        )
    LOGGER.info("Archive verified read-only: %s | SHA256=%s", ARCHIVE_OPJU, archive_hash)

    for key, path in SOURCE_FILES.items():
        if not path.is_file():
            raise FileNotFoundError(f"Missing frozen source CSV: {path}")
        actual_hash = sha256_file(path)
        if actual_hash != EXPECTED_SHA256[key]:
            raise RuntimeError(
                f"Frozen CSV hash mismatch for {path.name}: "
                f"expected {EXPECTED_SHA256[key]}, got {actual_hash}"
            )
        LOGGER.info("Source verified: %s | SHA256=%s", path.name, actual_hash)


def parse_value(text: str):
    if text == "":
        return ""
    try:
        return float(text)
    except ValueError:
        return text


def read_csv_columns(path: Path) -> tuple[list[str], dict[str, list]]:
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if not reader.fieldnames:
            raise RuntimeError(f"CSV has no header: {path}")
        headers = list(reader.fieldnames)
        columns = {header: [] for header in headers}
        for row in reader:
            for header in headers:
                columns[header].append(parse_value(row[header]))
    return headers, columns


def load_sources() -> dict[str, tuple[list[str], dict[str, list]]]:
    loaded = {}
    for key, path in SOURCE_FILES.items():
        headers, columns = read_csv_columns(path)
        row_count = len(columns[headers[0]])
        if row_count != EXPECTED_ROWS[key]:
            raise RuntimeError(
                f"Unexpected row count for {path.name}: "
                f"expected {EXPECTED_ROWS[key]}, got {row_count}"
            )
        loaded[key] = (headers, columns)
        LOGGER.info("Loaded %s: %d rows, %d columns", path.name, row_count, len(headers))
    return loaded


def write_summary_table(summary_columns: dict[str, list]) -> None:
    required_cases = ("Case05", "Case06")
    row_by_case = {
        str(case_id): index for index, case_id in enumerate(summary_columns["case_id"])
    }
    missing = [case for case in required_cases if case not in row_by_case]
    if missing:
        raise RuntimeError(f"Missing summary cases: {missing}")

    lines = [
        "| 工况 | True fault factor | M2 estimated | Counterfactual |",
        "|---|---:|---:|---:|",
    ]
    for case in required_cases:
        index = row_by_case[case]
        true_value = float(summary_columns["true_fault_factor"][index])
        m2_value = float(summary_columns["vff_rls_estimated_fault_factor"][index])
        counterfactual = float(
            summary_columns["counterfactual_parameter_fault_factor"][index]
        )
        lines.append(
            f"| {case} | {true_value:.3f} | {m2_value:.3f} | {counterfactual:.3f} |"
        )
    TABLE_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    LOGGER.info("Markdown table created from fig2d_summary.csv: %s", TABLE_PATH)


def import_original_columns(sheet, source_path: Path, headers, columns) -> None:
    units_by_name = {
        "time_s": "s",
        "time_from_window_start_s": "s",
        "cs1_truth_pF": "pF",
        "cs1_vff_rls_estimate_pF": "pF",
        "cs2_truth_pF": "pF",
        "cs2_vff_rls_estimate_pF": "pF",
        "true_fault_increment_B_A": "A",
        "false_coupling_compensation_B_A": "A",
    }
    for index, header in enumerate(headers):
        sheet.from_list(
            index,
            columns[header],
            lname=header,
            units=units_by_name.get(header, ""),
            comments=f"Unmodified source column from {source_path.name}",
            axis="N",
        )


def make_parameter_bias_sheet(book, headers, columns):
    sheet = book[0]
    sheet.name = "Case05_ParameterBias"
    sheet.lname = "Case05 parameter bias; original columns retained"
    import_original_columns(sheet, SOURCE_FILES["parameter_bias"], headers, columns)

    base = len(headers)
    delta_cs1 = [
        float(estimate) - float(truth)
        for estimate, truth in zip(
            columns["cs1_vff_rls_estimate_pF"], columns["cs1_truth_pF"]
        )
    ]
    delta_cs2 = [
        float(estimate) - float(truth)
        for estimate, truth in zip(
            columns["cs2_vff_rls_estimate_pF"], columns["cs2_truth_pF"]
        )
    ]
    sheet.from_list(
        base,
        delta_cs1,
        lname="delta_cs1_pF",
        units="pF",
        comments=(
            "Origin-only derived column: cs1_vff_rls_estimate_pF "
            "- cs1_truth_pF"
        ),
        axis="Y",
    )
    sheet.from_list(
        base + 1,
        delta_cs2,
        lname="delta_cs2_pF",
        units="pF",
        comments=(
            "Origin-only derived column: cs2_vff_rls_estimate_pF "
            "- cs2_truth_pF"
        ),
        axis="Y",
    )
    return sheet, {"time_s": headers.index("time_s"), "delta_cs1": base, "delta_cs2": base + 1}


def make_waveform_sheet(book, headers, columns):
    sheet = book.add_sheet("Case05_Waveform")
    sheet.lname = "Case05 waveform; original columns retained"
    import_original_columns(sheet, SOURCE_FILES["waveform"], headers, columns)

    base = len(headers)
    time_ms = [float(value) * 1000.0 for value in columns["time_from_window_start_s"]]
    true_mA = [float(value) * 1000.0 for value in columns["true_fault_increment_B_A"]]
    false_mA = [
        float(value) * 1000.0
        for value in columns["false_coupling_compensation_B_A"]
    ]
    derived_specs = (
        (
            time_ms,
            "time_from_window_start_ms",
            "ms",
            "Origin-only display column: time_from_window_start_s * 1000",
            "X",
        ),
        (
            true_mA,
            "true_fault_increment_B_mA",
            "mA",
            "Origin-only display column: true_fault_increment_B_A * 1000",
            "Y",
        ),
        (
            false_mA,
            "false_coupling_compensation_B_mA",
            "mA",
            "Origin-only display column: false_coupling_compensation_B_A * 1000",
            "Y",
        ),
    )
    for offset, (values, lname, units, comments, axis) in enumerate(derived_specs):
        sheet.from_list(
            base + offset,
            values,
            lname=lname,
            units=units,
            comments=comments,
            axis=axis,
        )
    return sheet, {"time_ms": base, "true_mA": base + 1, "false_mA": base + 2}


def set_layer_rect(layer, rect) -> None:
    left, top, width, height = rect
    layer.set_int("unit", 1)
    layer.set_float("left", left)
    layer.set_float("top", top)
    layer.set_float("width", width)
    layer.set_float("height", height)


def style_layer(layer, xlim, ylim, xlabel: str, ylabel: str) -> None:
    layer.set_xlim(*xlim)
    layer.set_ylim(*ylim)
    layer.axis("x").title = f"\\f:{FONT_LATIN}({xlabel})"
    layer.axis("y").title = f"\\f:{FONT_LATIN}({ylabel})"
    layer.lt_exec(
        f'layer.x.label.font=font("{FONT_LATIN}"); '
        f'layer.y.label.font=font("{FONT_LATIN}"); '
        f"layer.x.label.pt={FONT_TICK_PT}; layer.y.label.pt={FONT_TICK_PT}; "
        f'xb.font=font("{FONT_LATIN}"); yl.font=font("{FONT_LATIN}"); '
        f"xb.fsize={FONT_AXIS_PT}; yl.fsize={FONT_AXIS_PT}; "
        "layer.x.color=color(#202020); layer.y.color=color(#202020); "
        "layer.x.thickness=0.8; layer.y.thickness=0.8; "
        "layer.x.tickthickness=0.8; layer.y.tickthickness=0.8; "
        "layer.x.ticks=5; layer.y.ticks=5; "
        "layer.x.showGrids=0; layer.y.showGrids=0;"
    )


def style_plot(plot, *, color: str, width: float, line_style: int) -> None:
    plot.color = color
    prop = plot._format_property
    plot.layer.SetNumProp(prop("line.width"), width)
    # Line style is most reliably controlled by LabTalk's set -d command.
    op.lt_exec(
        f"range __fig2_plot = {plot.lt_range()}; set __fig2_plot -d {line_style};"
    )


def add_reference_line(layer, x1, y1, x2, y2, dashed: bool) -> None:
    line = layer.add_line(x1, y1, x2, y2)
    line.color = COLOR_REFERENCE
    line.width = LINE_WIDTH_REFERENCE
    line.type = 1 if dashed else 0


def add_label(layer, text: str, x: float, y: float, size: float, color=COLOR_BLACK):
    label = layer.add_label(text, x, y)
    label.text = f"\\f:{FONT_LATIN}({text})"
    label.set_int("attach", 2)
    label.set_float("x1", x)
    label.set_float("y1", y)
    label.set_float("fsize", size)
    label.set_int("font", 1)
    label.color = color
    return label


def set_legend(layer, text: str, x: float, y: float) -> None:
    layer.lt_exec("legend -s")
    legend = layer.label("Legend")
    if not legend:
        raise RuntimeError("Origin did not create a legend object")
    legend.text = text
    legend.set_int("attach", 2)
    legend.set_float("x1", x)
    legend.set_float("y1", y)
    legend.set_float("fsize", FONT_ANNOTATION_PT)
    layer.lt_exec(
        f'legend.font=font("{FONT_LATIN}"); '
        f"legend.fsize={FONT_ANNOTATION_PT}; legend.showframe=0;"
    )


def build_origin_project(data):
    op.set_show(True)
    op.new(asksave=False)
    LOGGER.info("Origin started; GUI is visible")

    book = op.new_book("w", lname="Fig2 simplified frozen data and Origin-only derived columns")
    parameter_sheet, parameter_cols = make_parameter_bias_sheet(book, *data["parameter_bias"])
    waveform_sheet, waveform_cols = make_waveform_sheet(book, *data["waveform"])
    LOGGER.info("All original columns retained; five display-only columns added in Origin")

    graph = op.new_graph(lname="Fig2 simplified fault absorption mechanism", template="origin")
    graph.name = "Fig2_simplified"
    graph.activate()
    # Set page dimensions through the GPage properties. LabTalk page.width/
    # page.height assignments are ignored by some Origin releases/templates.
    page_res_x = graph.get_float("resx")
    page_res_y = graph.get_float("resy")
    graph.set_int("kar", 0)
    graph.set_float("width", PAGE_WIDTH_MM / 25.4 * page_res_x)
    graph.set_float("height", PAGE_HEIGHT_MM / 25.4 * page_res_y)
    graph.lt_exec(
        "page.updatetoprinter=0; page.revcolor=0; page.color=color(white);"
    )
    while len(graph) < 2:
        graph.add_layer(0)
    layers = [graph[index] for index in range(2)]
    for layer, rect in zip(layers, PANEL_RECTS):
        set_layer_rect(layer, rect)

    # Panel (a): fault-induced parameter bias.
    layer_a = layers[0]
    style_layer(
        layer_a,
        PANEL_A_XLIM,
        PANEL_A_YLIM,
        "Time / s",
        "Parameter bias, ΔCs / pF",
    )
    add_reference_line(
        layer_a,
        FAULT_ONSET_S,
        PANEL_A_YLIM[0],
        FAULT_ONSET_S,
        PANEL_A_YLIM[1],
        dashed=True,
    )
    add_reference_line(
        layer_a,
        PANEL_A_XLIM[0],
        0.0,
        PANEL_A_XLIM[1],
        0.0,
        dashed=False,
    )
    delta_cs1 = layer_a.add_plot(
        parameter_sheet,
        parameter_cols["delta_cs1"],
        parameter_cols["time_s"],
        type="l",
    )
    delta_cs2 = layer_a.add_plot(
        parameter_sheet,
        parameter_cols["delta_cs2"],
        parameter_cols["time_s"],
        type="l",
    )
    style_plot(delta_cs1, color=COLOR_BLACK, width=LINE_WIDTH_MAIN, line_style=0)
    style_plot(delta_cs2, color=COLOR_BLUE, width=LINE_WIDTH_MAIN, line_style=1)
    add_label(layer_a, "(a)", 0.72, 5.75, FONT_PANEL_PT)
    add_label(layer_a, "Fault onset", 3.03, 5.20, FONT_ANNOTATION_PT, COLOR_REFERENCE)
    set_legend(
        layer_a,
        "\\l(1) ΔCs1    \\l(2) ΔCs2",
        1.10,
        5.35,
    )

    # Panel (b): physical consequence, retaining every raw sample.
    layer_b = layers[1]
    style_layer(
        layer_b,
        PANEL_B_XLIM,
        PANEL_B_YLIM,
        "Relative time / ms",
        "Current / mA",
    )
    add_reference_line(
        layer_b,
        PANEL_B_XLIM[0],
        0.0,
        PANEL_B_XLIM[1],
        0.0,
        dashed=False,
    )
    true_wave = layer_b.add_plot(
        waveform_sheet,
        waveform_cols["true_mA"],
        waveform_cols["time_ms"],
        type="l",
    )
    false_wave = layer_b.add_plot(
        waveform_sheet,
        waveform_cols["false_mA"],
        waveform_cols["time_ms"],
        type="l",
    )
    style_plot(true_wave, color=COLOR_BLACK, width=LINE_WIDTH_MAIN, line_style=0)
    style_plot(false_wave, color=COLOR_RED, width=LINE_WIDTH_MAIN, line_style=1)
    add_label(layer_b, "(b)", 0.35, 1.15, FONT_PANEL_PT)
    set_legend(
        layer_b,
        "\\l(1) True fault increment\n\\l(2) False coupling compensation",
        13.0,
        1.10,
    )

    graph.activate()
    return book, graph, layers, parameter_sheet, parameter_cols, waveform_sheet, waveform_cols


def validate_origin_content(
    data,
    graph,
    layers,
    parameter_sheet,
    parameter_cols,
    waveform_sheet,
    waveform_cols,
) -> None:
    if len(graph) != 2:
        raise RuntimeError(f"Expected 2 graph layers, got {len(graph)}")
    plot_counts = [len(layer.plot_list()) for layer in layers]
    if plot_counts != [2, 2]:
        raise RuntimeError(f"Expected plot counts [2, 2], got {plot_counts}")

    parameter_headers, parameter_source = data["parameter_bias"]
    waveform_headers, waveform_source = data["waveform"]

    for sheet, headers, source_columns, label in (
        (parameter_sheet, parameter_headers, parameter_source, "parameter_bias"),
        (waveform_sheet, waveform_headers, waveform_source, "waveform"),
    ):
        for index, header in enumerate(headers):
            origin_values = sheet.to_list(index)
            source_values = source_columns[header]
            if len(origin_values) != len(source_values):
                raise RuntimeError(f"Row-count mismatch for {label}.{header}")
            for origin_value, source_value in zip(origin_values, source_values):
                if isinstance(source_value, float):
                    if abs(float(origin_value) - source_value) > 1e-15:
                        raise RuntimeError(f"Raw value changed in {label}.{header}")
                elif str(origin_value) != str(source_value):
                    raise RuntimeError(f"Raw text changed in {label}.{header}")

    derived_checks = (
        (
            parameter_sheet.to_list(parameter_cols["delta_cs1"]),
            parameter_source["cs1_vff_rls_estimate_pF"],
            parameter_source["cs1_truth_pF"],
            1.0,
            "delta_cs1_pF",
        ),
        (
            parameter_sheet.to_list(parameter_cols["delta_cs2"]),
            parameter_source["cs2_vff_rls_estimate_pF"],
            parameter_source["cs2_truth_pF"],
            1.0,
            "delta_cs2_pF",
        ),
    )
    for derived, first, second, scale, label in derived_checks:
        max_error = max(
            abs(float(value) - (float(a) - float(b)) * scale)
            for value, a, b in zip(derived, first, second)
        )
        if max_error > 1e-12:
            raise RuntimeError(f"Derived column mismatch for {label}: {max_error}")

    for derived_col, source_name, label in (
        (waveform_cols["time_ms"], "time_from_window_start_s", "time_ms"),
        (waveform_cols["true_mA"], "true_fault_increment_B_A", "true_mA"),
        (
            waveform_cols["false_mA"],
            "false_coupling_compensation_B_A",
            "false_mA",
        ),
    ):
        derived = waveform_sheet.to_list(derived_col)
        source = waveform_source[source_name]
        max_error = max(
            abs(float(display) - float(raw) * 1000.0)
            for display, raw in zip(derived, source)
        )
        if max_error > 1e-12:
            raise RuntimeError(f"Display-unit column mismatch for {label}: {max_error}")

    LOGGER.info("Origin validation passed: 2 layers, exactly 2 plots per layer")
    LOGGER.info("All raw columns match CSV values; derived columns match exact definitions")


def export_outputs(graph) -> None:
    output_path_lt = str(SCRIPT_DIR).replace("/", "\\")
    graph.activate()
    graph.lt_exec(
        "expGraph type:=pdf filename:=\"Fig2_simplified\" "
        f"path:=\"{output_path_lt}\" overwrite:=replace "
        "tr.Margin:=2 tr.SpeedMode:=2 "
        f"tr1.Unit:=1 tr1.Rescaling:=0 tr1.Width:={PAGE_WIDTH_MM / 10.0} "
        "tr.Advanced.Resolution:=1 "
        "tr2.PDF.PDF.ColorTranslation:=0 tr2.PDF.Fonts.Embed:=1;"
    )
    graph.lt_exec(
        "expGraph type:=png filename:=\"Fig2_simplified_preview\" "
        f"path:=\"{output_path_lt}\" overwrite:=replace "
        "tr.Margin:=2 tr.SpeedMode:=2 "
        f"tr1.Unit:=1 tr1.Rescaling:=0 tr1.Width:={PAGE_WIDTH_MM / 10.0} "
        f"tr2.PNG.dotsperinch:={PREVIEW_DPI} "
        "tr2.PNG.bitsperpixel:=\"24-bit Color\";"
    )
    op.save(str(OPJU_PATH))


def verify_outputs_and_integrity() -> None:
    for path in (OPJU_PATH, PDF_PATH, PREVIEW_PATH, TABLE_PATH):
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f"Expected output was not created: {path}")
        LOGGER.info("Output created: %s | %d bytes", path, path.stat().st_size)

    for key, path in SOURCE_FILES.items():
        actual_hash = sha256_file(path)
        if actual_hash != EXPECTED_SHA256[key]:
            raise RuntimeError(f"Frozen CSV changed during drawing: {path}")
    if sha256_file(ARCHIVE_OPJU) != ARCHIVE_OPJU_SHA256:
        raise RuntimeError("Archived Fig2.opju changed during simplified figure generation")
    LOGGER.info("Post-run integrity check passed: source CSVs and archived Fig2.opju unchanged")


def main() -> None:
    LOGGER.info("Starting simplified Fig.2 Origin build")
    verify_frozen_inputs()
    data = load_sources()
    write_summary_table(data["summary"][1])
    (
        _book,
        graph,
        layers,
        parameter_sheet,
        parameter_cols,
        waveform_sheet,
        waveform_cols,
    ) = build_origin_project(data)
    validate_origin_content(
        data,
        graph,
        layers,
        parameter_sheet,
        parameter_cols,
        waveform_sheet,
        waveform_cols,
    )
    export_outputs(graph)
    verify_outputs_and_integrity()
    LOGGER.info("Simplified Fig.2 completed successfully")
    LOGGER.info("OPJU: %s", OPJU_PATH)
    LOGGER.info("PDF: %s", PDF_PATH)
    LOGGER.info("Preview PNG: %s", PREVIEW_PATH)
    LOGGER.info("Markdown table: %s", TABLE_PATH)
    LOGGER.info("Origin remains open for manual inspection")
    print("\nSimplified Fig.2 generated. Origin remains open for manual inspection.")
    print("Press Enter in this terminal only when you want this controller to exit.")
    try:
        input()
    except EOFError:
        # Non-interactive runners have no stdin. Origin remains visible because
        # the script deliberately does not call op.exit().
        LOGGER.info("No interactive stdin; controller exited without closing Origin")


if __name__ == "__main__":
    main()
