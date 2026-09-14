# AGENTS.md

## Project overview

This repository is a personal fork of:

https://github.com/zeroa234/ryza-ai-revive

Git remotes are expected to follow this convention:

- `origin` → personal fork (`Fian222/ryza-ai-revive`)
- `upstream` → original repository (`zeroa234/ryza-ai-revive`)

The project contains:

- a web-based application core;
- Android wrapper and build tooling;
- desktop/Electron support;
- game and quest logic;
- memory and persistence logic;
- avatar and Spine rendering;
- expression, gesture, and motion systems;
- LLM integration;
- translation and language handling;
- TTS integration;
- supporting build, validation, and regression scripts.

The primary development environment for this fork is Linux Mint.

The upstream project should remain recognizable. Prefer extending the existing
architecture instead of replacing it.

---

## Development environment

Primary environment:

- OS: Linux Mint
- Shell: Bash
- Python: Python 3.12 or compatible Python 3
- Node.js: Node.js 18 or newer
- npm: available with Node.js
- Java: OpenJDK 17
- Android API target: 34
- Android Build Tools: 34.0.0
- Git: Git 2.x

Prefer commands that work natively on Linux.

Do not assume that Windows-only executables, PowerShell, Windows drive letters, or
Windows path separators are available.

Do not hard-code the developer's local username or project path.

For example, do not write code that assumes:

```text
/home/akhmat/Projects/ryza-ai-revive
```

Resolve repository-relative paths dynamically instead.

---

## Repository relationship

This fork tracks the original repository as `upstream`.

The intended relationship is:

```text
zeroa234/ryza-ai-revive
        ↓
    upstream
        ↓
Fian222/ryza-ai-revive
        ↓
      origin
```

The local `master` branch should remain as close as practical to
`upstream/master`.

Custom functionality should normally live in feature branches.

Before implementing functionality that may already have been added upstream:

1. inspect the current branch;
2. fetch or inspect upstream when appropriate;
3. verify whether upstream already contains equivalent behavior;
4. avoid duplicating an existing upstream implementation.

Do not automatically fetch, merge, rebase, push, or create a pull request unless
the user requests it or it is clearly required for the current task.

---

## Git workflow

The default upstream branch is:

```text
master
```

Rules:

- Do not implement new features directly on `master`.
- Keep `master` close to `upstream/master`.
- Perform new work on dedicated branches.
- Do not push automatically.
- Do not create pull requests automatically.
- Do not merge into `master` unless explicitly requested.
- Do not force-push unless explicitly requested.
- Do not rewrite published history unless explicitly requested.
- Avoid destructive Git operations.
- Never use `git reset --hard`, `git clean -fd`, or similar destructive commands
  without explicit approval.
- Do not discard existing user changes.
- Do not silently modify files unrelated to the current task.

Recommended branch naming:

```text
feat/linux-build
feat/nsfw-toggle
feat/<feature-name>

fix/<description>

test/<description>

docs/<description>

refactor/<description>
```

Before starting substantial work, inspect:

```bash
git status
git branch --show-current
git remote -v
```

If the current branch is `master`, do not begin implementing a feature there.
Create or ask to use an appropriate feature branch.

---

## Commit discipline

Keep unrelated work in separate commits.

Good examples:

```text
feat: add Linux Android build support
feat: add NSFW permission toggle
fix: handle missing avatar assets gracefully
test: add NSFW permission regression coverage
docs: document Linux build workflow
refactor: share Android build configuration
```

Avoid commits such as:

```text
update stuff
changes
fix everything
linux and nsfw changes
misc
```

Do not combine independent features into one large commit.

For example:

```text
Linux Android build support
```

and:

```text
NSFW permission toggle
```

should remain independently reviewable.

Do not create commits unless explicitly requested by the user.

If a commit is requested:

1. inspect `git status`;
2. inspect `git diff`;
3. stage only relevant files;
4. verify no secrets or restored binary assets are staged;
5. use a concise conventional-style commit message when practical.

