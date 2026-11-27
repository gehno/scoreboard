# Scoreboard

Offline scoreboard for sports matches, built with Flutter/Dart for Windows and
Linux desktop. One operator window controls the match and a separate display
window shows the scoreboard on a second monitor, projector or TV.

See [FEATURES.md](FEATURES.md) for the full feature list and
[CHANGELOG.md](CHANGELOG.md) for release notes.

## Highlights
- Sports: handball, football, basketball, volleyball, ice hockey, tennis and table tennis.
- Match engine: clock (up or down), periods or sets, scores, tennis points, timeouts, 2-minute suspensions, undo and redo.
- Display window on any monitor in borderless fullscreen, fed over a local loopback WebSocket.
- Drag and drop layout editor and 12 themes (6 dark, 6 light).
- Configurable match rules, team names and logos, keyboard shortcuts and language (English, Deutsch).
- Export and import of all settings and layouts as a zip file.
- Works fully offline.

## Getting started
Windows requires Flutter (stable) with Windows desktop support and Visual
Studio 2022 Build Tools ("Desktop development with C++"). Linux requires
Flutter (stable) with Linux desktop support and the
[Linux desktop prerequisites](https://docs.flutter.dev/platform-integration/linux/setup):
`clang`, `cmake`, `ninja-build`, `pkg-config`, GTK 3 development files and
`libstdc++` development files.

```
cd apps/scoreboard
flutter pub get
flutter run -d windows
```

Release build: `flutter build windows --release`. The output is written to
`apps/scoreboard/build/windows/x64/runner/Release`.

On Linux, use `flutter run -d linux` or build a release bundle with
`flutter build linux --release`. The bundle is written to
`apps/scoreboard/build/linux/x64/release/bundle`; the target system needs the
GTK 3 and other system libraries linked by the build.

## Web demo
The browser version is a preview of the operator UI and its scoreboard. Match
controls, settings and the layout editor work in memory; changes are lost on
reload. The separate display window, local image files and backup import/export
are unavailable.

To build static files for a GitHub project site:

```
cd apps/scoreboard
flutter pub get
flutter build web --release --base-href /REPOSITORY_NAME/
```

The site is written to `apps/scoreboard/build/web`. Use `--base-href /` for a
user or organization site, or when hosting at the domain root. Flutter needs
HTTP to load the app; opening `index.html` directly does not work. To preview
locally instead, run `flutter run -d chrome` from `apps/scoreboard`.

For automatic GitHub Pages deployment, set **Settings → Pages → Build and
deployment → Source** to **GitHub Actions**. The Web demo workflow builds on
pushes and pull requests and deploys the default branch. The repository's Pages
settings and visibility must permit deployment.

## Usage
- **Display window:** click the TV icon to open it. With several monitors you pick one and it opens in borderless fullscreen there. In the display window, F11 or a double-click toggles fullscreen and Esc leaves it. It closes together with the operator window.
- **Default hotkeys:** Space start/stop, Q/A home +/-, P/L away +/-, W/O timeout, E/I suspension, N next period/set, Esc abort timeout, Ctrl+Z/Y undo/redo. Shortcuts are ignored while typing in a text field.
- **Settings (gear icon):** one page per topic:
  - Team names and optional logos.
  - Match rules: sport, periods or sets, minutes per period, timeouts per team, timeout length and clock direction. Applying starts a new match for that sport and keeps the team names.
  - Theme.
  - Language.
  - Shortcuts.
- **Themes:** Classic, Midnight, Neon, Terminal, Forest and High contrast (dark), plus Daylight, Sunrise, Mint, Sky, Paper and High contrast light (light). A theme recolors the scoreboard and restyles the operator UI independently of the sport. "Classic" keeps each sport's own colors.
- **Layout editor:** layouts define what is shown and where. Each sport has its own saved layout.
- **Persistence:** settings are saved in `settings.json` next to the layouts. Windows stores them under `%APPDATA%/scoreboard_layouts`; Linux uses `$XDG_CONFIG_HOME/scoreboard_layouts` or `~/.config/scoreboard_layouts`. Use export/import to back up or move everything as a zip.

## Project structure
- `packages/scoreboard_core`: pure Dart (no Flutter, no `dart:io`). Contains sports, match state and controller, layouts and bindings, themes and the display protocol.
- `apps/scoreboard`: Flutter app.
  - `lib/app/`: shell, theme, about dialog.
  - `lib/operator/`: operator screen.
  - `lib/editor/`: layout editor.
  - `lib/settings/`: settings pages and persistence.
  - `lib/match/`: match session state.
  - `lib/display/` and `lib/scoreboard/`: display window and renderer.
  - `lib/l10n/`: ARB translations and localized model labels.
  - `lib/storage/`: storage code.
  - `lib/platform/`: the code that touches the OS (files, windows, sockets, processes), behind the `AppStorage` and `DisplayOutput` interfaces.
- `.github/`: CI/release workflow and the release notes script.

The app version and author are defined only in `apps/scoreboard/pubspec.yaml`.

App icon: `apps/scoreboard/assets/icon/app_icon.svg` is the source. After changing it,
export `app_icon.png` (1024 px) and run `dart run flutter_launcher_icons` in `apps/scoreboard`.

## Platforms
Windows and Linux are supported desktop platforms; the browser build is a
limited demo. Linux builds currently target x64 and require GTK 3 runtime
libraries. On Wayland, the compositor controls window placement, so opening the
display fullscreen on a specific monitor may depend on the desktop environment.
macOS, Android and iOS are not supported. Platform-specific code is in
`apps/scoreboard/lib/platform/`, with native runner code under `windows/` and
`linux/`.

## Testing
```
cd packages/scoreboard_core && dart analyze --fatal-infos && dart test
cd apps/scoreboard && flutter analyze && flutter test
```

## Localization
The app uses Flutter's `gen-l10n` with ARB files. The configuration is in `apps/scoreboard/l10n.yaml`.
- Messages: `apps/scoreboard/lib/l10n/app_en.arb` (template) and `app_de.arb`.
- `flutter pub get` or `flutter gen-l10n` generates the typed `AppLocalizations` classes. They are gitignored.
- In widgets, use `context.l10n.<key>`. Sport, theme, period and shortcut names are localized in `lib/l10n/localized_values.dart`.
- To add a language, add an `app_<code>.arb` file and extend `AppLanguage` in the settings.

The selected language is saved in the settings and also applies to the display window.

## CI and releases
`.github/workflows/ci.yml` runs on every push and pull request:
- `test-core` (Ubuntu): analyzes and tests `scoreboard_core`.
- `test-windows` (Windows): analyzes and tests the Flutter app.
- `build-windows` (Windows): builds the app. On tags, it creates a release build and uploads a zip artifact.
- `build-linux` (Ubuntu): analyzes, tests and builds the app. On tags, it uploads a Linux x64 bundle as a tarball.
- `release` (Ubuntu, tags only): runs after all jobs succeed. It extracts the matching changelog section with `.github/scripts/release-notes.sh` and publishes a GitHub release containing the build artifact.

To release:
1. Set `version:` in `apps/scoreboard/pubspec.yaml` (e.g. `1.1.0+2`).
2. Add a `## 1.1.0 - <title>` section to `CHANGELOG.md`.
3. Push the tag `v1.1.0`.

The tag must match the pubspec version without the build number, and `CHANGELOG.md` must contain
exactly one matching section. That section becomes the release description. Tags with a
prerelease suffix (e.g. `v1.1.0-rc.1`) are published as prereleases.

## Built with AI-agentic coding
This tool was built with AI-agentic coding (GitHub Copilot CLI). The code was generated and iterated by AI agents under human direction. Review and test it before relying on it, especially for real matches.

## Dependencies
This table lists direct dependencies only. Transitive dependencies are pinned in the `pubspec.lock` files.

| Package | Used in | Purpose | License |
|---|---|---|---|
| [Flutter SDK](https://flutter.dev) | app | UI framework | BSD-3-Clause |
| [flutter_localizations](https://api.flutter.dev/flutter/flutter_localizations/) | app | Flutter localization support | BSD-3-Clause |
| [intl](https://pub.dev/packages/intl) | app | Message formatting and plurals | BSD-3-Clause |
| [material_ui](https://pub.dev/packages/material_ui) | app | Material widgets and localizations | BSD-3-Clause |
| [archive](https://pub.dev/packages/archive) | app | Zip export/import of settings and layouts | MIT |
| [flutter_svg](https://pub.dev/packages/flutter_svg) | app | Renders SVG team logos | MIT |
| [flutter_lints](https://pub.dev/packages/flutter_lints) | app (dev) | Lint rules | BSD-3-Clause |
| [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) | app (dev) | Generates the app icon from `assets/icon/app_icon.png` | MIT |
| [flutter_test](https://api.flutter.dev/flutter/flutter_test/) | app (dev) | Widget tests | BSD-3-Clause |
| [lints](https://pub.dev/packages/lints) | core (dev) | Lint rules | BSD-3-Clause |
| [test](https://pub.dev/packages/test) | core (dev) | Unit tests | BSD-3-Clause |

`scoreboard_core` has no runtime dependencies. The licenses listed are as published on pub.dev. Verify them with `flutter pub deps` or the in-app license page before a release.

## License
Copyright © Henrik Frühling.
Licensed under the [GNU Affero General Public License v3.0](LICENSE).
