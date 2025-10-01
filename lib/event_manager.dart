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
  }) : start = startOfDay(start),
       end = startOfDay(start).add(const Duration(hours: 24)),
       location = "";

  Event copy() {
    Event event = Event(name: name, start: start, eventType: eventType, repeat: repeat);
    event.location = location;
    event.end = end;
    event.reminders = reminders.toList();
    event.notes = notes;

    return event;
  }
}

enum PopupType { edit, detail, edittag, addtag }

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
  Map<DateTime, List<Event>> _events = {};

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

  void add(Event event) {
    insertMapDefault(_events, startOfDay(event.start), (events) {
      events.add(event);
    }, [event]);
  }

  List<Event> getDate(DateTime date) {
    return _events[startOfDay(date)] ?? [];
  }

  void update(DateTime date) {
    List<Event> events = getDate(date);
    date = startOfDay(date);

    List<Event> changeDate = events.where((event) => event.start != date).toList();

    if (changeDate.isNotEmpty) {
      List<Event> newEvents = events.where((event) => event.start == date).toList();
      _events[date] = newEvents;
      for (Event event in changeDate) {
        add(event);
      }
    } 
  }

  void remove(DateTime date, Event event) {
    _events[startOfDay(date)]?.remove(event);
  }

  void replace(Event oldEvent, Event newEvent) {
    DateTime dateTime = startOfDay(oldEvent.start);
    List<Event> events = getDate(dateTime);
    int index = events.indexOf(oldEvent);
    if (index != -1) {
      events[index] = newEvent;
    }

    update(dateTime);
  }
}