---

## Development philosophy

Prefer the smallest correct change.

General rules:

- Preserve the existing project architecture.
- Preserve existing coding conventions.
- Reuse existing helpers and abstractions.
- Inspect current code before adding new abstractions.
- Avoid broad rewrites.
- Avoid opportunistic refactors unrelated to the task.
- Avoid unnecessary dependencies.
- Prefer existing project utilities over introducing new libraries.
- Do not rename unrelated symbols.
- Do not move unrelated files.
- Do not alter behavior outside the requested scope.
- Preserve compatibility with existing supported platforms where practical.
- Preserve existing Windows functionality when adding Linux functionality.
- Prefer additive changes over destructive replacements.
- Keep changes easy to review.
- Keep custom fork changes easy to rebase or merge with upstream later.

Do not over-engineer small features.

If the existing project already contains 80% of the required implementation, extend
that implementation instead of creating a second system.

---

## Vibe-coding behavior

The user may provide short, high-level requests such as:

```text
add linux build
```

or:

```text
add nsfw toggle
```

Treat those as requests to inspect the project and determine the appropriate
implementation from the existing architecture.

For vibe-coding tasks:

- inspect relevant files before writing code;
- infer routine technical details from the repository;
- follow existing patterns;
- make reasonable implementation decisions independently;
- avoid repeatedly asking for confirmation about minor details;
- ask only when different choices materially change behavior, compatibility,
  security, licensing, or project direction;
- prefer delivering a working incremental implementation over proposing a large
  redesign;
- explain important assumptions briefly.

Do not generate large amounts of code before understanding the relevant existing
implementation.

---

## Scope control

Stay within the requested task.

When adding Linux build support, do not also:

- refactor game logic;
- modify LLM prompts;
- redesign settings;
- modify avatar rendering;
- alter NSFW behavior;
- update unrelated dependencies;
- reorganize the repository.

When adding an NSFW permission toggle, do not also:

- rewrite the Android build system;
- modify unrelated game mechanics;
- replace the TTS provider architecture;
- redesign memory behavior;
- refactor unrelated UI components.

If unrelated problems are discovered:

- report them;
- do not automatically fix them unless they block the requested work.

---

## Secrets and privacy

Never hard-code or commit:

- API keys;
- access tokens;
- passwords;
- session tokens;
- authentication cookies;
- private credentials;
- private endpoints;
- personal machine paths;
- local usernames.

Examples that must never be committed:

```text
gsk_...
sk-...
sk-fish-...
Bearer ...
/home/<username>/...
```

Use:

- application settings;
- local storage mechanisms already used by the project;
- environment variables;
- runtime configuration;
- existing provider configuration systems.

Do not introduce default API keys for:

- Groq;
- OpenRouter;
- Fish Audio;
- Alibaba/Qwen;
- OpenAI;
- or any other provider.

Preserve and respect the repository's privacy validation.

Run when relevant:

```bash
python3 scripts/privacy_check.py web
```

Do not weaken, bypass, or remove privacy checks merely to make a build succeed.

---

## Media and binary assets

Large media files are intentionally not all committed to Git.

Examples include:

- Spine `.skel` binaries;
- large textures;
- avatar resources;
- audio;
- voice samples;
- release media;
- other binary assets restored from packaged builds.

A fresh clone may therefore not contain all files required by motion or expression
tests.

Do not assume missing binary media means the source code is broken.

Media can be restored from a compatible release APK using:

```bash
python3 scripts/restore_media.py <release-apk>
```

After restoration, rebuild indexes when required:

```bash
python3 scripts/build_indexes.py
```

Do not commit restored large media unless explicitly requested and allowed by the
repository's existing rules.

Before staging broad changes, inspect:

```bash
git status
```

Do not blindly run:

```bash
git add .
```

when restored media or generated artifacts may be present.

---

## Restored Spine assets

Some regression tests require restored Spine binaries.

Important examples include:

