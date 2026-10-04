# FreeCAD debugging lab

Tooling on the `lab` branch of the fork `subashk84/FreeCAD`. It is unrelated to
FreeCAD's history and is never proposed upstream. It lets a debugging session
reproduce an issue on a FreeCAD weekly build and test a Python fix without building
FreeCAD from source.

The contributor is a human. Sessions produce a diagnosis and a candidate fix; the
human verifies and submits it. See `SESSION_RULES.md`.

## Layout

| Path | Purpose |
|---|---|
| `SESSION_RULES.md` | What a session may and may not do, and the method to follow |
| `NOTES_TEMPLATE.md` | The report a session writes for the human |
| `bin/bootstrap.sh` | Download and extract the weekly build into `$HOME/fc-weekly` |
| `bin/fc-cmd` | Run FreeCAD without a GUI (scripts, unit tests) |
| `bin/fc-gui` | Run FreeCAD with its GUI on a virtual display |
| `bin/overlay.sh` | Copy changed Python files into the weekly build, and undo it |
| `bin/gui_script_template.py` | Starting point for a GUI reproduction script |
| `issues/<number>/` | Issue text, comments and attachments, saved from upstream |
| `notes/<number>.md` | Session reports (on `lab-notes/<number>` branches) |

## Use in a cloud session

The fork is checked out at `/home/user/FreeCAD` as a shallow clone of `main`.

```bash
cd /home/user/FreeCAD
git fetch origin lab
git worktree add /home/user/lab FETCH_HEAD
cd /home/user/lab
bin/bootstrap.sh
```

Upstream's issue API and issue attachments are not reachable from a cloud session.
Everything needed is under `issues/<number>/`.

## Running things

```bash
bin/fc-cmd /tmp/repro.py            # console script, print() works
bin/fc-gui /tmp/repro_gui.py        # GUI script, see the template for output and exit
bin/fc-cmd -t TestDraft             # a console unit test module
bin/fc-gui -t TestDraftGui          # a GUI unit test module
```

Both wrappers use a throwaway profile in `/tmp/fc-lab-profile` and a private font
cache in `/tmp/fc-lab-cache`, so results do not depend on stored preferences or on
other programs' font caches. Both stop after `FC_TIMEOUT` seconds (default 600).

`bin/fc-gui` uses a virtual X display when `xvfb-run` is installed. Set
`FC_GUI_MODE=offscreen` to use Qt's offscreen platform instead; it prints a harmless
"Failed to create context" line because there is no OpenGL.

Checked on weekly-2026.10.01 (FreeCAD 26.3.0): `TestDraft` runs 85 tests and
`TestDraftGui` runs 38, all passing on the unmodified build.

## Testing a fix

```bash
bin/overlay.sh apply /home/user/FreeCAD    # changed .py files -> weekly build
bin/fc-gui /tmp/repro_gui.py               # now runs the fixed code
bin/overlay.sh restore                     # back to the unmodified build
```

The weekly build is a few days older than `main`. The overlay copies only the files
the fix changes, so a file that also changed upstream in those days arrives in its
`main` version. If a test result looks unrelated to the fix, check for that first.

## Use on the contributor's own machine

Set `FC_HOME` to an extracted weekly AppImage and run the same wrappers. Do not point
`overlay.sh` at a FreeCAD installation that is used for real work.
