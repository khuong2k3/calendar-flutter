import 'package:flutter/material.dart';
import 'package:flutter_app/calendar.dart';
import 'package:flutter_app/calenderbig.dart';
import 'package:flutter_app/dropdown.dart';
import 'package:flutter_app/event_manager.dart';
import 'package:flutter_app/helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  DateTime _selectedDate = startOfDay(DateTime.now());
  final EventManager _eventManager = EventManager([]);

  // final OverlayPortalController _overlayCtrl = OverlayPortalController();
  // Widget _createTag(BuildContext context, Event event) {
  //
  //   return MyDropdown(
  //     controller: _overlayCtrl,
  //     offset: Offset(20, 0),
  //     content: EditTag(
  //       event: event,
  //       onSave: (event) {
  //         _overlayCtrl.hide();
  //       },
  //       onEdit: (event) {
  //       },
  //     ),
  //     arrowColor: Theme.of(context).dividerColor,
  //     child: Container(
  //       height: 20,
  //       padding: EdgeInsets.only(left: 10, right: 10),
  //       decoration: BoxDecoration(color: Theme.of(context).primaryColor),
  //       alignment: AlignmentGeometry.centerLeft,
  //       child: Text(event.name),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _eventManager.addListener(() {
      setState(() { });
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
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
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Calendar(
                      seleted: startOfDay(DateTime.now()),
                      width: 280,
                      onSelectDate: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),
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
                            children: _eventManager.getDate(_selectedDate).map((event) {
                              return Tags(
                                event: event,
                                onSave: (newEvent) {
                                  setState(() {
                                    _eventManager.replace(event, newEvent);
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
              ),
              Calenderbig(events: _eventManager),
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

      // const MyHomePage(title: 'Flutter Demo Home Page'),
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
      child: Container(
        height: 20,
        padding: EdgeInsets.only(left: 10, right: 10),
        decoration: BoxDecoration(color: Theme.of(context).dividerColor),
        alignment: AlignmentGeometry.centerLeft,
        child: Text(event.name),
      ),
    );
  }
}




// class  extends StatelessWidget {
//   ({super.key});
// }

