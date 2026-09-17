import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../core/bridge/bridge_service.dart';
import '../../../../core/bridge/bridge_web_config.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../widgets/bridge_control_panel.dart';
import '../widgets/bridge_event_log_view.dart';

/// The bridge POC demo screen: an embedded WebView running the bundled
/// `web_poc` React app, plus native-side controls and a shared event log
/// below it.
///
/// The "Web hidden" toggle only simulates scenario 10 (web not currently
/// visible) *within this page* via `Offstage` — it deliberately does not
/// keep the WebView alive across actually leaving this route. `go_router`
/// disposes a popped route's subtree (including the platform WebView), and
/// hoisting the WebView above the router to survive navigation is a bigger
/// structural change this POC doesn't need. Re-opening this page reloads
/// the WebView, which re-fires `BRIDGE_READY` and re-flushes the persisted
/// queue automatically — so "events not silently lost" still holds
/// end-to-end, just not via a literally-never-destroyed native view.
class BridgePocPage extends StatefulWidget {
  const BridgePocPage({super.key});

  @override
  State<BridgePocPage> createState() => _BridgePocPageState();
}

class _BridgePocPageState extends State<BridgePocPage> {
  bool _webHidden = false;

  void _onWebViewCreated(InAppWebViewController controller) {
    di.sl<BridgeService>().attachController(controller);
  }

  @override
  void dispose() {
    di.sl<BridgeService>().detachController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bridge POC')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            // The InAppWebView child is never swapped out for another
            // widget — Offstage keeps it mounted (and thus keeps the
            // platform WebView / React JS state alive) while hidden.
            child: Offstage(
              offstage: _webHidden,
              child: InAppWebView(
                initialUrlRequest:
                    URLRequest(url: WebUri(BridgeWebConfig.indexUrl)),
                onWebViewCreated: _onWebViewCreated,
              ),
            ),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Web hidden (simulate backgrounded tab)'),
            value: _webHidden,
            onChanged: (value) => setState(() => _webHidden = value),
          ),
          const Divider(height: 1),
          const BridgeControlPanel(),
          const Divider(height: 1),
          const Expanded(flex: 2, child: BridgeEventLogView()),
        ],
      ),
    );
  }
}
