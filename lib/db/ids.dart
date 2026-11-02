import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Time-ordered UUIDv7, generated on the device so records can be created
/// offline without colliding across phones.
String newId() => _uuid.v7();

/// Default for device-side timestamps. Public because Drift's generated code
/// copies this reference into `database.g.dart`.
DateTime utcNow() => DateTime.now().toUtc();

/// The one id of a site's override of [key], the same on every phone, so
/// two admins editing it offline edit one row (last write wins).
String settingOverrideId(String siteId, String key) =>
    _uuid.v5(Namespace.url.value, 'dobo:setting/$siteId/$key');

/// The `Person` of the account [memberId], the same on every phone, so two
/// admin phones creating it offline create one row (last write wins).
String accountPersonId(String memberId) =>
    _uuid.v5(Namespace.url.value, 'dobo:account-person/$memberId');
