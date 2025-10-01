import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/calendar.dart';
import 'package:flutter_app/dropdown.dart';
import 'package:flutter_app/event_manager.dart';
import 'package:flutter_app/helper.dart';
import 'package:flutter_app/tooltip.dart';

const int maxRender = 200;

class Calenderbig extends StatefulWidget {
  final EventManager events;

  const Calenderbig({super.key, required this.events});

  @override
  State<Calenderbig> createState() => _CalendarBigState();
}

class _CalendarBigState extends State<Calenderbig> {
  DateTime startRender = startOfDay(DateTime.now());
  DateTime endRender = startOfDay(DateTime.now()).add(Duration(days: 100));

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
              return Card(child: Center(child: Text(days[index])));
            },
          ),
          Flexible(
            flex: 1,
            child: CalenderGrid(
              startDate: startRender,
              endDate: endRender,
              events: widget.events,
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
  final EventManager events;

  const CalenderGrid({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.events,
  });

  @override
  State<CalenderGrid> createState() => _CalenderGrid();
}

class _CalenderGrid extends State<CalenderGrid> {
  final GlobalKey _key = GlobalKey();
  final GlobalKey _keySc = GlobalKey();
  Size? scrollViewSize;

  double _currentWidth = 0.0;
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
          if (endRender.difference(startRender) > Duration(days: maxRender)) {
            endRender.subtract(Duration(days: 7));
          }
        } else {
          endRender = endRender.add(Duration(days: 7));
          if (endRender.difference(startRender) > Duration(days: maxRender)) {
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

  void _hideOverlay() {
    _overlayCtrl.hide();
    setState(() {
      scrollPhysics = null;
    });
  }

  Widget _buildOverlay(BuildContext context) {
    if (globalPopupEventNotifier.value == null) {
      return SizedBox.shrink();
    }
    PopupEvent popupEvent = globalPopupEventNotifier.value as PopupEvent;

    if (popupEvent.popupType == PopupType.detail) {
      DateTime dateTime = startOfDay(popupEvent.event.start);
      return EditDetail(
        event: popupEvent.event,
        onExit: () {
          _hideOverlay();
        },
        onSave: (event) {
          _hideOverlay();
          widget.events.replace(popupEvent.event, event);
        },
        onDelete: (event) {
          widget.events.remove(dateTime, event);
          _hideOverlay();
        },
      );
    }

    if (popupEvent.popupType == PopupType.addtag ||
        popupEvent.popupType == PopupType.edittag) {
      return TooltipWrapper(
        globalOffset: _popupOffset,
        boundingBox: scrollViewSize,
        layerLink: _layerLink,
        paintColor: Theme.of(context).dividerColor,
        child: EditTag(
          event: popupEvent.event,
          onSave: (event) {
            if (popupEvent.popupType == PopupType.addtag) {
              widget.events.add(event);
            }
            _hideOverlay();
          },
          onEdit: (event) {
            setState(() {});
            if (popupEvent.popupType == PopupType.addtag) {
              widget.events.add(event);
            }
            globalPopupEventNotifier.value = PopupEvent(
              event,
              PopupType.detail,
            );
          },
        ),
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
          widget.events.add(event);
          _hideOverlay();
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

  Widget _createTag(BuildContext context, Event event) {
    return InkWell(
      onTap: () {
        globalPopupEventNotifier.value = PopupEvent(event, PopupType.edittag);
        _overlayCtrl.toggle();
      },
      child: Container(
        height: 20,
        padding: EdgeInsets.only(left: 5, right: 5),
        width: double.infinity,
        decoration: BoxDecoration(color: Theme.of(context).hintColor),
        child: Text(event.name),
      ),
    );
  }

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

    double cellSize = _currentWidth / 7;
    int tagNum = (cellSize / 20).floor() - 2;

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
                List<Event> listEvents = widget.events.getDate(itemDay);
                List<Widget> tags = [];

                for (int i = 0; i < min(listEvents.length, tagNum); i++) {
                  tags.add(_createTag(context, listEvents[i]));
                }

                if (listEvents.length == tagNum + 1) {
                  tags.add(_createTag(context, listEvents.last));
                } else if (listEvents.length > tagNum + 1) {
                  tags.add(Text('${listEvents.length - tagNum - 1}'));
                }

                if (today == itemDay) {
                  cardColor = Theme.of(context).highlightColor;
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
                        PopupType.addtag,
                      );
                      _overlayCtrl.toggle();
                      if (_overlayCtrl.isShowing) {
                        setState(() {
                          scrollPhysics = NeverScrollableScrollPhysics();
                        });
                      } else {
                        setState(() {
                          scrollPhysics = null;
                        });
                      }
                      _open = !_open;
                    },
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${itemDay.day}'),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: tags,
                          ),
                        ],
                      ),
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
    super.key,
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
          Text(dateString(widget.event.start)),
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
  final Event event;
  final void Function() onExit;
  final void Function(Event) onSave;
  final void Function(Event) onDelete;

  const EditDetail({
    super.key,
    required this.event,
    required this.onExit,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<StatefulWidget> createState() => _EditDetail();
}

class _EditDetail extends State<EditDetail> {
  late bool isAllDay;
  final _controllerReminders = OverlayPortalController();
  final _controlScroll = ScrollController();
  late TextEditingController _nameControler;
  late TextEditingController _locationControler;
  late TextEditingController _notesControler;
  late Event _event;

  @override
  void initState() {
    super.initState();
    isAllDay =
        widget.event.start.hour == 0 &&
        widget.event.end.difference(widget.event.start).inHours == 24;

    _nameControler = TextEditingController(text: widget.event.name);
    _locationControler = TextEditingController(text: widget.event.location);
    _notesControler = TextEditingController(text: widget.event.notes);
    _event = widget.event.copy();
  }

  @override
  void dispose() {
    super.dispose();
    _nameControler.dispose();
    _locationControler.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        decoration: BoxDecoration(
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
                    dateString(_event.start),
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
                        child: const Text("Cancel"),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                        onPressed: () {
                          widget.onSave(_event);
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 700,
              child: SingleChildScrollView(
                controller: _controlScroll,
                padding: const EdgeInsets.only(
                  left: 50,
                  right: 50,
                  top: 5,
                  bottom: 50,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Event Name:"),
                        TextField(
                          controller: _nameControler,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _event.name = value;
                          },
                        ),
                        const Text("Location:"),
                        TextField(
                          controller: _locationControler,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _event.location = value;
                          },
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
                                  _event.start = startOfDay(_event.start);
                                  _event.end = _event.start.add(
                                    Duration(hours: 24),
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                        DropdownDateSelector(
                          name: "Start",
                          date: _event.start,
                          onChange: (date) {
                            setState(() {});
                            _event.start = date;
                            if (_event.end
                                .difference(_event.start)
                                .isNegative) {
                              _event.end = _event.start;
                            }
                          },
                        ),
                        DropdownDateSelector(
                          name: "End",
                          disabled: isAllDay,
                          date: _event.end,
                          onChange: (date) {
                            setState(() {});
                            widget.event.end = date;
                            if (_event.end
                                .difference(_event.start)
                                .isNegative) {
                              _event.start = _event.end;
                            }
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Reqeat"),
                            DropdownButton(
                              value: _event.repeat,
                              items: Repeat.values.map((repeat) {
                                return DropdownMenuItem(
                                  value: repeat,
                                  child: Text(repeat.toName()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _event.repeat = value;
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
                            _event.reminders.add(item as Reminder);
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
                          child: const Text(
                            "Reminders",
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text("Notes:", style: TextStyle(fontSize: 20)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10.0,
                      children: [
                        const Text("Notes: "),
                        TextField(
                          controller: _notesControler,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            widget.onDelete(widget.event);
                          },
                          child: const Center(child: Text("Delete Event")),
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

class EditTag extends StatefulWidget {
  final Event event;
  final void Function(Event) onSave;
  final void Function(Event) onEdit;

  const EditTag({
    super.key,
    required this.event,
    required this.onSave,
    required this.onEdit,
  });

  @override
  State<StatefulWidget> createState() => _EditTag();
}

class _EditTag extends State<EditTag> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.event.name);
  }

  @override
  void dispose() {
    super.dispose();
    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5.0,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FilledButton(
                    onPressed: () {
                      widget.onEdit(widget.event);
                    },
                    child: Icon(Icons.edit),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(widget.event);
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
              Center(
                child: Text(
                  dateString(widget.event.start),
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          const Text("Edit name:", style: TextStyle(fontSize: 15)),
          TextField(
            controller: _textController,
            onChanged: (value) {
              widget.event.name = value;
            },
            decoration: InputDecoration(
              filled: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class DropdownDateSelector extends StatefulWidget {
  final String name;
  final bool? disabled;
  final DateTime date;
  final void Function(DateTime) onChange;

  const DropdownDateSelector({
    super.key,
    required this.name,
    required this.date,
    required this.onChange,
    this.disabled,
  });

  @override
  State<StatefulWidget> createState() => _DropdownDateSelector();
}

class _DropdownDateSelector extends State<DropdownDateSelector> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    List<Widget> elements = [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.name),
          TextButton(
            onPressed: () {
              if (widget.disabled == null || widget.disabled == false) {
                setState(() {
                  _open = !_open;
                });
              }
            },
            child: Row(
              children: [
                Text(widget.date.toString()),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ],
      ),
    ];

    if (_open) {
      elements.add(DateInput(date: widget.date, onChange: widget.onChange));
    }

    return Column(
      spacing: 10.0,
      mainAxisSize: MainAxisSize.min,
      children: elements,
    );
  }
}

class DateInput extends StatefulWidget {
  final DateTime date;
  final void Function(DateTime) onChange;

  const DateInput({super.key, required this.date, required this.onChange});

  @override
  State<StatefulWidget> createState() => _DateInput();
}

class _DateInput extends State<DateInput> {
  late TextEditingController _controler;
  late DateTime _date;
  // late int _hour;
  // late int _minute;

  @override
  void initState() {
    super.initState();
    _controler = TextEditingController(
      text: "${widget.date.year}/${widget.date.month}/${widget.date.day}",
    );
    _date = widget.date;
    // _hour = widget.date.hour;
    // _minute = widget.date.minute;
  }

  @override
  void dispose() {
    super.dispose();
    _controler.dispose();
  }

  void _changeDate(DateTime date) {
    setState(() {
      String newText = "${date.year}/${date.month}/${date.day}";
      _date = date;
      _controler.value = _controler.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
        composing: TextRange.empty,
      );
    });
    widget.onChange(date);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        MyDropdown(
          arrowColor: Theme.of(context).shadowColor,
          content: Container(
            padding: EdgeInsets.only(left: 10, right: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).shadowColor,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Calendar(
              width: 280,
              seleted: _date,
              onSelectDate: (date) {
                _changeDate(date);
              },
            ),
          ),
          child: SizedBox(
            width: 150,
            child: TextField(
              textAlign: TextAlign.center,
              keyboardType: TextInputType.datetime,
              controller: _controler,
              onChanged: (value) {
                List<int> splited = value
                    .replaceAll(RegExp(r'[^0-9\/]'), "")
                    .split("/")
                    .where((x) => x != "")
                    .map(int.parse)
                    .toList();

                if (splited.isNotEmpty) {
                  _changeDate(
                    DateTime(
                      splited[0],
                      ((splited.length > 1 ? splited[1] : 0) % 12) + 1,
                      ((splited.length > 2 ? splited[2] : 0) %
                              daysInMonth(splited[0], splited[1])) +
                          1,
                      _date.hour,
                      _date.minute,
                    ),
                  );
                }
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            NumberPicker(
              value: _date.hour,
              start: 0,
              end: 23,
              onChange: (value) {
                _changeDate(_date.copyWith(hour: value));
              },
            ),
            Text(":"),
            NumberPicker(
              value: _date.minute,
              start: 0,
              end: 59,
              onChange: (value) {
                _changeDate(_date.copyWith(minute: value));
              },
            ),
          ],
        ),
      ],
    );
  }
}

class NumberPicker extends StatefulWidget {
  final int value;
  final int? start;
  final int? end;
  final void Function(int) onChange;

  const NumberPicker({
    super.key,
    required this.value,
    this.start,
    this.end,
    required this.onChange,
  });

  @override
  State<StatefulWidget> createState() => _NumberPicker();
}

class _NumberPicker extends State<NumberPicker> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  void _changeValue(int value) {
    if (widget.end != null && value > (widget.end as int)) {
      value = widget.end as int;
    }

    if (widget.start != null && value < (widget.start as int)) {
      value = widget.start as int;
    }
    String newValue = value.toString();
    _controller.value = _controller.value.copyWith(
      text: newValue,
      selection: TextSelection.collapsed(offset: newValue.length),
      composing: TextRange.empty,
    );
    widget.onChange(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(5)),
        color: Theme.of(context).shadowColor,
        border: BoxBorder.all(color: Theme.of(context).shadowColor),
      ),
      child: Column(
        spacing: 5,
        children: [
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.all(5),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              _changeValue(widget.value + 1);
            },
            child: Icon(Icons.add),
          ),
          SizedBox(
            width: 25,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(border: InputBorder.none),
              onChanged: (value) {
                value = value.replaceAll(RegExp(r"\D"), "");
                if (value.isEmpty) {
                  _changeValue(0);
                } else {
                  _changeValue(int.parse(value));
                }
              },
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.all(0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              _changeValue(widget.value - 1);
            },
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
