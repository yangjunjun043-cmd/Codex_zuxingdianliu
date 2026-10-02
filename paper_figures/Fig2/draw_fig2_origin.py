"""Build the first formal Origin version of Fig. 2.

This script only reads the six frozen Fig. 2 CSV files.  It does not start
MATLAB/Simulink and it never writes to the CSV files.  The display-only ms
and mA columns for panel (c) are created in the Origin project workbook.
"""

from __future__ import annotations

import csv
import hashlib
import logging
import math
import sys
from pathlib import Path

import originpro as op


# ---------------------------------------------------------------------------
# Centralized figure parameters
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = SCRIPT_DIR
OPJU_PATH = OUTPUT_DIR / "Fig2.opju"
TIFF_PATH = OUTPUT_DIR / "Fig2.tif"
PDF_PATH = OUTPUT_DIR / "Fig2.pdf"
LOG_PATH = OUTPUT_DIR / "draw_fig2_origin.log"

SOURCE_FILES = {
    "panel_a": SCRIPT_DIR / "fig2a_fault_factor.csv",
    "panel_b_case05": SCRIPT_DIR / "fig2b_case05_cs.csv",
    "panel_b_case06": SCRIPT_DIR / "fig2b_case06_cs.csv",
    "panel_c_case05": SCRIPT_DIR / "fig2c_case05_waveform.csv",
    "panel_c_case06": SCRIPT_DIR / "fig2c_case06_waveform.csv",
    "panel_d": SCRIPT_DIR / "fig2d_summary.csv",
}

EXPECTED_SHA256 = {
    "panel_a": "B9E98896D3D671FB46CF8862FAB3C6C4C03C5CE35E5853889ACD1E5992068861",
    "panel_b_case05": "777CE1BC03E885361EC215D54BF3763D114462094DC9943BE86B4B3FCE9609BB",
    "panel_b_case06": "5605529E82F8007E6CC0D5A790647298F20B65FF1D81F6BA1112566D37C95C38",
    "panel_c_case05": "229EBDE1280A5D47CFD6F73938CBEB5E974D6B695E768F5B60598ECC58C79C58",
    "panel_c_case06": "EBB2C356ADAC228C7126A6EF108A0EDA6D18754DE5C69D9B8F75E7F0D3F5D1DC",
    "panel_d": "5FDD97E0F631588A6103588E8E310458D91DD816B1C82983E3236D9031C8312B",
}

EXPECTED_ROWS = {
    "panel_a": 165,
    "panel_b_case05": 165,
    "panel_b_case06": 165,
    "panel_c_case05": 2000,
    "panel_c_case06": 2000,
    "panel_d": 2,
}

PAGE_WIDTH_MM = 178.0
PAGE_HEIGHT_MM = 165.0
EXPORT_DPI = 600

FONT_LATIN = "Times New Roman"
FONT_CHINESE = "SimSun"
FONT_TICK_PT = 7.5
FONT_AXIS_PT = 8.5
FONT_PANEL_PT = 10.0

COLOR_BLACK = "#222222"
COLOR_BLUE = "#2F5D8A"
COLOR_RED = "#B54A3A"
COLOR_GRAY = "#A9A9A9"
COLOR_LIGHT_GRAY = "#D0D0D0"

LINE_WIDTH_MAIN = 1.5
LINE_WIDTH_SECONDARY = 1.35
LINE_WIDTH_REFERENCE = 0.9
SYMBOL_SIZE_MAIN = 5.0
SYMBOL_SIZE_DUMBBELL = 8.0
SYMBOL_SKIP_PANEL_A = 10

FAULT_ONSET_S = 3.0
PANEL_A_XLIM = (0.70, 4.00, 0.50)
PANEL_A_YLIM = (0.95, 1.65, 0.20)
PANEL_B_XLIM = (0.70, 4.00, 0.50)
PANEL_B_CS1_YLIM = (9.0, 18.5, 2.0)
PANEL_B_CS2_YLIM = (2.5, 10.8, 2.0)
PANEL_C_XLIM = (0.0, 40.0, 10.0)
PANEL_C_YLIM = (-1.2, 1.2, 0.4)
PANEL_D_XLIM = (1.35, 1.65, 0.05)
PANEL_D_YLIM = (0.5, 2.5, 0.5)

