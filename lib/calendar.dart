import 'package:flutter/material.dart';
import 'package:flutter_app/helper.dart';

List<int> MONTHS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
List<String> DAYS = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"];

class Calendar extends StatefulWidget {
  int? year;
  int? month;
  void Function(DateTime)? onSelectDate;

  Calendar({super.key, this.year, this.month, this.onSelectDate});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    if (widget.month != null) {
      _month = widget.month as int;
    } else {
      _month = DateTime.now().month;
    }
    if (widget.year != null) {
      _year = widget.year as int;
    } else {
      _year = DateTime.now().year;
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = startOfDay(DateTime.now());

    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10.0,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _month -= 1;
                    if (_month == 0) {
                      _month = 12;
                      _year -= 1;
                    }
                  });
                },
                child: Icon(Icons.arrow_left)
              ),
              Text("$_month"),
              TextButton(
                onPressed: () {
                  setState(() {
                    _month += 1;
                    if (_month == 13) {
                      _month = 1;
                      _year += 1;
                    }
                  });
                },
                child: Icon(Icons.arrow_right)
              ),
            ],
          ),
          MonthView(
            cellSize: 40, year: _year, month: _month, today: now,
            onSelectDate: (date) {
              if (widget.onSelectDate != null) {
                (widget.onSelectDate as void Function(DateTime))(date);
              }
            },
          ),
        ],
      )
    );
  }
}

class MonthView extends StatelessWidget {
  int cellSize;
  int year;
  int month;
  DateTime today;
  void Function(DateTime) onSelectDate;

  MonthView({super.key, required this.cellSize, required this.year, required this.month, required this.today, required this.onSelectDate});

  @override
  Widget build(BuildContext context) {
    int dayInMonth = MONTHS[month - 1];
    DateTime startDate = DateTime(year, month, 1);
    int start = startDate.weekday % 7;
    double height = (((dayInMonth + start) / 7.0).ceil() + 1) * cellSize.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        // border: BoxBorder.all(color: Theme.of(context).hintColor, width: 1),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      width: cellSize * 7,
      height: height,
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: dayInMonth + start + 7,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 0.0,
          mainAxisSpacing: 0.0,
        ),
        itemBuilder: (context, index) {
          if (index < 7) {
            return Card(child: Center(child: Text(DAYS[index])));
          }
          if (index < start + 7) {
            return Card();
          }
          DateTime currentDate = startDate.add(Duration(days: index - start - 7));

          Color? cardColor;
          if (currentDate == today) {
            cardColor = Theme.of(context).hintColor;
          }

          return Card(
            color: cardColor,
            child: InkWell(
              onTap: () {
                onSelectDate(currentDate);
              },
              child: Center(child: Text('${currentDate.day}')),
            )
          );
        },
      ),
    );
  }
}

Widget month(BuildContext context, int cellSize, int day, int start, int today) {
  double height = (((day + start) / 7.0).ceil() + 1) * cellSize.toDouble();

  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).primaryColor,
      border: BoxBorder.all(color: Theme.of(context).hintColor, width: 1),
      borderRadius: BorderRadius.all(Radius.circular(5)),
    ),
    width: cellSize * 7,
    height: height,
    child: GridView.builder(
      itemCount: day + start + 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 0.0,
        mainAxisSpacing: 0.0,
      ),
      itemBuilder: (context, index) {
        if (index < 7) {
          return Card(child: Center(child: Text(DAYS[index])));
        }
        if (index < start + 7) {
          return Card();
        }
        if (index - start - 6 == today) {
          return Card(
            color: Theme.of(context).hintColor,
            child: Center(child: Text('${index - start - 6}')),
          );
        }

        return Card(
          // borderOnForeground: false,
          child: Center(child: Text('${index - start - 6}')),
        );
      },
    ),
  );
}
