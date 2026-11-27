# Scoreboard features

## Implemented

### Platform
- Flutter/Dart desktop app for Windows, with a pure-Dart core package (`scoreboard_core`).
- Runs fully offline. The display window is fed over a local loopback WebSocket.
- Only Windows is supported. Other platforms can be re-added with `flutter create`.

### Sports and match engine
- Handball, football, basketball, volleyball, ice hockey, tennis and table tennis.
- Clock that counts up or down and can be edited. Periods or sets.
- Scores, games and sets. Tennis points are shown as 15/30/40/AD.
- Timeouts per team, which can be aborted with a refund.
- 2-minute suspensions.
- Undo and redo for all match actions.
- Configurable match rules per sport: periods or sets, minutes per period, timeouts per team, timeout length and clock direction.

### Operator
- Adaptive layout: side by side on wide windows, stacked on tall ones.
- Optional live preview of the scoreboard.
- Rebindable keyboard shortcuts. A conflicting binding is swapped automatically. Shortcuts are ignored while typing.
- Optional team logos (png, jpg, gif, webp, bmp, svg), chosen with a file dialog or drag and drop.

### Display
- Separate window with a monitor picker.
- Borderless fullscreen, scaled to the monitor.
- F11 or a double-click toggles fullscreen, and Esc leaves it.
- Reconnects automatically and closes together with the operator window.

### Design
- Drag and drop layout editor with:
  - Text, rectangle and image elements.
  - Placeholders and visibility conditions.
  - Optional grid, snap to grid (5–100 px) and alignment guides for edges and centers.
- Default layout per sport. Layouts are saved per sport.
- 12 themes (6 dark, 6 light) with their own colors, corner style and UI style, independent of the sport.

### Settings and data
- One settings page per topic: team names, match rules (including the sport), theme, language and shortcuts.
- Settings and layouts are saved locally. Everything can be exported and imported as a zip.
- About dialog with version, author, license (GNU AGPLv3) and third-party licenses.

### Localization
- English and German, using Flutter `gen-l10n` (ARB files, typed messages, ICU plurals).
- The language can be switched at runtime and is saved. It also applies to the window title, the display window and model labels (sports, themes, periods, shortcuts).

### Development and releases
- Unit tests for the core and widget tests for the app.
- GitHub Actions with separate jobs for core tests, Windows tests and the Windows build.
- Tag-based releases: when a version tag is pushed, the Windows x64 zip is published as a GitHub release. The release description is taken from the matching `CHANGELOG.md` section.

## Possible future features
- **Mobile:** Android and iOS operator UI, with the phone driving an external display (Presentation API, AirPlay or HDMI).
- **Remote control:** control from a phone or tablet over the local network, and a browser or TV display over LAN.
- **Team library:** a persistent list of teams (name, short name, logo, colors, sport) to pick home and away teams from, with import and export.
- **Match data:** match history, crash recovery of a running match, rosters with goal scorers and player cards.
- **Rules and sports:** more sport rules (7m throws, cards, fouls, shot clock, penalty shootout), a sponsor carousel, and a goal flash or horn sound.
- **Editor:** groups, custom fonts, gradients and animations, and layout import and export.
- **Releases:** a Windows installer, other platforms, and handling monitors being plugged in or out.
- **Quality:** golden tests for identical rendering, a long-run clock drift test, and translated default layout text.
- **Other:** more languages, results export (CSV/PDF), and an operator light/dark toggle independent of the scoreboard theme.
