// event_manager.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_app/helper.dart';
import 'package:uuid/uuid.dart';

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

Uuid uuidGen = Uuid();

class Event {
  String id;
  String name;
  String location;
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
  }) : id = uuidGen.v4(),
       start = startOfDay(start),
       end = startOfDay(start).add(const Duration(hours: 24)),
       location = "";

  Event copy() {
    Event event = Event(
      name: name,
      start: start,
      eventType: eventType,
      repeat: repeat,
    );
    event.id = id;
    event.location = location;
    event.end = end;
    event.reminders = reminders.toList();
    event.notes = notes;

    return event;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    Event? otherEvent = other as Event?;
    if (otherEvent != null) {
      return id == otherEvent.id;
    }
    return false;
  }
}

enum PopupType { editdetail, edittag, addtag, adddetail }

enum Repeat {
  no,
  daily,
  weekly,
  monthly,
  yearly;

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

class EventManager {
  final Map<DateTime, List<Event>> _events = {};
  final List<void Function()> listeners = [];
  // void Function()? onChange;

  EventManager(List<Event> events) {
    for (Event event in events) {
      DateTime date = startOfDay(event.start);
      List<Event>? eventsList = _events[date];
      if (eventsList != null) {
        eventsList.add(event);
      } else {
        _events[date] = [event];
      }
    }
  }

  void addListener(void Function() listener) {
    listeners.add(listener);
  }

  void _add(Event event) {
    insertMapDefault(_events, startOfDay(event.start), (events) {
      events.add(event);
    }, [event]);
  }

  void _update(DateTime date) {
    List<Event> events = getDate(date);
    date = startOfDay(date);

    List<Event> changeDate = events
        .where((event) => event.start != date)
        .toList();

    if (changeDate.isNotEmpty) {
      List<Event> newEvents = events
          .where((event) => event.start == date)
          .toList();
      _events[date] = newEvents;
      for (Event event in changeDate) {
        _add(event);
      }
    }
  }

  void _remove(DateTime date, Event event) {
    _events[startOfDay(date)]?.remove(event);
  }

  void onChange() {
    for (void Function() listener in listeners) {
      listener();
    }
  }

  void add(Event event) {
    _add(event);
    onChange();
  }

  List<Event> getDate(DateTime date) {
    return _events[startOfDay(date)] ?? [];
  }

  void update(DateTime date) {
    _update(date);
    onChange();
  }

  void remove(DateTime date, Event event) {
    _remove(date, event);
    onChange();
  }

  void replace(Event oldEvent, Event newEvent) {
    DateTime dateTime = startOfDay(oldEvent.start);
    List<Event> events = getDate(dateTime);
    int index = events.indexOf(oldEvent);
    if (index != -1) {
      events[index] = newEvent;
    }

    _update(dateTime);
    onChange();
  }
}