# Percent-of-page rectangles: left, top, width, height.
LAYER_RECTS = [
    (8.0, 4.0, 88.0, 15.0),   # (a)
    (8.0, 25.0, 40.0, 17.0),  # (b), Case05 Cs1
    (56.0, 25.0, 40.0, 17.0), # (b), Case06 Cs1
    (8.0, 49.0, 40.0, 17.0),  # (b), Case05 Cs2
    (56.0, 49.0, 40.0, 17.0), # (b), Case06 Cs2
    (8.0, 75.0, 25.5, 17.0),  # (c), Case05
    (38.0, 75.0, 25.5, 17.0), # (c), Case06
    (70.0, 75.0, 26.0, 17.0), # (d)
]


def configure_logging() -> logging.Logger:
    logger = logging.getLogger("draw_fig2_origin")
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


def verify_sources() -> None:
    """Fail before launching Origin if any frozen CSV differs."""
    for key, path in SOURCE_FILES.items():
        if not path.is_file():
            raise FileNotFoundError(f"Missing required source CSV: {path}")
        actual = sha256_file(path)
        expected = EXPECTED_SHA256[key]
        if actual != expected:
            raise RuntimeError(
                f"Frozen source hash mismatch for {path.name}: "
                f"expected {expected}, got {actual}"
            )
        LOGGER.info("Source verified: %s | SHA256=%s", path.name, actual)


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


def load_all_sources() -> dict[str, tuple[list[str], dict[str, list]]]:
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


def import_source_sheet(book, sheet_name: str, source_path: Path, headers, columns):
    sheet = book.add_sheet(sheet_name)
    sheet.lname = source_path.name
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
        axis = "N"
        sheet.from_list(
            index,
            columns[header],
            lname=header,
            units=units_by_name.get(header, ""),
            comments=f"Unmodified source column from {source_path.name}",
            axis=axis,
        )
    return sheet


def set_col_metadata(sheet, col: int, lname: str, units: str, comments: str, axis: str) -> None:
    values = sheet.to_list(col)
    sheet.from_list(col, values, lname=lname, units=units, comments=comments, axis=axis)


def add_panel_c_derived_columns(sheet, headers, columns) -> dict[str, int]:
    """Append display units only in Origin; all original columns stay untouched."""
    base = len(headers)
    time_ms = [float(value) * 1000.0 for value in columns["time_from_window_start_s"]]
    true_mA = [float(value) * 1000.0 for value in columns["true_fault_increment_B_A"]]
    false_mA = [float(value) * 1000.0 for value in columns["false_coupling_compensation_B_A"]]
    sheet.from_list(
        base,
        time_ms,
        lname="time_from_window_start_ms",
        units="ms",
        comments="Origin-only derived column: time_from_window_start_s * 1000",
        axis="X",
    )
    sheet.from_list(
        base + 1,
        true_mA,
        lname="true_fault_increment_B_mA",
        units="mA",
        comments="Origin-only derived column: true_fault_increment_B_A * 1000",
        axis="Y",
    )
    sheet.from_list(
        base + 2,
        false_mA,
        lname="false_coupling_compensation_B_mA",
        units="mA",
        comments="Origin-only derived column: false_coupling_compensation_B_A * 1000",
        axis="Y",
    )
    return {"time_ms": base, "true_mA": base + 1, "false_mA": base + 2}


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
    if xlabel:
        layer.axis("x").title = f"\\f:{FONT_LATIN}({xlabel})"
    else:
        layer.axis("x").title = ""
    if ylabel:
        layer.axis("y").title = f"\\f:{FONT_LATIN}({ylabel})"
    else:
        layer.axis("y").title = ""
    # Apply conservative, broadly supported layer properties.  More cosmetic
    # refinements can be made interactively after the first structural review.
    layer.set_int("tickstyle", 2)
    layer.set_float("tickw", 0.8)
    layer.set_float("tickl", 20.0)