```text
web/assets/spine/crf_chr_002/crf_skn_002_0001_01/
web/assets/spine/crf_chr_002/crf_skn_002_0001_99/
```

Tests may require files such as:

```text
*.skel
*.atlas
*.png
*_gesture.json
```

An error such as:

```text
ENOENT: no such file or directory ... *.skel
```

does not automatically indicate a code regression.

Before diagnosing it as a source-code issue:

1. verify whether release media has been restored;
2. inspect the expected asset directory;
3. run `restore_media.py` if appropriate;
4. retry the test.

Do not modify regression tests merely to hide missing restored assets.

---

## Generated files

Determine whether a file is generated before editing it manually.

If an existing script generates a file:

- prefer modifying its source/input when necessary;
- regenerate using the official script;
- avoid manually editing generated output unless explicitly appropriate.

Examples of generation-related scripts may include:

```text
scripts/build_indexes.py
scripts/stamp_version.js
```

Preserve the project's existing generated-file workflow.

Do not commit build artifacts unless explicitly requested.

---

## Testing philosophy

Run tests relevant to the changed behavior.

Do not claim a test passed unless it was actually executed successfully.

Report:

- tests that passed;
- tests that failed;
- tests that were skipped;
- tests that could not run;
- the reason for any skipped or unavailable test.

Do not hide failing tests.

Prefer targeted tests first, followed by broader regression coverage when practical.

---

## Core regression tests

For general application logic changes, run:

```bash
node scripts/boot_smoke.js
node scripts/game_logic_regression.js
node scripts/memory_regression.js
python3 scripts/privacy_check.py web
```

These cover important application behavior including:

- application boot;
- core state;
- game mechanics;
- memory behavior;
- LLM-related configuration behavior;
- privacy validation.

If the changed files affect one of these areas, the relevant test should normally
be executed.

---

## Avatar and motion regression tests

When restored media is available, run:

```bash
node scripts/motion_regression.js
node scripts/expression_coverage.js
```

These tests exercise areas including:

- Spine skeleton loading;
- avatar posture;
- sitting and standing skeletons;
- gaze;
- blinking;
- gestures;
- facial expressions;
- tap hit testing;
- camera behavior;
- atlas variants;
- referenced animations;
- expression coverage.

Do not classify informational orphan/unreferenced animation output as a failure when
the script itself reports success.

The important final states include output such as:

```text
2 skins + ... invariant checks passed.
```

and:

```text
COVERAGE: OK
```

---

## Test changes

When fixing or adding behavior:

- add regression coverage when practical;
- do not modify tests only to match an incorrect implementation;
- preserve meaningful existing assertions;
- avoid deleting failing assertions without understanding them;
- keep tests deterministic where possible.

For a bug fix, prefer:

```text
reproduce bug in test
→ implement fix
→ test passes
```

when reasonable.

---

## Baseline expectations

Before major changes, the existing project should ideally pass:

```bash
node scripts/boot_smoke.js
node scripts/game_logic_regression.js
node scripts/memory_regression.js
node scripts/motion_regression.js
node scripts/expression_coverage.js
python3 scripts/privacy_check.py web
```

The motion and expression tests require restored media.

If baseline tests fail before modifications:

- record the pre-existing failure;
- distinguish it from failures introduced by the current change.

---

## Linux support

The upstream Android tooling is currently Windows-oriented.

Linux support should be implemented as an additive feature.

Preferred Linux equivalents:

```text
scripts/setup_android_tools.sh
scripts/build_apk.sh
```

Existing Windows scripts should remain available:

```text
scripts/setup_android_tools.ps1
scripts/build_apk.ps1
```

Do not delete, rename, or break existing Windows scripts simply because Linux
scripts are introduced.

The goal is:

```text
Windows
    → existing PowerShell build remains functional

Linux
    → equivalent native Bash build becomes available
```

---

## Linux implementation strategy

Before implementing Linux Android build support:

