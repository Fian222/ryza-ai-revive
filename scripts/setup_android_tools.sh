#!/usr/bin/env bash
# One-time setup of a project-local Android build toolchain for Linux.
# Installs: Temurin JDK 17, Android command-line tools, platform 34, and
# build-tools 34.0.0. Safe to rerun; already-installed components are reused.
set -euo pipefail

ANDROID_API=34
BUILD_TOOLS_VERSION=34.0.0
CMDLINE_TOOLS_REVISION=11076708

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
  mkdir -p -- "$configured"
  (cd -- "$configured" && pwd -P)
}

download_file() {
  local destination=$1
  shift
  local url
  for url in "$@"; do
    printf 'Trying %s\n' "$url"
    rm -f -- "$destination.part"
    if command -v curl >/dev/null 2>&1; then
      if curl --fail --location --retry 3 --retry-delay 2 \
        --output "$destination.part" "$url"; then
        mv -- "$destination.part" "$destination"
        return 0
      fi
    elif wget --tries=3 --timeout=60 --output-document="$destination.part" "$url"; then
      mv -- "$destination.part" "$destination"
      return 0
    fi
  done
  rm -f -- "$destination.part"
  die "could not download $(basename -- "$destination"); check the network connection and try again"
}

java_is_17() {
  local java_bin=$1
  local version_output version_line
  [[ -x $java_bin ]] || return 1
  version_output=$("$java_bin" -version 2>&1) || return 1
  version_line=${version_output%%$'\n'*}
  [[ $version_line == *'version "17.'* || $version_line == *'version "17"'* ]]
}

[[ $(uname -s) == Linux ]] || die "this setup script supports Linux only"
case "$(uname -m)" in
  x86_64|amd64) ;;
  *) die "Android Build Tools for Linux require an x86_64 host; found $(uname -m)" ;;
esac

require_command tar "tar is required (on Linux Mint: sudo apt install tar)"
require_command unzip "unzip is required (on Linux Mint: sudo apt install unzip)"
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  die "curl or wget is required (on Linux Mint: sudo apt install curl)"
fi

TOOLS_DIR=$(resolve_tools_dir)
[[ $TOOLS_DIR != / ]] || die "refusing to use / as the Android tools directory"
JDK_DIR="$TOOLS_DIR/jdk17"
SDK_DIR="$TOOLS_DIR/android-sdk"
CMDLINE_DIR="$SDK_DIR/cmdline-tools/latest"

TEMP_DIR=$(mktemp -d "$TOOLS_DIR/.android-setup.XXXXXX")
cleanup() {
  rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT

printf 'Android tools directory: %s\n' "$TOOLS_DIR"

if java_is_17 "$JDK_DIR/bin/java" && [[ -x $JDK_DIR/bin/javac ]]; then
  printf 'Reusing installed JDK 17: %s\n' "$JDK_DIR"
else
  printf '\n== install Temurin JDK 17 ==\n'
  JDK_ARCHIVE="$TEMP_DIR/jdk17.tar.gz"
  download_file "$JDK_ARCHIVE" \
    "https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse"
  mkdir -p -- "$TEMP_DIR/jdk-extract"
  tar -xzf "$JDK_ARCHIVE" -C "$TEMP_DIR/jdk-extract"
  JDK_SOURCE=$(find "$TEMP_DIR/jdk-extract" -mindepth 1 -maxdepth 1 -type d -print -quit)
  [[ -n $JDK_SOURCE && -x $JDK_SOURCE/bin/javac ]] || die "downloaded JDK archive has an unexpected layout"
  java_is_17 "$JDK_SOURCE/bin/java" || die "downloaded JDK is not Java 17"
  rm -rf -- "$JDK_DIR"
  mv -- "$JDK_SOURCE" "$JDK_DIR"
fi

mkdir -p -- "$SDK_DIR/cmdline-tools"
if [[ -x $CMDLINE_DIR/bin/sdkmanager ]]; then
  printf 'Reusing Android command-line tools: %s\n' "$CMDLINE_DIR"
else
  printf '\n== install Android command-line tools ==\n'
  CMDLINE_ARCHIVE="$TEMP_DIR/cmdline-tools.zip"
  download_file "$CMDLINE_ARCHIVE" \
    "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_REVISION}_latest.zip" \
    "https://mirrors.cloud.tencent.com/AndroidSDK/commandlinetools-linux-${CMDLINE_TOOLS_REVISION}_latest.zip"
  mkdir -p -- "$TEMP_DIR/cmdline-extract"
  unzip -q "$CMDLINE_ARCHIVE" -d "$TEMP_DIR/cmdline-extract"
  [[ -f $TEMP_DIR/cmdline-extract/cmdline-tools/bin/sdkmanager ]] || \
    die "downloaded Android command-line tools archive has an unexpected layout"
  rm -rf -- "$CMDLINE_DIR"
  mv -- "$TEMP_DIR/cmdline-extract/cmdline-tools" "$CMDLINE_DIR"
  chmod +x "$CMDLINE_DIR/bin/sdkmanager"
fi

export JAVA_HOME="$JDK_DIR"
export ANDROID_SDK_ROOT="$SDK_DIR"
export PATH="$JAVA_HOME/bin:$PATH"
SDKMANAGER="$CMDLINE_DIR/bin/sdkmanager"

printf '\n== accept Android SDK licenses ==\n'
# sdkmanager closes stdin after the last prompt, which makes `yes` receive
# SIGPIPE. Inspect sdkmanager's status instead of the pipeline's aggregate status.
set +e
set +o pipefail
yes | "$SDKMANAGER" --sdk_root="$SDK_DIR" --licenses
LICENSE_STATUS=${PIPESTATUS[1]}
set -o pipefail
set -e
[[ $LICENSE_STATUS -eq 0 ]] || die "Android SDK license acceptance failed"

printf '\n== install Android SDK packages ==\n'
"$SDKMANAGER" --sdk_root="$SDK_DIR" \
  "platform-tools" \
  "platforms;android-$ANDROID_API" \
  "build-tools;$BUILD_TOOLS_VERSION"

REQUIRED_TOOLS=(
  "$JDK_DIR/bin/java"
  "$JDK_DIR/bin/javac"
  "$JDK_DIR/bin/keytool"
  "$SDK_DIR/platforms/android-$ANDROID_API/android.jar"
  "$SDK_DIR/build-tools/$BUILD_TOOLS_VERSION/aapt"
  "$SDK_DIR/build-tools/$BUILD_TOOLS_VERSION/aapt2"
  "$SDK_DIR/build-tools/$BUILD_TOOLS_VERSION/d8"
  "$SDK_DIR/build-tools/$BUILD_TOOLS_VERSION/zipalign"
  "$SDK_DIR/build-tools/$BUILD_TOOLS_VERSION/apksigner"
)
for tool in "${REQUIRED_TOOLS[@]}"; do
  [[ -e $tool ]] || die "setup completed but required tool is missing: $tool"
done

printf '\n== installed versions ==\n'
"$JDK_DIR/bin/java" -version
"$SDK_DIR/build-tools/$BUILD_TOOLS_VERSION/aapt2" version
printf 'Android platform: android-%s\n' "$ANDROID_API"
printf 'Android Build Tools: %s\n' "$BUILD_TOOLS_VERSION"
printf 'Toolchain ready: %s\n' "$TOOLS_DIR"
