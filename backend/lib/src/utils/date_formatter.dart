class DateFormatter {
  /// Formats a Dart [DateTime] into a MySQL-compatible `YYYY-MM-DD HH:MM:SS` timestamp string.
  static String toMySQLString(DateTime dt) {
    final utc = dt.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final hh = utc.hour.toString().padLeft(2, '0');
    final mm = utc.minute.toString().padLeft(2, '0');
    final ss = utc.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }

  /// Parses a date value returned from MySQL into a Dart [DateTime].
  static DateTime parse(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    final str = value.toString().trim();
    if (str.isEmpty) return DateTime.now();

    return DateTime.tryParse(str) ??
        DateTime.tryParse(str.replaceAll(' ', 'T')) ??
        DateTime.now();
  }
}
