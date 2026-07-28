// lib/features/transactions/utils/transaction_helpers.dart
//
// Pure functions that take a List<TransactionUi> and return a filtered / sorted /
// grouped version. "Pure" = no side effects, no stored state: same input -> same
// output. That makes them easy to reason about and easy to test.
//
// The screen holds the user's choices (selected month, sort, filter, search text)
// in its State, and on each build pipes the mock list through these functions:
//     inMonth -> byType/bySearch -> sorted -> groupByDay

import '../models/transaction_ui.dart';

// Two enums for the choices the UI offers. (Enums ARE right here: a fixed,
// known set of options we control — unlike categories, which are user data.)
enum TxSort { dateDesc, dateAsc, amountDesc, amountAsc }

enum TxTypeFilter { all, income, expense }

/// One day's worth of transactions, ready to render as a section in the list:
/// a header (`day`), the rows (`items`), and the net total for that day (`dayNet`).
class DaySection {
  final DateTime day; // midnight of that calendar day (time stripped off)
  final List<TransactionUi> items;
  final double dayNet; // sum of amounts (income positive, expense negative)

  const DaySection({
    required this.day,
    required this.items,
    required this.dayNet,
  });
}

// ===========================================================================
//  DEMO (worked example) — study this, then write inMonth/bySearch/sorted below
// ===========================================================================

/// Keep only income, only expense, or everything.
List<TransactionUi> byType(List<TransactionUi> list, TxTypeFilter filter) {
  // A `switch` over the enum is exhaustive — the analyzer checks we handle every case.
  switch (filter) {
    case TxTypeFilter.all:
      return list; // nothing to filter out
    case TxTypeFilter.income:
      // `.where(test)` returns a lazy iterable of items where test() is true;
      // `.toList()` turns it back into a concrete List.
      return list.where((t) => t.isIncome).toList();
    case TxTypeFilter.expense:
      return list.where((t) => t.isExpense).toList();
  }
}

// ===========================================================================
//  YOUR TURN (3 functions) — replace each `return list;` placeholder
// ===========================================================================

/// Keep only transactions that fall in the same YEAR + MONTH as [month].
List<TransactionUi> inMonth(List<TransactionUi> list, DateTime month) {
  // Keep a transaction only if its year AND month match the requested month.
  return list
      .where(
        (t) => t.dateTime.year == month.year && t.dateTime.month == month.month,
      )
      .toList();
}

/// Keep transactions whose NAME contains [query] (case-insensitive).
/// If the query is empty/blank, return the whole list unchanged.
List<TransactionUi> bySearch(List<TransactionUi> list, String query) {
  // Normalise the query once: trim spaces, lowercase so the match ignores case.
  final q = query.trim().toLowerCase();
  // Blank search box -> don't filter anything out.
  if (q.isEmpty) return list;
  // Keep transactions whose (lowercased) name contains the query text.
  return list.where((t) => t.name.toLowerCase().contains(q)).toList();
}

/// Return a NEW list sorted according to [sort]. Do NOT sort `list` in place —
/// callers don't expect their input to be mutated.
List<TransactionUi> sorted(List<TransactionUi> list, TxSort sort) {
  // Work on a COPY so we never reorder the caller's original list.
  // `[...list]` spreads every item into a brand-new, modifiable list.
  final copy = [...list];

  // Pick the right comparator based on the chosen sort.
  // In a comparator (a, b): putting `b` before `a` gives DESCENDING order.
  switch (sort) {
    case TxSort.dateDesc:
      copy.sort((a, b) => b.dateTime.compareTo(a.dateTime)); // newest first
      break;
    case TxSort.dateAsc:
      copy.sort((a, b) => a.dateTime.compareTo(b.dateTime)); // oldest first
      break;
    // Sort by SIZE (magnitude), not by signed value. We compare `.abs()` because
    // `amount` is negative for expenses, but the row shows the absolute RM value —
    // so sorting by the raw signed number would look "inverted" on screen.
    case TxSort.amountDesc:
      copy.sort(
        (a, b) => b.amount.abs().compareTo(a.amount.abs()),
      ); // biggest RM first
      break;
    case TxSort.amountAsc:
      copy.sort(
        (a, b) => a.amount.abs().compareTo(b.amount.abs()),
      ); // smallest RM first
      break;
  }
  return copy;
}

// ===========================================================================
//  DEMO (worked example) — the tricky grouping logic, done for you
// ===========================================================================

/// Group a flat list into per-day sections, PRESERVING the order of [list].
/// Dart Maps keep insertion order, so the day-sections (and the rows inside
/// each one) come out in the same order as the incoming list. => sort the list
/// BEFORE calling groupByDay, and the grouping will follow that sort.
List<DaySection> groupByDay(List<TransactionUi> list) {
  // Step 1: bucket transactions by their calendar day.
  // The map KEY is the day with the time stripped off (so 01:20 and 13:37 on the
  // same date land in the same bucket).
  final Map<DateTime, List<TransactionUi>> buckets = {};
  for (final t in list) {
    final day = DateTime(t.dateTime.year, t.dateTime.month, t.dateTime.day);
    // putIfAbsent: if this day has no list yet, create an empty one; then add.
    buckets.putIfAbsent(day, () => []).add(t);
  }

  // Step 2: turn each bucket into a DaySection, computing that day's net total.
  // `fold` walks the list accumulating a running sum (starts at 0.0).
  // NOTE: we do NOT re-sort the sections here — that would override the sort the
  // caller already applied. Insertion order (from the sorted input) is kept.
  return buckets.entries.map((entry) {
    final net = entry.value.fold<double>(0, (sum, t) => sum + t.amount);
    return DaySection(day: entry.key, items: entry.value, dayNet: net);
  }).toList();
}

/// The distinct months that have at least one transaction, oldest -> newest.
/// Used to build the horizontal month strip.
List<DateTime> monthsWithData(List<TransactionUi> list) {
  // A Set automatically removes duplicates. We normalise each date to the 1st of
  // its month so e.g. 12 June and 24 June both collapse to "June 2026".
  final months = <DateTime>{};
  for (final t in list) {
    months.add(DateTime(t.dateTime.year, t.dateTime.month));
  }
  // `..sort` is the cascade operator: sort the list, then return that same list.
  return months.toList()..sort((a, b) => a.compareTo(b));
}
