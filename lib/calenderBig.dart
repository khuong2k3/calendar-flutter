import 'package:flutter/material.dart';

List<String> DAYS = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"];
int MAX_RENDER = 150;

class Calenderbig extends StatefulWidget {
  const Calenderbig({super.key});

  @override
  State<Calenderbig> createState() => _CalendarBigState();
}

class _CalendarBigState extends State<Calenderbig> {
  final GlobalKey _key = GlobalKey();
  DateTime startRender = DateTime.now();
  DateTime endRender = DateTime.now().add(Duration(days: 50));
  ScrollController controller = ScrollController(initialScrollOffset: 0.001, keepScrollOffset: false);
  Size _currentSize = Size(0, 0);

  void _onScroll() {
    double currentPosition = controller.offset;

    if (controller.position.atEdge) {
      setState(() {
        if (currentPosition == 0.0) {
          startRender = startRender.subtract(Duration(days: 7));
          controller.jumpTo(0.001);
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
  }

  void _onChangeSize() {
    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null && renderBox.hasSize) {
      if (renderBox.size != _currentSize) {
        setState(() {
          _currentSize = renderBox.size;
        });
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onChangeSize();
    });
  }

  @override
  void initState() {
    super.initState();

    controller.addListener(_onScroll);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onChangeSize();
    });

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
            child: SingleChildScrollView(
              key: _key,
              controller: controller,
              child: CalenderGrid(startDate: startRender, endDate: endRender, currentSize: _currentSize,),
            ),
          ),
        ],
      ),
    );
  }
}

class CalenderGrid extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final Size currentSize;

  const CalenderGrid({super.key, required this.startDate, required this.endDate, required this.currentSize});

  @override
  Widget build(BuildContext context) {
    DateTime weekStart = startDate.subtract(Duration(days: startDate.weekday));
    DateTime weekEnd = endDate.add(Duration(days: 7 - endDate.weekday));
    int dayDiff = weekEnd.difference(weekStart).inDays;
    DateTime today = DateTime.now();

    return GridView.builder(
      shrinkWrap: true,
      itemCount: dayDiff,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 1.0,
        mainAxisSpacing: 1.0,
      ),
      itemBuilder: (context, index) {
        DateTime itemDay = weekStart.add(Duration(days: index));

        if (itemDay.day == today.day &&
            itemDay.month == today.month &&
            itemDay.year == today.year) {
          return Card(
            color: Colors.red,
            shadowColor: Colors.red,
            child: Center(
              child: Text('${weekStart.add(Duration(days: index)).day}'),
            ),
          );
        }

        return Card(
          child: Center(
            child: Text('${weekStart.add(Duration(days: index)).day}'),
          ),
        );
      },
    );
  }
}

// Widget renderDays(DateTime startDate, DateTime endDate) {
//   DateTime weekStart = startDate.subtract(Duration(days: startDate.weekday));
//   DateTime weekEnd = endDate.add(Duration(days: 7 - endDate.weekday));
//   int dayDiff = weekEnd.difference(weekStart).inDays;
//   DateTime today = DateTime.now();
//
//   return GridView.builder(
//     shrinkWrap: true,
//     itemCount: dayDiff,
//     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//       crossAxisCount: 7,
//       crossAxisSpacing: 1.0,
//       mainAxisSpacing: 1.0,
//     ),
//     itemBuilder: (context, index) {
//       DateTime itemDay = weekStart.add(Duration(days: index));
//
//       if (itemDay.day == today.day &&
//           itemDay.month == today.month &&
//           itemDay.year == today.year) {
//         return Card(
//           color: Colors.red,
//           shadowColor: Colors.red,
//           child: Center(
//             child: Text('${weekStart.add(Duration(days: index)).day}'),
//           ),
//         );
//       }
//
//       return Card(
//         child: Center(
//           child: Text('${weekStart.add(Duration(days: index)).day}'),
//         ),
//       );
//     },
//   );
// }
