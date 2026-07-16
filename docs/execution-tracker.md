# Multi-Agent Execution Tracker

This file is the source of truth for implementation progress. Agents must claim
work here before changing code and must record evidence before checking work
off. Keep task IDs stable so commits, branches, and handoffs remain traceable.

## Coordination Protocol

### Status values

- `READY`: dependencies are complete and the task may be claimed.
- `WAITING`: a dependency gate is still open.
- `IN_PROGRESS`: exactly one owner has claimed the task.
- `BLOCKED`: work cannot continue; the reason and required unblock are recorded.
- `DONE`: acceptance criteria passed, changes are on `main`, and evidence is
  recorded. Only `DONE` tasks receive a checked checkbox.

### Claiming work

1. Pull the latest `origin/main` and confirm every listed dependency is `DONE`.
2. Choose one `READY` task. Change only that task's status to `IN_PROGRESS` and
   fill in Owner and Branch.
3. Use branch name `agent/<task-id>-<short-slug>`.
4. Commit the claim as `Claim <task-id>` and push it to `main` before starting
   implementation. If the push is rejected, sync and choose another task if a
   different agent claimed it first.
5. Do not modify another owner's files or shared interfaces without coordinating
   through a note in that task's Evidence field.
6. When completing a dependency, change each newly unblocked task from
   `WAITING` to `READY` in the same tracker update. For a task with multiple
   dependencies, the owner completing the final dependency performs this step.

### Completing or blocking work

- Complete the task's stated "Done when" criteria and run the relevant checks.
- Merge or push the implementation to `main` before marking the task `DONE`.
- Change `[ ]` to `[x]`, set Status to `DONE`, and record the main commit SHA,
  test commands/results, and any simulator, FIT, screenshot, or hardware
  artifact in Evidence.
- If blocked, keep `[ ]`, set Status to `BLOCKED`, and record the exact blocker,
  owner needed, and next action in Evidence.
- A gate may be checked only after all tasks above that gate are `DONE`.
- Hardware tasks marked Owner `USER` require evidence from the physical watch;
  a cloud agent cannot self-certify them.

## Phase 0: Reproducible Baseline

- [x] `B0.1` Record the Connect IQ SDK version and reproducible build command.
  Status: `DONE` | Owner: `Codex` | Branch: `agent/B0.1-reproducible-build` | Depends: none
  Done when: a clean checkout can build with the documented SDK and command.
  Evidence: main commit `bad9b2b`; OpenJDK `17.0.19`; `monkeyc -v`
  reported Connect IQ SDK `9.2.0`; the documented `monkeyc -d fr970 ...
  -r -w --build-stats 0` command reported `BUILD SUCCESSFUL` with a 17,180-byte
  PRG, 902 bytes of foreground data, and 1,334 bytes of foreground code. The
  available SDK Manager device library did not offer the planned `fenix7`
  baseline, so `fr970` was enabled alongside the inherited targets for this
  build; making it the only target remains scoped to `B0.2`.

- [x] `B0.2` Target only `fr970` and compile the inherited application unchanged.
  Status: `DONE` | Owner: `Codex` | Branch: `agent/B0.2-fr970-baseline` | Depends: `B0.1`
  Done when: the baseline compiles and its memory usage is recorded.
  Evidence: main commit `375f0ec`; `xmllint` validated the manifest and all
  resource XML; XPath checks reported `minApiLevel=6.0.0`, one product, and
  product ID `fr970`; the documented release build reported `BUILD SUCCESSFUL`,
  902 bytes of foreground data, 1,334 bytes of foreground code, zero extended
  code pages, and a 17,180-byte PRG against the device file's 131,072-byte data
  field memory limit. Captured warnings: the inherited launcher icon is scaled
  from 74×72 to 65×65, and the inherited scan loop contains an unreachable
  statement; neither warning blocks the baseline build.

- [ ] `B0.3` Produce the baseline artifact and sideload instructions.
  Status: `IN_PROGRESS` | Owner: `Codex` | Branch: `agent/B0.3-sideload-artifact` | Depends: `B0.2`
  Done when: an installable artifact and exact watch setup steps are available.
  Evidence: `—`

- [ ] `G0` Close the reproducible-baseline gate.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `B0.1–B0.3`
  Done when: all Phase 0 tasks are `DONE`.
  Evidence: `—`

## Phase 1: Real-Bike Protocol Gate

- [ ] `P1.1` Add development-only advertisement diagnostics.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `G0`
  Done when: raw payload, bike ID, manufacturer ID, RSSI, and parse failures can
  be captured without entering release behavior.
  Evidence: `—`

