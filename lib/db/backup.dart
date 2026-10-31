import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:intl/intl.dart';

import '../domain/dates.dart';
import '../sync/sync_tables.dart';
import 'database.dart';
import 'ids.dart';

/// Why a backup wasn't imported: `not_a_backup` or `other_association`.
class BackupRefused implements Exception {
  const BackupRefused(this.code);

  final String code;

  @override
  String toString() => 'BackupRefused($code)';
}

class ImportResult {
  const ImportResult({required this.added, required this.updated});

  final int added;
  final int updated;
}

/// The session keys a phone with no session takes from a backup. Never the
/// device id, the sync cursors or the last sync time: those describe the
/// phone, not the farm.
const _sessionKeys = [
  'association_id',
  'user_id',
  'site_id',
  'role',
  'is_admin',
  'is_sales',
  'linked',
];

/// Writes this phone's whole database to `dobo-<dd-mm-yyyy>.sqlite` in
/// [dir], to share by any means (SPEC §7 Backup). Works offline.
Future<File> exportBackup(AppDatabase db, Directory dir) async {
  final day = DateFormat('dd-MM-yyyy').format(farmDate(utcNow()));
  final file = File('${dir.path}/dobo-$day.sqlite');
  if (file.existsSync()) file.deleteSync();
  await db.customStatement('VACUUM INTO ?', [file.path]);
  return file;
}

/// Merges [backup] into this phone (plan Decision 15). Events are added
/// once; a reference row is taken when it is new here or edited later than
/// this phone's copy. Rows keep their sync state, device and author. A
/// phone with no session takes the backup's. Refuses before writing
/// anything when the file isn't a Dobo backup or belongs to another
/// association.
Future<ImportResult> importBackup(AppDatabase db, File backup) async {
  // Work on a copy: opening it migrates an older version in place.
  final copy = File('${backup.path}.import-${newId()}');
  await backup.copy(copy.path);
  try {
    final theirs = await _readMeta(copy);
    final ours = {
      for (final r in await db.select(db.localMeta).get()) r.key: r.value,
    };
    final association = ours['association_id'];
    if (association != null && association != theirs['association_id']) {
      throw const BackupRefused('other_association');
    }

    await db.customStatement('ATTACH DATABASE ? AS backup', [copy.path]);
    try {
      final result = await db.transaction(() => _merge(db, theirs, ours));
      db.notifyUpdates({
        for (final t in syncTables(db)) TableUpdate.onTable(t.info),
        TableUpdate.onTable(db.localMeta),
      });
      return result;
    } finally {
      await db.customStatement('DETACH DATABASE backup');
    }
  } finally {
    if (copy.existsSync()) copy.deleteSync();
  }
}

/// The backup's `local_meta`, after migrating it to this version.
Future<Map<String, String>> _readMeta(File file) async {
  final backup = AppDatabase(NativeDatabase(file));
  try {
    final meta = {
      for (final r in await backup.select(backup.localMeta).get())
        r.key: r.value,
    };
    if (meta['association_id'] == null) {
      throw const BackupRefused('not_a_backup');
    }
    return meta;
  } on BackupRefused {
    rethrow;
  } catch (_) {
    throw const BackupRefused('not_a_backup');
  } finally {
    await backup.close();
  }
}

Future<ImportResult> _merge(
  AppDatabase db,
  Map<String, String> theirs,
  Map<String, String> ours,
) async {
  var added = 0, updated = 0;
  for (final t in syncTables(db)) {
    final cols = t.info.$columns.map((c) => '"${c.$name}"').join(', ');
    if (t.kind == RowKind.reference) {
      // Dates are compared as instants: their text may differ in length.
      updated += await db.customUpdate(
        'UPDATE main."${t.name}" SET ($cols) = '
        '(SELECT $cols FROM backup."${t.name}" b WHERE b.id = '
        'main."${t.name}".id) '
        'WHERE id IN (SELECT b.id FROM backup."${t.name}" b '
        'JOIN main."${t.name}" m ON m.id = b.id '
        'WHERE julianday(b.updated_at_device) > '
        'julianday(m.updated_at_device))',
      );
    }
    added += await db.customUpdate(
      'INSERT OR IGNORE INTO main."${t.name}" ($cols) '
      'SELECT $cols FROM backup."${t.name}"',
    );
  }
  if (ours['user_id'] == null) {
    for (final key in _sessionKeys) {
      final value = theirs[key];
      if (value == null) continue;
      await db
          .into(db.localMeta)
          .insert(
            LocalMetaCompanion.insert(key: key, value: value),
            mode: InsertMode.insertOrReplace,
          );
    }
  }
  return ImportResult(added: added, updated: updated);
}
