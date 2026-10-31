import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../locale_controller.dart';
import '../sync/backup_actions.dart';

/// First launch (plan Decision 4): sign in as a member or a worker, or
/// create the association. Readable in French and Malagasy.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    Widget big(Key key, IconData icon, String label, String to) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FilledButton.icon(
        key: key,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
        icon: Icon(icon, size: 32),
        label: Text(label),
        onPressed: () => context.push(to),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.welcomeTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'fr', label: Text('FR')),
                ButtonSegment(value: 'mg', label: Text('MG')),
              ],
              selected: {locale.languageCode},
              onSelectionChanged: (s) => ref
                  .read(localeControllerProvider.notifier)
                  .set(Locale(s.single)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          big(
            const Key('welcomeWorker'),
            Icons.agriculture,
            l10n.welcomeWorker,
            '/welcome/login?worker=1',
          ),
          big(
            const Key('welcomeMember'),
            Icons.person,
            l10n.welcomeMember,
            '/welcome/login',
          ),
          big(
            const Key('welcomeCreate'),
            Icons.add_home_work,
            l10n.welcomeCreate,
            '/welcome/create',
          ),
          // A phone that broke: its backup works here with no network.
          OutlinedButton.icon(
            key: const Key('welcomeImport'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.restore),
            label: Text(l10n.backupImport),
            onPressed: () => pickAndImport(context, ref),
          ),
        ],
      ),
    );
  }
}
