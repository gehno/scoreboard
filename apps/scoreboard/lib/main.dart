import 'platform/startup_web.dart'
    if (dart.library.io) 'platform/startup_desktop.dart' as startup;

Future<void> main(List<String> args) => startup.start(args);
