# Issue <number>: <title>

## Outcome

One of: fix ready for review / reproduced, no fix / not reproduced / needs C++ change.
Two or three sentences on what was found.

## What goes wrong, in plain words

What the user does, what they see, what they should see.

## Reproduction

The script (full text) and its output on the unmodified weekly build.
FreeCAD version line from the build.

## Root cause

File and line numbers. What the code does and why that produces the wrong result.

## The fix

Branch name and commit hash.
What changed and why this is the smallest change that addresses the cause.
Other approaches considered and why they were not chosen.

## The diff, explained line by line

Every changed line, with one sentence on what it does.

## Tests

Tests added (file, test name). Output of the reproduction script and of the module's
test suite before and after the fix.

## Check it by hand

Numbered steps to see the bug and the fix in the FreeCAD window, using the weekly
AppImage. This is what the human contributor will run.

## Questions for the maintainers

Any point where the correct behaviour is a design decision. For each: the options,
which one the fix implements, and what would change under the others.

## Not verified

Everything that was not tested, including platforms and related workflows.

## Other problems noticed

Unrelated defects seen along the way. Not fixed here.

## Session facts

Wall-clock time, approximate number of commands run, anything that slowed the work.
