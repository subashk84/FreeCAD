# Brief: issue 20352

BIM: IfcProperties cannot work with a custom property set whose name has no `Pset_`
prefix in `CustomPsets.csv`.

## What the thread settled

- The maintainer of BIM (yorikvanhavre, 2025-05-13) decided the direction: stop
  "beautifying" property set names. The dialog strips the `Pset_` prefix and inserts
  spaces before capitals ("FreeCAD" becomes "Free C A D"), then tries to reverse that
  when the user picks a set, which fails for names without the prefix. Names are to be
  shown and used exactly as written.
- He pointed at two places in `src/Mod/BIM/bimcommands/BimIfcProperties.py`: where
  `self.psetkeys` is built (he suggested `self.psetkeys = self.psetdefs.keys()`) and
  where the chosen label is turned back into a definition name
  (`psetdef = psetlabel.replace(" ", "")`). Line numbers in his comment are from
  May 2025; find the code by content.
- He said he would do it himself (2025-05-15). Nothing followed. The issue is
  unassigned and has no pull request.
- Roy-043 (2026-05-07) noted that similar code exists elsewhere. `pset_definitions.csv`
  is read in `BIM/ArchComponent.py`, `BIM/bimcommands/BimPreflight.py`,
  `BIM/bimcommands/BimIfcProperties.py` and `BIM/nativeifc/ifc_status.py`;
  `CustomPsets.csv` in `BimIfcProperties.py` and `nativeifc/ifc_status.py`. Check each
  for the same name mangling and say in the notes which ones have it. Fix only what is
  needed for this issue to behave correctly end to end, and list the rest.

## Reproduction hints

- `CustomPsets.csv` (attached here) goes in the `BIM` folder of the user data
  directory. With the lab wrappers the profile is `$FREECAD_USER_HOME`; find the exact
  folder with `FreeCAD.getUserAppDataDir()`.
- The dialog is the `BIM_IfcProperties` command. Driving the Qt dialog from a script is
  possible but fiddly. Prefer testing the functions that build the list of set names
  and that map a chosen label back to a definition, and show the before and after
  values for a set named with the prefix and one without.

## Watch for

- Existing documents and users' own `CustomPsets.csv` files must keep working.
- Labels shown in the dialog change for every user (no more spaces, prefix kept).
  That is the maintainer's stated intent, but say so plainly in the notes because it
  is a visible change.
