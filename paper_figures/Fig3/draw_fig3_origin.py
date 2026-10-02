"""Create the formal Origin project and preview for paper Fig. 3.

The script reads only the three frozen Fig. 3 plotting CSV files.  It does
not run MATLAB/Simulink, read plotting values from fig3_master.csv, derive
new metrics, smooth, fit, interpolate, or add data points.
"""

from __future__ import annotations

import csv
import hashlib
import logging
import math
import sys
from pathlib import Path

import originpro as op


SCRIPT_DIR = Path(__file__).resolve().parent
OPJU_PATH = SCRIPT_DIR / "Fig3.opju"
TEMP_OPJU_PATH = SCRIPT_DIR / "Fig3_build_tmp.opju"
PREVIEW_PATH = SCRIPT_DIR / "Fig3_preview.png"
PNG_600_PATH = SCRIPT_DIR / "Fig3_600dpi.png"
REPORT_PATH = SCRIPT_DIR / "FIG3_ORIGIN_REPORT.md"
LOG_PATH = SCRIPT_DIR / "draw_fig3_origin.log"

SOURCE_FILES = {
    "a": SCRIPT_DIR / "fig3a_bias_norm.csv",
    "b": SCRIPT_DIR / "fig3b_retention_error.csv",
    "c": SCRIPT_DIR / "fig3c_gate_weight.csv",
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
EXPECTED_SERIES = {"a": 3, "b": 3, "c": 2}

FONT = "Times New Roman"
FONT_TICK_PT = 8.0
FONT_AXIS_PT = 9.0
FONT_PANEL_PT = 10.0
FONT_LEGEND_PT = 7.5

COLOR_BLACK = "#202020"
COLOR_HG = "#4D6680"
COLOR_REW = "#93483F"

LINE_WIDTH = 1.45
SYMBOL_SIZE = 6.0

METHOD_STYLE = {
    "VFF-RLS": {
        "color": COLOR_BLACK,
        "line_style": 0,
        "symbol_kind": 1,
        "symbol_interior": 1,
    },
    "HG-VFF-RLS": {
        "color": COLOR_HG,
        "line_style": 1,
        "symbol_kind": 3,
        "symbol_interior": 2,
    },
    "REW-VFF-RLS": {
        "color": COLOR_REW,
        "line_style": 3,
        "symbol_kind": 4,
        "symbol_interior": 2,
    },
}

PANEL_CONFIG = {
    "a": {
        "ylabel": "Parameter bias norm / pF",
        "ylim": (0.0, 7.5, 1.0),
        "series": ["VFF-RLS", "HG-VFF-RLS", "REW-VFF-RLS"],
        "legend": ["VFF-RLS", "HG-VFF-RLS", "REW-VFF-RLS"],
        "legend_xy": (1.055, 7.25),
        "panel_xy": (1.012, 7.38),
    },
    "b": {
        "ylabel": "|Retention error| / %",
        "ylim": (0.0, 13.5, 2.0),
        "series": ["VFF-RLS", "HG-VFF-RLS", "REW-VFF-RLS"],
        "legend": ["VFF-RLS", "HG-VFF-RLS", "REW-VFF-RLS"],
        "legend_xy": (1.055, 13.05),
        "panel_xy": (1.012, 13.30),
    },
    "c": {
        "ylabel": "Gate / update response",
        "ylim": (0.0, 1.0, 0.2),
        "series": ["HG-VFF-RLS", "REW-VFF-RLS"],
        "legend": ["HG-VFF-RLS gate", "REW-VFF-RLS weight"],
        "legend_xy": (1.385, 0.19),
        "panel_xy": (1.012, 0.985),
    },
}

COMBINED_WIDTH_MM = 178.0
COMBINED_HEIGHT_MM = 150.0
COMBINED_LAYER_RECTS = [
    (8.0, 5.0, 40.0, 35.0),
    (56.0, 5.0, 40.0, 35.0),
    (8.0, 55.0, 88.0, 35.0),
]


def configure_logging() -> logging.Logger:
    logger = logging.getLogger("draw_fig3_origin")
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
            raise RuntimeError(
                f"Header mismatch for {path.name}: "
                f"expected {EXPECTED_HEADERS[key]}, got {reader.fieldnames}"
            )
        columns = {header: [] for header in reader.fieldnames}
        for row in reader:
            for header in reader.fieldnames:
                columns[header].append(float(row[header]))
    if len(columns["fault_factor"]) != 6:
        raise RuntimeError(f"{path.name} must contain exactly six data rows")
    if columns["fault_factor"] != EXPECTED_X:
        raise RuntimeError(
            f"X values changed in {path.name}: {columns['fault_factor']}"
        )
    if len(reader.fieldnames) - 1 != EXPECTED_SERIES[key]:
        raise RuntimeError(f"Unexpected Y-series count in {path.name}")
    LOGGER.info(
        "Verified %s | SHA256=%s | rows=6 | Y series=%d",
        path.name,
        actual_hash,
        EXPECTED_SERIES[key],
    )
    return list(reader.fieldnames), columns


def load_sources() -> dict[str, tuple[list[str], dict[str, list[float]]]]:
    data = {key: read_source(key) for key in ("a", "b", "c")}
    c_columns = data["c"][1]
    gate = c_columns["HG_VFF_RLS_gate_active_ratio"]
    weight = c_columns["REW_VFF_RLS_mean_update_weight"]
    if not all(0.0 <= value <= 1.0 for value in gate + weight):
        raise RuntimeError("Fig.3(c) contains a value outside [0,1]")
    if gate[:4] != [0.0, 0.0, 0.0, 0.0] or any(
        abs(value - 0.96) > 1e-12 for value in gate[4:]
    ):
        raise RuntimeError(f"Frozen HG-VFF-RLS gate response changed: {gate}")
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
        axis = "X" if index == 0 else "Y"
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
            axis=axis,
        )
    return book, sheet


