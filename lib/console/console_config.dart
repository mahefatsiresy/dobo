/// The web console's own settings (SPEC F16). Not farming numbers: those
/// live in `lib/domain/config.dart`.
library;

/// Without a pointer or key event for this long, the console signs out.
const consoleIdleLimit = Duration(minutes: 30);

/// The widest the console's content grows on a large screen.
const consoleMaxWidth = 1100.0;
