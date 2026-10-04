"""Template for a script run with bin/fc-gui.

In GUI mode FreeCAD sends print() to its report view, so nothing reaches the
terminal. Use say() below. The script must end the process itself, otherwise
FreeCAD stays open until the wrapper's timeout.
"""

import os
import sys
import traceback

import FreeCAD as App
import FreeCADGui as Gui


def say(*args):
    """Print to the real terminal."""
    sys.__stdout__.write(" ".join(str(a) for a in args) + "\n")
    sys.__stdout__.flush()


def main():
    doc = App.newDocument("Repro")
    # ... build the scene, change properties, read ViewObject values ...
    doc.recompute()
    say("RESULT", "replace this with the evidence")


try:
    main()
except Exception:
    say(traceback.format_exc())
    os._exit(1)
os._exit(0)