def set_page_size(graph, width_mm: float, height_mm: float) -> None:
    graph.activate()
    graph.lt_exec(
        "page.updatetoprinter=0; page.kar=0; page.revcolor=0; "
        "page.color=color(white); "
        f"page.width=({width_mm}/25.4)*page.resx; "
        f"page.height=({height_mm}/25.4)*page.resy;"
    )


def set_layer_rect(layer, rect) -> None:
    left, top, width, height = rect
    layer.set_int("unit", 1)
    layer.set_float("left", left)
    layer.set_float("top", top)
    layer.set_float("width", width)
    layer.set_float("height", height)
    layer.set_int("fixed", 1)
    layer.lt_exec("layer -f1;")


def style_axis(layer, ylabel: str, ylim) -> None:
    layer.set_xlim(1.0, 1.65, 0.10)
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


def style_plot(plot, method: str) -> None:
    style = METHOD_STYLE[method]
    plot.color = style["color"]
    plot.symbol_kind = style["symbol_kind"]
    plot.symbol_interior = style["symbol_interior"]
    plot.symbol_size = SYMBOL_SIZE
    prop = plot._format_property
    plot.layer.SetNumProp(prop("line.width"), LINE_WIDTH)
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
    layer.lt_exec("legend -s")
    legend = layer.label("Legend")
    if not legend:
        raise RuntimeError(f"Origin did not create the legend for panel {key}")
    legend.text = "\n".join(
        f"\\l({index + 1}) {text}"
        for index, text in enumerate(PANEL_CONFIG[key]["legend"])
    )
    x, y = PANEL_CONFIG[key]["legend_xy"]
    legend.set_int("attach", 2)
    legend.set_float("x1", x)
    legend.set_float("y1", y)
    legend.set_int("font", op.lt_int(f'font("{FONT}")'))
    legend.set_float("fsize", FONT_LEGEND_PT)
    legend.set_int("frame", 0)
    legend.color = COLOR_BLACK


def populate_panel(layer, key: str, sheet) -> None:
    style_axis(layer, PANEL_CONFIG[key]["ylabel"], PANEL_CONFIG[key]["ylim"])
    for y_column, method in enumerate(PANEL_CONFIG[key]["series"], start=1):
        plot = layer.add_plot(sheet, coly=y_column, colx=0, type="y")
        if plot is None:
            raise RuntimeError(f"Failed to create panel {key} plot {method}")
        style_plot(plot, method)
    add_panel_label(layer, key)
    set_legend(layer, key)


def create_single_graph(key: str, sheet):
    long_name = {
        "a": "Fig3A_Bias",
        "b": "Fig3B_Retention",
        "c": "Fig3C_GateWeight",
    }[key]
    short_name = {"a": "Fig3A_Bias", "b": "Fig3B_Ret", "c": "Fig3C_GW"}[key]
    graph = op.new_graph(lname=long_name, template="origin")
    graph.name = short_name
    set_page_size(graph, 90.0 if key != "c" else 178.0, 70.0)
    layer = graph[0]
    set_layer_rect(layer, (14.0 if key != "c" else 8.0, 8.0, 80.0 if key != "c" else 88.0, 78.0))
    populate_panel(layer, key, sheet)
    graph.activate()
    return graph


def create_combined_graph(sheets):
    graph = op.new_graph(lname="Fig3_Combined", template="origin")
    graph.name = "Fig3Combined"
    set_page_size(graph, COMBINED_WIDTH_MM, COMBINED_HEIGHT_MM)
    while len(graph) < 3:
        graph.add_layer(0)
    layers = [graph[index] for index in range(3)]
    for layer, rect in zip(layers, COMBINED_LAYER_RECTS):
        set_layer_rect(layer, rect)
    for layer, key in zip(layers, ("a", "b", "c")):
        populate_panel(layer, key, sheets[key])
    graph.activate()
    return graph, layers


