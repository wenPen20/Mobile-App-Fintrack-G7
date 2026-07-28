// lib/core/widgets/month_selector.dart
//
// The horizontal strip of months (… April  May  *June*  July …). The SELECTED
// month is highlighted with the teal colour + an underline.
//
// SHARED widget: used by both the Transactions and Budget screens. It's "dumb" —
// it doesn't own which month is selected. The SCREEN owns that state and passes
// it in (`selectedMonth`), plus a callback (`onSelected`) the widget calls when a
// month is tapped. "State up, events down" keeps the widget reusable.
//
// Why StatefulWidget? It owns a ScrollController (created ONCE, disposed on
// teardown) and auto-scrolls to the selected month. Creating the controller in
// build() — as the old copy did — leaked a controller every frame and snapped
// the scroll position back on each rebuild.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fintrack_mobile/core/constants/app_colors.dart';

class MonthSelector extends StatefulWidget {
  final List<DateTime> months; // the months to show, oldest -> newest
  final DateTime selectedMonth; // which one is currently active
  final ValueChanged<DateTime> onSelected; // called when the user taps a month

  const MonthSelector({
    super.key,
    required this.months,
    required this.selectedMonth,
    required this.onSelected,
  });

  @override
  State<MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<MonthSelector> {
  final ScrollController _controller = ScrollController();
  // A key on the currently-selected item so we can scroll it into view.
  final GlobalKey _selectedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Scroll to the selected month once the first layout exists (we need real
    // sizes/positions, which don't exist until after the first frame).
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(covariant MonthSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the selected month changed programmatically (not by a tap), re-center it.
    if (!_isSameMonth(oldWidget.selectedMonth, widget.selectedMonth)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Two DateTimes are "the same month" if year + month match (ignore the day).
  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  void _scrollToSelected() {
    final ctx = _selectedKey.currentContext;
    if (ctx == null || !_controller.hasClients) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5, // center the selected month horizontally
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52, // the strip needs a fixed height to scroll horizontally
      // ScrollConfiguration + _DragScrollBehavior is the key drag fix: Flutter's
      // default behaviour only lets TOUCH/stylus drag a scrollable, so on desktop
      // and web you couldn't drag this strip with a mouse. We opt mouse+trackpad in.
      child: ScrollConfiguration(
        behavior: const _DragScrollBehavior(),
        child: SingleChildScrollView(
          controller: _controller,
          scrollDirection: Axis.horizontal, // <- makes it scroll sideways
          child: Row(
            children: [
              for (int i = 0; i < widget.months.length; i++) ...[
                if (i == 0 || widget.months[i].year != widget.months[i - 1].year)
                  _buildYearSeparator(widget.months[i].year),
                _buildMonth(widget.months[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearSeparator(int year) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$year',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            // Empty placeholder to offset the text alignment exactly like the month underlines
            const SizedBox(height: 3),
          ],
        ),
        const SizedBox(width: 12),
        Container(
          width: 1,
          height: 20,
          color: AppColors.border,
        ),
      ],
    );
  }

  Widget _buildMonth(DateTime month) {
    final isSelected = _isSameMonth(month, widget.selectedMonth);

    return GestureDetector(
      // Only the selected item carries the key we scroll to.
      key: isSelected ? _selectedKey : null,
      onTap: () => widget.onSelected(month), // tell the screen which month was tapped
      behavior: HitTestBehavior.opaque, // whole area is tappable, not just text
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('MMMM').format(month), // "June"
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            // The little underline under the selected month. For unselected
            // months it's transparent, so every item stays the same height.
            Container(
              height: 3,
              width: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets scrollables be dragged by mouse and trackpad, not just touch. Without
/// this, horizontal strips are un-draggable with a mouse on desktop/web.
class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
