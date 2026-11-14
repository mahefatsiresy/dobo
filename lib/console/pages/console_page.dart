import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../console_errors.dart';

/// A console page: its title, its main button, and the content below.
class ConsolePage extends StatelessWidget {
  const ConsolePage({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(32),
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
          ?action,
        ],
      ),
      const SizedBox(height: 24),
      child,
    ],
  );
}

/// [rows] once loaded: a spinner meanwhile, the reason when it failed.
class AsyncRows<T> extends StatelessWidget {
  const AsyncRows({super.key, required this.value, required this.builder});

  final AsyncValue<List<T>> value;
  final Widget Function(List<T> rows) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (value) {
      AsyncData(:final value) when value.isEmpty => Text(l10n.consoleNothingYet),
      AsyncData(:final value) => builder(value),
      AsyncError(:final error) => Text(
        consoleErrorText(l10n, error),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

/// A table filling the page's width.
class ConsoleTable extends StatelessWidget {
  const ConsoleTable({super.key, required this.columns, required this.rows});

  final List<String> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: DataTable(
      columns: [for (final c in columns) DataColumn(label: Text(c))],
      rows: rows,
    ),
  );
}
