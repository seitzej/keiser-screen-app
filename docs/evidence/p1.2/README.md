# P1.2 Real-Bike Capture Evidence

This directory is the durable handoff from the user-owned physical-watch task
`P1.2` to packet-contract task `P1.3`.

## Diagnostic artifact

The locally prepared, ignored artifact is:

```text
bin/keiser-screen-app-fr970-diagnostics.prg
Size: 103948 bytes
SHA-256: c53a9a3dfbcfd06da4e57839d9a9a793800b067a49d8055eae0f83398d23098f
```

It was built without the release flag. Static string inspection found four
raw-advertisement markers in this diagnostic artifact and none in the
17,228-byte release-validation artifact.

Because the PRG is signed and ignored, it is handed to the watch from the local
`bin/` directory and is not committed.

## Required files

Complete `worksheet.md` and add sanitized logs for all four scenarios:

```text
idle.txt
idle.bak.txt              optional when no backup was produced
low.txt
low.bak.txt               optional when no backup was produced
moderate.txt
moderate.bak.txt          optional when no backup was produced
high.txt
high.bak.txt              optional when no backup was produced
```

Each file must contain only complete `M3_ADV` lines from its named interval.
Delete unrelated log lines as whole lines. Do not edit payload bytes or fields
within a retained line. Preserve anomalous manufacturer IDs, lengths, statuses,
and payloads so `P1.3` can evaluate them.

## Completion checks

Before `P1.2` can be marked `DONE`:

- Each scenario has at least one usable advertisement and an unambiguous
  worksheet row.
- The active scenarios cover multiple resistance and power values.
- The worksheet records bike ID, power, cadence, resistance, distance,
  calories, duration, distance units, and watch time.
- One active scenario records a normal minute rollover.
- Every payload has two hexadecimal characters per reported byte.
- The user confirmation in `worksheet.md` is completed.

Maximum-duration wrapping is deliberately deferred. `P1.3` confirms packet
offsets, types, units, and decoded values; the observations here are not yet a
protocol contract.
