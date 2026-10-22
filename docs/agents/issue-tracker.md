# Issue tracker: Linear

Ideas, work, status and milestones for this repo live in Linear: team **Aa-hh**, project **Fluidity** (https://linear.app/aa-hh/project/fluidity-452000c40416). Nothing is tracked in repo files. Record it in Linear first, then do the work (see the Linear-first rule in `AGENTS.md`).

## Conventions

- One Linear issue per ticket, in the Fluidity project.
- A larger piece of work is a parent issue, with its tickets as sub-issues.
- Milestones are Linear project milestones.
- Status is the issue's Linear workflow state, never a line in a file.
- Triage roles map to Linear labels (see `triage-labels.md`).
- Comments and conversation history go in the issue's comments.
- Supporting detail too long for an issue (research write-ups, specs) may live in a repo file. The Linear issue links to it, and the file never holds status.

## When a skill says "publish to the issue tracker"

Create a Linear issue in the Fluidity project.

## When a skill says "fetch the relevant ticket"

Read the Linear issue. The user will normally pass its identifier (for example `AA-272`) or URL.

## Wayfinding operations

Used by `/wayfinder`.

- **Map**: a Linear issue in the Fluidity project, labelled `wayfinder:map`. Its description holds the Destination, Notes, Decisions-so-far, Not-yet-specified and Out-of-scope sections.
- **Child ticket**: a sub-issue of the map, labelled with its type (`wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling` or `wayfinder:task`), with the question in the description.
- **Blocking**: Linear's own "blocked by" relation between sub-issues.
- **Frontier**: the map's sub-issues that are not Done or Canceled, have no assignee, and whose blockers are all Done.
- **Claim**: assign the ticket to the dev driving the map before any work.
- **Resolve**: post the answer as a comment, move the issue to Done, then add a line (name, link, gist) to the map's Decisions-so-far.
- **Research findings**: committed as a file on a `research/<name>` branch, with a comment on the ticket pointing to the branch and file.
- **Out of scope**: move the ticket to Canceled and add one line to the map's Out-of-scope section.