1. read `scripts/setup_android_tools.ps1`;
2. read `scripts/build_apk.ps1`;
3. identify every external tool used;
4. identify tool versions;
5. identify build order;
6. identify input files;
7. identify generated intermediate files;
8. identify signing behavior;
9. identify final APK output location;
10. reproduce equivalent behavior using Linux-native tools.

Do not invent a completely unrelated Android build architecture unless there is a
strong technical reason.

Prefer parity with upstream.

---

## Linux shell script rules

Linux shell scripts should use:

```bash
#!/usr/bin/env bash
```

Prefer strict shell handling where compatible:

```bash
set -euo pipefail
```

Scripts should:

- use Unix path conventions;
- quote variables;
- handle paths containing spaces where practical;
- use repository-relative paths;
- detect missing dependencies;
- provide useful failure messages;
- exit non-zero on errors;
- avoid silently ignoring failures;
- be safe to rerun when practical;
- avoid requiring root during normal build execution;
- avoid machine-specific paths;
- avoid downloading unnecessary files repeatedly.

Useful dependency checks include:

```bash
command -v java >/dev/null
command -v javac >/dev/null
command -v node >/dev/null
command -v python3 >/dev/null
```

Do not use Linux build scripts that depend on:

```text
.exe
.bat
Windows drive letters
Windows path separators
PowerShell-only commands
```

---

## System package installation

Project scripts should not silently modify the operating system.

Do not automatically run commands such as:

```bash
sudo apt install ...
```

inside normal build scripts.

If a required system package is missing:

- detect it;
- show a clear error;
- tell the user what dependency is required.

A dedicated setup script may download project-local Android tooling where
appropriate.

Prefer project-local Android SDK/tooling when practical so builds are reproducible.

---

## Android build configuration

Maintain compatibility with:

```text
OpenJDK 17
Android API 34
Android Build Tools 34.0.0
```

unless upstream changes these versions or the user explicitly requests an upgrade.

Preserve upstream Android configuration where practical.

Do not casually upgrade:

- compile SDK;
- build tools;
- Java version;
- package format;
- signing behavior;

as part of unrelated work.

---

## Android build pipeline

The Linux Android build should reproduce the upstream build pipeline as closely as
possible.

Relevant stages may include:

```text
version stamping
        ↓
privacy validation
        ↓
resource compilation
        ↓
Java compilation
        ↓
DEX generation
        ↓
APK packaging
        ↓
web asset packaging
        ↓
alignment
        ↓
signing
        ↓
verification
        ↓
final APK
```

Inspect the PowerShell build script for the authoritative current order.

Do not assume this document overrides newer upstream build behavior.

---

## Android tool setup

The desired Linux workflow should ideally be:

```bash
./scripts/setup_android_tools.sh
./scripts/build_apk.sh
```

The setup script should:

- locate the repository root;
- determine the local tools directory;
- detect existing compatible tools;
- avoid unnecessary redownloads;
- obtain Linux-compatible Android command-line tooling;
- install or obtain required SDK components;
- validate installed tools;
- report useful versions and paths;
- be rerunnable.

If project-local tooling is used, keep its directory ignored by Git when
appropriate.

Do not embed the developer's home directory.

---

## Android build script expectations

The Linux build script should:

- locate the repository root automatically;
- validate Java;
- validate Android tooling;
- validate Node.js;
- validate Python when required;
- validate required source assets;
- run version stamping if upstream does;
- run privacy validation;
- compile required Android resources;
- compile Java sources;
- generate DEX files;
- package web assets;
- align the APK;
- sign the APK;
- verify the final APK;
- clearly print the final output path.

If a required restored media asset is missing, fail with a useful message instead
of a confusing low-level error when practical.

---

## Android signing

Preserve upstream signing behavior.

Do not:

- expose signing passwords;
- commit private keystores unexpectedly;
- replace release signing configuration without reason;
- disable APK signature verification merely to make builds pass.

If the upstream build generates or uses a development keystore, reproduce the same
intent on Linux.

Treat keystores and signing credentials as sensitive.

---

