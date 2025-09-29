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
