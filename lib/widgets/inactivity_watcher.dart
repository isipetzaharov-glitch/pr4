// lib/widgets/inactivity_watcher.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warningBefore;
  final VoidCallback onTimeout;
  final VoidCallback? onWarning;
  final Widget child;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.onTimeout,
    required this.child,
    this.warningBefore = const Duration(seconds: 30),
    this.onWarning,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _timeoutTimer;
  Timer? _warningTimer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  void _restart() {
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();

    final warnAt = widget.timeout - widget.warningBefore;
    if (warnAt > Duration.zero) {
      _warningTimer = Timer(warnAt, () {
        widget.onWarning?.call();
      });
    }
    _timeoutTimer = Timer(widget.timeout, widget.onTimeout);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _timeoutTimer?.cancel();
    _warningTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: widget.child,
    );
  }
}
