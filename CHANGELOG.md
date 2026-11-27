# Changelog

All notable changes to this project are documented here.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
The release version is maintained only in `apps/scoreboard/pubspec.yaml`.
Each release tag `vX.Y.Z` must have exactly one matching `## X.Y.Z` section, which
is used as the GitHub release description.

## 1.0.0 - First release

### Added
- Offline scoreboard for Windows with a separate operator window and display window. The display window has a monitor picker, borderless fullscreen and auto-reconnect, and it closes together with the operator window.
- Sports: handball, football, basketball, volleyball, ice hockey, tennis and table tennis.
- Match engine: clock (up or down), periods or sets, scores, tennis points, timeouts (which can be aborted), 2-minute suspensions, undo and redo.
- Match rules per sport: periods or sets, minutes per period, timeouts per team, timeout length and clock direction.
- Operator screen with an adaptive layout and an optional live preview.
- Optional team logos (png, jpg, gif, webp, bmp, svg), chosen with a file dialog or drag and drop.
- Drag and drop layout editor with text, rectangle and image elements, placeholders and visibility conditions. It also has an optional grid, snap to grid and alignment guides.
- 12 themes (6 dark, 6 light), independent of the sport.
- Settings pages for team names, match rules, theme, language and rebindable keyboard shortcuts.
- Export and import of all persisted data (settings and layouts) as a zip file.
- English and German localization based on Flutter `gen-l10n` (ARB files). Language switching applies at runtime, including the window title and display labels.
- App icon and an About dialog with version, author and licenses.
- GitHub Actions CI with separate jobs for core tests, Windows tests and the Windows build.
- Tag-based GitHub releases that publish the Windows x64 zip, with the matching changelog section as the release description.

### Licensing
- Licensed under the GNU Affero General Public License v3.0.
