"""Create Fig. 3 Version 2 in Origin from the three frozen plotting CSVs.

Version 2 changes presentation only.  It does not run MATLAB/Simulink,
modify source CSVs, derive values, smooth, fit, interpolate, or add points.
"""

from __future__ import annotations

import csv
import hashlib
import logging
import sys
from pathlib import Path

import originpro as op


ROOT = Path(__file__).resolve().parent
OPJU_PATH = ROOT / "Fig3_v2.opju"
TEMP_OPJU_PATH = ROOT / "Fig3_v2_build_tmp.opju"
PREVIEW_PATH = ROOT / "Fig3_v2_preview.png"
LOG_PATH = ROOT / "draw_fig3_origin_v2.log"

SOURCE_FILES = {
    "a": ROOT / "fig3a_bias_norm.csv",
    "b": ROOT / "fig3b_retention_error.csv",
    "c": ROOT / "fig3c_gate_weight.csv",
}

EXPECTED_SHA256 = {
    "a": "26F240855D9ACF6C1A9CAFFD6DF70FD6C9736369E2798858014E4DBAAD34EA91",
    "b": "A6A33B6C0B9A861417F36694114EEBE7D363CED89926CC29C6A7878648DA6678",
    "c": "762FCC11DC7D0AFF790B67F4CCFC456A5B7E129482540D502A55F59A913F5676",
}

EXPECTED_HEADERS = {
    "a": [
        "fault_factor",
        "VFF_RLS_bias_norm_pF",
        "HG_VFF_RLS_bias_norm_pF",
        "REW_VFF_RLS_bias_norm_pF",
    ],
    "b": [
        "fault_factor",
        "VFF_RLS_abs_retention_error_pct",
        "HG_VFF_RLS_abs_retention_error_pct",
        "REW_VFF_RLS_abs_retention_error_pct",
    ],
    "c": [
        "fault_factor",
        "HG_VFF_RLS_gate_active_ratio",
        "REW_VFF_RLS_mean_update_weight",
    ],
}

EXPECTED_X = [1.05, 1.10, 1.20, 1.30, 1.40, 1.60]

# Version 1 artifacts are read-only controls for the no-overwrite requirement.
V1_FILES = [
    ROOT / "Fig3.opju",
    ROOT / "Fig3_preview.png",
    ROOT / "Fig3_600dpi.png",
    ROOT / "FIG3_ORIGIN_REPORT.md",
]

FONT = "Times New Roman"
FONT_TICK_PT = 7.8
FONT_AXIS_PT = 8.5
FONT_PANEL_PT = 8.5
FONT_LEGEND_PT = 7.0

COLOR_BLACK = "#202020"
COLOR_HG = "#4D6680"
COLOR_REW = "#93483F"

LINE_WIDTH = 1.0
SYMBOL_SIZE = 8.0

METHOD_STYLE = {
    "VFF-RLS": {
        "color": COLOR_BLACK,
        "line_style": 0,
        "symbol_kind": 2,  # circle
        "symbol_interior": 1,
    },
    "HG-VFF-RLS": {
        "color": COLOR_HG,
        "line_style": 1,
        "symbol_kind": 1,  # square
        "symbol_interior": 2,
    },
    "REW-VFF-RLS": {
        "color": COLOR_REW,
        "line_style": 3,
        "symbol_kind": 4,  # triangle
        "symbol_interior": 2,
    },
}

PANEL_CONFIG = {
    "a": {
        "ylabel": "Parameter bias / pF",
        "ylim": (0.0, 7.5, 1.0),
        "series": ["VFF-RLS", "HG-VFF-RLS", "REW-VFF-RLS"],
        "legend": ["VFF-RLS", "HG-VFF-RLS", "REW-VFF-RLS"],
        "legend_xy": (1.075, 7.28),
        "panel_xy": (1.012, 7.38),
    },
    "b": {
        "ylabel": "|Retention error| / %",
        "ylim": (0.0, 13.5, 2.0),
        "series": ["VFF-RLS", "HG-VFF-RLS", "REW-VFF-RLS"],
        "legend": None,
        "panel_xy": (1.012, 13.30),
    },
    "c": {
        "ylabel": "Gate ratio / update weight",
        "ylim": (0.0, 1.0, 0.2),
        "series": ["HG-VFF-RLS", "REW-VFF-RLS"],
        "legend": ["HG-VFF-RLS gate", "REW-VFF-RLS weight"],
        "legend_xy": (1.325, 0.285),
        "panel_xy": (1.012, 0.985),
    },
}

PAGE_WIDTH_MM = 170.0
PAGE_HEIGHT_MM = 58.0

