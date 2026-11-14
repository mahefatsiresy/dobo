import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'console_config.dart';

/// Calls [onIdle] once after [limit] with no pointer or key event (SPEC
/// F16: an unattended browser doesn't keep an admin's rights).
class IdleGuard extends StatefulWidget {
  const IdleGuard({
    super.key,
    required this.child,
    required this.onIdle,
    this.limit = consoleIdleLimit,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onIdle;
  final Duration limit;

  /// Off while nobody is signed in.
  final bool enabled;

  @override
  State<IdleGuard> createState() => _IdleGuardState();
}

class _IdleGuardState extends State<IdleGuard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(IdleGuard old) {
    super.didUpdateWidget(old);
    if (old.enabled != widget.enabled) _restart();
  }

  void _restart() {
    _timer?.cancel();
    _timer = widget.enabled ? Timer(widget.limit, widget.onIdle) : null;
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _restart(),
    onPointerMove: (_) => _restart(),
    onPointerHover: (_) => _restart(),
    onPointerSignal: (_) => _restart(),
    child: widget.child,
  );
}
