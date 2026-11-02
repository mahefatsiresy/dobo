import 'package:dobo/db/database.dart';
import 'package:dobo/db/sync_state.dart';
import 'package:dobo/domain/types.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a visit report row round-trips its period and content', () async {
    await db
        .into(db.visitReports)
        .insert(
          VisitReportsCompanion.insert(
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'd1',
            recordedAt: DateTime.utc(2026, 3, 20, 9),
            visitId: 'v1',
            siteId: 's1',
            periodFrom: DateTime.utc(2026, 3, 12, 21),
            periodTo: DateTime.utc(2026, 3, 19, 21),
            content: '{"format":1}',
          ),
        );
    final r = await db.select(db.visitReports).getSingle();
    expect(
      (r.visitId, r.content, r.isTombstone, r.syncState),
      ('v1', '{"format":1}', false, SyncState.pending),
    );
    expect(r.periodTo, DateTime.utc(2026, 3, 19, 21));
  });

  test('a photo row defaults to not uploading', () async {
    await db
        .into(db.photos)
        .insert(
          PhotosCompanion.insert(
            associationId: 'a1',
            enteredBy: 'm1',
            deviceId: 'd1',
            recordedAt: DateTime.utc(2026, 3, 20, 9),
            ownerKind: PhotoOwner.observation,
            ownerId: 'o1',
            photoKey: 'k1',
            bytes: 120000,
          ),
        );
    final p = await db.select(db.photos).getSingle();
    expect(
      (p.ownerKind, p.ownerId, p.photoKey, p.upload, p.bytes),
      (PhotoOwner.observation, 'o1', 'k1', false, 120000),
    );
  });

  test('read marks and the upload queue are device-only rows', () async {
    await db
        .into(db.reportReads)
        .insert(
          ReportReadsCompanion.insert(
            reportId: 'r1',
            readAt: DateTime.utc(2026, 3, 20),
          ),
        );
    await db
        .into(db.photoUploads)
        .insert(PhotoUploadsCompanion.insert(photoKey: 'k1'));
    final u = await db.select(db.photoUploads).getSingle();
    expect((u.photoKey, u.uploadedAt, u.error), ('k1', null, null));
    expect((await db.select(db.reportReads).getSingle()).reportId, 'r1');
  });
}