def validate_origin_content(data, sheets, single_graphs, combined_graph, combined_layers) -> None:
    for key in ("a", "b", "c"):
        headers, columns = data[key]
        for column_index, header in enumerate(headers):
            origin_values = sheets[key].to_list(column_index)
            source_values = columns[header]
            if len(origin_values) != 6:
                raise RuntimeError(f"Origin row count mismatch for {key}/{header}")
            max_error = max(
                abs(float(origin_value) - float(source_value))
                for origin_value, source_value in zip(origin_values, source_values)
            )
            if max_error > 1e-14:
                raise RuntimeError(
                    f"Origin/source mismatch for {key}/{header}: {max_error}"
                )

    expected_single_counts = {"a": 3, "b": 3, "c": 2}
    for key, graph in single_graphs.items():
        if len(graph) != 1:
            raise RuntimeError(f"Single graph {key} must contain one layer")
        actual_count = len(graph[0].plot_list())
        if actual_count != expected_single_counts[key]:
            raise RuntimeError(
                f"Single graph {key} plot count {actual_count}, "
                f"expected {expected_single_counts[key]}"
            )

    if len(combined_graph) != 3:
        raise RuntimeError("Fig3_Combined must contain exactly three layers")
    combined_counts = [len(layer.plot_list()) for layer in combined_layers]
    if combined_counts != [3, 3, 2]:
        raise RuntimeError(
            f"Combined plot counts changed: expected [3,3,2], got {combined_counts}"
        )

    expected_books = {"Fig3A_Data", "Fig3B_Data", "Fig3C_Data"}
    actual_books = {book.lname for book in op.pages("w")}
    if not expected_books.issubset(actual_books):
        raise RuntimeError(f"Missing Origin workbooks: {expected_books - actual_books}")
    expected_graphs = {
        "Fig3A_Bias",
        "Fig3B_Retention",
        "Fig3C_GateWeight",
        "Fig3_Combined",
    }
    actual_graphs = {graph.lname for graph in op.pages("g")}
    if not expected_graphs.issubset(actual_graphs):
        raise RuntimeError(f"Missing Origin graph pages: {expected_graphs - actual_graphs}")

    LOGGER.info(
        "Origin content validation passed: workbooks=%s graphs=%s combined plots=%s",
        sorted(expected_books),
        sorted(expected_graphs),
        combined_counts,
    )


def export_and_save(combined_graph) -> None:
    outdir = str(SCRIPT_DIR).replace("/", "\\")
    combined_graph.activate()
    combined_graph.lt_exec(
        "expGraph type:=png filename:=\"Fig3_preview\" "
        f"path:=\"{outdir}\" overwrite:=replace "
        "tr.Margin:=2 tr.SpeedMode:=2 "
        f"tr1.Unit:=1 tr1.Rescaling:=0 tr1.Width:={COMBINED_WIDTH_MM / 10.0} "
        "tr2.PNG.dotsperinch:=300 "
        "tr2.PNG.bitsperpixel:=\"24-bit Color\";"
    )
    combined_graph.lt_exec(
        "expGraph type:=png filename:=\"Fig3_600dpi\" "
        f"path:=\"{outdir}\" overwrite:=replace "
        "tr.Margin:=2 tr.SpeedMode:=2 "
        f"tr1.Unit:=1 tr1.Rescaling:=0 tr1.Width:={COMBINED_WIDTH_MM / 10.0} "
        "tr2.PNG.dotsperinch:=600 "
        "tr2.PNG.bitsperpixel:=\"24-bit Color\";"
    )
    if TEMP_OPJU_PATH.exists():
        TEMP_OPJU_PATH.unlink()
    if not op.save(str(TEMP_OPJU_PATH)):
        raise RuntimeError(f"Origin failed to save temporary project {TEMP_OPJU_PATH}")
    # Origin keeps the saved OPJU handle open while the project is active.
    # Close that project before the atomic replacement, then reopen the final
    # path so the user can inspect the delivered project in Origin.
    op.new(asksave=False)
    TEMP_OPJU_PATH.replace(OPJU_PATH)
    if not op.open(str(OPJU_PATH), readonly=False, asksave=False):
        raise RuntimeError(f"Origin failed to reopen final project {OPJU_PATH}")
    reopened_graph = op.find_graph("Fig3Combined")
    if reopened_graph:
        reopened_graph.activate()


def verify_outputs() -> None:
    for path in (OPJU_PATH, PREVIEW_PATH, PNG_600_PATH):
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f"Expected Origin output missing or empty: {path}")
        LOGGER.info("Output created: %s | %d bytes", path.name, path.stat().st_size)