# Percent-of-page rectangles.  Identical top/width/height values guarantee
# equal plot areas and an exactly aligned X-axis baseline.
LAYER_RECTS = [
    (7.2, 7.0, 26.5, 71.0),
    (39.2, 7.0, 26.5, 71.0),
    (71.2, 7.0, 26.5, 71.0),
]


def configure_logging() -> logging.Logger:
    logger = logging.getLogger("draw_fig3_origin_v2")
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


def snapshot_v1() -> dict[Path, str]:
    missing = [path for path in V1_FILES if not path.is_file()]
    if missing:
        raise FileNotFoundError(f"Version 1 control files missing: {missing}")
    return {path: sha256_file(path) for path in V1_FILES}


def read_source(key: str) -> tuple[list[str], dict[str, list[float]]]:
    path = SOURCE_FILES[key]
    if not path.is_file():
        raise FileNotFoundError(f"Missing frozen plotting CSV: {path}")
    actual_hash = sha256_file(path)
    if actual_hash != EXPECTED_SHA256[key]:
        raise RuntimeError(
            f"Frozen source hash mismatch for {path.name}: "
            f"expected {EXPECTED_SHA256[key]}, got {actual_hash}"
        )
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames != EXPECTED_HEADERS[key]:
            raise RuntimeError(f"Unexpected headers in {path.name}")
        columns = {header: [] for header in reader.fieldnames}
        for row in reader:
            for header in reader.fieldnames:
                columns[header].append(float(row[header]))
    if columns["fault_factor"] != EXPECTED_X:
        raise RuntimeError(f"X values changed in {path.name}")
    if any(len(values) != 6 for values in columns.values()):
        raise RuntimeError(f"{path.name} must contain exactly six rows")
    LOGGER.info("Verified frozen source %s | SHA256=%s", path.name, actual_hash)
    return list(reader.fieldnames), columns


def load_sources() -> dict[str, tuple[list[str], dict[str, list[float]]]]:
    data = {key: read_source(key) for key in ("a", "b", "c")}
    gate = data["c"][1]["HG_VFF_RLS_gate_active_ratio"]
    weight = data["c"][1]["REW_VFF_RLS_mean_update_weight"]
    if not all(0.0 <= value <= 1.0 for value in gate + weight):
        raise RuntimeError("Fig.3(c) contains a value outside [0,1]")
    if gate != [0.0, 0.0, 0.0, 0.0, 0.96, 0.96]:
        raise RuntimeError(f"Frozen gate response changed: {gate}")
    return data


def import_book(key: str, headers: list[str], columns: dict[str, list[float]]):
    long_name = {"a": "Fig3A_Data", "b": "Fig3B_Data", "c": "Fig3C_Data"}[key]
    short_name = {"a": "F3AData", "b": "F3BData", "c": "F3CData"}[key]
    book = op.new_book("w", lname=long_name)
    book.name = short_name
    sheet = book[0]
    sheet.name = "Data"
    sheet.lname = SOURCE_FILES[key].name
    for index, header in enumerate(headers):
        units = ""
        if key == "a" and index > 0:
            units = "pF"
        elif key == "b" and index > 0:
            units = "%"
        sheet.from_list(
            index,
            columns[header],
            lname=header,
            units=units,
            comments=f"Unmodified plotting column from {SOURCE_FILES[key].name}",
            axis="X" if index == 0 else "Y",
        )
    return book, sheet


def set_page_size(graph) -> None:
    graph.activate()
    # Use GPage properties directly.  LabTalk page.width/page.height can be
    # ignored by the Origin 2024b default template.
    page_res_x = graph.get_float("resx")
    page_res_y = graph.get_float("resy")
    graph.set_int("kar", 0)
    graph.set_float("width", PAGE_WIDTH_MM / 25.4 * page_res_x)
    graph.set_float("height", PAGE_HEIGHT_MM / 25.4 * page_res_y)
    graph.lt_exec(
        "page.updatetoprinter=0; page.revcolor=0; page.color=color(white);"
    )


def set_layer_rect(layer, rect: tuple[float, float, float, float]) -> None:
    left, top, width, height = rect
    layer.set_int("unit", 1)
    layer.set_float("left", left)
    layer.set_float("top", top)
    layer.set_float("width", width)
    layer.set_float("height", height)
    layer.set_int("fixed", 1)
    layer.lt_exec("layer -f1;")


