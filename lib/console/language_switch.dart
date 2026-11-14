import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../locale_controller.dart';
import '../l10n/app_localizations.dart';
import 'console_errors.dart';
import 'console_providers.dart';

/// The admin's language (SPEC §9, F16): switches the console now and is
/// saved on their own member row, so it follows them to the phone.
class ConsoleLanguageSwitch extends ConsumerWidget {
  const ConsoleLanguageSwitch({super.key});

  Future<void> _set(BuildContext context, WidgetRef ref, String locale) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    ref.read(localeControllerProvider.notifier).set(Locale(locale));
    try {
      final me = ref.read(consoleSessionProvider).value;
      if (me == null) return;
      final api = ref.read(consoleApiProvider);
      final own = (await api.members()).singleWhere((m) => m.id == me.memberId);
      await api.saveMember(own.copyWith(locale: locale));
      ref.invalidate(membersProvider);
      await ref.read(consoleSessionProvider.notifier).reload();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(consoleErrorText(l10n, e))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider).languageCode;
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: 'fr',
          label: Text('FR', key: Key('consoleLanguage-fr')),
        ),
        ButtonSegment(
          value: 'mg',
          label: Text('MG', key: Key('consoleLanguage-mg')),
        ),
      ],
      selected: {locale},
      onSelectionChanged: (s) => _set(context, ref, s.single),
    );
  }
}
