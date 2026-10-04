"""Smoke test for bin/fc-gui: create a Draft object and a layer, read a view property."""

import os
import sys
import traceback

import FreeCAD as App
import FreeCADGui as Gui  # noqa: F401  (import proves the GUI module loads)

try:
    import Draft

    doc = App.newDocument("Smoke")
    rect = Draft.make_rectangle(10, 5)
    layer = Draft.make_layer("Smoke layer")
    doc.recompute()
    _ = rect.ViewObject.LineColor
    _ = layer.ViewObject.LineColor
    sys.__stdout__.write("GUI_SMOKE_OK GuiUp=%s\n" % App.GuiUp)
    sys.__stdout__.flush()
except Exception:
    sys.__stdout__.write(traceback.format_exc())
    sys.__stdout__.flush()
    os._exit(1)
os._exit(0)
