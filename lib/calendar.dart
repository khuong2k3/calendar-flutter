import 'package:flutter/material.dart';
import 'package:flutter_app/helper.dart';

class Calendar extends StatefulWidget {
  // int year;
  // int month;
  double width;
  DateTime seleted;
  void Function(DateTime)? onSelectDate;

  Calendar({
    super.key,
    required this.width,
    this.onSelectDate,
    required this.seleted,
  });

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();

    _year = widget.seleted.year;
    _month = widget.seleted.month;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5, bottom: 5),
      child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10.0,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {
                    setState(() {
                      _month -= 1;
                      if (_month == 0) {
                        _month = 12;
                        _year -= 1;
                      }
                    });
                  },
                  child: Icon(Icons.arrow_left),
                ),
                Text(MONTHS_NAME[_month - 1]),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {
                    setState(() {
                      _month += 1;
                      if (_month == 13) {
                        _month = 1;
                        _year += 1;
                      }
                    });
                  },
                  child: Icon(Icons.arrow_right),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {
                    setState(() {
                      _year--;
                    });
                  },
                  child: Icon(Icons.arrow_left),
                ),
                Text("$_year"),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {
                    setState(() {
                      _year++;
                    });
                  },
                  child: Icon(Icons.arrow_right),
                ),
              ],
            ),
          ],
        ),
        MonthView(
          width: widget.width,
          year: _year,
          month: _month,
          seleted: widget.seleted,
          onSelectDate: (date) {
            if (widget.onSelectDate != null) {
              (widget.onSelectDate as void Function(DateTime))(date);
            }
          },
        ),
      ],
    ));
  }
}

class MonthView extends StatelessWidget {
  final double width;
  final int year;
  final int month;
  final DateTime seleted;
  final void Function(DateTime) onSelectDate;

  const MonthView({
    super.key,
    required this.width,
    required this.year,
    required this.month,
    required this.onSelectDate,
    required this.seleted,
  });

  @override
  Widget build(BuildContext context) {
    int dayInMonth = daysInMonth(year, month);
    DateTime startDate = DateTime(year, month, 1);
    int start = startDate.weekday % 7;
    double cellSize = width / 7;
    double height =
        (((dayInMonth + start) / 7.0).ceil() + 1) * cellSize.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      width: width,
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
          DateTime currentDate = startDate.add(
            Duration(days: index - start - 7),
          );

          Color? cardColor;

          if (currentDate == seleted) {
            cardColor = Theme.of(context).hintColor;
          }

          return Card(
            color: cardColor,
            child: InkWell(
              onTap: () {
                onSelectDate(currentDate);
              },
              child: Center(child: Text('${currentDate.day}')),
            ),
          );
        },
      ),
    );
  }
}
