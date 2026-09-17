import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/bridge_cubit.dart';

/// Buttons for every App→Web demo scenario (1, 3, 5, 6, 7, 8, 12) — the
/// Web→App side (2, 4) is driven from the React app's own mirrored controls.
class BridgeControlPanel extends StatelessWidget {
  const BridgeControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BridgeCubit>();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ElevatedButton(
            onPressed: cubit.sendOrderUpdateDemo,
            child: const Text('Send ORDER_UPDATE'),
          ),
          OutlinedButton(
            onPressed: cubit.sendRapidFire,
            child: const Text('Rapid Fire (5)'),
          ),
          OutlinedButton(
            onPressed: cubit.resendLastEvent,
            child: const Text('Resend Last (duplicate)'),
          ),
          OutlinedButton(
            onPressed: cubit.sendDelayed,
            child: const Text('Send Delayed (5s)'),
          ),
          OutlinedButton(
            onPressed: cubit.sendMalformedRaw,
            child: const Text('Send Malformed'),
          ),
          OutlinedButton(
            onPressed: cubit.sendLargePayload,
            child: const Text('Send Large Payload'),
          ),
          FilledButton.tonal(
            onPressed: cubit.simulateOffline,
            child: const Text('Simulate Offline'),
          ),
          FilledButton.tonal(
            onPressed: cubit.simulateOnline,
            child: const Text('Simulate Online'),
          ),
          TextButton(
            onPressed: cubit.clearLog,
            child: const Text('Clear Log'),
          ),
        ],
      ),
    );
  }
}
