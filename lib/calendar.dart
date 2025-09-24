import 'package:flutter/material.dart';

List<int> MONTHS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
List<String> DAYS = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"];

class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  int _count = 0;

  void _incrementCounter() {
    _count += 1;
  }

  @override
  Widget build(BuildContext context) {
    // _incrementCounter();
    DateTime now = DateTime.now();
    int weekday = (now.weekday + 6) % 7;
    int startDay = (now.day - weekday) % 7;

    return Container(
      child: month(50, MONTHS[now.month - 1], startDay, now.day),
    );
  }
}

Widget month(int cellSize, int day, int start, int today) {
  double height = (((day + start) / 7.0).ceil() + 1) * cellSize.toDouble();

  return Container(
    decoration: BoxDecoration(color: Colors.blue),
    width: cellSize * 7,
    height: height,
    child: GridView.builder(
      itemCount: day + start + 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 1.0,
        mainAxisSpacing: 1.0,
      ),
      itemBuilder: (context, index) {
        if (index < 7) {
          return Card(child: Center(child: Text(DAYS[index])));
        }
        if (index < start + 7) {
          return Card();
        }

        if (index - start - 6 == today) {
          return Card(color: Colors.red, child: Center(child: Text('${index - start - 6}')));
        }

        return Card(child: Center(child: Text('${index - start - 6}')));
      },
    ),
  );
}
