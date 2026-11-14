import '../../l10n/app_localizations.dart';
import '../../db/repositories/errors.dart';
import '../../sync/auth_gateway.dart';
import '../../sync/sync_api.dart';

/// What to tell someone whose sign-in or account action failed.
String accountErrorText(AppLocalizations l10n, Object error) => switch (error) {
  SyncOffline() => l10n.errorOffline,
  SyncSignedOut() => l10n.errorOffline,
  AuthFailed(code: 'invalid_credentials') => l10n.errorBadLogin,
  AuthFailed(code: 'other_association') => l10n.errorOtherAssociation,
  AuthFailed(code: 'no_member') => l10n.errorNoMember,
  AuthFailed(code: 'no_site') => l10n.errorNoSite,
  AuthFailed(code: 'not_admin') => l10n.errorNotAdmin,
  UnsentRecords(:final count) => l10n.takeoverUnsent(count),
  AuthFailed(code: 'login_taken' || 'user_already_exists') => l10n.errorTaken,
  AuthFailed(:final code) => l10n.errorFailed(code),
  _ => l10n.errorFailed('$error'),
};