## Build artifacts

Do not commit build outputs by default.

Examples:

```text
output/android/*.apk
intermediate build directories
temporary DEX files
temporary resource packages
```

Respect existing `.gitignore` rules.

If new Linux build tooling creates additional temporary directories, ensure they are
appropriately ignored when needed.

---

## Application architecture

Before editing application logic, inspect how the existing project organizes:

- configuration;
- UI;
- state;
- persistence;
- avatar rendering;
- game logic;
- LLM calls;
- TTS calls;
- translation;
- localization.

Avoid creating parallel systems for behavior the project already handles.

Prefer modifying the closest existing abstraction.

---

## Configuration

Preserve the existing configuration model.

Do not introduce duplicate configuration for values already represented elsewhere.

For new settings:

- choose a clear default;
- define whether the setting persists;
- ensure UI reflects runtime state;
- ensure reset behavior is intentional;
- follow existing config/state naming conventions;
- avoid breaking existing saved state.

Migrations or compatibility handling may be necessary if persisted state changes
shape.

---

## Localization

Use the existing localization/i18n system for user-facing strings.

Do not hard-code new visible English strings directly in logic if the surrounding UI
uses translation keys.

When adding a setting:

1. inspect existing locale files or translation structures;
2. add the new key consistently;
3. preserve existing locales;
4. follow existing fallback behavior.

Do not remove translations unrelated to the task.

Do not invent broad localization rewrites when adding one small string.

---

## LLM architecture

The application supports configurable LLM providers.

Do not hard-code one provider unless explicitly requested.

Examples of possible providers may include:

- Groq;
- OpenRouter;
- OpenAI-compatible endpoints;
- other compatible services.

Treat model configuration as runtime configuration.

Do not commit personal model API keys.

Preserve existing model-selection behavior.

---

## LLM behavior

When editing prompts or response parsing:

- inspect current prompt construction;
- inspect machine-readable control tags;
- preserve backward compatibility where practical;
- do not casually change output protocols;
- update relevant tests if protocol behavior intentionally changes.

Machine-readable fields such as emotion, attitude, stage, or undress state should not
leak into displayed dialogue unless intentionally designed to do so.

Do not change prompt personality or roleplay behavior as a side effect of unrelated
work.

---

## TTS architecture

Treat TTS as independent from the LLM.

Conceptually:

```text
LLM
    → generates semantic response

display language
    → controls visible dialogue

translation
    → may generate spoken-language text

TTS provider
    → synthesizes audio

voice configuration
    → controls voice identity
```

Do not assume changing the LLM changes the voice.

Preserve provider configurability.

Never commit personal TTS API keys.

---

## Language behavior

The project may use different languages for:

- UI;
- LLM output;
- displayed dialogue;
- bundled audio;
- translated TTS text;
- synthesized speech.

Preserve this separation.

A supported configuration may conceptually be:

```text
user input       → Indonesian
LLM output       → Indonesian
displayed text   → Indonesian
TTS input        → Japanese
speech           → Japanese
```

Do not collapse these language settings into one locale without understanding the
existing design.

---

## Voice cloning

Do not automatically upload local voice/reference assets to third-party services
unless the existing feature explicitly does so and the user has configured the
provider.

Keep voice-provider behavior explicit.

Do not embed provider credentials into the application bundle.

For self-hosted TTS additions:

- keep endpoint configuration flexible;
- avoid assuming localhost when Android may connect over LAN;
- do not remove existing cloud TTS support.

---

## NSFW / undress architecture

The upstream project already contains NSFW/undress-related behavior.

Do not implement a second NSFW rendering system from scratch.

Inspect:

```text
web/js/nsfw.js
web/js/avatar.js
web/js/api.js
web/js/app.js
web/js/config.js
```

and any related tests before changing behavior.

Existing functionality may include:

- `undress:on`;
- `undress:off`;
- compatibility aliases;
- runtime NSFW state;
- atlas texture variants;
- screen-state facts communicated to the LLM.

