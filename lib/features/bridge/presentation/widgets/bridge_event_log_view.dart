import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bridge/bridge_log_entry.dart';
import '../cubit/bridge_cubit.dart';
import '../cubit/bridge_state.dart';

/// Renders `BridgeState.log` — direction, event type, delivery status, and
/// round-trip latency once acked. Status colors come from the theme's
/// `colorScheme` (matching `ConnectivityBanner`'s existing convention), not
/// hardcoded colors.
class BridgeEventLogView extends StatelessWidget {
  const BridgeEventLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BridgeCubit, BridgeState>(
      builder: (context, state) {
        if (state.log.isEmpty) {
          return const Center(child: Text('No events yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: state.log.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) => _LogRow(entry: state.log[index]),
        );
      },
    );
  }
}

class _LogRow extends StatelessWidget {
  final BridgeLogEntry entry;

  const _LogRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAppToWeb = entry.direction == BridgeDirection.appToWeb;
    final latency = entry.latencyMs;

    return ListTile(
      dense: true,
      leading: Icon(
        isAppToWeb ? Icons.north_east : Icons.south_west,
        color: colorScheme.primary,
      ),
      title: Text(entry.event?.eventType ?? '(unparseable payload)'),
      subtitle: Text(
        entry.errorMessage ?? entry.event?.payload.toString() ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _statusLabel(entry.status),
            style: TextStyle(
              color: _statusColor(entry.status, colorScheme),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (latency != null)
            Text('${latency}ms', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  String _statusLabel(BridgeDeliveryStatus status) => switch (status) {
        BridgeDeliveryStatus.queued => 'QUEUED',
        BridgeDeliveryStatus.sending => 'SENDING',
        BridgeDeliveryStatus.sent => 'SENT',
        BridgeDeliveryStatus.awaitingAck => 'AWAITING ACK',
        BridgeDeliveryStatus.acked => 'ACKED',
        BridgeDeliveryStatus.retrying => 'RETRYING',
        BridgeDeliveryStatus.failed => 'FAILED',
        BridgeDeliveryStatus.received => 'RECEIVED',
        BridgeDeliveryStatus.duplicate => 'DUPLICATE',
        BridgeDeliveryStatus.malformed => 'MALFORMED',
      };

  Color _statusColor(BridgeDeliveryStatus status, ColorScheme colorScheme) {
    switch (status) {
      case BridgeDeliveryStatus.failed:
      case BridgeDeliveryStatus.malformed:
        return colorScheme.error;
      case BridgeDeliveryStatus.duplicate:
      case BridgeDeliveryStatus.retrying:
        return colorScheme.tertiary;
      case BridgeDeliveryStatus.acked:
      case BridgeDeliveryStatus.sent:
      case BridgeDeliveryStatus.received:
        return colorScheme.primary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}
