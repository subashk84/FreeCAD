# Rules for a debugging session

You are helping a human contributor (GitHub user `subashk84`) debug one FreeCAD issue.
The human will review, test and submit the result personally. FreeCAD's AI policy
(`AI_POLICY.md` in the repo root) requires that. Your job is a diagnosis and a candidate
fix they can understand and verify. Read these rules before touching anything.

## Hard limits

1. **Nothing goes upstream.** Do not open pull requests. Do not comment on, react to or
   edit any issue or pull request in `FreeCAD/FreeCAD`. Do not run `gh pr create`,
   `gh issue comment`, `gh pr comment` or `gh api` calls that write.
2. **No cross-references.** GitHub links any commit message that mentions an issue to
   that issue's public timeline. In commit messages write `issue 16725` in plain words.
   Never write `#16725`, `FreeCAD/FreeCAD#16725` or a `github.com/.../issues/...` URL
   in a commit message. File contents are fine.
3. **Push only to these branches** of `origin` (the fork): `fix/<number>-<slug>` and
   `lab-notes/<number>`. Never push to `main` or `lab`. Never force-push.
4. **Python only.** Do not build FreeCAD from source. If the fix needs a C++ change,
   stop, and say so in the notes with the file and function involved.
5. **One issue.** Do not fix other problems you notice. List them in the notes.

## Method

1. Read `issues/<number>/issue.txt` and `comments.txt` in this lab checkout. Note any
   disagreement in the thread about what the correct behaviour is.
2. Run `bin/bootstrap.sh` once. It prepares a FreeCAD weekly build in `$HOME/fc-weekly`.
3. **Reproduce first.** Write a script under `/tmp` that shows the wrong behaviour on the
   unmodified weekly build and prints the evidence. Use `bin/fc-cmd` for scripts that
   need no view objects and `bin/fc-gui` for scripts that touch `ViewObject` or
   `FreeCADGui`. If you cannot reproduce it after a serious attempt, stop and write the
   notes. A failed reproduction, documented, is a useful result.
4. Find the root cause in the source checkout (`src/Mod/...`).
5. Create the fix branch from `origin/main`: `git switch -c fix/<number>-<slug> origin/main`.
   Make the smallest change that fixes the cause. Match the surrounding code style.
   Do not reformat lines you did not change.
6. Add or extend a unit test in the module's existing test files when the module has
   them (for Draft: `src/Mod/Draft/drafttests/`). The test must fail before the fix
   and pass after it.
7. Test against the weekly build: `bin/overlay.sh apply <checkout>` copies your changed
   Python files from the checkout into the weekly build, `bin/overlay.sh restore`
   undoes it. Run your reproduction script and the module's test suite both ways and
   keep the output.
8. Commit the fix as **one** commit on the fix branch. Subject line:
   `<Module>: <what the commit achieves>`. Keep the body to a few factual lines. The
   human rewrites this message before submitting.
9. Write the notes (next section) and push both branches.

## When the expected behaviour is unclear

Do not choose silently. Describe each reasonable behaviour, say which one you
implemented and why it is the most conservative, and mark the question
"needs a maintainer decision" in the notes.

## Notes

Copy `NOTES_TEMPLATE.md` to `notes/<number>.md` in this lab checkout, fill every
section, commit it on a new branch `lab-notes/<number>` and push that branch.

Write for a reader who uses FreeCAD for drawings but is not a Python developer. They
must be able to explain the change to a reviewer in their own words.

Separate what you verified (with the command and its output) from what you believe.
Say plainly what you did not test.