Reuse these mechanisms.

---

## NSFW permission toggle

If implementing an explicit NSFW permission toggle, distinguish two concepts:

```text
permission
```

and:

```text
current undress visual state
```

They are not the same thing.

Recommended semantics:

```text
permission OFF
    → NSFW visual state cannot be activated

permission ON
    → existing undress state machinery may operate
```

The LLM must not be able to bypass an explicit user-disabled permission.

For example:

```text
permission OFF + LLM undress:on
    → remain visually normal

permission ON + LLM undress:on
    → activate supported NSFW atlas variant

permission ON + LLM undress:off
    → restore normal atlas

permission switched OFF while active
    → restore normal atlas
```

Prefer default:

```text
OFF
```

unless explicitly requested otherwise.

---

## NSFW implementation guidelines

When implementing the toggle:

- reuse the existing `Nsfw` object/module;
- avoid duplicating atlas selection logic;
- avoid duplicating LLM parser logic;
- preserve existing aliases;
- preserve current reset behavior unless intentionally changed;
- make settings UI reflect permission state;
- persist the permission consistently with other application settings;
- ensure a reset does not accidentally bypass permission;
- ensure loading saved state does not activate forbidden state while permission is
  disabled.

Do not couple NSFW permission work with unrelated conversation-policy changes.

---

## NSFW conversation behavior

Visual NSFW state and adult conversation behavior are separate concerns.

Do not assume:

```text
NSFW visual enabled
```

means:

```text
adult conversation mode enabled
```

If an adult-conversation feature is ever implemented, treat it as a distinct feature
with its own configuration and prompt behavior.

Do not silently modify LLM conversational restrictions when implementing only a
visual permission toggle.

---

## NSFW regression tests

If implementing an NSFW permission toggle, add or extend regression coverage where
practical.

Important cases:

```text
default permission is OFF

permission OFF
+ undress:on
→ no NSFW visual activation

permission ON
+ undress:on
→ NSFW visual activation allowed

permission ON
+ undress:off
→ normal visual restored

permission ON
+ currently active
+ user switches permission OFF
→ normal visual restored

reset application state
→ permission/state behave as designed
```

Reuse existing boot or application regression infrastructure where sensible instead
of creating unnecessarily complex test tooling.

---

## Avatar and atlas variants

NSFW visuals may use atlas/texture variants while reusing the same Spine skeleton.

Do not assume every visual variant requires a new `.skel`.

Inspect existing variant discovery behavior before modifying paths.

Keep variant selection costume-generic where upstream currently does so.

Do not hard-code behavior only for one posture if the renderer supports both:

```text
_01 → sitting
_99 → standing
```

Relevant motion tests should continue passing.

---

## Skin handling

Do not confuse:

```text
wearable Spine skins
```

with:

```text
preview-only outfits
```

Some outfit entries may have previews but lack a renderable Spine skeleton.

Preserve existing fallback behavior unless the task explicitly changes it.

Do not represent preview-only assets as fully wearable without the required model
data.

---

## Game logic

Avoid modifying game state or progression as part of unrelated UI/build work.

Changes affecting:

- stamina;
- EXP;
- level;
- inventory;
- quests;
- daily login;
- map movement;
- time passage;

should run:

```bash
node scripts/game_logic_regression.js
```

Preserve existing state reducer behavior.

---

## Memory system

Changes affecting:

- conversation sessions;
- summaries;
- memory cards;
- context construction;
- model context estimation;
- thinking configuration;

should run:

```bash
node scripts/memory_regression.js
```

Do not rewrite memory persistence as part of unrelated work.

---

## Boot behavior

Changes affecting:

- configuration;
- application initialization;
- settings;
- LLM/TTS wiring;
- NSFW parsing;
- startup state;

should normally run:

```bash
node scripts/boot_smoke.js
```

Preserve successful application initialization.

---

## Documentation

Update documentation when the user-facing setup or developer workflow changes.

For Linux Android support, documentation should explain:

