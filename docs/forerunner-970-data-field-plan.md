# Forerunner 970 Keiser M3i Data Field Build Plan

## Objective

Build a Garmin Connect IQ data field for the Forerunner 970 that reads workout data broadcast by an original Keiser M3i bike and records it into the same Garmin Indoor Bike activity as the watch's native heart-rate data.

The desired workflow is:

```text
Keiser M3i BLE advertisement
        ↓
Garmin Connect IQ data field
        ↓
Garmin Indoor Bike activity
        ↓
Garmin Connect
        ↓
Strava
```

The phone and Keiser M Series app should not be required during the ride.

## Repository Strategy

This repository is the public `seitzej/keiser-screen-app` fork of
`tao-j/Keiser2Garmin`. Preserve the upstream Git history, GPL-3.0 license, and
attribution.

Treat the inherited application as a protocol reference and working baseline,
not as the target architecture. Retain the proven M3 advertisement discovery,
bike-ID filtering, payload offsets, settings behavior, and compatible FIT field
IDs while replacing the runtime structure with validated packet models,
freshness-aware state management, separated BLE/UI/FIT responsibilities, and
automated tests.

Agents must coordinate through the
[multi-agent execution tracker](execution-tracker.md). The tracker is the source
of truth for task ownership, dependency gates, completion state, and validation
evidence. A task is not complete merely because code exists on a branch.

The MVP targets only the Garmin Forerunner 970. Broader device support can be
reintroduced later after it compiles and is tested on each declared family.

## Recommended App Type

Implement this as a **Connect IQ data field**, not a standalone activity app.

The user should:

1. Add the data field to the built-in Garmin `Indoor Bike` activity.
2. Start the activity from Garmin's normal activity UI.
3. View live Keiser metrics on the selected activity screen.
4. Stop and save the activity normally.
5. Let Garmin sync the resulting FIT activity to Garmin Connect and Strava.

This preserves Garmin's native handling of:

- Wrist heart rate
- Start, pause, resume, and save behavior
- Activity timestamps
- Garmin Connect synchronization
- Standard indoor cycling activity metadata
- Garmin-derived training metrics that do not depend on native cycling-power sensor data

## Existing Reference Implementation

Use this repository as the starting point:

- `https://github.com/tao-j/Keiser2Garmin`

The repository already demonstrates:

- Scanning for the original M3i BLE broadcasts
- Matching devices named `M3`
- Reading Keiser manufacturer-specific advertisement data
- Filtering by bike ID
- Parsing cadence, power, calories, duration, distance, resistance, and Keiser HR
- Writing Connect IQ developer fields into the activity FIT file

The current project is old and does not explicitly target the Forerunner 970. Fork and modernize it rather than starting from zero.

## Keiser BLE Behavior

The original M3i broadcasts workout data through BLE advertisements. It does not need to maintain a normal connected GATT session for this use case.

The data field should continuously scan for BLE advertisements and parse matching manufacturer-specific data.

Expected device characteristics from the reference implementation:

```text
BLE device name: M3
Data source: manufacturer-specific advertisement payload
Bike discriminator: bike ID embedded in payload
```

Reference parsing behavior:

```text
cadence   = payload[4]
heartRate = little-endian payload[6:8] / 10
power     = little-endian payload[8:10]
calories  = little-endian payload[10:12]
duration  = payload[12] + payload[13] * 60
distance  = little-endian payload[14:16] / 10
gear      = payload[16]
```

Verify byte offsets against real captures from the user's bike before treating them as final.

## Heart Rate Source

Do not use the Keiser heart-rate value as the authoritative activity heart rate.

The Garmin watch should record its own native wrist-HR stream through the built-in Indoor Bike activity.

The data field may:

- Ignore the Keiser HR field entirely, or
- Expose it only as a diagnostic developer field

Do not map Keiser HR into the native Garmin HR field.

## Metrics to Display

The primary screen should show:

- Current power, watts
- Current cadence, RPM
- Current resistance level
- Connection/data freshness state

Secondary or configurable fields may show:

- Keiser distance
- Keiser elapsed time
- Keiser calories
- Bike ID
- Packet age
- Last packet timestamp
- Packet count
- Dropout count