def style_axis(layer, ylabel: str, ylim: tuple[float, float, float]) -> None:
    # Numeric X axis with 0.2 major step.  Actual data remain at their exact
    # values, including 1.05 and 1.10.
    layer.set_xlim(1.0, 1.65, 0.20)
    layer.set_ylim(*ylim)
    layer.axis("x").title = f"\\f:{FONT}(Fault factor)"
    layer.axis("y").title = f"\\f:{FONT}({ylabel})"
    layer.activate()
    layer.lt_exec(
        f'layer.x.label.font=font("{FONT}"); '
        f'layer.y.label.font=font("{FONT}"); '
        f"layer.x.label.pt={FONT_TICK_PT}; layer.y.label.pt={FONT_TICK_PT}; "
        f'layer.x.label.color=color("{COLOR_BLACK}"); '
        f'layer.y.label.color=color("{COLOR_BLACK}"); '
        f'layer.x.color=color("{COLOR_BLACK}"); '
        f'layer.y.color=color("{COLOR_BLACK}"); '
        "layer.x.thickness=0.8; layer.y.thickness=0.8; "
        "layer.x.tickthickness=0.8; layer.y.tickthickness=0.8; "
        "layer.x.ticks=5; layer.y.ticks=5; "
        "layer.x.showGrids=0; layer.y.showGrids=0;"
    )
    for name in ("XB", "YL"):
        label = layer.label(name)
        if label:
            label.set_int("font", op.lt_int(f'font("{FONT}")'))
            label.set_float("fsize", FONT_AXIS_PT)
            label.color = COLOR_BLACK


def style_plot(plot, method: str, symbol_only: bool = False) -> None:
    style = METHOD_STYLE[method]
    plot.color = style["color"]
    plot.symbol_kind = style["symbol_kind"]
    plot.symbol_interior = style["symbol_interior"]
    plot.symbol_size = SYMBOL_SIZE
    prop = plot._format_property
    plot.layer.SetNumProp(prop("line.width"), 0.0 if symbol_only else LINE_WIDTH)
    plot.layer.SetNumProp(prop("line.style"), style["line_style"])
    plot.layer.SetNumProp(prop("aa"), 1)


def add_panel_label(layer, key: str) -> None:
    x, y = PANEL_CONFIG[key]["panel_xy"]
    label = layer.add_label(f"({key})", x, y)
    label.set_int("attach", 2)
    label.set_float("x1", x)
    label.set_float("y1", y)
    label.set_int("font", op.lt_int(f'font("{FONT}")'))
    label.set_float("fsize", FONT_PANEL_PT)
    label.set_int("bold", 1)
    label.color = COLOR_BLACK


def set_legend(layer, key: str) -> None:
    entries = PANEL_CONFIG[key]["legend"]
    if entries is None:
        existing = layer.label("Legend")
        if existing:
            existing.destroy()
        return
    layer.lt_exec("legend -s")
    legend = layer.label("Legend")
    if not legend:
        raise RuntimeError(f"Origin did not create a legend for panel {key}")
    legend.text = "\n".join(
        f"\\l({index + 1}) {text}" for index, text in enumerate(entries)
    )
    x, y = PANEL_CONFIG[key]["legend_xy"]
    legend.set_int("attach", 2)
    legend.set_float("x1", x)
    legend.set_float("y1", y)
    legend.set_int("font", op.lt_int(f'font("{FONT}")'))
    legend.set_float("fsize", FONT_LEGEND_PT)
    legend.color = COLOR_BLACK
    layer.lt_exec(
        f'legend.font=font("{FONT}"); legend.fsize={FONT_LEGEND_PT}; '
        "legend.showframe=0;"
    )


def populate_panel(layer, key: str, sheet) -> list:
    style_axis(layer, PANEL_CONFIG[key]["ylabel"], PANEL_CONFIG[key]["ylim"])
    plots = []
    for y_column, method in enumerate(PANEL_CONFIG[key]["series"], start=1):
        symbol_only = key == "c" and method == "HG-VFF-RLS"
        plot_type = "s" if symbol_only else "y"
        plot = layer.add_plot(sheet, coly=y_column, colx=0, type=plot_type)
        if plot is None:
            raise RuntimeError(f"Failed to create panel {key} plot {method}")
        style_plot(plot, method, symbol_only=symbol_only)
        plots.append(plot)
    add_panel_label(layer, key)
    set_legend(layer, key)
    return plots


def create_combined_graph(sheets):
    graph = op.new_graph(lname="Fig3_V2_Combined", template="origin")
    graph.name = "Fig3V2"
    set_page_size(graph)
    while len(graph) < 3:
        graph.add_layer(0)
    layers = [graph[index] for index in range(3)]
    all_plots = {}
    for layer, key, rect in zip(layers, ("a", "b", "c"), LAYER_RECTS):
        set_layer_rect(layer, rect)
        all_plots[key] = populate_panel(layer, key, sheets[key])
    graph.activate()
    return graph, layers, all_plots


