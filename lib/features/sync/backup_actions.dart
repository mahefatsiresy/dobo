import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../db/backup.dart';
import '../../db/database_provider.dart';
import '../../l10n/app_localizations.dart';

typedef BackupSharer = Future<void> Function(File file);
typedef BackupPicker = Future<File?> Function();

/// Hands a backup file to any installed app (Bluetooth, WhatsApp, a cable).
final backupSharerProvider = Provider<BackupSharer>(
  (ref) => (file) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  },
);

/// Lets someone choose a backup file on the phone.
final backupPickerProvider = Provider<BackupPicker>(
  (ref) => () async {
    final picked = await FilePicker.pickFiles();
    final path = picked.isEmpty ? null : picked.single.path;
    return path == null ? null : File(path);
  },
);

/// Where an export is written before it is shared.
final backupDirProvider = Provider<Future<Directory> Function()>(
  (ref) => getTemporaryDirectory,
);

/// Exports the phone's database and opens the share sheet.
Future<void> exportAndShare(WidgetRef ref) async {
  final dir = await ref.read(backupDirProvider)();
  final file = await exportBackup(ref.read(databaseProvider), dir);
  await ref.read(backupSharerProvider)(file);
}

/// Picks a backup and imports it; tells the outcome in a snack bar.
Future<void> pickAndImport(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final file = await ref.read(backupPickerProvider)();
  if (file == null) return;
  String message;
  try {
    final r = await importBackup(ref.read(databaseProvider), file);
    message = l10n.backupImported(r.added, r.updated);
  } on BackupRefused catch (e) {
    message = e.code == 'other_association'
        ? l10n.backupOtherAssociation
        : l10n.backupNotABackup;
  }
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