def style_plot(
    plot,
    *,
    color: str,
    width: float,
    line_style: int = 0,
    symbol_kind: int | None = None,
    symbol_size: float | None = None,
    symbol_interior: int = 1,
    symbol_skip: int | None = None,
) -> None:
    plot.color = color
    prop = plot._format_property
    plot.layer.SetNumProp(prop("line.width"), width)
    plot.layer.SetNumProp(prop("line.style"), line_style)
    if symbol_kind is not None:
        plot.symbol_kind = symbol_kind
        plot.symbol_interior = symbol_interior
    if symbol_size is not None:
        plot.symbol_size = symbol_size
    if symbol_skip is not None:
        plot.layer.SetNumProp(prop("symbol.skip"), symbol_skip)


def add_vertical_reference(layer, x: float, ymin: float, ymax: float, color=COLOR_GRAY):
    line = layer.add_line(x, ymin, x, ymax)
    line.color = color
    line.width = LINE_WIDTH_REFERENCE
    line.type = 1
    return line


def add_data_label(layer, text: str, x: float, y: float, size: float = FONT_PANEL_PT):
    label = layer.add_label(text, x, y)
    label.set_int("attach", 2)
    label.set_float("x1", x)
    label.set_float("y1", y)
    label.set_float("fsize", size)
    label.color = COLOR_BLACK
    return label


def set_legend(layer, lines: list[str]) -> None:
    layer.lt_exec("legend -s")
    legend = layer.label("Legend")
    if legend:
        legend.text = "\n".join(f"\\l({index + 1}) {text}" for index, text in enumerate(lines))
        legend.set_float("fsize", FONT_TICK_PT)


def make_dumbbell_sheet(book, summary_columns):
    sheet = book.add_sheet("PanelDPlot")
    sheet.lname = "Panel (d) Origin-only plotting data"
    case_ids = [str(value) for value in summary_columns["case_id"]]
    row_by_case = {case_id: index for index, case_id in enumerate(case_ids)}
    y_by_case = {"Case05": 2.0, "Case06": 1.0}

    true_x = [float(summary_columns["true_fault_factor"][row_by_case[case]]) for case in ("Case05", "Case06")]
    m2_x = [float(summary_columns["vff_rls_estimated_fault_factor"][row_by_case[case]]) for case in ("Case05", "Case06")]
    cf_x = [float(summary_columns["counterfactual_parameter_fault_factor"][row_by_case[case]]) for case in ("Case05", "Case06")]
    y = [y_by_case["Case05"], y_by_case["Case06"]]

    connector_x = [m2_x[0], true_x[0], math.nan, m2_x[1], true_x[1]]
    connector_y = [y[0], y[0], math.nan, y[1], y[1]]
    data_columns = [
        (connector_x, "connector_x", "X"),
        (connector_y, "connector_y", "Y"),
        (true_x, "True", "X"),
        (y, "true_y", "Y"),
        (m2_x, "M2 VFF-RLS", "X"),
        (y, "m2_y", "Y"),
        (cf_x, "Counterfactual", "X"),
        (y, "counterfactual_y", "Y"),
    ]
    for col, (values, lname, axis) in enumerate(data_columns):
        sheet.from_list(
            col,
            values,
            lname=lname,
            comments="Origin-only plotting data derived from fig2d_summary.csv",
            axis=axis,
        )
    return sheet


