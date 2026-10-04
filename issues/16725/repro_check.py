"""Quick check that issue 16725 shows on a given build.

    FC_REPRO_FILE=issues/16725/FC-mirrored-object-layer.FCStd bin/fc-gui issues/16725/repro_check.py

It opens the reporter's file, drops "Rectangle (mirrored)" on "Test layer" the way
the tree view does, and prints the line colour, width and style of the mirror and of
its source before and after. On FreeCAD 1.1.1 it ends with "RESULT BUG REPRODUCED".
It is a starting point for a session, not the unit test for the fix.
"""

import os
import sys
import traceback

import FreeCAD as App
import FreeCADGui as Gui


def say(*args):
    sys.__stdout__.write(" ".join(str(a) for a in args) + "\n")
    sys.__stdout__.flush()


def rgb(col):
    return tuple(round(c, 2) for c in col[:3])


def main():
    import Draft
    from draftutils import utils

    say("VERSION", ".".join(App.Version()[0:3]), App.Version()[3])
    doc = App.openDocument(os.environ["FC_REPRO_FILE"])
    layer = None
    for o in doc.Objects:
        say("OBJ", o.Name, "|", o.Label, "|", utils.get_type(o), "| InList:", [p.Name for p in o.InList])
        if utils.get_type(o) == "Layer":
            layer = o
    mirrored = [o for o in doc.Objects if o.TypeId == "Part::Mirroring" and "Rectangle" in o.Label]
    if not layer or not mirrored:
        say("RESULT cannot run: layer or mirror object not found")
        return
    mir = mirrored[0]
    src = mir.Source
    lv = layer.ViewObject
    say("LAYER", layer.Label, "LineColor", rgb(lv.LineColor), "LineWidth", lv.LineWidth, "DrawStyle", lv.DrawStyle)
    say("BEFORE mirror", rgb(mir.ViewObject.LineColor), mir.ViewObject.LineWidth, mir.ViewObject.DrawStyle)
    say("BEFORE source", rgb(src.ViewObject.LineColor), src.ViewObject.LineWidth, src.ViewObject.DrawStyle)

    # What dropping the mirrored object on the layer in the tree does:
    lv.Proxy.dropObject(lv, mir)
    doc.recompute()

    say("AFTER  mirror", rgb(mir.ViewObject.LineColor), mir.ViewObject.LineWidth, mir.ViewObject.DrawStyle)
    say("AFTER  source", rgb(src.ViewObject.LineColor), src.ViewObject.LineWidth, src.ViewObject.DrawStyle)
    say("LAYER GROUP", [o.Name for o in layer.Group])
    mirror_ok = rgb(mir.ViewObject.LineColor) == rgb(lv.LineColor)
    source_ok = rgb(src.ViewObject.LineColor) == rgb(lv.LineColor)
    say("RESULT mirror takes layer colour:", mirror_ok, "| source takes layer colour:", source_ok)
    say("RESULT", "BUG REPRODUCED" if (mirror_ok and not source_ok) else "not reproduced as described")


try:
    main()
except Exception:
    say(traceback.format_exc())
    os._exit(1)
os._exit(0)