Recommended default layout:

```text
POWER
  214 W

CADENCE       RESISTANCE
  88 RPM          14

DATA AGE
  0.4 s
```

The display should make stale data obvious. Never continue showing an old power value as though it were current.

## Data Freshness Rules

Maintain a timestamp for the last valid packet.

Suggested states:

```text
Fresh:       packet age <= 2 seconds
Degraded:    packet age > 2 and <= 5 seconds
Disconnected packet age > 5 seconds
```

Behavior:

- Fresh: display current values normally.
- Degraded: retain the most recent values but show a stale indicator.
- Disconnected: display placeholders or zero values and a clear disconnected state.
- On reacquisition: resume automatically without requiring user interaction.

Use monotonic time where available.

## Bike Selection

Support manual and automatic bike selection.

### MVP

Add an app setting for the Keiser bike ID.

The data field should ignore advertisements from other M3 bikes unless their bike ID matches the configured ID.

### Improved Version

Add a discovery mode that:

1. Scans all nearby `M3` advertisements.
2. Lists observed bike IDs and signal strengths.
3. Lets the user select one.
4. Stores the selected bike ID in application properties.

Avoid binding permanently to the first M3 advertisement found in a gym environment.

## FIT Recording

Create Connect IQ developer fields for at least:

- Power
- Cadence
- Resistance
- Distance
- Keiser elapsed time
- Keiser calories
- Packet age or connection state, optional diagnostic field

Preserve the existing developer-field IDs where practical so activities remain
compatible with the inherited application:

```text
0  Cadence
1  Keiser HR (deprecated; diagnostics only if retained)
2  Power
3  Keiser calories
4  Keiser elapsed time
5  Keiser distance
6  Resistance
7  Connection state
8  Packet age
```

The reference implementation attempts to use FIT native field numbers. Do not assume that this makes the values native Garmin sensor fields.

Connect IQ data fields generally write developer fields. Garmin Connect may display these values, but Garmin may not use them for:

- FTP detection
- Cycling VO2 max
- Native power curves
- Power-based training load
- Native cadence summaries
- Other sensor-dependent Garmin analytics

Treat native Garmin recognition as a separate hardware-bridge problem.

### Recording Frequency

Write the current values during the data field's regular `compute()` cycle.

Avoid writing invalid or stale values as real measurements.

Suggested behavior:

- Fresh packet: write parsed values.
- Temporarily degraded: either write the last value with a separate stale-state field or omit the value.
- Disconnected: omit the metric or write an invalid/null value where the API permits.

Prefer omission over recording false zero-power intervals unless zero is known to be a real bike value.

## Connect IQ Architecture

Suggested classes:

```text
KeiserDataFieldApp
    Application lifecycle and settings

KeiserDataFieldView
    Data field rendering
    FIT contributor field creation
    Writes current values during compute()

KeiserBleDelegate
    BLE scan lifecycle
    Advertisement filtering
    Manufacturer-data extraction
    Packet parsing
    Reacquisition behavior

KeiserPacket
    Parsed immutable packet model
    Bike ID
    Cadence
    Power
    Calories
    Duration
    Distance
    Resistance
    Optional Keiser HR
    Receive timestamp

KeiserState
    Latest packet
    Packet age
    Connection state
    Packet count
    Dropout count
    Parse-error count
```

Keep BLE parsing separate from UI and FIT recording.

## BLE Scan Lifecycle

The scanner should:

1. Start when the data field becomes active.
2. Filter aggressively for relevant advertisements.
3. Continue scanning throughout the activity.
4. Recover after temporary BLE interruptions.
5. Stop or release resources when the data field is no longer active.
6. Avoid repeated initialization that leaks scan handles or delegates.

Because this is advertisement-based, there is no normal connection-state machine. The effective connection state is determined by valid packet recency.

## Parser Requirements

The parser must:

- Validate minimum payload length before indexing.
- Validate any known data-type byte.
- Handle unsigned byte conversion correctly.
- Handle little-endian integer conversion correctly.
- Reject malformed packets without crashing.
- Track parse errors.
- Preserve raw payloads in debug builds.
- Avoid operator-precedence bugs in bit-shift expressions.