def build_origin_project(data):
    op.set_show(True)
    op.new(asksave=False)
    LOGGER.info("Origin launched and GUI set visible")

    book = op.new_book("w", lname="Fig2 frozen data and Origin-only derived columns")
    default_sheet = book[0]
    default_sheet.name = "Index"
    default_sheet.lname = "Fig2 data provenance"
    default_sheet.from_list(0, ["Source CSVs verified by SHA-256 before import"], lname="note")

    sheets = {}
    sheet_specs = [
        ("panel_a", "PanelA"),
        ("panel_b_case05", "PanelB_Case05"),
        ("panel_b_case06", "PanelB_Case06"),
        ("panel_c_case05", "PanelC_Case05"),
        ("panel_c_case06", "PanelC_Case06"),
        ("panel_d", "PanelD_Raw"),
    ]
    for key, sheet_name in sheet_specs:
        headers, columns = data[key]
        sheets[key] = import_source_sheet(
            book, sheet_name, SOURCE_FILES[key], headers, columns
        )

    c05_derived = add_panel_c_derived_columns(
        sheets["panel_c_case05"], *data["panel_c_case05"]
    )
    c06_derived = add_panel_c_derived_columns(
        sheets["panel_c_case06"], *data["panel_c_case06"]
    )
    dumbbell_sheet = make_dumbbell_sheet(book, data["panel_d"][1])
    LOGGER.info("Created panel (c) ms/mA columns inside Origin only")

    graph = op.new_graph(lname="Fig2 Ungated VFF-RLS fault absorption mechanism", template="origin")
    graph.name = "Fig2"
    graph.activate()
    graph.lt_exec(
        # The stock graph template keeps its original aspect ratio unless KAR
        # is disabled, which would silently ignore the requested height.
        "page.updatetoprinter=0; page.kar=0; "
        f"page.width=({PAGE_WIDTH_MM}/25.4)*page.resx; "
        f"page.height=({PAGE_HEIGHT_MM}/25.4)*page.resy;"
    )
    while len(graph) < 8:
        graph.add_layer(0)
    layers = [graph[index] for index in range(8)]
    for layer, rect in zip(layers, LAYER_RECTS):
        set_layer_rect(layer, rect)

    # Panel (a): true fault factor, Case05 and Case06.
    layer = layers[0]
    style_layer(layer, PANEL_A_XLIM, PANEL_A_YLIM, "Time / s", "Fault factor")
    p1 = layer.add_plot(sheets["panel_a"], 2, 1, type="y")
    p2 = layer.add_plot(sheets["panel_a"], 3, 1, type="y")
    style_plot(
        p1, color=COLOR_BLACK, width=LINE_WIDTH_MAIN, line_style=0,
        symbol_kind=1, symbol_size=SYMBOL_SIZE_MAIN, symbol_interior=2,
        symbol_skip=SYMBOL_SKIP_PANEL_A,
    )
    style_plot(
        p2, color=COLOR_BLUE, width=LINE_WIDTH_MAIN, line_style=1,
        symbol_kind=3, symbol_size=SYMBOL_SIZE_MAIN, symbol_interior=2,
        symbol_skip=SYMBOL_SKIP_PANEL_A,
    )
    add_vertical_reference(layer, FAULT_ONSET_S, PANEL_A_YLIM[0], PANEL_A_YLIM[1])
    add_data_label(layer, "(a)", 0.72, 1.64)
    add_data_label(layer, "fault onset", 3.02, 1.62, FONT_TICK_PT)
    set_legend(layer, ["Case05", "Case06"])

    # Panel (b): Case05/Case06 columns and Cs1/Cs2 rows.
    b_specs = [
        (layers[1], "panel_b_case05", 2, 3, PANEL_B_CS1_YLIM, "", "C_s1 / pF", "Case05"),
        (layers[2], "panel_b_case06", 2, 3, PANEL_B_CS1_YLIM, "", "", "Case06"),
        (layers[3], "panel_b_case05", 4, 5, PANEL_B_CS2_YLIM, "Time / s", "C_s2 / pF", ""),
        (layers[4], "panel_b_case06", 4, 5, PANEL_B_CS2_YLIM, "Time / s", "", ""),
    ]
    for index, (layer, key, truth_col, est_col, ylim, xlabel, ylabel, subtitle) in enumerate(b_specs):
        style_layer(layer, PANEL_B_XLIM, ylim, xlabel, ylabel)
        truth = layer.add_plot(sheets[key], truth_col, 1, type="l")
        estimate = layer.add_plot(sheets[key], est_col, 1, type="l")
        style_plot(truth, color=COLOR_BLACK, width=LINE_WIDTH_SECONDARY, line_style=1)
        style_plot(estimate, color=COLOR_BLUE, width=LINE_WIDTH_MAIN, line_style=0)
        add_vertical_reference(layer, FAULT_ONSET_S, ylim[0], ylim[1])
        if subtitle:
            add_data_label(layer, subtitle, 2.00, ylim[1] - 0.05 * (ylim[1] - ylim[0]), FONT_AXIS_PT)
        if index == 0:
            add_data_label(layer, "(b)", 0.72, ylim[1] - 0.02 * (ylim[1] - ylim[0]))
            set_legend(layer, ["Truth", "M2 VFF-RLS"])

    # Panel (c): display-only ms/mA columns stored inside Origin.
    c_specs = [
        (layers[5], "panel_c_case05", c05_derived, "Case05"),
        (layers[6], "panel_c_case06", c06_derived, "Case06"),
    ]
    for index, (layer, key, derived, subtitle) in enumerate(c_specs):
        ylabel = "Current / mA" if index == 0 else ""
        style_layer(layer, PANEL_C_XLIM, PANEL_C_YLIM, "Relative time / ms", ylabel)
        true_wave = layer.add_plot(
            sheets[key], derived["true_mA"], derived["time_ms"], type="l"
        )
        false_wave = layer.add_plot(
            sheets[key], derived["false_mA"], derived["time_ms"], type="l"
        )
        style_plot(true_wave, color=COLOR_BLACK, width=LINE_WIDTH_MAIN, line_style=0)
        style_plot(false_wave, color=COLOR_RED, width=LINE_WIDTH_MAIN, line_style=1)
        add_data_label(layer, subtitle, 14.0, 1.12, FONT_AXIS_PT)
        if index == 0:
            add_data_label(layer, "(c)", 0.3, 1.17)
            set_legend(layer, ["True fault increment", "False coupling compensation"])

    # Panel (d): horizontal dumbbell comparison.
    layer = layers[7]
    style_layer(layer, PANEL_D_XLIM, PANEL_D_YLIM, "Fault factor", "")
    connector = layer.add_plot(dumbbell_sheet, 1, 0, type="l")
    true_plot = layer.add_plot(dumbbell_sheet, 3, 2, type="s")
    m2_plot = layer.add_plot(dumbbell_sheet, 5, 4, type="s")
    cf_plot = layer.add_plot(dumbbell_sheet, 7, 6, type="s")
    style_plot(connector, color=COLOR_LIGHT_GRAY, width=2.0, line_style=0)
    style_plot(
        true_plot, color=COLOR_BLACK, width=0.0, symbol_kind=4,
        symbol_size=SYMBOL_SIZE_DUMBBELL, symbol_interior=1,
    )
    style_plot(
        m2_plot, color=COLOR_BLUE, width=0.0, symbol_kind=1,
        symbol_size=SYMBOL_SIZE_DUMBBELL, symbol_interior=1,
    )
    style_plot(
        cf_plot, color=COLOR_RED, width=0.0, symbol_kind=2,
        symbol_size=SYMBOL_SIZE_DUMBBELL, symbol_interior=2,
    )
    add_vertical_reference(layer, 1.60, PANEL_D_YLIM[0], PANEL_D_YLIM[1], COLOR_GRAY)
    add_data_label(layer, "(d)", 1.352, 2.47)
    add_data_label(layer, "Case05", 1.352, 2.08, FONT_TICK_PT)
    add_data_label(layer, "Case06", 1.352, 1.08, FONT_TICK_PT)
    layer.lt_exec("legend -s")
    legend = layer.label("Legend")
    if legend:
        legend.text = (
            "\\l(2) True\n"
            "\\l(3) M2 VFF-RLS\n"
            "\\l(4) Counterfactual"
        )
        legend.set_float("fsize", FONT_TICK_PT)

    # Re-activate the completed figure before save/export.
    graph.activate()
    return book, sheets, graph, layers, c05_derived, c06_derived


