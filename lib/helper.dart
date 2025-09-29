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


List<int> MONTHS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
List<String> DAYS = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"];

bool isLeapYear(int year) {
  return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
}

int daysInMonth(int year, int month) {
  if (month != 2) {
    return MONTHS[month - 1];
  } else if (isLeapYear(year)) {
    return 29;
  } else {
    return 28;
  }
}