def validate_origin_content(data, sheets, graph, layers, plots) -> None:
    for key in ("a", "b", "c"):
        headers, columns = data[key]
        for column_index, header in enumerate(headers):
            imported = [float(value) for value in sheets[key].to_list(column_index)]
            if imported != columns[header]:
                raise RuntimeError(f"Origin/source mismatch for {key}/{header}")

    if len(graph) != 3:
        raise RuntimeError("Fig3_V2_Combined must contain exactly three layers")
    counts = [len(layer.plot_list()) for layer in layers]
    if counts != [3, 3, 2]:
        raise RuntimeError(f"Unexpected plot counts: {counts}")

    widths = [layer.get_float("width") for layer in layers]
    heights = [layer.get_float("height") for layer in layers]
    tops = [layer.get_float("top") for layer in layers]
    baselines = [top + height for top, height in zip(tops, heights)]
    for values, label in ((widths, "width"), (heights, "height"), (baselines, "baseline")):
        if max(values) - min(values) > 1e-9:
            raise RuntimeError(f"Layer {label} mismatch: {values}")

    # The first Fig.3(c) plot was created as Origin Scatter ('s'), and its
    # line width is also forced to zero as a second protection against a
    # connection between the 1.30 and 1.40 observations.
    gate_plot = plots["c"][0]
    gate_line_width = gate_plot.layer.GetNumProp(
        gate_plot._format_property("line.width")
    )
    if abs(float(gate_line_width)) > 1e-12:
        raise RuntimeError(f"HG gate plot is not symbol-only: width={gate_line_width}")

    if layers[0].label("Legend") is None:
        raise RuntimeError("Panel (a) compact legend is missing")
    if layers[1].label("Legend") is not None:
        raise RuntimeError("Panel (b) must not repeat the algorithm legend")
    if layers[2].label("Legend") is None:
        raise RuntimeError("Panel (c) compact legend is missing")

    LOGGER.info(
        "Origin validation passed | plots=%s | widths=%s | heights=%s | "
        "baselines=%s | gate_line_width=%s",
        counts,
        widths,
        heights,
        baselines,
        gate_line_width,
    )


def export_and_save(graph) -> None:
    outdir = str(ROOT).replace("/", "\\")
    graph.activate()
    graph.lt_exec(
        "expGraph type:=png filename:=\"Fig3_v2_preview\" "
        f"path:=\"{outdir}\" overwrite:=replace "
        "tr.Margin:=0 tr.SpeedMode:=2 "
        f"tr1.Unit:=1 tr1.Rescaling:=0 tr1.Width:={PAGE_WIDTH_MM / 10.0} "
        "tr2.PNG.dotsperinch:=300 "
        "tr2.PNG.bitsperpixel:=\"24-bit Color\";"
    )
    if TEMP_OPJU_PATH.exists():
        TEMP_OPJU_PATH.unlink()
    if not op.save(str(TEMP_OPJU_PATH)):
        raise RuntimeError(f"Origin failed to save {TEMP_OPJU_PATH}")
    op.new(asksave=False)
    TEMP_OPJU_PATH.replace(OPJU_PATH)
    if not op.open(str(OPJU_PATH), readonly=False, asksave=False):
        raise RuntimeError(f"Origin failed to reopen {OPJU_PATH}")
    reopened = op.find_graph("Fig3V2")
    if not reopened or len(reopened) != 3:
        raise RuntimeError("Saved Fig3_v2.opju did not reopen correctly")


def verify_outputs(v1_snapshot: dict[Path, str]) -> None:
    for path in (OPJU_PATH, PREVIEW_PATH):
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f"Missing or empty output: {path}")
        LOGGER.info("Output created: %s | %d bytes", path.name, path.stat().st_size)
    for key, path in SOURCE_FILES.items():
        if sha256_file(path) != EXPECTED_SHA256[key]:
            raise RuntimeError(f"Frozen source changed during V2 build: {path}")
    for path, expected_hash in v1_snapshot.items():
        if sha256_file(path) != expected_hash:
            raise RuntimeError(f"Version 1 artifact was modified: {path}")
    LOGGER.info("Frozen CSV and Version 1 hash checks passed")


def main() -> None:
    LOGGER.info("Starting Fig.3 Version 2 Origin build")
    v1_snapshot = snapshot_v1()
    data = load_sources()
    # Keep the dedicated automation instance hidden; the PNG is the review
    # artifact and closing the instance avoids leaving an OPJU file lock.
    op.set_show(False)
    op.new(asksave=False)
    LOGGER.info("Origin launched; no MATLAB/Simulink command was invoked")
    try:
        sheets = {}
        for key in ("a", "b", "c"):
            headers, columns = data[key]
            _, sheets[key] = import_book(key, headers, columns)
        graph, layers, plots = create_combined_graph(sheets)
        validate_origin_content(data, sheets, graph, layers, plots)
        export_and_save(graph)
        verify_outputs(v1_snapshot)
        LOGGER.info("Fig.3 Version 2 completed successfully")
    finally:
        op.exit()


if __name__ == "__main__":
    main()