def validate_origin_content(data, sheets, graph, layers, c05_derived, c06_derived) -> None:
    if len(graph) != 8:
        raise RuntimeError(f"Expected 8 graph layers, got {len(graph)}")
    expected_plot_counts = [2, 2, 2, 2, 2, 2, 2, 4]
    actual_plot_counts = [len(layer.plot_list()) for layer in layers]
    if actual_plot_counts != expected_plot_counts:
        raise RuntimeError(
            f"Unexpected plot counts: expected {expected_plot_counts}, got {actual_plot_counts}"
        )

    for key, derived in (
        ("panel_c_case05", c05_derived),
        ("panel_c_case06", c06_derived),
    ):
        _, columns = data[key]
        raw_time = sheets[key].to_list(2)
        raw_true = sheets[key].to_list(3)
        raw_false = sheets[key].to_list(4)
        if len(raw_time) != 2000 or len(raw_true) != 2000 or len(raw_false) != 2000:
            raise RuntimeError(f"Origin raw waveform row count mismatch for {key}")
        for origin_values, source_values, label in (
            (raw_time, columns["time_from_window_start_s"], "time_s"),
            (raw_true, columns["true_fault_increment_B_A"], "true_A"),
            (raw_false, columns["false_coupling_compensation_B_A"], "false_A"),
        ):
            max_error = max(abs(float(a) - float(b)) for a, b in zip(origin_values, source_values))
            if max_error > 1e-15:
                raise RuntimeError(f"Raw Origin/source mismatch for {key} {label}: {max_error}")
        derived_time = sheets[key].to_list(derived["time_ms"])
        derived_true = sheets[key].to_list(derived["true_mA"])
        derived_false = sheets[key].to_list(derived["false_mA"])
        for display_values, source_values, label in (
            (derived_time, columns["time_from_window_start_s"], "time_ms"),
            (derived_true, columns["true_fault_increment_B_A"], "true_mA"),
            (derived_false, columns["false_coupling_compensation_B_A"], "false_mA"),
        ):
            max_error = max(
                abs(float(display) - float(source) * 1000.0)
                for display, source in zip(display_values, source_values)
            )
            if max_error > 1e-12:
                raise RuntimeError(f"Derived Origin column mismatch for {key} {label}: {max_error}")

    LOGGER.info("Origin content validation passed: 8 layers, plots=%s", actual_plot_counts)
    LOGGER.info("Panel (c) raw A/s columns unchanged; Origin-only ms/mA columns verified")


