# Brief: issue 16725

Draft: when a mirrored object is moved to a layer, its source object does not take
over the layer's properties.

## What is known

- `repro_check.py` in this folder reproduces it on FreeCAD 1.1.1 and on
  weekly-2026.10.01: after dropping "Rectangle (mirrored)" on "Test layer", the mirror
  is red and dashed like the layer, the source rectangle keeps its dark solid line.
- The layer code is `src/Mod/Draft/draftobjects/layer.py` and
  `src/Mod/Draft/draftviewproviders/view_layer.py`. `change_view_properties()` loops
  over the layer's `Group`, direct members only, and `layer.py` calls it with
  `targets=[child]` for a newly added object.
- A mirrored object (type `Part::Mirroring`) keeps its source nested under it in the
  tree. The source is not in the layer's `Group`, so it is not restyled.
- Dropping on a layer ends in `ViewProviderLayer.dropObject()`, which calls the layer
  proxy's `addObject()`. A script can call that directly.

## The design question

A maintainer first asked whether this is a bug ("you need to move the base object to
the layer too"). The reporter answered that the base cannot be moved once it is
nested under the mirror. Another maintainer linked a related report that layer
appearance does not reach children. The issue is labelled Confirmed and a triager
asked for a proposed solution. The correct behaviour is therefore partly a design
decision: lay out the options and implement the most conservative one.

## Baseline

On the unmodified weekly build `bin/fc-cmd -t TestDraft` runs 85 tests and
`bin/fc-gui -t TestDraftGui` runs 38, all passing.
