import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fintrack_mobile/features/ai_assistant/widgets/ai_assistant_fab.dart';
import 'package:fintrack_mobile/shared/navigation/bottom_nav_bar.dart';

/// The main app shell: hosts the active tab, the bottom nav, and the AI
/// assistant FAB. The FAB hides when the user scrolls down and reappears when
/// they scroll back up, so it never permanently blocks content.
class AppShell extends StatefulWidget {
  final Widget child;
  final String currentLocation;

  const AppShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _fabVisible = true;

  bool _onScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    // reverse = scrolling down (hide), forward = scrolling up (show).
    if (notification.direction == ScrollDirection.reverse && _fabVisible) {
      setState(() => _fabVisible = false);
    } else if (notification.direction == ScrollDirection.forward &&
        !_fabVisible) {
      setState(() => _fabVisible = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        offset: _fabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _fabVisible ? 1 : 0,
          child: const AiAssistantFab(),
        ),
      ),
      bottomNavigationBar: FintrackBottomNavBar(
        currentLocation: widget.currentLocation,
      ),
    );
  }
}
