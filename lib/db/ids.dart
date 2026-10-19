import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Time-ordered UUIDv7, generated on the device so records can be created
/// offline without colliding across phones.
String newId() => _uuid.v7();

/// Default for device-side timestamps. Public because Drift's generated code
/// copies this reference into `database.g.dart`.
DateTime utcNow() => DateTime.now().toUtc();
