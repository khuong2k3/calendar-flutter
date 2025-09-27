import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/dropdown.dart';
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
              crossAxisSpacing: 0.0,
              mainAxisSpacing: 0.0,
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
  final GlobalKey _keySc = GlobalKey();
  Size? scrollViewSize;

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
      DateTime date = startOfDay(event.start);
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
          scrollViewSize =
              (_keySc.currentContext?.findRenderObject() as RenderBox?)?.size;
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onChangeSize();
    });
  }

  // OverlayPortalController? _prevOverlay;
  final OverlayPortalController _overlayCtrl = OverlayPortalController();
  final _layerLink = LayerLink();
  Offset _popupOffset = Offset(0, 0);
  bool _open = false;

  Widget _buildOverlay(BuildContext context) {
    if (globalPopupEventNotifier.value == null) {
      return SizedBox.shrink();
    }
    PopupEvent popupEvent = globalPopupEventNotifier.value as PopupEvent;

    if (popupEvent.popupType == PopupType.detail) {
      return EditDetail(
        event: popupEvent.event,
        onExit: () {
          _overlayCtrl.hide();
        },
        onSave: (event) {
          insertMapDefault(events, startOfDay(event.start), (listEvent) {
            listEvent.add(event);
          }, [event]);
          _overlayCtrl.hide();
        },
      );
    }

    return TooltipWrapper(
      globalOffset: _popupOffset,
      boundingBox: scrollViewSize,
      layerLink: _layerLink,
      paintColor: Colors.cyan,
      child: EditDate(
        event: popupEvent.event,
        onOk: (event) {
          _overlayCtrl.hide();
          insertMapDefault(events, startOfDay(event.start), (listEvent) {
            listEvent.add(event);
          }, [event]);
          setState(() {
            scrollPhysics = null;
          });
        },
        onEdit: (event) {
          popupEvent.popupType = PopupType.detail;
          setState(() {
            scrollPhysics = null;
          });
        },
      ),
    );
  }

  ScrollPhysics? scrollPhysics;

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

    return Listener(
      onPointerDown: (e) {
        _popupOffset = e.localPosition;
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: OverlayPortal(
          controller: _overlayCtrl,
          overlayChildBuilder: _buildOverlay,
          child: SingleChildScrollView(
            key: _keySc,
            controller: controller,
            physics: scrollPhysics,
            child: GridView.builder(
              key: _key,
              shrinkWrap: true,
              itemCount: dayDiff,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 0.0,
                mainAxisSpacing: 0.0,
              ),
              itemBuilder: (context, index) {
                DateTime itemDay = weekStart.add(Duration(days: index));
                Color cardColor = Colors.black26;
                List<Event> listEvents = events[itemDay] ?? [];
                List<Widget> tags = [];

                if (listEvents.isNotEmpty) {
                  tags.add(Text(listEvents[0].name));
                }
                if (listEvents.length > 1) {
                  tags.add(Text('${listEvents.length - 1}'));
                }

                if (today == itemDay) {
                  cardColor = Colors.red;
                }

                return Container(
                  decoration: BoxDecoration(
                    boxShadow: [BoxShadow(color: cardColor)],
                    border: BoxBorder.all(color: Colors.white, width: 1),
                  ),
                  child: InkWell(
                    onTap: () {
                      globalPopupEventNotifier.value = PopupEvent(
                        Event(
                          name: "",
                          start: itemDay,
                          eventType: EventType.user,
                          repeat: Repeat.no,
                        ),
                        PopupType.edit,
                      );
                      _overlayCtrl.toggle();
                      setState(() {
                        scrollPhysics = NeverScrollableScrollPhysics();
                      });
                      _open = !_open;
                    },
                    child: Center(child:
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        Text('${itemDay.day}'),
                        Column(
                            mainAxisSize: MainAxisSize.min,
                            children: tags,
                          ),
                      ],)
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

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
  final Event event;
  final void Function(Event) onOk;
  final void Function(Event) onEdit;

  const EditDate({
    required this.event,
    required this.onOk,
    required this.onEdit,
  });

  @override
  State<EditDate> createState() => _EditDate();
}

class _EditDate extends State<EditDate> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsetsGeometry.all(10.0),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        boxShadow: [BoxShadow(color: Colors.cyan)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${widget.event.start.year}-${widget.event.start.month}-${widget.event.start.day}',
          ),
          const Text("Event Name:"),
          Padding(
            padding: const EdgeInsets.all(5),
            child: TextField(
              onChanged: (str) {
                widget.event.name = str;
              },
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    widget.onEdit(widget.event);
                  },
                  child: Text("Edit detail"),
                ),
                FilledButton(
                  onPressed: () {
                    widget.onOk(widget.event);
                  },
                  child: Text("Ok"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditDetail extends StatefulWidget {
  Event event;
  void Function() onExit;
  void Function(Event) onSave;

  EditDetail({required this.event, required this.onExit, required this.onSave});

  @override
  State<StatefulWidget> createState() => _EditDetail();
}

class _EditDetail extends State<EditDetail> {
  bool isAllDay = false;
  final _controllerReminders = OverlayPortalController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 10,
      insetPadding: const EdgeInsets.all(100),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          spacing: 10.0,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Center(
                  child: Text(
                    '${widget.event.start.year}-${widget.event.start.month}-${widget.event.start.day}',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10, left: 10, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed: widget.onExit,
                        child: Text("Cancel"),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed: () {
                          widget.onSave(widget.event);
                        },
                        child: Text("Save"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.only(left: 50, right: 50, top: 5, bottom: 50),
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Event Name:"),
                        TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const Text("Location:"),
                        TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    const Text("Schedule:", style: TextStyle(fontSize: 20)),
                    Column(
                      spacing: 10.0,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("All day:"),
                            Switch(
                              value: isAllDay,
                              onChanged: (value) {
                                setState(() {
                                  isAllDay = value;
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [const Text("Start")],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [const Text("End")],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Reqeat"),
                            DropdownButton(
                              value: widget.event.repeat,
                              items: Repeat.values.map((repeat) {
                                return DropdownMenuItem(
                                  value: repeat,
                                  child: Text(repeat.toName()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    widget.event.repeat = value as Repeat;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    const Text("Reminders:", style: TextStyle(fontSize: 20)),
                    Column(
                      children: widget.event.reminders.map((reminder) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(reminder.toString()),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  widget.event.reminders.remove(reminder);
                                });
                              },
                              child: Icon(Icons.cancel),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    MyDropdown(
                      controller: _controllerReminders,
                      content: SelectionList(
                        items:
                            [
                              Reminder(5, "minute"),
                              Reminder(10, "minute"),
                              Reminder(15, "minute"),
                              Reminder(30, "minute"),
                              Reminder(1, "hour"),
                              Reminder(6, "hour"),
                              Reminder(12, "hour"),
                              Reminder(1, "day"),
                              Reminder(3, "day"),
                              Reminder(1, "week"),
                            ].map((reminder) {
                              return DropdownMenuItem(
                                value: reminder,
                                child: Text(
                                  reminder.toString(),
                                  style: TextStyle(fontSize: 15),
                                ),
                              );
                            }).toList(),
                        onSelected: (item) {
                          setState(() {
                            widget.event.reminders.add(item as Reminder);
                          });
                          _controllerReminders.hide();
                        },
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.only(
                          top: 5,
                          bottom: 5,
                          left: 10,
                          right: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Center(
                          child: Text(
                            "Reminders",
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    const Text("Notes:", style: TextStyle(fontSize: 20)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10.0,
                      children: [
                        const Text("Notes: "),
                        TextField(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            widget.event.notes = value;
                          },
                        ),
                        FilledButton(
                          onPressed: () {},
                          child: Center(child: Text("Delete Event")),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
