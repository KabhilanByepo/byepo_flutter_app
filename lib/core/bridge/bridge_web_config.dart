/// Static configuration for the bundled `web_poc` React app and the local
/// server that serves it.
///
/// The React app is built (`cd web_poc && npm run build`) straight into
/// `assets/web_poc/` — see that project's `vite.config.ts` — and declared
/// as a Flutter asset in `pubspec.yaml`. `InAppLocalhostServer` then serves
/// that asset directory over plain HTTP so the React app's root-relative
/// paths resolve correctly (a `file://` load would break them).
class BridgeWebConfig {
  const BridgeWebConfig._();

  static const int port = 8080;
  static const String documentRoot = 'assets/web_poc';
  static const String indexUrl = 'http://localhost:$port/index.html';
}
