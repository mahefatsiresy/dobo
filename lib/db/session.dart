/// Who is writing, from which phone, for which site. Every synced row is
/// stamped from it. Until accounts exist (M4) the ids are local placeholders
/// created at first-launch setup.
class Session {
  const Session({
    required this.associationId,
    required this.userId,
    required this.deviceId,
    required this.siteId,
  });

  final String associationId;
  final String userId;
  final String deviceId;
  final String siteId;
}
