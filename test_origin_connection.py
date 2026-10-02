"""Minimal VS Code/Python/originpro/Origin connection test.

This script creates only temporary test data in a new Origin project session.
It does not read project data, save an OPJU file, or export an image.
"""

import originpro as op


def main() -> None:
    x_values = [1, 2, 3, 4, 5]
    y_values = [1, 4, 9, 16, 25]

    # Start the external Origin application and show its GUI.
    op.set_show(True)

    # Create a blank workbook, then add a worksheet for the test data.
    workbook = op.new_book("w", lname="Origin Python Connection Test")
    if workbook is None:
        raise RuntimeError("Origin did not create the test workbook.")

    worksheet = workbook.add_sheet("TestData")
    if worksheet is None:
        raise RuntimeError("Origin did not create the test worksheet.")

    worksheet.from_list(0, x_values, lname="X", axis="X")
    worksheet.from_list(1, y_values, lname="Y", axis="Y")

    # In originpro 1.1.15, plot type 'y' is Line + Symbol.
    graph = op.new_graph(
        lname="Origin Python Connection Test Plot",
        template="origin",
    )
    if graph is None:
        raise RuntimeError("Origin did not create the test graph.")

    layer = graph[0]
    plot = layer.add_plot(worksheet, coly=1, colx=0, type="y")
    if plot is None:
        raise RuntimeError("Origin did not create the Line + Symbol plot.")

    layer.rescale()
    graph.activate()

    print("ORIGIN_CONNECTION_TEST=PASS", flush=True)
    print("Origin is visible with a test workbook and Line + Symbol graph.", flush=True)
    print("Press Enter in this terminal only after the manual inspection is complete.", flush=True)
    input()


if __name__ == "__main__":
    main()
