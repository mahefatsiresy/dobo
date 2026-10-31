import '../domain/types.dart';

/// Who is writing, from which phone, for which site. Every synced row is
/// stamped from it. A phone set up before accounts existed (M2/M3) keeps the
/// local ids it created; they become the server's ids when the association
/// is created from that phone.
class Session {
  const Session({
    required this.associationId,
    required this.userId,
    required this.deviceId,
    required this.siteId,
    this.role = MemberRole.member,
    this.isAdmin = false,
    this.isSales = false,
    this.isLinked = false,
  });

  final String associationId;

  /// The member's id, stamped as `entered_by`.
  final String userId;
  final String deviceId;
  final String siteId;
  final MemberRole role;
  final bool isAdmin;
  final bool isSales;

  /// The session belongs to a server account. A phone set up before
  /// accounts (or with no server) isn't, and doesn't sync until it is.
  final bool isLinked;

  bool get isWorker => role == MemberRole.worker;

  @override
  bool operator ==(Object other) =>
      other is Session &&
      other.associationId == associationId &&
      other.userId == userId &&
      other.deviceId == deviceId &&
      other.siteId == siteId &&
      other.role == role &&
      other.isAdmin == isAdmin &&
      other.isSales == isSales &&
      other.isLinked == isLinked;

  @override
  int get hashCode => Object.hash(
    associationId,
    userId,
    deviceId,
    siteId,
    role,
    isAdmin,
    isSales,
    isLinked,
  );
}
