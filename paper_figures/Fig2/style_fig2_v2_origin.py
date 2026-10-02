"""Apply V2 layout/style edits to the approved Fig2.opju project.

The script copies and opens Fig2.opju, changes only graph-page layout and
styling, verifies that every worksheet value and every plot data binding is
unchanged, and then saves/export the V2 deliverables.  No CSV is rewritten.
"""

from __future__ import annotations

import hashlib
import logging
import math
import shutil
import struct
import sys
from pathlib import Path

import originpro as op


# ---------------------------------------------------------------------------
# Centralized V2 styling parameters
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
V1_OPJU = SCRIPT_DIR / "Fig2.opju"
WORKING_OPJU = SCRIPT_DIR / "Fig2_v2_working.opju"
V2_OPJU = SCRIPT_DIR / "Fig2_v2.opju"
V2_PDF = SCRIPT_DIR / "Fig2_v2.pdf"
V2_PREVIEW = SCRIPT_DIR / "Fig2_v2_preview.png"
LOG_PATH = SCRIPT_DIR / "style_fig2_v2_origin.log"

CSV_FILES = [
    SCRIPT_DIR / "fig2a_fault_factor.csv",
    SCRIPT_DIR / "fig2b_case05_cs.csv",
    SCRIPT_DIR / "fig2b_case06_cs.csv",
    SCRIPT_DIR / "fig2c_case05_waveform.csv",
    SCRIPT_DIR / "fig2c_case06_waveform.csv",
    SCRIPT_DIR / "fig2d_summary.csv",
]

EXPECTED_CSV_SHA256 = {
    "fig2a_fault_factor.csv": "B9E98896D3D671FB46CF8862FAB3C6C4C03C5CE35E5853889ACD1E5992068861",
    "fig2b_case05_cs.csv": "777CE1BC03E885361EC215D54BF3763D114462094DC9943BE86B4B3FCE9609BB",
    "fig2b_case06_cs.csv": "5605529E82F8007E6CC0D5A790647298F20B65FF1D81F6BA1112566D37C95C38",
    "fig2c_case05_waveform.csv": "229EBDE1280A5D47CFD6F73938CBEB5E974D6B695E768F5B60598ECC58C79C58",
    "fig2c_case06_waveform.csv": "EBB2C356ADAC228C7126A6EF108A0EDA6D18754DE5C69D9B8F75E7F0D3F5D1DC",
    "fig2d_summary.csv": "5FDD97E0F631588A6103588E8E310458D91DD816B1C82983E3236D9031C8312B",
}

PAGE_WIDTH_MM = 178.0
PAGE_HEIGHT_MM = 153.0
PREVIEW_DPI = 300

FONT_LATIN = "Times New Roman"
FONT_TICK_PT = 8.0
FONT_AXIS_PT = 8.5
FONT_LEGEND_PT = 7.6
FONT_PANEL_PT = 9.5
FONT_SUBTITLE_PT = 8.2
FONT_VALUE_PT = 7.2

COLOR_BLACK = "#222222"
COLOR_BLUE = "#2F5D8A"
COLOR_RED = "#B54A3A"
COLOR_GRAY = "#9A9A9A"

AXIS_WIDTH_PT = 0.8
TICK_WIDTH_PT = 0.8
CURVE_WIDTH_PT = 1.35
REFERENCE_WIDTH_PT = 0.8

# left, top, width, height in % of page.  Panel (a) is deliberately shallow;
# the bottom data area is divided approximately 61% to panel (c), 39% to (d).
LAYER_RECTS = [
    (8.0, 4.0, 88.0, 12.0),
    (8.0, 23.0, 40.0, 17.5),
    (56.0, 23.0, 40.0, 17.5),
    (8.0, 47.0, 40.0, 17.5),
    (56.0, 47.0, 40.0, 17.5),
    (8.0, 73.0, 24.5, 20.0),
    (35.5, 73.0, 24.5, 20.0),
    (64.0, 73.0, 32.0, 20.0),
]