def export_outputs(graph) -> None:
    output_path_lt = str(OUTPUT_DIR).replace("/", "\\")
    graph.activate()
    graph.lt_exec(
        "expGraph type:=tif filename:=\"Fig2\" "
        f"path:=\"{output_path_lt}\" overwrite:=replace "
        "tr.Margin:=2 tr.SpeedMode:=2 "
        f"tr1.Unit:=1 tr1.Rescaling:=0 tr1.Width:={PAGE_WIDTH_MM / 10.0} "
        f"tr2.TIF.dotsperinch:={EXPORT_DPI} "
        "tr2.TIF.bitsperpixel:=\"24-bit Color\" "
        "tr2.TIF.ColorSpace:=\"RGB\" tr2.TIF.Compression:=\"LZW\";"
    )
    graph.lt_exec(
        "expGraph type:=pdf filename:=\"Fig2\" "
        f"path:=\"{output_path_lt}\" overwrite:=replace "
        "tr.Margin:=2 tr.SpeedMode:=2 "
        f"tr1.Unit:=1 tr1.Rescaling:=0 tr1.Width:={PAGE_WIDTH_MM / 10.0} "
        f"tr.Advanced.Resolution:=1 tr.Advanced.DPI:={EXPORT_DPI} "
        "tr2.PDF.PDF.ColorTranslation:=0 tr2.PDF.Fonts.Embed:=1;"
    )
    op.save(str(OPJU_PATH))


def verify_outputs() -> None:
    for path in (OPJU_PATH, TIFF_PATH, PDF_PATH):
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f"Expected output was not created: {path}")
        LOGGER.info("Output created: %s | %d bytes", path, path.stat().st_size)


def verify_sources_unchanged() -> None:
    for key, path in SOURCE_FILES.items():
        actual = sha256_file(path)
        if actual != EXPECTED_SHA256[key]:
            raise RuntimeError(f"Source CSV changed during drawing: {path}")
    LOGGER.info("Post-run source hash check passed: all six CSV files unchanged")


def main() -> None:
    LOGGER.info("Starting formal Fig.2 Origin build")
    verify_sources()
    data = load_all_sources()
    book, sheets, graph, layers, c05_derived, c06_derived = build_origin_project(data)
    validate_origin_content(data, sheets, graph, layers, c05_derived, c06_derived)
    export_outputs(graph)
    verify_outputs()
    verify_sources_unchanged()
    LOGGER.info("Fig.2 first version completed successfully")
    LOGGER.info("OPJU: %s", OPJU_PATH)
    LOGGER.info("TIFF: %s", TIFF_PATH)
    LOGGER.info("PDF: %s", PDF_PATH)
    LOGGER.info("Origin remains open for manual inspection")
    print("\nFig.2 generated. Origin will remain open for manual inspection.")
    print("Press Enter in this terminal only when you want this Python controller to exit.")
    input()


if __name__ == "__main__":
    main()
