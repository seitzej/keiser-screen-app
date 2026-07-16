# Capture M3i Advertisement Diagnostics

This procedure supports tracker task `P1.2`. It captures development-only BLE
advertisement diagnostics from the user's original Keiser M3i without adding
raw payload logging to release builds.

Do not treat values captured here as the confirmed protocol contract. That
contract is established by `P1.3` after the payloads are matched to console
readings.

## Build the diagnostic artifact

Use the pinned Connect IQ SDK `9.2.0`, OpenJDK `17.0.19`, and private developer
key described in [Build and Sideload the Data Field](build-and-sideload.md).

From the repository root, build without the `-r` release flag:

```sh
mkdir -p bin
monkeyc \
  -d fr970 \
  -f monkey.jungle \
  -o bin/keiser-screen-app-fr970-diagnostics.prg \
  -y "$DEVELOPER_KEY" \
  -w \
  --build-stats 0
```

Omitting `-r` includes methods annotated with `:debug`. The normal release
command still uses `-r`, which excludes the raw-payload formatter and logger at
compile time.

## Prepare logging on the watch

`System.println()` does not create its device log automatically. Before
starting the capture:

1. Connect the Forerunner 970 in MTP mode.
2. Copy `bin/keiser-screen-app-fr970-diagnostics.prg` to `GARMIN/APPS`.
3. Create an empty file named
   `keiser-screen-app-fr970-diagnostics.TXT` and copy it to
   `GARMIN/APPS/LOGS`.
4. Eject the watch cleanly, then add **Keiser BLE Data Field** to a one-field
   Indoor Bike data screen if it is not already configured.

The `.TXT` base name must exactly match the sideloaded `.PRG` base name. Garmin
rotates a log after approximately 5 KB into a same-named `.BAK` file, replacing
any older backup, so keep each capture interval short.

## Diagnostic record format

Each manufacturer-data entry from an advertisement named `M3` is one line:

```text
M3_ADV manufacturer=0x0102 rssi=-52 bikeId=4 length=17 status=parseable payload=001122...
```

The payload is uppercase hexadecimal with two digits per byte and no separator.
Possible `status` values are:

- `parseable`: long enough and supported by the inherited parser checks.
- `bike_id_unavailable`: too short to read the inherited bike-ID offset.
- `payload_too_short`: contains a bike ID but is too short for all inherited
  offsets.
- `unsupported_data_type`: has a data-type byte outside the inherited accepted
  values.
- `manufacturer_data_missing`: the `M3` advertisement had no manufacturer-data
  entry.

`parseable` means only that the inherited parser can index the payload. It does
not confirm the offsets, units, or meaning of any byte.

## Capture scenarios

Use a separate capture interval and fresh watch log for each scenario. Start an
Indoor Bike activity with the diagnostic field visible, hold the console
reading steady for about 20–30 seconds, and record the watch time plus the
console values. Capture at least:

1. Idle bike before pedaling.
2. Easy pedaling at a low resistance.
3. Steady pedaling at a moderate resistance and power.
4. Steady pedaling at a higher resistance and power.

During one active interval, extend the capture long enough to record the normal
console-duration transition from `mm:59` to `(mm+1):00`. Maximum-duration
wrapping is a later hardware follow-up and does not block `P1.2`.

Use this worksheet while capturing:

| Scenario | Watch time | Bike ID | Power | Cadence | Resistance | Distance | Calories | Duration start/end | Distance units |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| Idle | | | | | | | | | |
| Low | | | | | | | | | |
| Moderate | | | | | | | | | |
| High | | | | | | | | | |

Stop and save or discard the Garmin activity normally. The diagnostic field
must not control the activity lifecycle.

## Retrieve and sanitize evidence

After each scenario, reconnect the watch and copy both files when present:

```text
GARMIN/APPS/LOGS/keiser-screen-app-fr970-diagnostics.TXT
GARMIN/APPS/LOGS/keiser-screen-app-fr970-diagnostics.BAK
```

Rename the retrieved files with the scenario name, for example `idle.txt` and
`idle.bak.txt`, then recreate an empty
`keiser-screen-app-fr970-diagnostics.TXT` before the next scenario. This keeps
log rotation from discarding or mixing scenario evidence.

Keep complete `M3_ADV` lines and do not edit payload bytes. Remove unrelated
log lines containing personal paths, device identifiers, or activity details.
Label each sanitized log with its worksheet scenario so `P1.3` can turn the
observations into fixtures and a confirmed packet contract. Place the completed
worksheet and sanitized logs under `docs/evidence/p1.2/`; see that directory's
README for the evidence contract and expected filenames.

Physical-watch captures and console readings are user-owned evidence. An agent
must not mark `P1.2` complete without those artifacts.
