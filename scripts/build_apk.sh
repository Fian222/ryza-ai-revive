#!/usr/bin/env bash
# Build the Android APK without Gradle: aapt2 -> javac -> d8 -> zipalign ->
# apksigner. Uses the project-local toolchain from setup_android_tools.sh.
set -euo pipefail

ANDROID_API=34
BUILD_TOOLS_VERSION=34.0.0
MIN_ANDROID_API=24

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
LOCAL_TOOLS_FILE="$ROOT_DIR/config/android-tools.local.txt"

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "$2"
}

trim_whitespace() {
  local value=$1
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

resolve_tools_dir() {
  local configured
  if [[ -n ${RYZA_ANDROID_TOOLS:-} ]]; then
    configured=$RYZA_ANDROID_TOOLS
  elif [[ -f $LOCAL_TOOLS_FILE ]]; then
    configured=$(<"$LOCAL_TOOLS_FILE")
  else
    configured="$ROOT_DIR/.android-tools"
  fi
  configured=$(trim_whitespace "$configured")
  [[ -n $configured ]] || die "$LOCAL_TOOLS_FILE is empty"
  if [[ $configured != /* ]]; then
    configured="$ROOT_DIR/$configured"
  fi
  printf '%s' "$configured"
}

require_tool() {
  [[ -x $1 ]] || die "missing or non-executable tool $1 — run scripts/setup_android_tools.sh first"
}

require_command node "Node.js 18 or newer is required to stamp the application version"
require_command python3 "Python 3 is required for asset packaging and privacy validation"

NODE_MAJOR=$(node -p 'Number(process.versions.node.split(".")[0])') || die "could not determine the Node.js version"
[[ $NODE_MAJOR =~ ^[0-9]+$ && $NODE_MAJOR -ge 18 ]] || die "Node.js 18 or newer is required; found $(node --version)"

TOOLS_DIR=$(resolve_tools_dir)
JDK_DIR="$TOOLS_DIR/jdk17"
SDK_DIR="$TOOLS_DIR/android-sdk"
BUILD_TOOLS_DIR="$SDK_DIR/build-tools/$BUILD_TOOLS_VERSION"
ANDROID_JAR="$SDK_DIR/platforms/android-$ANDROID_API/android.jar"

JAVA="$JDK_DIR/bin/java"
JAVAC="$JDK_DIR/bin/javac"
KEYTOOL="$JDK_DIR/bin/keytool"
AAPT="$BUILD_TOOLS_DIR/aapt"
AAPT2="$BUILD_TOOLS_DIR/aapt2"
D8="$BUILD_TOOLS_DIR/d8"
ZIPALIGN="$BUILD_TOOLS_DIR/zipalign"
APKSIGNER="$BUILD_TOOLS_DIR/apksigner"

for path in "$JAVA" "$JAVAC" "$KEYTOOL" "$AAPT" "$AAPT2" "$D8" \
  "$ZIPALIGN" "$APKSIGNER"; do
  require_tool "$path"
done
[[ -f $ANDROID_JAR ]] || die "missing $ANDROID_JAR — run scripts/setup_android_tools.sh first"

JAVA_VERSION_OUTPUT=$("$JAVA" -version 2>&1) || die "could not run the project-local Java runtime"
JAVA_VERSION=${JAVA_VERSION_OUTPUT%%$'\n'*}
[[ $JAVA_VERSION == *'version "17.'* || $JAVA_VERSION == *'version "17"'* ]] || \
  die "OpenJDK 17 is required; project-local runtime reports: $JAVA_VERSION"

export JAVA_HOME="$JDK_DIR"
export ANDROID_SDK_ROOT="$SDK_DIR"
export PATH="$JAVA_HOME/bin:$PATH"

ANDROID_DIR="$ROOT_DIR/android"
WEB_DIR="$ROOT_DIR/web"
WORK_DIR="$ROOT_DIR/output/apk-work"
OUTPUT_DIR="$ROOT_DIR/output/android"

for source_path in \
  "$ROOT_DIR/config/version.json" \
  "$ANDROID_DIR/app/src/main/AndroidManifest.xml" \
  "$ANDROID_DIR/app/src/main/res" \
  "$ANDROID_DIR/app/src/main/java" \
  "$WEB_DIR/index.html"; do
  [[ -e $source_path ]] || die "required build input is missing: $source_path"
done

printf '== verify restored runtime media ==\n'
if ! python3 - "$WEB_DIR" <<'PY'
import json
import os
import sys

web = os.path.abspath(sys.argv[1])
index_dir = os.path.join(web, "assets", "_index")
indexes = (
    "skins.json", "scenes.json", "voice_bank.json", "ambient.json",
    "bgm.json", "prologue.json", "tap_voice.json", "se.json",
    "characters.json",
)
missing = []

def asset_paths(value):
    if isinstance(value, dict):
        for child in value.values():
            yield from asset_paths(child)
    elif isinstance(value, list):
        for child in value:
            yield from asset_paths(child)
    elif isinstance(value, str) and value.startswith("assets/"):
        yield value

for name in indexes:
    path = os.path.join(index_dir, name)
    if not os.path.isfile(path):
        missing.append(os.path.relpath(path, web))
        continue
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError) as exc:
        print("ERROR: could not read asset index %s: %s" % (path, exc), file=sys.stderr)
        sys.exit(1)
    for relative in asset_paths(data):
        if not os.path.isfile(os.path.join(web, *relative.split("/"))):
            missing.append(relative)

if missing:
    unique = sorted(set(missing))
    print("ERROR: %d indexed runtime asset(s) are missing." % len(unique), file=sys.stderr)
    for path in unique[:20]:
        print("  " + path, file=sys.stderr)
    if len(unique) > 20:
        print("  ... and %d more" % (len(unique) - 20), file=sys.stderr)
    sys.exit(1)
print("Restored media check OK")
PY
then
  printf '%s\n' \
    "Restore media from a compatible release package, rebuild the indexes, and retry:" \
    "  python3 scripts/restore_media.py /path/to/RyzaChat-<version>.apk" \
    "  python3 scripts/build_indexes.py" >&2
  exit 1
fi

printf '== version from config/version.json ==\n'
VERSION_DATA=$(python3 -c \
  'import json, sys; data=json.load(open(sys.argv[1], encoding="utf-8")); print("%s\t%s" % (data["version"], data["code"]))' \
  "$ROOT_DIR/config/version.json") || die "could not read config/version.json"
IFS=$'\t' read -r VERSION VERSION_CODE <<< "$VERSION_DATA"
[[ $VERSION =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]] || die "invalid version in config/version.json: $VERSION"
[[ $VERSION_CODE =~ ^[0-9]+$ ]] || die "invalid version code in config/version.json: $VERSION_CODE"
node "$SCRIPT_DIR/stamp_version.js" "$VERSION" "$VERSION_CODE" || \
  die "could not stamp the version into the shell manifests"
printf 'Building RyzaChat-%s.apk (versionCode %s)\n' "$VERSION" "$VERSION_CODE"

printf '== privacy gate on the tree that is about to be packed ==\n'
python3 "$SCRIPT_DIR/privacy_check.py" "$WEB_DIR" "$ANDROID_DIR/app/src/main" || \
  die "privacy check refused the build; nothing was packaged"

rm -rf -- "$WORK_DIR"
mkdir -p -- "$WORK_DIR" "$OUTPUT_DIR"

printf '== compile resources ==\n'
"$AAPT2" compile --dir "$ANDROID_DIR/app/src/main/res" -o "$WORK_DIR/res.zip" || \
  die "aapt2 compile failed"

printf '== link base apk (manifest + resources) ==\n'
"$AAPT2" link \
  -o "$WORK_DIR/base.apk" \
  --manifest "$ANDROID_DIR/app/src/main/AndroidManifest.xml" \
  -I "$ANDROID_JAR" \
  "$WORK_DIR/res.zip" \
  --auto-add-overlay \
  --min-sdk-version "$MIN_ANDROID_API" \
  --target-sdk-version "$ANDROID_API" \
  --version-code "$VERSION_CODE" \
  --version-name "$VERSION" || die "aapt2 link failed"

printf '== javac ==\n'
CLASSES_DIR="$WORK_DIR/classes"
mkdir -p -- "$CLASSES_DIR"
mapfile -d '' JAVA_SOURCES < <(find "$ANDROID_DIR/app/src/main/java" -type f -name '*.java' -print0)
[[ ${#JAVA_SOURCES[@]} -gt 0 ]] || die "no Java source files found under android/app/src/main/java"
"$JAVAC" -nowarn -encoding UTF-8 --release 11 -classpath "$ANDROID_JAR" \
  -d "$CLASSES_DIR" "${JAVA_SOURCES[@]}" || die "javac failed"

printf '== d8 ==\n'
mapfile -d '' CLASS_FILES < <(find "$CLASSES_DIR" -type f -name '*.class' -print0)
[[ ${#CLASS_FILES[@]} -gt 0 ]] || die "javac produced no class files"
"$D8" --release --lib "$ANDROID_JAR" --output "$WORK_DIR" "${CLASS_FILES[@]}" || \
  die "d8 failed"
[[ -f $WORK_DIR/classes.dex ]] || die "d8 completed but classes.dex is missing"

printf '== add dex into apk ==\n'
(cd -- "$WORK_DIR" && "$AAPT" add base.apk classes.dex) || die "aapt add failed"

printf '== pack web assets (forward slashes) ==\n'
python3 "$SCRIPT_DIR/pack_apk_assets.py" "$WORK_DIR/base.apk" "$WEB_DIR" || \
  die "asset packing failed"

printf '== zipalign ==\n'
"$ZIPALIGN" -f 4 "$WORK_DIR/base.apk" "$WORK_DIR/aligned.apk" || die "zipalign failed"

printf '== sign ==\n'
# Reuse this gitignored key for every release so Android permits upgrades.
KEYSTORE_DIR="$ANDROID_DIR/keystore"
KEYSTORE="$KEYSTORE_DIR/ryza.keystore"
mkdir -p -- "$KEYSTORE_DIR"
if [[ ! -f $KEYSTORE ]]; then
  "$KEYTOOL" -genkeypair -v \
    -keystore "$KEYSTORE" \
    -alias ryza \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Ryza Chat, OU=offline rebuild" \
    -storepass ryza-chat \
    -keypass ryza-chat >/dev/null || die "could not create the APK signing keystore"
fi

APK="$OUTPUT_DIR/RyzaChat-$VERSION.apk"
"$APKSIGNER" sign \
  --ks "$KEYSTORE" \
  --ks-pass pass:ryza-chat \
  --key-pass pass:ryza-chat \
  --out "$APK" \
  "$WORK_DIR/aligned.apk" || die "apksigner failed"

printf '== verify ==\n'
"$APKSIGNER" verify "$APK" || die "APK signature verification failed"

printf '== privacy gate on the signed APK (member names + text members) ==\n'
python3 "$SCRIPT_DIR/privacy_check.py" --quiet "$APK" || \
  die "the signed APK contains developer-identifying data; do not distribute it"

APK_BYTES=$(stat -c '%s' "$APK")
APK_MB=$(awk -v bytes="$APK_BYTES" 'BEGIN { printf "%.1f", bytes / 1048576 }')
printf 'Built: %s  (%s MB)\n' "$APK" "$APK_MB"