- prerequisites;
- supported Java version;
- Android tool setup;
- media restoration requirement;
- setup command;
- build command;
- output location;
- common missing-asset errors.

Do not rewrite unrelated README sections.

Prefer adding concise Linux instructions alongside existing Windows instructions.

---

## README compatibility

Do not delete Windows instructions from the README when adding Linux instructions.

Aim for documentation such as:

```text
Android build

Windows
    setup_android_tools.ps1
    build_apk.ps1

Linux
    setup_android_tools.sh
    build_apk.sh
```

Keep platform-specific instructions clear.

---

## Cross-platform parity

When Linux support mirrors Windows functionality:

- keep script names parallel;
- keep configuration versions aligned;
- keep output naming aligned;
- keep validation steps aligned;
- keep signing intent aligned.

If Linux behavior intentionally differs, document the reason.

---

## Upstream compatibility

Custom changes should remain easy to reconcile with future upstream updates.

Prefer:

- small changes;
- dedicated files;
- isolated commits;
- minimal edits to shared upstream code.

Avoid unnecessary formatting rewrites of upstream files.

A large formatting-only diff makes future merges harder.

Do not reformat entire JavaScript files merely to modify a few lines.

---

## Pull-request readiness

Even though this fork is primarily personal, some features may later be offered
upstream.

Features with potential upstream value should therefore be:

- isolated;
- documented;
- tested;
- free of personal paths;
- free of secrets;
- compatible with existing behavior;
- reasonably cross-platform;
- easy to review.

Linux build support is a good example of a feature that may later be proposed
upstream.

Personal customization does not need to be forced into an upstream-compatible PR
unless requested.

---

## Contributor attribution

Do not copy code from another fork without considering attribution and licensing.

If using an implementation from another contributor:

- preserve required license obligations;
- prefer original implementation when independently developing the same simple
  behavior;
- do not falsely claim authorship of copied substantial code.

Do not automatically add external contributor commits unless explicitly requested.

---

## Coding-agent workflow

For each development task:

1. Read this `AGENTS.md`.
2. Determine the repository root.
3. Check `git status`.
4. Check the current branch.
5. Identify the requested scope.
6. Inspect relevant source files.
7. Inspect relevant tests.
8. Inspect existing upstream architecture.
9. Determine the smallest appropriate implementation.
10. Implement the change.
11. Run targeted tests.
12. Run broader regression tests when practical.
13. Run privacy checks when relevant.
14. Inspect `git diff`.
15. Inspect `git status`.
16. Summarize changes.
17. Summarize test results.
18. Mention any remaining limitation.

Do not push, merge, tag, release, or create a pull request unless explicitly
requested.

---

## Planning behavior

For small changes:

- do not spend excessive time producing a formal plan;
- inspect code and implement directly.

For changes affecting multiple subsystems:

- briefly state the implementation plan;
- identify affected files;
- identify relevant tests;
- then implement.

Do not create large speculative design documents unless requested.

---

## Error handling

When a command fails:

1. read the actual error;
2. identify whether it is:
   - source-code failure;
   - dependency failure;
   - missing restored asset;
   - platform incompatibility;
   - test regression;
   - environment issue;
3. fix the actual cause;
4. do not suppress errors without understanding them.

For example:

```text
ENOENT ... *.skel
```

should prompt an asset-restoration check before changing application logic.

---

## Dependency policy

Avoid adding dependencies unless necessary.

Before adding a package:

1. check whether the project already has equivalent functionality;
2. check whether a standard tool can handle the requirement;
3. evaluate cross-platform consequences;
4. explain why the dependency is needed.

Do not add heavy build frameworks merely to replace a small existing script unless
the user explicitly wants that architectural change.

---

## Performance

Do not introduce obvious unnecessary work into hot application paths.

Be cautious when changing:

- animation loops;
- avatar rendering;
- repeated prompt generation;
- memory processing;
- network requests;
- TTS playback;
- asset loading.

