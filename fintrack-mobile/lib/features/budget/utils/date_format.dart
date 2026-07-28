// lib/features/transactions/utils/date_format.dart
//
// Tiny wrappers around `intl`'s DateFormat so our date/time strings are defined
// in ONE place. If the design ever wants a different format, we change it here
// only — the widgets just call these functions and don't care about the pattern.
//
// `intl` is the standard Dart date/number formatting package (like Python's
// datetime.strftime). DateFormat('pattern').format(someDateTime) -> a String.

import 'package:intl/intl.dart';

// A quick guide to the "pattern" letters used below:
//   EEEE -> full weekday name      ("Wednesday")
//   d    -> day of month, no zero  ("24",  or "4" not "04")
//   MMMM -> full month name        ("June")
//   HH   -> hour, 24h, zero-padded ("01", "13")
//   mm   -> minute, zero-padded    ("20", "05")

/// "Wednesday, 24 June" — the sub-header shown above each day's transactions.
String formatDayHeader(DateTime date) =>
    DateFormat('EEEE, d MMMM').format(date);

/// "June" — used by the horizontal month strip.
String formatMonth(DateTime date) => DateFormat('MMMM').format(date);

/// "01:20" — the time shown on the right of each transaction row.
String formatTime(DateTime date) => DateFormat('HH:mm').format(date);
