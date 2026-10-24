import 'package:flutter/widgets.dart';

/// One save at a time: on a slow phone a double tap on Save must not write
/// twice (a second correction of the same record would fork it).
mixin SaveOnce<T extends StatefulWidget> on State<T> {
  bool saving = false;

  Future<void> saveOnce(Future<void> Function() save) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await save();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
