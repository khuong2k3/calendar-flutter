import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_app/event_manager.dart';
import 'package:flutter_app/helper.dart';
import 'package:flutter_app/tooltip.dart';

List<String> DAYS = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"];
int MAX_RENDER = 150;

class Calenderbig extends StatefulWidget {
  const Calenderbig({super.key});

  @override
  State<Calenderbig> createState() => _CalendarBigState();
}

class _CalendarBigState extends State<Calenderbig> {
  DateTime startRender = startOfDay(DateTime.now());
  DateTime endRender = startOfDay(DateTime.now()).add(Duration(days: 70));

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          GridView.builder(
            itemCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 1.0,
              mainAxisSpacing: 1.0,
            ),
            itemBuilder: (context, index) {
              return Card(child: Center(child: Text(DAYS[index])));
            },
          ),
          Flexible(
            flex: 1,
            child: CalenderGrid(
              startDate: startRender,
              endDate: endRender,
              events: [],
            ),
          ),
        ],
      ),
    );
  }
}

class CalenderGrid extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<Event> events;

  const CalenderGrid({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.events,
  });

  State<CalenderGrid> createState() => _CalenderGrid();
}

class _CalenderGrid extends State<CalenderGrid> {
  final GlobalKey _key = GlobalKey();
  double _currentWidth = 0.0;
  Map<DateTime, List<Event>> events = {};
  ScrollController controller = ScrollController(
    initialScrollOffset: 0.001,
    keepScrollOffset: false,
  );

  late DateTime startRender;
  late DateTime endRender;

  void _onScroll() {
    double currentPosition = controller.offset;

    if (controller.position.atEdge) {
      setState(() {
        if (currentPosition == 0.0) {
          startRender = startRender.subtract(Duration(days: 7));
          if (endRender.difference(startRender) > Duration(days: MAX_RENDER)) {
            endRender.subtract(Duration(days: 7));
          }
        } else {
          endRender = endRender.add(Duration(days: 7));
          if (endRender.difference(startRender) > Duration(days: MAX_RENDER)) {
            startRender.add(Duration(days: 7));
          }
        }
      });
    }

    double cellSize = _currentWidth / 7;
    double newPosition = (currentPosition / cellSize).round() * cellSize;

    controller.jumpTo(max(0.001, newPosition));
  }

  @override
  void initState() {
    super.initState();
    for (Event event in widget.events) {
      DateTime date = startOfDay(event.date);
      List<Event>? eventsList = events[date];
      if (eventsList != null) {
        eventsList.add(event);
      } else {
        events[date] = [event];
      }
    }
    setState(() {
      startRender = widget.startDate;
      endRender = widget.endDate;
    });
    controller.addListener(_onScroll);
  }

  void _onChangeSize() {
    final RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null && renderBox.hasSize) {
      if (renderBox.size.width != _currentWidth) {
        setState(() {
          _currentWidth = renderBox.size.width;
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onChangeSize();
    });
  }

  OverlayPortalController? _prevOverlay;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onChangeSize();
    });

    DateTime weekStart = startRender.subtract(
      Duration(days: startRender.weekday),
    );
    DateTime weekEnd = endRender.add(Duration(days: 7 - endRender.weekday));

    int dayDiff = weekEnd.difference(weekStart).inDays;
    DateTime today = startOfDay(DateTime.now());

    return SingleChildScrollView(
      controller: controller,
      child: Listener(
        onPointerDown: (e) {
          if (_prevOverlay != globalEventNotifier.value &&
              globalEventNotifier.value != null) {
            globalEventNotifier.value?.hide();
          }
          _prevOverlay = globalEventNotifier.value;
        },
        child: GridView.builder(
          key: _key,
          shrinkWrap: true,
          itemCount: dayDiff,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 1.0,
            mainAxisSpacing: 1.0,
          ),
          itemBuilder: (context, index) {
            DateTime itemDay = weekStart.add(Duration(days: index));
            Color? cardColor;

            if (today == itemDay) {
              cardColor = Colors.red;
            }

            return MyTooltip(
              arrowColor: Colors.cyan,
              content: EditDate(),
              child: Card(
                color: cardColor,
                child: Center(child: Text('${itemDay.day}')),
              ),
            );
          },
        ),
      ),
    );
  }
}

class Event {
  String name;
  DateTime date;
  EventType eventType;

  Event({required this.name, required this.date, required this.eventType});
}

enum EventType { holiday, user }

class EventTags extends StatelessWidget {
  final List<Event> events;

  const EventTags({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    List<Widget> tags = [];
    if (events.isNotEmpty) {
      tags.add(Text(events[0].name));
    }

    if (events.length > 1) {
      tags.add(Text('+${events.length - 1}'));
    }

    return Row(children: tags);
  }
}

class EditDate extends StatefulWidget {
  @override
  State<EditDate> createState() => _EditDate();
}

class _EditDate extends State<EditDate> {

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 250,
      padding: EdgeInsetsGeometry.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        boxShadow: [BoxShadow(color: Colors.cyan)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Event Name:"),
          TextField(),
          Text("Event Name:"),
          TextField(),
        ],
      )
    );
  }
}
