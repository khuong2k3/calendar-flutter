// event_manager.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_app/helper.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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

enum EventType {
  holiday,
  user;

  static EventType fromString(String value) {
    switch (value) {
      case "EventType.holiday":
        return EventType.holiday;
      case "EventType.user":
        return EventType.user;
      default:
        return EventType.user;
    }
  }
}

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
      'eventType': eventType.toString(),
      'repeat': repeat.toString(),
      'notes': notes,
      'reminders': jsonEncode(reminders.map((ele) => ele.toMap()).toList()),
    };
  }

  static Event fromMap(Map<String, dynamic> value) {
    Event event = Event(
      name: value['name'],
      start: DateTime.fromMillisecondsSinceEpoch(value['start']),
      eventType: EventType.fromString(value['eventType']),
      repeat: Repeat.fromString(value['repeat']),
    );
    event.id = value['id'];
    event.end = DateTime.fromMillisecondsSinceEpoch(value['end']);
    event.location = value['location'];
    event.notes = value['notes'];
    // List<dynamic> reminders =
    for (dynamic reminder in jsonDecode(value['reminders']).map((ele) {
      return Reminder.fromMap(ele as Map<String, dynamic>);
    }).toList()) {
      event.reminders.add(reminder as Reminder);
    }

    return event;
  }
}

enum PopupType { editdetail, edittag, addtag, adddetail }

enum Repeat {
  no,
  daily,
  weekly,
  monthly,
  yearly;

  static Repeat fromString(String value) {
    switch (value) {
      case "Repeat.no":
        return Repeat.no;
      case "Repeat.daily":
        return Repeat.daily;
      case "Repeat.weekly":
        return Repeat.weekly;
      case "Repeat.monthly":
        return Repeat.monthly;
      case "Repeat.yearly":
        return Repeat.yearly;
      default:
        return Repeat.no;
    }
  }

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

  Map<String, dynamic> toMap() {
    return {'duration': duration, 'range': range};
  }

  static Reminder fromMap(Map<String, dynamic> value) {
    return Reminder(value['duration'], value['range']);
  }

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

class EventInfoChange {
  final DateTime? date;

  const EventInfoChange(this.date);
}

class EventManager {
  final Map<String, List<Event>> _events = {};
  List<bool Function(EventInfoChange)> listeners = [];
  final DatabaseHelper _db = DatabaseHelper();
  // void Function()? onChange;

  String _dateString(DateTime date) {
    return "${date.year}:${date.month}:${date.day}";
  }

  EventManager() {
    _db.query().then((events) {
      for (Event event in events) {
        String date = _dateString(event.start);
        List<Event>? eventsList = _events[date];
        if (eventsList != null) {
          eventsList.add(event);
        } else {
          _events[date] = [event];
        }
      }
      // onChange(EventInfoChange(null));
    });
  }

  void addListener(bool Function(EventInfoChange) listener) {
    listeners.add(listener);
  }

  void _add(Event event) {
    insertMapDefault(_events, _dateString(event.start), (events) {
      events.add(event);
    }, [event]);
  }

  List<EventInfoChange> _update(DateTime date) {
    List<Event> events = getDate(date);
    date = startOfDay(date);

    List<Event> changeDate = events
        .where((event) => event.start != date)
        .toList();

    List<EventInfoChange> changedDate = [];
    if (changeDate.isNotEmpty) {
      List<Event> newEvents = events
          .where((event) => event.start == date)
          .toList();
      _events[_dateString(date)] = newEvents;
      for (Event event in changeDate) {
        _add(event);
        changedDate.add(EventInfoChange(event.start));
      }
    }

    return changedDate;
  }

  void _remove(DateTime date, Event event) {
    _events[_dateString(date)]?.remove(event);
  }

  void onChange(EventInfoChange change) {
    List<bool Function(EventInfoChange)> newList = [];
    for (bool Function(EventInfoChange) listener in listeners) {
      if (listener(change)) {
        newList.add(listener);
      }
    }
    listeners = newList;
  }

  void add(Event event) {
    _add(event);
    onChange(EventInfoChange(event.start));
    _db.insertEvent(event);
  }

  List<Event> getDate(DateTime date) {
    return _events[_dateString(date)] ?? [];
  }

  void update(DateTime date) {
    for (EventInfoChange event in _update(date)) {
      onChange(event);
    }
  }

  void remove(DateTime date, Event event) {
    _remove(date, event);
    onChange(EventInfoChange(date));
    _db.removeEvent(event);
  }

  void replace(Event oldEvent, Event newEvent) {
    DateTime dateTime = startOfDay(oldEvent.start);
    List<Event> events = getDate(dateTime);
    int index = events.indexOf(oldEvent);
    if (index != -1) {
      events[index] = newEvent;
    }

    update(dateTime);
    _db.insertEvent(newEvent);
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the device's application document directory
    // Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(".", "db.sqlite");

    // Open the database
    return await openDatabase(
      path,
      version: 1, // Database version
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade,
    );
  }

  Future<int> insertEvent(Event event) async {
    Database db = await database;

    return await db.insert(
      "event",
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future removeEvent(Event event) async {
    Database db = await database;
    await db.delete("event", where: "id = ?", whereArgs: [event.id]);
  }

  Future<List<Event>> query() async {
    Database db = await database;
    List<Event> events = (await db.query("event")).map((ele) {
      return Event.fromMap(ele);
    }).toList();

    return events;
  }

  // This function is called only once when the database is first created
  Future _onCreate(Database db, int version) async {
    await db.execute("""
      create table event(
        id string primary key,
        name string,
        location string,
        start timestamp,
        end timestamp,
        eventType string,
        repeat string,
        notes text,
        reminders text
      );
      """);

    // await db.execute("""
    //   create table reminder (
    //     eventId string,
    //     id string,
    //     duration integer,
    //     range string,
    //     primary key(eventId, id),
    //     foreign key(eventId) references event(id)
    //   );
    //   """);
  }

  // // This function handles database upgrades (e.g., adding a new column)
  // Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //   // Example: If upgrading from v1 to v2, add a new table
  //   if (oldVersion < 2) {
  //     await db.execute('''
  //       CREATE TABLE logs (
  //         id INTEGER PRIMARY KEY,
  //         message TEXT
  //       )
  //     ''');
  //   }
  // }
}
