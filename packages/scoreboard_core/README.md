# scoreboard_core

Pure-Dart engine of the scoreboard app. No Flutter and no `dart:io`, so any UI or platform can reuse it.

- **Sports and rules:** `SportDefinition`, `SportRegistry`
- **Match state:** `MatchState` and `MatchController` (undo/redo, clock, suspensions, timeouts)
- **Layouts:** `ScoreboardLayout`, `ScoreboardTheme`, default layouts per sport, binding resolution
- **Display protocol:** `DisplayMessage` (what the operator sends to a display)

Time is advanced explicitly with `MatchController.tick`, which keeps the engine deterministic and testable.

```
dart test
```
