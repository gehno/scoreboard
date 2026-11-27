import 'package:scoreboard_core/scoreboard_core.dart';

import '../settings/shortcuts.dart';
import 'app_localizations.dart';

String localizedSportName(AppLocalizations l10n, SportDefinition sport) =>
    switch ((sport.id, sport.name)) {
      ('handball', 'Handball') => l10n.sportHandball,
      ('basketball', 'Basketball') => l10n.sportBasketball,
      ('football', 'Football') => l10n.sportFootball,
      ('volleyball', 'Volleyball') => l10n.sportVolleyball,
      ('tabletennis', 'Table tennis') => l10n.sportTableTennis,
      ('tennis', 'Tennis') => l10n.sportTennis,
      ('icehockey', 'Ice hockey') => l10n.sportIceHockey,
      _ => sport.name,
    };

String localizedThemeName(AppLocalizations l10n, ScoreboardTheme theme) =>
    switch ((theme.id, theme.name)) {
      ('classic', 'Classic') => l10n.themeClassic,
      ('midnight', 'Midnight') => l10n.themeMidnight,
      ('daylight', 'Daylight') => l10n.themeDaylight,
      ('neon', 'Neon') => l10n.themeNeon,
      ('terminal', 'Terminal') => l10n.themeTerminal,
      ('highcontrast', 'High contrast') => l10n.themeHighContrast,
      ('forest', 'Forest') => l10n.themeForest,
      ('sunrise', 'Sunrise') => l10n.themeSunrise,
      ('mint', 'Mint') => l10n.themeMint,
      ('sky', 'Sky') => l10n.themeSky,
      ('paper', 'Paper') => l10n.themePaper,
      ('highcontrastlight', 'High contrast light') =>
        l10n.themeHighContrastLight,
      _ => theme.name,
    };

String localizedPeriodLabel(
  AppLocalizations l10n,
  SportDefinition sport,
  int period,
) {
  final label = sport.periodLabel(period);
  return switch ((sport.id, label)) {
    ('handball' || 'football', '1st half') => l10n.periodFirstHalf,
    ('handball' || 'football', '2nd half') => l10n.periodSecondHalf,
    ('icehockey', '1st period') => l10n.periodFirstPeriod,
    ('icehockey', '2nd period') => l10n.periodSecondPeriod,
    ('icehockey', '3rd period') => l10n.periodThirdPeriod,
    ('volleyball' || 'tennis', _) when _matchesNumbered(label, 'Set') =>
      l10n.setNumber(_numberInLabel(label, 'Set')),
    ('tabletennis', _) when _matchesNumbered(label, 'Game') => l10n.gameNumber(
      _numberInLabel(label, 'Game'),
    ),
    ('handball' || 'football' || 'basketball' || 'icehockey', _)
        when _matchesNumbered(label, 'Period') =>
      l10n.periodNumber(_numberInLabel(label, 'Period')),
    _ => label,
  };
}

bool _matchesNumbered(String label, String noun) =>
    RegExp('^$noun ([0-9]+)\$').hasMatch(label);

int _numberInLabel(String label, String noun) =>
    int.parse(RegExp('^$noun ([0-9]+)\$').firstMatch(label)!.group(1)!);

String localizedShortcutAction(AppLocalizations l10n, ShortcutAction action) =>
    switch (action) {
      ShortcutAction.toggleClock => l10n.shortcutToggleClock,
      ShortcutAction.homePlus => l10n.shortcutHomePlus,
      ShortcutAction.homeMinus => l10n.shortcutHomeMinus,
      ShortcutAction.awayPlus => l10n.shortcutAwayPlus,
      ShortcutAction.awayMinus => l10n.shortcutAwayMinus,
      ShortcutAction.homeTimeout => l10n.shortcutHomeTimeout,
      ShortcutAction.awayTimeout => l10n.shortcutAwayTimeout,
      ShortcutAction.homeSuspension => l10n.shortcutHomeSuspension,
      ShortcutAction.awaySuspension => l10n.shortcutAwaySuspension,
      ShortcutAction.nextPeriod => l10n.shortcutNextPeriod,
      ShortcutAction.cancelTimeout => l10n.shortcutCancelTimeout,
      ShortcutAction.undo => l10n.undo,
      ShortcutAction.redo => l10n.redo,
    };