EXPECTED_PLOT_COUNTS = [2, 2, 2, 2, 2, 2, 2, 4]
EXPECTED_LIMITS = [
    ((0.70, 4.00, 0.50), (0.95, 1.65, 0.20)),
    ((0.70, 4.00, 0.50), (9.0, 18.5, 2.0)),
    ((0.70, 4.00, 0.50), (9.0, 18.5, 2.0)),
    ((0.70, 4.00, 0.50), (2.5, 10.8, 2.0)),
    ((0.70, 4.00, 0.50), (2.5, 10.8, 2.0)),
    ((0.0, 40.0, 10.0), (-1.2, 1.2, 0.4)),
    ((0.0, 40.0, 10.0), (-1.2, 1.2, 0.4)),
    ((1.35, 1.65, 0.05), (0.5, 2.5, 0.5)),
]


def configure_logging() -> logging.Logger:
    logger = logging.getLogger("style_fig2_v2_origin")
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


def verify_csv_hashes() -> dict[str, str]:
    hashes = {}
    for path in CSV_FILES:
        actual = sha256_file(path)
        expected = EXPECTED_CSV_SHA256[path.name]
        if actual != expected:
            raise RuntimeError(
                f"Frozen CSV hash mismatch for {path.name}: expected {expected}, got {actual}"
            )
        hashes[path.name] = actual
        LOGGER.info("Frozen CSV verified: %s | %s", path.name, actual)
    return hashes


def update_digest_with_value(digest, value) -> None:
    if isinstance(value, str):
        encoded = value.encode("utf-8")
        digest.update(b"S" + len(encoded).to_bytes(8, "big") + encoded)
    elif value is None:
        digest.update(b"N")
    else:
        digest.update(b"F" + struct.pack(">d", float(value)))


def origin_data_digest() -> tuple[str, list[tuple[str, str, int, int]]]:
    """Hash every worksheet value without changing any workbook content."""
    digest = hashlib.sha256()
    metadata = []
    books = sorted(list(op.pages("w")), key=lambda item: item.name)
    for book in books:
        for sheet in book:
            metadata.append((book.name, sheet.name, sheet.rows, sheet.cols))
            digest.update(book.name.encode("utf-8") + b"\0" + sheet.name.encode("utf-8"))
            digest.update(struct.pack(">II", sheet.rows, sheet.cols))
            for col in range(sheet.cols):
                values = sheet.to_list(col)
                digest.update(struct.pack(">I", len(values)))
                for value in values:
                    update_digest_with_value(digest, value)
    return digest.hexdigest().upper(), metadata


def plot_binding_snapshot(graph) -> list[list[str]]:
    return [[plot.lt_range() for plot in layer.plot_list()] for layer in graph]


def set_layer_rect(layer, rect) -> None:
    left, top, width, height = rect
    layer.set_int("unit", 1)
    layer.set_float("left", left)
    layer.set_float("top", top)
    layer.set_float("width", width)
    layer.set_float("height", height)


def style_axis(layer, xlim, ylim, *, show_x_labels=True, show_y_labels=True) -> None:
    layer.set_xlim(*xlim)
    layer.set_ylim(*ylim)
    layer.activate()
    layer.lt_exec(
        f'layer.x.label.font=font("{FONT_LATIN}"); '
        f'layer.y.label.font=font("{FONT_LATIN}"); '
        f"layer.x.label.pt={FONT_TICK_PT}; layer.y.label.pt={FONT_TICK_PT}; "
        f'layer.x.label.color=color("{COLOR_BLACK}"); '
        f'layer.y.label.color=color("{COLOR_BLACK}"); '
        f'layer.x.color=color("{COLOR_BLACK}"); layer.y.color=color("{COLOR_BLACK}"); '
        f"layer.x.thickness={AXIS_WIDTH_PT}; layer.y.thickness={AXIS_WIDTH_PT}; "
        f"layer.x.tickthickness={TICK_WIDTH_PT}; layer.y.tickthickness={TICK_WIDTH_PT}; "
        "layer.x.ticks=5; layer.y.ticks=5; "
        "layer.x.showGrids=0; layer.y.showGrids=0; "
        f"layer.x.showlabel={1 if show_x_labels else 0}; "
        f"layer.y.showlabel={1 if show_y_labels else 0};"
    )
    for name in ("xb", "yl", "xt", "yr"):
        label = layer.label(name)
        if label:
            label.set_int("font", op.lt_int(f'font("{FONT_LATIN}")'))
            label.set_float("fsize", FONT_AXIS_PT)
            label.color = COLOR_BLACK


