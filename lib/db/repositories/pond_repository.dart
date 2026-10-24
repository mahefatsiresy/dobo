import 'package:drift/drift.dart';

import '../../domain/types.dart';
import '../database.dart';
import '../ids.dart';
import '../session.dart';
import '../sync_state.dart';
import 'errors.dart';

/// The editable fields of a pond.
class PondInput {
  const PondInput({
    required this.code,
    required this.colour,
    this.structure = StructureType.earth,
    required this.role,
    this.waterSupply,
    this.lengthM,
    this.widthM,
    this.surfaceM2Override,
    this.depthInletM,
    this.depthOutletM,
  });

  final String code;
  final PondColour colour;
  final StructureType structure;
  final PondRole role;
  final WaterSupply? waterSupply;
  final double? lengthM;
  final double? widthM;
  final double? surfaceM2Override;
  final double? depthInletM;
  final double? depthOutletM;

  PondsCompanion _fields() => PondsCompanion(
    code: Value(code.trim()),
    colour: Value(colour),
    structure: Value(structure),
    role: Value(role),
    waterSupply: Value(waterSupply),
    lengthM: Value(lengthM),
    widthM: Value(widthM),
    surfaceM2Override: Value(surfaceM2Override),
    depthInletM: Value(depthInletM),
    depthOutletM: Value(depthOutletM),
  );
}

/// First palette colour no active pond uses, so new ponds look different.
PondColour nextFreeColour(List<Pond> ponds) {
  final used = {for (final p in ponds) p.colour};
  return PondColour.values.firstWhere(
    (c) => !used.contains(c),
    orElse: () => PondColour.blue,
  );
}

class PondRepository {
  PondRepository(this.db, this.session);

  final AppDatabase db;
  final Session session;

  SimpleSelectStatement<$PondsTable, Pond> _active() =>
      db.select(db.ponds)
        ..where((p) => p.siteId.equals(session.siteId) & p.archived.not());

  /// The site's ponds that aren't archived, by code.
  Stream<List<Pond>> watchActive() =>
      (_active()..orderBy([(p) => OrderingTerm.asc(p.code.lower())])).watch();

  /// The site's ponds, archived ones included.
  Stream<List<Pond>> watchAll() => (db.select(
    db.ponds,
  )..where((p) => p.siteId.equals(session.siteId))).watch();

  Future<Pond> get(String id) =>
      (db.select(db.ponds)..where((p) => p.id.equals(id))).getSingle();

  Future<String> create(PondInput input) => db.transaction(() async {
    await _checkCode(input.code);
    final id = newId();
    await db
        .into(db.ponds)
        .insert(
          input._fields().copyWith(
            id: Value(id),
            associationId: Value(session.associationId),
            enteredBy: Value(session.userId),
            deviceId: Value(session.deviceId),
            siteId: Value(session.siteId),
          ),
        );
    return id;
  });

  Future<void> update(String id, PondInput input) => db.transaction(() async {
    await _checkCode(input.code, exceptId: id);
    await _write(id, input._fields());
  });

  Future<void> setStatus(String id, PondStatus status) =>
      _write(id, PondsCompanion(status: Value(status)));

  Future<void> archive(String id) =>
      _write(id, const PondsCompanion(archived: Value(true)));

  Future<void> _write(String id, PondsCompanion fields) =>
      (db.update(db.ponds)..where((p) => p.id.equals(id))).write(
        fields.copyWith(
          updatedAtDevice: Value(utcNow()),
          syncState: const Value(SyncState.pending),
        ),
      );

  Future<void> _checkCode(String code, {String? exceptId}) async {
    final wanted = normaliseCode(code);
    final clash = (await _active().get()).any(
      (p) => p.id != exceptId && normaliseCode(p.code) == wanted,
    );
    if (clash) throw DuplicateCodeException(code.trim());
  }
}
