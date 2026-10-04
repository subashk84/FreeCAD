# Prompt for a debugging session

Replace `<number>`, `<title>` and `<slug>`, then send this as the session's first
message. Everything issue-specific belongs in `issues/<number>/brief.md`, not here.

```text
You are debugging ONE FreeCAD issue for a human contributor, who will review, test and
submit the result personally. You never post anything to the upstream project.

Setup. Run these first, from /home/user/FreeCAD (the contributor's fork, checked out
as a shallow clone of main):

  git fetch origin lab
  git worktree add /home/user/lab FETCH_HEAD
  cd /home/user/lab && cat SESSION_RULES.md README.md

SESSION_RULES.md is binding. Follow its hard limits and its method exactly. If anything
in this message conflicts with it, SESSION_RULES.md wins.

The issue: number <number>, '<title>'. Its text, the comment thread, any attachments
and a brief of what is already known are in /home/user/lab/issues/<number>/. Read
brief.md first. Upstream's issue API is not reachable from here, so use those files.

Deliverables, both pushed to origin:
1. Branch fix/<number>-<slug>, created from origin/main, with exactly one commit that
   contains the code change and a unit test and nothing else.
2. Branch lab-notes/<number>, created in the /home/user/lab worktree, adding
   notes/<number>.md written from NOTES_TEMPLATE.md with every section filled in.

If you cannot reproduce the problem, or the fix would need C++ changes, do not force a
fix: push only the notes branch and explain what you found.

Working constraints:
- Do the work yourself in this session. Do not use subagents.
- Do not build FreeCAD from source. Test Python changes with bin/overlay.sh against
  the weekly build.
- Do not open a pull request. Do not comment on any issue. Push to no branch other
  than the two named above.
- In commit messages write 'issue <number>' in words. Never write a hash sign followed
  by the number, and never a github.com issue URL, in a commit message.
- Keep command output short: pipe long output through tail or grep.

Finish with a short final message: the outcome in one line, the two branch names with
their commit hashes, and the single most important thing the human must check before
trusting the result.
```

## Launching

Sessions are started as one-time routines on the contributor's Claude account:
model `claude-opus-5-5`, source `https://github.com/subashk84/FreeCAD`, tools Bash,
Read, Write, Edit, Glob and Grep, start time a minute or two ahead. One issue per
session. Before launching, run `bin/fetch-issue.sh <number>` again and check that the
issue is still open, unassigned and has no open pull request.
