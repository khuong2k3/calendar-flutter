import 'package:flutter/material.dart';
import 'package:flutter_app/calendar.dart';
import 'package:flutter_app/calenderbig.dart';
import 'package:flutter_app/dropdown.dart';
import 'package:flutter_app/event_manager.dart';
import 'package:flutter_app/helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final EventManager eventManager = EventManager([]);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calendar App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        // appBar: AppBar(
        //   title: Text("App"),
        //   centerTitle: true,
        //   leading: Icon(Icons.login),
        // ),
        // drawer: Drawer(child: ListTile(title: Text("do thing"))),
        body: Listener(
          onPointerDown: (e) {
            globalMouseNotifier.value = e;
          },
          behavior: HitTestBehavior.translucent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10.0,
            children: [
              EventList(date: DateTime.now(), events: eventManager),
              Calenderbig(events: eventManager),
            ],
          ),
        ),
        // bottomNavigationBar: NavigationBar(
        //   destinations: [
        //     NavigationDestination(icon: Icon(Icons.home), label: "Home"),
        //     NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        //   ],
        //   onDestinationSelected: (int value) {
        //     // print(value);
        //   },
        // ),
        // floatingActionButton: Column(
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     FloatingActionButton(onPressed: () => {}, child: Icon(Icons.add)),
        //   ],
        // ),
      ),
    );
  }
}

class Tags extends StatelessWidget {
  final OverlayPortalController _overlayCtrl = OverlayPortalController();
  final Event event;
  final void Function(Event) onSave;

  Tags({
    super.key,
    required this.event,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return MyDropdown(
      controller: _overlayCtrl,
      offset: Offset(20, 0),
      content: EditTag(
        event: event,
        onSave: (newEvent) {
          onSave(newEvent);
          _overlayCtrl.hide();
        },
        onEdit: (event) {
        },
      ),
      arrowColor: Theme.of(context).dividerColor,
      child: InkWell(
        onTap: _overlayCtrl.toggle,
        child: Container(
          height: 20,
          padding: EdgeInsets.only(left: 10, right: 10),
          decoration: BoxDecoration(color: Theme.of(context).dividerColor),
          alignment: AlignmentGeometry.centerLeft,
          child: Text(event.name),
        ),
      )
    );
  }
}


class EventList extends StatefulWidget {
  final DateTime date;
  final EventManager events;

  const EventList({
    super.key,
    required this.date,
    required this.events,
  });

  @override
  State<StatefulWidget> createState() => _EventList();
}

class _EventList extends State<EventList> {
  late DateTime _selectedDate;

  bool _onChange(EventInfoChange info) {
    if (startOfDay(info.date) == _selectedDate && mounted) {
        setState(() { });
    }

    return mounted;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = startOfDay(widget.date);
    widget.events.addListener(_onChange);

  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Calendar(
            seleted: _selectedDate,
            showToday: true,
            width: 280,
            onSelectDate: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          // ElevatedButton(
          //   onPressed: () {
          //     widget.events.save();
          //   },
          //   child: const Text("save"),
          // ),
          Padding(
            padding: EdgeInsets.all(10), 
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Events ${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}:"),
                Column(
                  spacing: 5,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.events.getDate(_selectedDate).map((event) {
                    return Tags(
                      event: event,
                      onSave: (newEvent) {
                        setState(() {
                          widget.events.replace(event, newEvent);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            )
          ),
        ],
      ),
    );
  }
}



// class  extends StatelessWidget {
//   ({super.key});
// }