def style_plot_lines(graph) -> None:
    for layer_index, layer in enumerate(graph):
        for plot_index, plot in enumerate(layer.plot_list()):
            prop = plot._format_property
            # The connector in panel (d) stays neutral and slightly lighter.
            width = 1.5 if (layer_index == 7 and plot_index == 0) else CURVE_WIDTH_PT
            plot.layer.SetNumProp(prop("line.width"), width)
            plot.layer.SetNumProp(prop("aa"), 1)
    # Panel (a) symbols are retained but reduced to avoid a dense comb effect.
    for plot in graph[0].plot_list():
        plot.symbol_size = 3.2


def iter_text_objects(layer):
    for obj in layer.obj.GraphObjects:
        try:
            text = obj.Text
        except Exception:
            continue
        if text is not None:
            yield obj, str(text)


def find_text_object(layer, exact_text: str):
    for obj, text in iter_text_objects(layer):
        if text == exact_text:
            return obj
    return None


def set_text_object(
    layer,
    exact_text: str,
    *,
    x: float,
    y: float,
    new_text: str | None = None,
    size: float = FONT_SUBTITLE_PT,
    bold: bool = False,
) -> None:
    obj = find_text_object(layer, exact_text)
    if obj is None:
        raise RuntimeError(f"Text object not found in layer {layer.index() + 1}: {exact_text}")
    obj.Text = new_text if new_text is not None else exact_text
    obj.SetNumProp("attach", 2)
    obj.SetNumProp("x1", x)
    obj.SetNumProp("y1", y)
    obj.SetNumProp("font", op.lt_int(f'font("{FONT_LATIN}")'))
    obj.SetNumProp("fsize", size)
    obj.SetNumProp("color", op.lt_int(f'color("{COLOR_BLACK}")'))
    obj.SetNumProp("bold", 1 if bold else 0)


def style_legend(layer, text: str, x: float, y: float) -> None:
    legend = layer.label("Legend")
    if legend is None:
        raise RuntimeError(f"Legend not found in layer {layer.index() + 1}")
    legend.text = text
    legend.set_int("attach", 2)
    legend.set_float("x1", x)
    legend.set_float("y1", y)
    legend.set_int("font", op.lt_int(f'font("{FONT_LATIN}")'))
    legend.set_float("fsize", FONT_LEGEND_PT)
    legend.set_int("frame", 0)
    legend.set_float("transparency", 100)
    legend.color = COLOR_BLACK


def remove_legend_if_present(layer) -> None:
    legend = layer.label("Legend")
    if legend is not None:
        layer.remove_label(legend)


def add_value_label(layer, text: str, x: float, y: float, color: str) -> None:
    label = layer.add_label(text, x, y)
    label.set_int("attach", 2)
    label.set_float("x1", x)
    label.set_float("y1", y)
    label.set_int("font", op.lt_int(f'font("{FONT_LATIN}")'))
    label.set_float("fsize", FONT_VALUE_PT)
    label.set_int("frame", 0)
    label.set_float("transparency", 100)
    label.color = color


def add_panel_d_value_labels(layer) -> None:
    # Labels are annotations only; plotted point coordinates are untouched.
    values = {
        "Case05": (1.59999999999967, 1.40107479735928, 1.60105115428053),
        "Case06": (1.59999999999967, 1.40226869710244, 1.60264742837203),
    }
    for case_id, y in (("Case05", 2.0), ("Case06", 1.0)):
        true_value, m2_value, cf_value = values[case_id]
        add_value_label(layer, f"M2 {m2_value:.3f}", m2_value + 0.004, y + 0.13, COLOR_BLUE)
        add_value_label(layer, f"True {true_value:.3f}", 1.555, y + 0.20, COLOR_BLACK)
        add_value_label(layer, f"CF {cf_value:.3f}", 1.555, y - 0.17, COLOR_RED)


