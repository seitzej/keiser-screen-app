# Build and Sideload the Data Field

## Pinned toolchain

Phase 0 is validated with the following toolchain:

- Connect IQ SDK `9.2.0`
- OpenJDK `17.0.19` (Garmin requires Java 11 or newer)
- Garmin device definitions downloaded by SDK Manager

Install Garmin's Connect IQ SDK Manager, select SDK `9.2.0`, and download the
device definitions needed by the build. On macOS, SDK Manager stores its active
SDK selection and device library under
`~/Library/Application Support/Garmin/ConnectIQ`.

On Apple Silicon Macs, the validated Homebrew installation is:

```sh
brew install openjdk@17
brew install --cask connectiq
brew install --cask connectiq-sdk-manager
```

Put Java and the Connect IQ compiler on `PATH` for the current shell, then
verify the pinned versions:

```sh
export PATH="/opt/homebrew/opt/openjdk@17/bin:/opt/homebrew/bin:$PATH"
java -version
monkeyc -v
```

The compiler check must report `Connect IQ Compiler version: 9.2.0`. Do not
treat a build from a different SDK version as Phase 0 evidence.

## Developer key

Connect IQ requires every PRG to be signed. Generate a private key outside the
repository and keep both key files private:

```sh
mkdir -p ~/.connectiq
openssl genrsa -out ~/.connectiq/developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER \
  -in ~/.connectiq/developer_key.pem \
  -out ~/.connectiq/developer_key.der \
  -nocrypt
export DEVELOPER_KEY="$HOME/.connectiq/developer_key.der"
```

Never commit the PEM or DER file. A key from another secure location can be
used by setting `DEVELOPER_KEY` to its absolute path.

## Baseline build

From a clean checkout, create the ignored output directory and compile the
inherited application for the baseline `fr970` target:

```sh
mkdir -p bin
monkeyc \
  -d fr970 \
  -f monkey.jungle \
  -o bin/keiser-screen-app-fr970.prg \
  -y "$DEVELOPER_KEY" \
  -r \
  -w \
  --build-stats 0
```

The command must exit successfully and create
`bin/keiser-screen-app-fr970.prg`. Generated files under `bin/` are ignored;
the source tree should remain clean after the build.

Verify the artifact before copying it to a watch:

```sh
ls -l bin/keiser-screen-app-fr970.prg
shasum -a 256 bin/keiser-screen-app-fr970.prg
```

Record the byte size and SHA-256 digest with the SDK version and build command.
The digest is expected to change whenever source, resources, manifest data, or
the signing key changes.

## USB sideload on Forerunner 970

1. On the watch, hold the middle-left button and select **Watch Settings >
   System > Advanced > USB Mode > MTP**.
2. Connect the watch to the computer with a data-capable USB cable.
3. Open the watch in an MTP-capable file manager and open its `GARMIN/APPS`
   directory.
4. Copy `bin/keiser-screen-app-fr970.prg` into `GARMIN/APPS`.
5. Eject or disconnect the watch cleanly. Restart the watch if the new data
   field does not appear immediately.

Garmin's command-line sideload workflow also produces a PRG and copies it to
`GARMIN/APPS`; the checked-in command is used here so the exact SDK, warnings,
memory statistics, filename, and checksum remain reproducible.

## Add the field to Indoor Bike

1. From the watch face, press the upper-right button.
2. Select **Activities > Indoor Bike**, scroll down, and open the activity
   settings.
3. Select **Data Screens**.
4. Edit an existing screen or choose **Add New**. For the inherited single-value
   display, select a one-field layout.
5. Select **Data Fields**, choose the Connect IQ data-field category, and select
   **Keiser BLE Data Field**.
6. Return to the activity, start Indoor Bike normally, and scroll to the screen
   containing the field.

The inherited bike ID setting defaults to `4`. If the bike uses another ID,
open the data field's settings in the Garmin Connect IQ app or Garmin Express
and set **Bike ID#** before starting the activity. The phone is not required
during the ride after configuration.

Phase 0 proves that the signed artifact builds and documents the sideload and
watch configuration path. Display, BLE, FIT, and real-bike behavior are
certified by the later simulator and physical-watch tasks in the execution
tracker.

For the development-only build and physical M3i protocol-capture procedure used
by Phase 1, see [Capture M3i Advertisement Diagnostics](advertisement-diagnostics.md).

Official references:

- [Garmin Connect IQ command-line setup](https://developer.garmin.com/connect-iq/reference-guides/monkey-c-command-line-setup/)
- [Garmin Connect IQ sideload workflow](https://developer.garmin.com/connect-iq/connect-iq-basics/your-first-app/)
- [Forerunner 970 advanced USB settings](https://www8.garmin.com/manuals/webhelp/GUID-025D75CF-3445-49E1-8D81-1AA74AB4E00F/EN-US/GUID-B6EEC065-0BAB-4A19-8350-A3A9DA44AD1D.html)
- [Forerunner 970 data-screen customization](https://www8.garmin.com/manuals/webhelp/GUID-025D75CF-3445-49E1-8D81-1AA74AB4E00F/EN-GB/GUID-638CD68D-11B0-4D9C-B8B7-E28D15EC4566.html)
