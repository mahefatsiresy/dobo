import '../features/account/account_errors.dart';
import '../l10n/app_localizations.dart';
import '../sync/auth_gateway.dart';
import 'data/console_api.dart';

/// What the console tells an admin whose action failed: the phone's
/// account messages, plus the console's own.
String consoleErrorText(AppLocalizations l10n, Object error) => switch (error) {
  AuthFailed(code: 'admins_only') => l10n.consoleAdminsOnly,
  ConsoleWriteFailed(code: 'last_admin') => l10n.rejectLastAdmin,
  ConsoleWriteFailed(:final code) => l10n.consoleRefused(code),
  _ => accountErrorText(l10n, error),
};