Use explicit helpers:

```text
uint16LE(low, high) = low | (high << 8)
decimalTenths(low, high) = uint16LE(low, high) / 10.0
```

Do not rely on ambiguous expressions such as:

```text
a + b << 8
```

Use:

```text
a | (b << 8)
```

or:

```text
a + (b << 8)
```

## Duration Handling

The reference code uses:

```text
seconds + minutes * 60
```

The M3i console may wrap its displayed duration. Confirm behavior around the console's maximum display value.

For the Garmin activity duration, rely on Garmin's native activity clock.

Treat Keiser duration as supplemental console data only.

## Distance Handling

The M3i distance value may not correspond to real-world distance in a physically meaningful way.

Record it as a Keiser console metric, but do not assume Garmin will accept it as native activity distance.

Confirm:

- Whether the console is configured for miles or kilometers
- Whether the payload changes units
- Whether a unit flag exists
- Whether the current reference implementation hardcodes miles incorrectly

Expose a user setting if the protocol does not provide units.

## Permissions and Manifest

Update the Connect IQ manifest to:

- Target only the Forerunner 970 (`fr970`) for the MVP
- Include the required BLE permissions
- Include FIT contributor support
- Include application properties for bike ID and optional unit settings
- Retain only supported device families that compile successfully

Do not declare broad device support without testing.

## UI Requirements

The data field must be useful under exercise conditions.

Requirements:

- Large primary power number
- No scrolling
- High contrast
- Minimal labels
- Clear stale/disconnected state
- No modal interaction during a ride
- No dependency on a phone
- No touch-only controls
- Support physical watch buttons and standard activity-screen behavior

The primary metric should be power.

## Reliability Requirements

The main purpose of the project is reliability, not feature breadth.

The app should:

- Survive missed BLE advertisements
- Resume after temporary dropouts
- Never end the Garmin activity by itself
- Never create a separate duplicate activity
- Never require the phone to remain nearby
- Never upload directly to Strava
- Let Garmin own save and sync behavior
- Avoid displaying stale data without warning
- Avoid crashes from malformed advertisement payloads

## Logging and Diagnostics

Add a debug mode that records or displays:

- Scan started/stopped
- Advertisements seen
- Matching `M3` advertisements
- Bike IDs observed
- Last RSSI
- Valid packets parsed
- Invalid packet count
- Last packet age
- Longest dropout
- Reacquisition count
- Raw payload hex, development builds only

A diagnostic screen or simulator logging is sufficient for the MVP.

## MVP Scope

The MVP is complete when it can:

1. Run as a data field inside Garmin's built-in Indoor Bike activity.
2. Detect the user's original Keiser M3i.
3. Filter by the configured bike ID.
4. Display live power, cadence, and resistance.
5. Show a stale/disconnected state based on packet age.
6. Recover automatically after missed packets.
7. Save power, cadence, resistance, and optional console distance as FIT developer fields.
8. Preserve native Garmin wrist HR in the same activity.
9. Sync the saved activity through Garmin Connect.
10. Run on the Forerunner 970 without a phone connection during the ride.

## Acceptance Test

Perform a 30-minute ride with:

- Garmin Indoor Bike activity running
- Wrist HR enabled
- Phone Bluetooth disabled or phone removed
- Data field visible for part of the ride
- Watch screen changed away from and back to the data field
- At least one induced BLE interruption if practical

Pass criteria:

- Garmin activity records the full 30 minutes.
- Wrist HR exists for the full activity.
- Keiser power and cadence are present for substantially the entire ride.
- Temporary data loss does not stop or corrupt the activity.
- Data resumes automatically after interruption.
- Only one activity is created.
- Garmin Connect receives the activity.
- Strava receives the Garmin-synced activity if Garmin-to-Strava sync is enabled.
- No partial Keiser-app upload is involved.

## Out of Scope for MVP

- Native Garmin cycling-power sensor emulation
- Native Garmin cadence sensor emulation
- FTP detection
- Cycling VO2 max based on M3i power
- Automatic resistance control
- Structured workout control
- Direct Strava API uploads
- Phone companion app
- Cloud backend
- ANT+ rebroadcast
- BLE GATT connection to the bike

