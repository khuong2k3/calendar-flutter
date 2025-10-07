DateTime startOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

void insertMapDefault<K, T>(
  Map<K, T> map,
  K key,
  void Function(T) setter,
  T defaultValue,
) {
  T? oldValue = map[key];
  if (oldValue != null) {
    setter(oldValue);
  } else {
    map[key] = defaultValue;
  }
}

String dateString(DateTime date) {
  return '${date.year}-${date.month}-${date.day}';
}

// List<int> MONTHS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
List<int> months = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
List<String> days = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"];
List<String> monthsName = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

bool isLeapYear(int year) {
  return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
}

int daysInMonth(int year, int month) {
  if (month != 2) {
    return months[month - 1];
  } else if (isLeapYear(year)) {
    return 29;
  } else {
    return 28;
  }
}

// A function to get the line number for debugging.
int getCurrentLineNumber() {
  // Get the current stack trace.
  final stackTrace = StackTrace.current.toString();

  // The stack trace string often contains entries like:
  // '#0      MyClass.myMethod (package:my_package/my_file.dart:10:5)'
  // We want the line number from the frame that called this function,
  // which is typically the second line (#1) in the stack trace when printed.

  // Split the stack trace into lines.
  final lines = stackTrace.split('\n');

  // The line of the caller is usually the second one (index 1).
  // Check if there are enough lines and try to extract the line number.
  if (lines.length > 1) {
    // Regular expression to find ':<line>:<column>)' at the end of a line
    final lineRegex = RegExp(r':(\d+):\d+\)');
    final match = lineRegex.firstMatch(lines[1]);

    if (match != null && match.group(1) != null) {
      return int.parse(match.group(1)!);
    }
  }

  // Return -1 on failure
  return -1;
}
