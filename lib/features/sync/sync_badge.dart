import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sync/providers.dart';

/// [child] with the count of records not yet sent; red when the server
/// refused any (SPEC §7: sync status is always visible).
class SyncBadge extends ConsumerWidget {
  const SyncBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(syncCountsProvider).value;
    final pending = counts?.pending ?? 0;
    final rejected = counts?.rejected ?? 0;
    final scheme = Theme.of(context).colorScheme;
    return Badge(
      key: const Key('syncBadge'),
      isLabelVisible: pending > 0 || rejected > 0,
      backgroundColor: rejected > 0 ? scheme.error : scheme.secondary,
      label: Text('${pending + rejected}'),
      child: child,
    );
  }
}