## Future Hardware Bridge

If native Garmin power and cadence recognition becomes necessary, build a separate ESP32 or nRF52 bridge that:

1. Listens for Keiser M3i advertisements.
2. Parses the proprietary payload.
3. Rebroadcasts standard BLE Cycling Power and Cadence or ANT+ profiles.
4. Pairs with Garmin as a normal sensor.

That is a separate phase and should not block the watch-data-field MVP.

## Execution Sequence and Parallel Work

Do not implement every subsystem at once. The baseline and real-bike protocol
must be verified first because they define the interfaces used by all later
work. After those gates close, four work lanes may proceed in parallel.

```text
Baseline compile gate
        ↓
Real-bike protocol gate
        ├── Parser and state lane
        ├── UI lane
        ├── FIT, settings, and lifecycle lane
        └── Diagnostics and test-infrastructure lane
                    ↓
             Integration gate
                    ↓
          Watch acceptance gate
```

### Phase 0: Reproducible Baseline

1. Record the Connect IQ SDK version and reproducible build commands.
2. Reduce the manifest to `fr970` and compile the inherited application before
   changing its behavior.
3. Produce a sideloadable baseline and watch-test instructions.

Gate 0 closes only when the inherited app builds for `fr970`, fits within the
data-field memory limit, and the exact toolchain and command are recorded.

### Phase 1: Real-Bike Protocol Verification

1. Add development-only raw-payload, bike-ID, manufacturer-ID, and RSSI output.
2. Sideload the diagnostic build and capture advertisements from the user's
   original M3i.
3. Confirm payload length, byte offsets, data-type values, units, duration
   wrapping, and representative values; save sanitized fixtures in the repo.
4. Write the confirmed packet contract and expected decoded values beside the
   fixtures.

Gate 1 closes only when a checked-in fixture can be decoded into values that
match the bike console. Until then, downstream agents may prepare scaffolding
but must not finalize parser, FIT, or display assumptions.

### Phase 2: Parallel Implementation Lanes

Once Gate 1 closes, complete the short shared-interface task `C2.0` in the
execution tracker. After that contract is committed, separate agents may claim
these lanes concurrently:

- **Parser and state:** immutable packet model, validated parser, explicit
  little-endian helpers, bike filtering, freshness states, dropouts, and
  reacquisition tests.
- **UI:** shared display model, full-screen power/cadence/resistance layout,
  compact fallback, and obvious degraded/disconnected presentation.
- **FIT, settings, and lifecycle:** compatible developer fields, Garmin-native
  HR preservation, stale-value omission, bike ID and unit settings, and safe
  scan start/stop behavior.
- **Diagnostics and test infrastructure:** counters, debug logging, fixtures,
  simulator scenarios, build scripts, and memory-budget reporting.

Each lane must consume the shared packet/state interfaces committed by the
`C2.0` owner. Interface changes that affect another lane require a tracker note
before code changes are merged.

### Phase 3: Integration

1. Merge the lanes and resolve interface mismatches centrally rather than
   independently changing shared contracts in each branch.
2. Compile for `fr970`, check the memory budget, and run all automated tests.
3. Exercise fresh, degraded, disconnected, malformed-packet, and reacquisition
   scenarios in the simulator.
4. Sideload the integrated build and confirm live display and FIT recording on
   the watch.

Gate 2 closes only when the integrated build passes automated and simulator
checks and completes a shorter device ride without stale data, crashes, or a
duplicate activity.

### Phase 4: Acceptance

Run the documented 30-minute ride, inspect the saved FIT activity, and verify
Garmin Connect and optional Strava synchronization. Mark the MVP complete only
after all acceptance evidence is recorded in the execution tracker.

## Source References

- Existing Garmin implementation:
  `https://github.com/tao-j/Keiser2Garmin`

- Existing hardware translation project:
  `https://github.com/tao-j/Keiser2ANT`

- Garmin Connect IQ Bluetooth Low Energy API:
  `https://developer.garmin.com/connect-iq/api-docs/Toybox/BluetoothLowEnergy.html`

- Garmin Connect IQ activity recording API:
  `https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityRecording.html`
