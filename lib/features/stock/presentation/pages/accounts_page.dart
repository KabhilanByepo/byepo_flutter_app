import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_cubit.dart';

/// Static placeholder profile screen (no auth/account backend in this POC),
/// plus the app's one interactive setting: Light/Dark/System theme.
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = context.watch<ThemeCubit>().state;
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('B')),
              title: Text('Byepo Demo User'),
              subtitle: Text('datascience@byepo.in'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appearance', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Dark'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.settings_suggest),
                        label: Text('System'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) => context
                        .read<ThemeCubit>()
                        .setThemeMode(selection.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.workspace_premium_outlined),
                  title: Text('Plan'),
                  trailing: Text('Free'),
                ),
                Divider(height: 0),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('App version'),
                  trailing: Text('1.0.0'),
                ),
                Divider(height: 0),
                ListTile(
                  leading: Icon(Icons.cloud_outlined),
                  title: Text('Data provider'),
                  trailing: Text('Finnhub'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Byepo Stock Market',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
