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
