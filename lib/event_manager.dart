// event_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_app/helper.dart';

// Defines the event data we want to broadcast
class GlobalMouseEvent {
  final Offset position;
  final PointerDeviceKind kind;
  final int buttons;

  GlobalMouseEvent(this.position, this.kind, this.buttons);
}

class PopupEvent {
  Event event;
  PopupType popupType;

  PopupEvent(this.event, this.popupType);
}

enum EventType { holiday, user }

class Event {
  String name;
  DateTime start;
  DateTime end;
  EventType eventType;
  Repeat repeat;
  String notes = "";
  List<Reminder> reminders = [];

  Event({
    required this.name,
    required DateTime start,
    required this.eventType,
    required this.repeat,
  }) : start = startOfDay(start),
    end = startOfDay(start).add(const Duration(hours: 24));
}


enum PopupType {
  edit,
  detail,
}

enum Repeat {
  no, daily, weekly, monthly, yearly;

  String toName() {
    switch (this) {
      case Repeat.no:
        return "No Repeat";
      case Repeat.daily:
        return "Daily";
      case Repeat.weekly:
        return "Weekly";
      case Repeat.monthly:
        return "Monthly";
      case Repeat.yearly:
        return "Yearly";
    }
  }
}

class Reminder {
  int duration;
  String range;

  Reminder(this.duration, this.range);


  @override
  String toString() {
    if (duration == 1) {
      return '$duration $range before';
    }
    return '$duration ${range}s before';
  }
}


final globalPopupEventNotifier = ValueNotifier<PopupEvent?>(null);

// Notifier to hold the latest event
final globalEventNotifier = ValueNotifier<OverlayPortalController?>(null);

final globalMouseNotifier = ValueNotifier<PointerDownEvent?>(null);