def apply_v2_style(graph) -> None:
    if len(graph) != 8:
        raise RuntimeError(f"Expected 8 layers in approved V1 project, got {len(graph)}")

    graph.activate()
    graph.lt_exec(
        "page.updatetoprinter=0; page.kar=0; page.revcolor=0; "
        "page.color=color(white); "
        f"page.width=({PAGE_WIDTH_MM}/25.4)*page.resx; "
        f"page.height=({PAGE_HEIGHT_MM}/25.4)*page.resy;"
    )

    for layer, rect, (xlim, ylim) in zip(graph, LAYER_RECTS, EXPECTED_LIMITS):
        set_layer_rect(layer, rect)
        style_axis(layer, xlim, ylim)

    # Remove repeated tick labels while preserving the corresponding axes.
    style_axis(graph[1], *EXPECTED_LIMITS[1], show_x_labels=False, show_y_labels=True)
    style_axis(graph[2], *EXPECTED_LIMITS[2], show_x_labels=False, show_y_labels=False)
    style_axis(graph[3], *EXPECTED_LIMITS[3], show_x_labels=True, show_y_labels=True)
    style_axis(graph[4], *EXPECTED_LIMITS[4], show_x_labels=True, show_y_labels=False)
    style_axis(graph[5], *EXPECTED_LIMITS[5], show_x_labels=True, show_y_labels=True)
    style_axis(graph[6], *EXPECTED_LIMITS[6], show_x_labels=True, show_y_labels=False)
    style_axis(graph[7], *EXPECTED_LIMITS[7], show_x_labels=True, show_y_labels=False)

    # Keep the approved axis titles but avoid repetition.
    graph[1].axis("x").title = ""
    graph[2].axis("x").title = ""
    graph[2].axis("y").title = ""
    graph[4].axis("y").title = ""
    graph[6].axis("y").title = ""
    graph[7].axis("y").title = ""

    style_plot_lines(graph)

    # Strictly aligned panel labels and column/subplot titles.
    set_text_object(graph[0], "(a)", x=0.715, y=1.645, size=FONT_PANEL_PT, bold=True)
    set_text_object(graph[1], "(b)", x=0.715, y=18.35, size=FONT_PANEL_PT, bold=True)
    set_text_object(graph[5], "(c)", x=0.10, y=1.18, size=FONT_PANEL_PT, bold=True)
    set_text_object(graph[7], "(d)", x=1.352, y=2.45, size=FONT_PANEL_PT, bold=True)

    set_text_object(graph[1], "Case05", x=2.02, y=18.34, size=FONT_SUBTITLE_PT, bold=True)
    set_text_object(graph[2], "Case06", x=2.02, y=18.34, size=FONT_SUBTITLE_PT, bold=True)
    set_text_object(graph[5], "Case05", x=15.8, y=1.13, size=FONT_SUBTITLE_PT, bold=True)
    set_text_object(graph[6], "Case06", x=15.8, y=1.13, size=FONT_SUBTITLE_PT, bold=True)
    set_text_object(graph[7], "Case05", x=1.352, y=2.08, size=FONT_SUBTITLE_PT, bold=True)
    set_text_object(graph[7], "Case06", x=1.352, y=1.08, size=FONT_SUBTITLE_PT, bold=True)
    set_text_object(graph[0], "fault onset", x=3.02, y=1.62, size=FONT_VALUE_PT)

    # One legend per logical panel; all legend frames are removed.
    style_legend(graph[0], "\\l(1) Case05    \\l(2) Case06", 3.34, 1.64)
    style_legend(
        graph[1],
        "\\l(1) Truth    \\l(2) M2 VFF-RLS estimate",
        2.15,
        18.35,
    )
    for index in range(2, 5):
        remove_legend_if_present(graph[index])
    style_legend(
        graph[5],
        "\\l(1) True fault increment    \\l(2) False coupling compensation",
        2.0,
        1.18,
    )
    remove_legend_if_present(graph[6])
    style_legend(
        graph[7],
        "\\l(2) True    \\l(3) M2    \\l(4) Counterfactual",
        1.43,
        2.46,
    )

    add_panel_d_value_labels(graph[7])
    graph.activate()


