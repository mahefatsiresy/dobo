/// [text] made safe for a file name on any file system: ASCII letters and
/// digits, runs of anything else as one `-`; [fallback] when nothing is left.
String fileSlug(String text, String fallback) {
  final safe = text
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return safe.isEmpty ? fallback : safe;
}