- [ ] `P1.2` Capture advertisements from the user's original M3i.
  Status: `WAITING` | Owner: `USER` | Branch: `—` | Depends: `P1.1`
  Done when: sanitized captures and matching console readings cover idle and
  active pedaling at multiple power and resistance values.
  Evidence: `—`

- [ ] `P1.3` Check in fixtures and the confirmed packet contract.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `P1.2`
  Done when: payload length, identifiers, offsets, types, units, duration
  behavior, and decoded expected values are documented and testable.
  Evidence: `—`

- [ ] `G1` Close the real-bike protocol gate.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `P1.1–P1.3`
  Done when: a checked-in fixture decodes to values matching the bike console.
  Evidence: `—`

## Phase 2: Parallel Implementation

First lock the interfaces shared by the four implementation lanes:

- [ ] `C2.0` Define the shared packet, state, and display contracts.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `G1`
  Done when: stable types, ownership boundaries, fixtures, and expected state
  transitions are documented sufficiently for each lane to work independently.
  Evidence: `—`

The four lanes below may be claimed concurrently after `C2.0` is `DONE`.

### Parser and state lane

- [ ] `PS2.1` Implement the immutable packet model and validated parser.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `C2.0`
  Done when: fixtures pass and malformed/short/unsupported packets are rejected.
  Evidence: `—`

- [ ] `PS2.2` Implement freshness, dropout, and reacquisition state.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `PS2.1`
  Done when: boundary tests cover fresh, degraded, disconnected, and recovery.
  Evidence: `—`

### UI lane

- [ ] `UI2.1` Implement the shared display model and full-screen layout.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `C2.0`
  Done when: power, cadence, resistance, and freshness render legibly on
  `fr970` without scrolling.
  Evidence: `—`

- [ ] `UI2.2` Implement compact and stale/disconnected presentation.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `UI2.1`
  Done when: reduced layouts remain useful and stale values cannot appear live.
  Evidence: `—`

### FIT, settings, and lifecycle lane

- [ ] `FIT2.1` Implement compatible developer fields and recording rules.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `C2.0`
  Done when: field IDs match the plan, Garmin HR is untouched, and stale or
  disconnected metrics are omitted rather than recorded as valid zeroes.
  Evidence: `—`

- [ ] `FIT2.2` Implement bike ID, unit settings, and safe scan lifecycle.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `FIT2.1`
  Done when: settings persist and repeated activation cannot leak scan state.
  Evidence: `—`

### Diagnostics and test-infrastructure lane

- [ ] `DT2.1` Implement counters and development-only diagnostics.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `C2.0`
  Done when: packet, error, dropout, reacquisition, RSSI, and packet-age data are
  observable without exposing raw payloads in release builds.
  Evidence: `—`

- [ ] `DT2.2` Add repeatable test, simulator, and memory-budget commands.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `C2.0`
  Done when: an agent can run all automated checks from a clean checkout.
  Evidence: `—`

## Phase 3: Integration Gate

- [ ] `I3.1` Integrate all four implementation lanes.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—`
  Depends: `PS2.2`, `UI2.2`, `FIT2.2`, `DT2.1`, `DT2.2`
  Done when: the merged app builds for `fr970` and remains within memory limits.
  Evidence: `—`

- [ ] `I3.2` Run automated and simulator state scenarios.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `I3.1`
  Done when: valid, malformed, fresh, degraded, disconnected, and reacquisition
  scenarios pass with recorded output.
  Evidence: `—`

- [ ] `I3.3` Complete a short integrated watch ride.
  Status: `WAITING` | Owner: `USER` | Branch: `—` | Depends: `I3.2`
  Done when: the watch displays live values, recovers from an interruption, and
  saves one activity with expected developer fields.
  Evidence: `—`

- [ ] `G2` Close the integration gate.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `I3.1–I3.3`
  Done when: all Phase 3 tasks are `DONE`.
  Evidence: `—`

## Phase 4: Watch Acceptance

- [ ] `A4.1` Complete the documented 30-minute ride.
  Status: `WAITING` | Owner: `USER` | Branch: `—` | Depends: `G2`
  Done when: the ride meets every condition and pass criterion in the build plan.
  Evidence: `—`

- [ ] `A4.2` Inspect the saved FIT activity and synchronization.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `A4.1`
  Done when: Garmin wrist HR and Keiser developer fields are present, only one
  activity exists, and Garmin Connect plus optional Strava sync are confirmed.
  Evidence: `—`

- [ ] `G3` Declare the MVP complete.
  Status: `WAITING` | Owner: `unclaimed` | Branch: `—` | Depends: `A4.1–A4.2`
  Done when: all MVP requirements and acceptance criteria are checked with
  evidence and no unresolved blocker remains.
  Evidence: `—`
