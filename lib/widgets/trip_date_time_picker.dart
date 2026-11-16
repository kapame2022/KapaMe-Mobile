import 'package:flutter/material.dart';

Future<DateTime?> showTripDateTimePicker({
  required BuildContext context,
  DateTime? initialDateTime,
}) async {
  final initial = initialDateTime ?? DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null || !context.mounted) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String formatTripDateTime(DateTime dateTime) =>
    dateTime.toIso8601String().substring(0, 16).replaceFirst('T', ' ');
