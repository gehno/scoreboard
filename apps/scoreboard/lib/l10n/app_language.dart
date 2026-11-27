enum AppLanguage {
  en('English'),
  de('Deutsch');

  const AppLanguage(this.displayName);

  final String displayName;

  static AppLanguage fromName(String? name) =>
      values.firstWhere((l) => l.name == name, orElse: () => en);
}
