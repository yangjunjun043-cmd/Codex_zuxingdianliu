"""Create Fig2_simplified_v2 with split parameter-bias subpanels.

Only the layout and graphical expression of the left parameter-bias panel are
changed relative to Fig2_simplified. The two frozen source CSVs are read-only;
no smoothing, filtering, interpolation, resampling, or point modification is
performed. Derived parameter-bias and display-unit columns exist only in the
generated Origin workbook.
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
}
EXPECTED_SHA256 = {
    "parameter_bias": "777CE1BC03E885361EC215D54BF3763D114462094DC9943BE86B4B3FCE9609BB",
    "waveform": "229EBDE1280A5D47CFD6F73938CBEB5E974D6B695E768F5B60598ECC58C79C58",
}
EXPECTED_ROWS = {"parameter_bias": 165, "waveform": 2000}

V1_FILES = (
    SCRIPT_DIR / "Fig2_simplified.opju",
    SCRIPT_DIR / "Fig2_simplified.pdf",
    SCRIPT_DIR / "Fig2_simplified_preview.png",
)

OPJU_PATH = SCRIPT_DIR / "Fig2_simplified_v2.opju"
PDF_PATH = SCRIPT_DIR / "Fig2_simplified_v2.pdf"
PREVIEW_PATH = SCRIPT_DIR / "Fig2_simplified_v2_preview.png"
LOG_PATH = SCRIPT_DIR / "draw_fig2_simplified_v2_origin.log"

PAGE_WIDTH_MM = 178.0
PAGE_HEIGHT_MM = 68.0
PREVIEW_DPI = 300

FONT_LATIN = "Times New Roman"
FONT_TICK_PT = 7.5
FONT_AXIS_PT = 8.5
FONT_PANEL_PT = 9.5
FONT_ANNOTATION_PT = 7.0

COLOR_BLACK = "#202020"
COLOR_BLUE = "#2F5D8A"
COLOR_RED = "#9C3F35"
COLOR_REFERENCE = "#B8B8B8"

LINE_WIDTH_MAIN = 1.40
LINE_WIDTH_REFERENCE = 0.75
FAULT_ONSET_S = 3.00

PANEL_A_XLIM = (2.90, 3.80, 0.20)
PANEL_A1_YLIM = (-0.5, 5.5, 1.0)
PANEL_A2_YLIM = (-5.5, 0.5, 1.0)
PANEL_B_XLIM = (0.0, 40.0, 10.0)
PANEL_B_YLIM = (-1.2, 1.2, 0.4)

# Percent of page: left, top, width, height.
LAYER_RECTS = (
    (7.5, 7.5, 40.5, 31.5),   # (a1) delta Cs1
    (7.5, 47.5, 40.5, 31.5),  # (a2) delta Cs2
    (55.5, 7.5, 40.5, 71.5),  # (b) waveform; data/axes unchanged
)
LEFT_VISUAL_SCALE = LAYER_RECTS[2][3] / LAYER_RECTS[0][3]


def configure_logging() -> logging.Logger:
    logger = logging.getLogger("draw_fig2_simplified_v2_origin")
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


def snapshot_files(paths: tuple[Path, ...]) -> dict[Path, tuple[int, int]]:
    snapshot = {}
    for path in paths:
        if not path.is_file():
            raise FileNotFoundError(f"Reviewed V1 artifact is missing: {path}")
        stat = path.stat()
        snapshot[path] = (stat.st_size, stat.st_mtime_ns)
    return snapshot


def verify_frozen_inputs() -> None:
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
    return sheet, {
        "time_s": headers.index("time_s"),
        "delta_cs1": base,
        "delta_cs2": base + 1,
    }


def make_waveform_sheet(book, headers, columns):
    sheet = book.add_sheet("Case05_Waveform")
    sheet.lname = "Case05 waveform; original columns retained"
    import_original_columns(sheet, SOURCE_FILES["waveform"], headers, columns)

    base = len(headers)
    derived_specs = (
        (
            [float(value) * 1000.0 for value in columns["time_from_window_start_s"]],
            "time_from_window_start_ms",
            "ms",
            "Origin-only display column: time_from_window_start_s * 1000",
            "X",
        ),
        (
            [float(value) * 1000.0 for value in columns["true_fault_increment_B_A"]],
            "true_fault_increment_B_mA",
            "mA",
            "Origin-only display column: true_fault_increment_B_A * 1000",
            "Y",
        ),
        (
            [
                float(value) * 1000.0
                for value in columns["false_coupling_compensation_B_A"]
            ],
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
    # Prevent Origin from applying a different text scale to layers with
    # different frame heights; font sizes remain the declared point sizes.
    layer.set_int("fixed", 1)
    layer.lt_exec("layer -f1;")


def style_layer(
    layer,
    xlim,
    ylim,
    xlabel: str,
    ylabel: str,
    *,
    show_x_tick_labels: bool = True,
    visual_scale: float = 1.0,
) -> None:
    layer.set_xlim(*xlim)
    layer.set_ylim(*ylim)
    layer.axis("x").title = f"\\f:{FONT_LATIN}({xlabel})" if xlabel else ""
    layer.axis("y").title = f"\\f:{FONT_LATIN}({ylabel})"
    layer.lt_exec(
        f'layer.x.label.font=font("{FONT_LATIN}"); '
        f'layer.y.label.font=font("{FONT_LATIN}"); '
        f"layer.x.label.pt={FONT_TICK_PT * visual_scale}; "
        f"layer.y.label.pt={FONT_TICK_PT * visual_scale}; "
        f"layer.x.showlabel={1 if show_x_tick_labels else 0}; "
        f'xb.font=font("{FONT_LATIN}"); yl.font=font("{FONT_LATIN}"); '
        f"xb.fsize={FONT_AXIS_PT * visual_scale}; "
        f"yl.fsize={FONT_AXIS_PT * visual_scale}; "
        "layer.x.color=color(#202020); layer.y.color=color(#202020); "
        f"layer.x.thickness={0.8 * visual_scale}; "
        f"layer.y.thickness={0.8 * visual_scale}; "
        f"layer.x.tickthickness={0.8 * visual_scale}; "
        f"layer.y.tickthickness={0.8 * visual_scale}; "
        "layer.x.ticks=5; layer.y.ticks=5; "
        "layer.x.showGrids=0; layer.y.showGrids=0;"
    )
    # Address the actual title objects directly. The first graph layer can
    # otherwise retain the stock template's 22 pt Y-title size.
    y_title = layer.label("YL")
    if y_title:
        y_title.set_float("fsize", FONT_AXIS_PT * visual_scale)
    x_title = layer.label("XB")
    if x_title:
        x_title.set_float("fsize", FONT_AXIS_PT * visual_scale)


def style_plot(plot, *, color: str, width: float, line_style: int) -> None:
    plot.color = color
    prop = plot._format_property
    plot.layer.SetNumProp(prop("line.width"), width)
    op.lt_exec(
        f"range __fig2_plot = {plot.lt_range()}; set __fig2_plot -d {line_style};"
    )


def add_reference_line(
    layer, x1, y1, x2, y2, dashed: bool, *, visual_scale: float = 1.0
) -> None:
    line = layer.add_line(x1, y1, x2, y2)
    line.color = COLOR_REFERENCE
    line.width = LINE_WIDTH_REFERENCE * visual_scale
    line.type = 1 if dashed else 0


def add_label(layer, text: str, x: float, y: float, size: float, color=COLOR_BLACK):
    label = layer.add_label(text, x, y)
    label.text = f"\\f:{FONT_LATIN}({text})"
    label.set_int("attach", 2)
    label.set_float("x1", x)
    label.set_float("y1", y)
    label.set_float("fsize", size)
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

    book = op.new_book(
        "w", lname="Fig2 simplified V2 frozen data and Origin-only derived columns"
    )
    parameter_sheet, parameter_cols = make_parameter_bias_sheet(
        book, *data["parameter_bias"]
    )
    waveform_sheet, waveform_cols = make_waveform_sheet(book, *data["waveform"])
    LOGGER.info("All original columns retained; five display-only columns added in Origin")

    graph = op.new_graph(
        lname="Fig2 simplified V2 fault absorption mechanism", template="origin"
    )
    graph.name = "Fig2_simplified_v2"
    graph.activate()
    page_res_x = graph.get_float("resx")
    page_res_y = graph.get_float("resy")
    graph.set_int("kar", 0)
    graph.set_float("width", PAGE_WIDTH_MM / 25.4 * page_res_x)
    graph.set_float("height", PAGE_HEIGHT_MM / 25.4 * page_res_y)
    graph.lt_exec(
        "page.updatetoprinter=0; page.revcolor=0; page.color=color(white);"
    )
    while len(graph) < 3:
        graph.add_layer(0)
    layers = [graph[index] for index in range(3)]
    for layer, rect in zip(layers, LAYER_RECTS):
        set_layer_rect(layer, rect)

    # Panel (a1): delta Cs1 in the local fault window.
    layer_a1 = layers[0]
    style_layer(
        layer_a1,
        PANEL_A_XLIM,
        PANEL_A1_YLIM,
        "",
        "ΔCs1 / pF",
        show_x_tick_labels=False,
        visual_scale=LEFT_VISUAL_SCALE,
    )
    add_reference_line(
        layer_a1,
        FAULT_ONSET_S,
        PANEL_A1_YLIM[0],
        FAULT_ONSET_S,
        PANEL_A1_YLIM[1],
        dashed=True,
        visual_scale=LEFT_VISUAL_SCALE,
    )
    add_reference_line(
        layer_a1,
        PANEL_A_XLIM[0],
        0.0,
        PANEL_A_XLIM[1],
        0.0,
        dashed=False,
        visual_scale=LEFT_VISUAL_SCALE,
    )
    delta_cs1 = layer_a1.add_plot(
        parameter_sheet,
        parameter_cols["delta_cs1"],
        parameter_cols["time_s"],
        type="l",
    )
    style_plot(
        delta_cs1,
        color=COLOR_BLACK,
        width=LINE_WIDTH_MAIN * LEFT_VISUAL_SCALE,
        line_style=0,
    )
    auto_legend = layer_a1.label("Legend")
    if auto_legend:
        auto_legend.remove()
    add_label(
        layer_a1,
        "(a1)",
        2.91,
        5.28,
        FONT_PANEL_PT * LEFT_VISUAL_SCALE,
    )
    add_label(
        layer_a1,
        "Fault onset",
        3.012,
        4.72,
        FONT_ANNOTATION_PT * LEFT_VISUAL_SCALE,
        COLOR_REFERENCE,
    )

    # Panel (a2): delta Cs2 with the identical shared x range.
    layer_a2 = layers[1]
    style_layer(
        layer_a2,
        PANEL_A_XLIM,
        PANEL_A2_YLIM,
        "Time / s",
        "ΔCs2 / pF",
        visual_scale=LEFT_VISUAL_SCALE,
    )
    add_reference_line(
        layer_a2,
        FAULT_ONSET_S,
        PANEL_A2_YLIM[0],
        FAULT_ONSET_S,
        PANEL_A2_YLIM[1],
        dashed=True,
        visual_scale=LEFT_VISUAL_SCALE,
    )
    add_reference_line(
        layer_a2,
        PANEL_A_XLIM[0],
        0.0,
        PANEL_A_XLIM[1],
        0.0,
        dashed=False,
        visual_scale=LEFT_VISUAL_SCALE,
    )
    delta_cs2 = layer_a2.add_plot(
        parameter_sheet,
        parameter_cols["delta_cs2"],
        parameter_cols["time_s"],
        type="l",
    )
    style_plot(
        delta_cs2,
        color=COLOR_BLUE,
        width=LINE_WIDTH_MAIN * LEFT_VISUAL_SCALE,
        line_style=1,
    )
    auto_legend = layer_a2.label("Legend")
    if auto_legend:
        auto_legend.remove()
    add_label(
        layer_a2,
        "(a2)",
        2.91,
        0.28,
        FONT_PANEL_PT * LEFT_VISUAL_SCALE,
    )

    # Panel (b): preserved waveform data, units, axes, and curve definitions.
    layer_b = layers[2]
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
    if len(graph) != 3:
        raise RuntimeError(f"Expected 3 graph layers, got {len(graph)}")
    plot_counts = [len(layer.plot_list()) for layer in layers]
    if plot_counts != [1, 1, 2]:
        raise RuntimeError(f"Expected plot counts [1, 1, 2], got {plot_counts}")

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

    for derived_col, estimate_name, truth_name, label in (
        (
            parameter_cols["delta_cs1"],
            "cs1_vff_rls_estimate_pF",
            "cs1_truth_pF",
            "delta_cs1_pF",
        ),
        (
            parameter_cols["delta_cs2"],
            "cs2_vff_rls_estimate_pF",
            "cs2_truth_pF",
            "delta_cs2_pF",
        ),
    ):
        derived = parameter_sheet.to_list(derived_col)
        estimates = parameter_source[estimate_name]
        truths = parameter_source[truth_name]
        max_error = max(
            abs(float(value) - (float(estimate) - float(truth)))
            for value, estimate, truth in zip(derived, estimates, truths)
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

    local_count = sum(
        PANEL_A_XLIM[0] <= float(value) <= PANEL_A_XLIM[1]
        for value in parameter_source["time_s"]
    )
    if local_count != 45:
        raise RuntimeError(f"Unexpected local-window point count: {local_count}")

    LOGGER.info("Origin validation passed: 3 layers, plots=%s", plot_counts)
    LOGGER.info("Shared local x window verified: 2.90-3.80 s, 45 unchanged points")
    LOGGER.info("All raw and derived columns match their frozen definitions")


def export_outputs(graph) -> None:
    output_path_lt = str(SCRIPT_DIR).replace("/", "\\")
    graph.activate()
    graph.lt_exec(
        "expGraph type:=pdf filename:=\"Fig2_simplified_v2\" "
        f"path:=\"{output_path_lt}\" overwrite:=replace "
        "tr.Margin:=2 tr.SpeedMode:=2 "
        f"tr1.Unit:=1 tr1.Rescaling:=0 tr1.Width:={PAGE_WIDTH_MM / 10.0} "
        "tr.Advanced.Resolution:=1 "
        "tr2.PDF.PDF.ColorTranslation:=0 tr2.PDF.Fonts.Embed:=1;"
    )
    graph.lt_exec(
        "expGraph type:=png filename:=\"Fig2_simplified_v2_preview\" "
        f"path:=\"{output_path_lt}\" overwrite:=replace "
        "tr.Margin:=2 tr.SpeedMode:=2 "
        f"tr1.Unit:=1 tr1.Rescaling:=0 tr1.Width:={PAGE_WIDTH_MM / 10.0} "
        f"tr2.PNG.dotsperinch:={PREVIEW_DPI} "
        "tr2.PNG.bitsperpixel:=\"24-bit Color\";"
    )
    op.save(str(OPJU_PATH))


def verify_outputs_and_integrity(v1_snapshot) -> None:
    for path in (OPJU_PATH, PDF_PATH, PREVIEW_PATH):
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f"Expected output was not created: {path}")
        LOGGER.info("Output created: %s | %d bytes", path, path.stat().st_size)

    for key, path in SOURCE_FILES.items():
        actual_hash = sha256_file(path)
        if actual_hash != EXPECTED_SHA256[key]:
            raise RuntimeError(f"Frozen CSV changed during drawing: {path}")
    if snapshot_files(V1_FILES) != v1_snapshot:
        raise RuntimeError("A reviewed Fig2_simplified V1 artifact changed during V2 generation")
    LOGGER.info("Post-run integrity passed: source CSVs and all V1 artifacts unchanged")


def main() -> None:
    LOGGER.info("Starting Fig2_simplified_v2 Origin build")
    v1_snapshot = snapshot_files(V1_FILES)
    verify_frozen_inputs()
    data = load_sources()
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
    verify_outputs_and_integrity(v1_snapshot)
    LOGGER.info("Fig2_simplified_v2 completed successfully")
    LOGGER.info("OPJU: %s", OPJU_PATH)
    LOGGER.info("PDF: %s", PDF_PATH)
    LOGGER.info("Preview PNG: %s", PREVIEW_PATH)
    LOGGER.info("Origin remains open for manual inspection")
    print("\nFig2_simplified_v2 generated. Origin remains open for inspection.")
    try:
        input("Press Enter only when you want this controller to exit.\n")
    except EOFError:
        LOGGER.info("No interactive stdin; controller exited without closing Origin")


if __name__ == "__main__":
    main()
