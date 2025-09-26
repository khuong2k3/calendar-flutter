// event_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

// Defines the event data we want to broadcast
class GlobalMouseEvent {
  final Offset position;
  final PointerDeviceKind kind;
  final int buttons;

  GlobalMouseEvent(this.position, this.kind, this.buttons);
}

// Notifier to hold the latest event
final globalEventNotifier = ValueNotifier<OverlayPortalController?>(null);
