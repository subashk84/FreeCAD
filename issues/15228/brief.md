# Brief: issue 15228

BIM: the column tool creates an object named "beam".

## What the thread settled

- Reproduction (Roy-043, 2024-07-08): start BIM_Beam, choose Category "Precast
  concrete" and Preset "Beam", create a beam by picking two points; then start
  BIM_Column and pick a point. The new column gets the beam's name. With a metal
  profile it does not happen; with a concrete preset it does. There is no "column"
  preset for concrete.
- Cause as stated by the BIM maintainer (yorikvanhavre, 2024-07-11): the beam and the
  column mode save their preset settings in the same place. They should be saved in
  two separate subsets, one for beams and one for columns. He postponed it until
  after 1.0 and it was not done.
- He also suggested that when the tool is started from the beam or the column button
  the mode is implicit, so the beam/column controls in the task panel should be
  hidden. That is a separate user-interface change. Do not do it here; mention it.
- Reconfirmed on 1.1.0dev in October 2025. Unassigned, no pull request.

## Where to look

The structure tool lives in `src/Mod/BIM/` (`ArchStructure.py` and the command under
`bimcommands/`). Find where the preset and category choices are stored and read back
(look for parameter get/set calls near the task panel code).

## Reproduction hints

The commands are interactive. Rather than simulating clicks, find the function that
decides the new object's name and IFC type from the stored settings, and show that it
returns the beam values in column mode after a beam was made with a concrete preset.
The lab wrappers use a fresh profile, so stored settings start empty: set them the way
the beam tool would, then run the column path.

## Watch for

- Stored user settings from earlier versions: after the change a user's existing
  preset choice should still be picked up sensibly, not lost without notice.
- The preview mismatch Roy-043 mentions in step 3 is a different problem. Leave it.