def export_outputs(graph) -> None:
    outdir = str(SCRIPT_DIR).replace("/", "\\")
    graph.activate()
    graph.lt_exec(
        "expGraph type:=pdf filename:=\"Fig2_v2\" "
        f"path:=\"{outdir}\" overwrite:=replace "
        "tr.Margin:=2 tr.SpeedMode:=2 "
        f"tr1.Unit:=1 tr1.Rescaling:=0 tr1.Width:={PAGE_WIDTH_MM / 10.0} "
        "tr.Advanced.Resolution:=1 tr2.PDF.PDF.ColorTranslation:=0 "
        "tr2.PDF.Fonts.Embed:=1;"
    )
    graph.lt_exec(
        "expGraph type:=png filename:=\"Fig2_v2_preview\" "
        f"path:=\"{outdir}\" overwrite:=replace "
        "tr.Margin:=2 tr.SpeedMode:=2 "
        f"tr1.Unit:=1 tr1.Rescaling:=0 tr1.Width:={PAGE_WIDTH_MM / 10.0} "
        f"tr2.PNG.dotsperinch:={PREVIEW_DPI} "
        "tr2.PNG.bitsperpixel:=\"24-bit Color\";"
    )


def verify_outputs() -> None:
    for path in (V2_OPJU, V2_PDF, V2_PREVIEW):
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f"Expected V2 output missing or empty: {path}")
        LOGGER.info("V2 output created: %s | %d bytes", path, path.stat().st_size)


def main() -> None:
    LOGGER.info("Starting Fig.2 V2 style-only update")
    csv_hashes_before = verify_csv_hashes()
    if not V1_OPJU.is_file():
        raise FileNotFoundError(f"Approved V1 project not found: {V1_OPJU}")

    shutil.copy2(V1_OPJU, WORKING_OPJU)
    v1_copy_hash_before = sha256_file(WORKING_OPJU)
    LOGGER.info("Approved V1 project copied without modification: %s", WORKING_OPJU)

    op.set_show(True)
    if not op.open(str(WORKING_OPJU), readonly=False, asksave=False):
        raise RuntimeError(f"Origin could not open V1 working copy: {WORKING_OPJU}")
    graph = op.find_graph("Fig2")
    if graph is None:
        raise RuntimeError("Approved Fig2 graph page not found in V1 project")

    data_digest_before, sheet_meta_before = origin_data_digest()
    bindings_before = plot_binding_snapshot(graph)
    plot_counts_before = [len(layer.plot_list()) for layer in graph]
    if plot_counts_before != EXPECTED_PLOT_COUNTS:
        raise RuntimeError(
            f"V1 plot-count baseline mismatch: {plot_counts_before} != {EXPECTED_PLOT_COUNTS}"
        )
    LOGGER.info("V1 data digest: %s", data_digest_before)
    LOGGER.info("V1 plot counts: %s", plot_counts_before)

    apply_v2_style(graph)

    data_digest_after, sheet_meta_after = origin_data_digest()
    bindings_after = plot_binding_snapshot(graph)
    plot_counts_after = [len(layer.plot_list()) for layer in graph]
    if data_digest_after != data_digest_before or sheet_meta_after != sheet_meta_before:
        raise RuntimeError("Worksheet values or worksheet structure changed during V2 styling")
    if bindings_after != bindings_before or plot_counts_after != plot_counts_before:
        raise RuntimeError("Plot data binding or curve count changed during V2 styling")
    LOGGER.info("PASS: every worksheet value and structure remained unchanged")
    LOGGER.info("PASS: all plot bindings and curve counts remained unchanged")

    if not op.save(str(V2_OPJU)):
        raise RuntimeError(f"Origin failed to save V2 project: {V2_OPJU}")
    export_outputs(graph)
    verify_outputs()

    if sha256_file(WORKING_OPJU) != v1_copy_hash_before:
        raise RuntimeError("The copied V1 seed project changed unexpectedly")
    csv_hashes_after = verify_csv_hashes()
    if csv_hashes_after != csv_hashes_before:
        raise RuntimeError("One or more frozen CSV files changed during V2 styling")

    LOGGER.info("Fig.2 V2 style-only update completed successfully")
    LOGGER.info("OPJU: %s", V2_OPJU)
    LOGGER.info("PDF: %s", V2_PDF)
    LOGGER.info("Preview: %s", V2_PREVIEW)
    LOGGER.info("Origin remains open for manual inspection")
    print("\nFig.2 V2 generated. Origin remains open for manual inspection.")
    print("Press Enter in this terminal only when you want this Python controller to exit.")
    input()


if __name__ == "__main__":
    main()