def verify_sources_unchanged() -> None:
    for key, path in SOURCE_FILES.items():
        actual = sha256_file(path)
        if actual != EXPECTED_SHA256[key]:
            raise RuntimeError(f"Frozen source changed during Origin drawing: {path}")
    LOGGER.info("Post-run source hash check passed for all three plotting CSVs")


def write_report() -> None:
    report = f"""# Fig.3 Origin 绘图验收报告

## 输出

- Origin 工程：`paper_figures/Fig3/Fig3.opju`
- 论文预览图：`paper_figures/Fig3/Fig3_preview.png`（300 dpi）
- 高分辨率图：`paper_figures/Fig3/Fig3_600dpi.png`（600 dpi）

## 子图数据与曲线

| 子图 | 输入 CSV | Y 曲线数量 | 曲线 |
|---|---|---:|---|
| Fig.3(a) Fault-induced parameter bias | `fig3a_bias_norm.csv` | 3 | VFF-RLS, HG-VFF-RLS, REW-VFF-RLS |
| Fig.3(b) Fault retention error | `fig3b_retention_error.csv` | 3 | VFF-RLS, HG-VFF-RLS, REW-VFF-RLS |
| Fig.3(c) Hard-gate / continuous update-weight response | `fig3c_gate_weight.csv` | 2 | HG-VFF-RLS gate, REW-VFF-RLS weight |

三个 CSV 均直接导入对应 Origin workbook：`Fig3A_Data`、`Fig3B_Data`、`Fig3C_Data`。`fig3_master.csv` 仅用于数据整理阶段的交叉核对，本绘图脚本未从 master 读取或重新生成作图指标。

## X 数据点

`1.05, 1.10, 1.20, 1.30, 1.40, 1.60`

X 轴使用数值轴，数据点保持真实数值间距。没有分类等距处理或人为横向偏移。

## 图形结构与样式

- Origin 图页：`Fig3A_Bias`、`Fig3B_Retention`、`Fig3C_GateWeight`、`Fig3_Combined`。
- 组合图采用上排 (a)+(b)、下排 (c) 跨双栏宽度的 2+1 布局。
- 全部曲线均为 line + symbol，点间使用直线连接，仅作为视觉引导。
- Fig.3(c) 两条曲线使用同一左 Y 轴，范围为 0–1；未使用双 Y 轴。
- Fig.3(c) 未使用 step plot，未绘制阈值竖线，未增加门控切换点。
- 三种方法同时使用不同 symbol shape 与 line style 区分，并保留轻量颜色以兼顾屏幕和黑白打印。
- 图中方法名仅使用 VFF-RLS、HG-VFF-RLS、REW-VFF-RLS。
- 1.60 frozen anchor 正常绘制，未添加醒目的 anchor 标记。

## 数据与处理检查

- Fig.3(a)：6 个 X 点 × 3 个 Y 系列；无额外点。
- Fig.3(b)：6 个 X 点 × 3 个 Y 系列；无额外点。
- Fig.3(c)：6 个 X 点 × 2 个 Y 系列；无额外点。
- Fig.3(c) 全部 Y 值位于 0–1。
- HG-VFF-RLS gate：1.05–1.30 为 0；1.40 与 1.60 为 0.96。
- 未修改任何输入 CSV；绘图前后 SHA-256 一致。

DATA_MODIFIED = NO

SIMULATION_RERUN = NO

SMOOTHING = NO

FITTING = NO

INTERPOLATION = NO

ARTIFICIAL_POINTS = NO
"""
    REPORT_PATH.write_text(report, encoding="utf-8")
    LOGGER.info("Acceptance report created: %s", REPORT_PATH.name)


def main() -> None:
    LOGGER.info("Starting formal Fig.3 Origin build")
    data = load_sources()
    op.set_show(True)
    op.new(asksave=False)
    LOGGER.info("Origin launched; no MATLAB/Simulink command was invoked")

    books = {}
    sheets = {}
    for key in ("a", "b", "c"):
        headers, columns = data[key]
        books[key], sheets[key] = import_book(key, headers, columns)

    single_graphs = {
        key: create_single_graph(key, sheets[key]) for key in ("a", "b", "c")
    }
    combined_graph, combined_layers = create_combined_graph(sheets)
    validate_origin_content(
        data, sheets, single_graphs, combined_graph, combined_layers
    )
    export_and_save(combined_graph)
    verify_outputs()
    verify_sources_unchanged()
    write_report()

    LOGGER.info("Fig.3 Origin project and previews completed successfully")
    print("\nFig.3 generated. Origin remains open for inspection.", flush=True)
    print("Press Enter in this terminal after inspection to release the controller.", flush=True)
    input()


if __name__ == "__main__":
    main()
