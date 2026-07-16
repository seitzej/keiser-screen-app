# Agent Coordination

Before changing code, read:

1. `docs/forerunner-970-data-field-plan.md`
2. `docs/execution-tracker.md`

The execution tracker is authoritative. Claim exactly one `READY` task on
`main` before implementation, use the task ID in the branch name, respect all
dependency gates, and avoid changing another lane's shared interfaces without a
tracker note.

Do not mark a task complete until its changes are on `main`, its "Done when"
criteria pass, and its Evidence field contains the commit and validation
results. Physical-watch tasks owned by `USER` cannot be certified by a cloud
agent.
