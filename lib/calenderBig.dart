import 'package:flutter/material.dart';

List<String> DAYS = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"];

class Calenderbig extends StatefulWidget {
  const Calenderbig({super.key});

  @override
  State<Calenderbig> createState() => _CalendarBigState();
}

class _CalendarBigState extends State<Calenderbig> {
  DateTime startRender = DateTime.now();
  DateTime endRender = DateTime.now().add(Duration(days: 50));
  ScrollController controller = ScrollController(keepScrollOffset: false);

  void _onScroll() {
    double currentPosition = controller.offset;

    if (controller.position.atEdge) {
      setState(() {
        if (currentPosition == 0.0) {
          startRender = startRender.subtract(Duration(days: 7));
          controller.jumpTo(0.001);
          if (endRender.difference(startRender) > Duration(days: 100)) {
            endRender.subtract(Duration(days: 7));
          }
        } else {
          endRender = endRender.add(Duration(days: 7));
          if (endRender.difference(startRender) > Duration(days: 100)) {
            startRender.add(Duration(days: 7));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    controller.addListener(_onScroll);

    return Expanded(
      child: Column(
        children: [
          Flexible(
            child: GridView.builder(
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
          ),
          Flexible(
            flex: 2,
            child: SingleChildScrollView(
              controller: controller,
              child: renderDays(startRender, endRender),
            ),
          ),
        ],
      ),
    );
  }
}

Widget renderDays(DateTime startDate, DateTime endDate) {
  DateTime weekStart = startDate.subtract(Duration(days: startDate.weekday));
  DateTime weekEnd = endDate.add(Duration(days: 7 - endDate.weekday));
  int dayDiff = weekEnd.difference(weekStart).inDays;

  return GridView.builder(
    shrinkWrap: true,
    itemCount: dayDiff,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 7,
      crossAxisSpacing: 1.0,
      mainAxisSpacing: 1.0,
    ),
    itemBuilder: (context, index) {
      return Card(
        child: Center(
          child: Text('${weekStart.add(Duration(days: index)).day}'),
        ),
      );
    },
  );
}
