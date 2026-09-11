import 'package:byepo_stock_market/core/lifecycle/app_lifecycle_cubit.dart';
import 'package:byepo_stock_market/core/lifecycle/app_lifecycle_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'relays AppLifecycleService state changes into Cubit states',
    (tester) async {
      final service = AppLifecycleService();
      final cubit = AppLifecycleCubit(service: service);

      expect(cubit.state, AppLifecycleState.resumed);

      // The real platform-driven state machine only allows this exact path
      // (resumed -> inactive -> hidden -> paused, and back), enforced by an
      // assertion in AppLifecycleListener itself.
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
        expect(cubit.state, state);
      }

      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        await tester.pump();
        expect(cubit.state, state);
      }

      await cubit.close();
      service.dispose();
    },
  );

  testWidgets('close cancels the subscription — no emits after close', (
    tester,
  ) async {
    final service = AppLifecycleService();
    final cubit = AppLifecycleCubit(service: service);
    await cubit.close();

    // No exception/late-emit should occur once the listener fires after
    // close(); the subscription was cancelled, so this is a no-op.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    service.dispose();
  });
}
