import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/byepo_logo.dart';

/// Shows the Byepo mark briefly, then replaces itself with the Dashboard.
/// Uses `context.go` (not `push`) so Android back from the Dashboard exits the
/// app rather than returning here.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const Duration _hold = Duration(seconds: 2);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_hold, () {
      if (mounted) context.go('/dashboard');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: ByepoLogo(size: 120)),
    );
  }
}
