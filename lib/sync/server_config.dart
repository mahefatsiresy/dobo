/// Where the server is, from `--dart-define-from-file=env/<name>.json`.
/// Without it the app runs fully offline and never syncs.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool get serverConfigured =>
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