Prefer caching and existing project patterns where appropriate.

Do not prematurely optimize unrelated code.

---

## Network behavior

Do not introduce unexpected network requests.

Any new external endpoint should be:

- configurable;
- explicit;
- documented where appropriate.

Do not transmit:

- API keys to unrelated services;
- local files;
- voice references;
- conversation content;

to new third-party services without an intentional feature design.

---

## Provider failures

LLM or TTS providers may return:

```text
429 Too Many Requests
401 Unauthorized
403 Forbidden
5xx server errors
network timeouts
```

When changing provider integration:

- preserve actionable error reporting;
- do not expose secret keys in logs;
- avoid infinite retry loops;
- respect existing retry/backoff patterns.

Do not treat provider rate limits as application logic failures.

---

## Local/self-hosted providers

If adding support for a local or self-hosted service:

- keep endpoint configurable;
- do not hard-code `localhost` as the only valid host;
- remember Android may need to reach a computer over LAN;
- preserve cloud-provider support;
- avoid coupling provider logic to Linux-only assumptions.

---

## Security

Avoid:

- `eval` for untrusted provider responses;
- shell command construction from untrusted text;
- logging secrets;
- embedding credentials in APK assets;
- disabling TLS checks without explicit reason.

Treat provider output as external input.

Preserve safe parsing conventions.

---

## User data

Do not unexpectedly wipe:

- memory;
- game progress;
- settings;
- provider configuration;
- saved state.

If a state schema change could break existing stored data, implement compatibility or
clearly document the reset requirement.

---

## Backward compatibility

When practical:

- existing settings should continue loading;
- existing chat modes should continue working;
- existing LLM providers should continue working;
- existing TTS providers should continue working;
- existing Windows build should continue working.

Do not introduce a personal customization that unnecessarily breaks upstream usage.

---

## Code review checklist

Before considering a change complete, verify:

- Is the change limited to the requested scope?
- Did we reuse existing architecture?
- Are there unrelated formatting changes?
- Are there hard-coded local paths?
- Are there API keys or credentials?
- Are generated or restored assets accidentally staged?
- Does Windows support remain intact?
- Does Linux behavior work when applicable?
- Were relevant tests executed?
- Does privacy validation pass?
- Is documentation needed?
- Is the diff easy to understand?

---

## Before finishing

Before reporting completion:

```bash
git status
git diff
```

or equivalent inspection should be performed when appropriate.

Confirm:

- no secrets were added;
- no personal absolute paths were added;
- no restored media was accidentally staged;
- no unrelated files were changed;
- relevant tests were run;
- failures are reported accurately.

The final report should include:

```text
Changed:
- ...

Tests:
- PASS ...
- PASS ...
- SKIPPED ... because ...

Notes:
- ...
```

Do not claim completion when a required build or test failed unless the failure is
clearly explained.

---

## Actions requiring explicit user request

Do not perform these actions automatically:

- push to `origin`;
- push to `upstream`;
- merge into `master`;
- force-push;
- create a GitHub pull request;
- tag a release;
- publish a release;
- upload an APK;
- delete branches;
- rewrite published Git history;
- remove user files;
- rotate credentials.

Prepare the work locally and ask or report what is ready.

---

## Current priorities for this fork

Current likely development areas include:

1. Linux-native Android build support.
2. Keeping Android build behavior equivalent to upstream Windows tooling.
3. Personal application configuration/customization.
4. Optional explicit NSFW/undress permission toggle.
5. Maintaining compatibility with upstream updates.
6. Supporting configurable LLM and TTS providers.
7. Keeping Indonesian display/chat language separable from Japanese TTS where
   supported.

These priorities are context, not permission to implement unrelated features.

Only implement the current requested task.

---

## Final principle

Treat this fork as:

```text
upstream-compatible base
        +
small, isolated personal enhancements
        +
Linux development support
```

Prefer changes that are:

```text
minimal
testable
reversible
reviewable
upstream-friendly
```

Read the existing implementation first, then modify it.