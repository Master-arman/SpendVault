import 'package:finance_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Temporal scope representing analytics aggregation timeframes.
enum TimespanScope {
  weekly,
  monthly,
  yearly,
}

/// Date range boundary data structure with start and end timestamps.
class TimespanRange {
  const TimespanRange({
    required this.start,
    required this.end,
    required this.scope,
  });

  final DateTime start;
  final DateTime end;
  final TimespanScope scope;

  /// Weekly scope: Monday 00:00:00.000 to Sunday 23:59:59.999
  factory TimespanRange.weekly([DateTime? referenceDate]) {
    final DateTime now = referenceDate ?? DateTime.now();
    // Monday is weekday 1 in Dart
    final int daysToSubtract = now.weekday - DateTime.monday;
    final DateTime monday = DateTime(now.year, now.month, now.day - daysToSubtract, 0, 0, 0, 0);
    final DateTime sunday = DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
    return TimespanRange(start: monday, end: sunday, scope: TimespanScope.weekly);
  }

  /// Monthly scope: Day 1 00:00:00.000 to End-of-Month 23:59:59.999
  factory TimespanRange.monthly([DateTime? referenceDate]) {
    final DateTime now = referenceDate ?? DateTime.now();
    final DateTime firstDay = DateTime(now.year, now.month, 1, 0, 0, 0, 0);
    final int lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
    final DateTime lastDay = DateTime(now.year, now.month, lastDayOfMonth, 23, 59, 59, 999);
    return TimespanRange(start: firstDay, end: lastDay, scope: TimespanScope.monthly);
  }

  /// Yearly scope: Jan 1 00:00:00.000 to Dec 31 23:59:59.999
  factory TimespanRange.yearly([DateTime? referenceDate]) {
    final DateTime now = referenceDate ?? DateTime.now();
    final DateTime jan1 = DateTime(now.year, 1, 1, 0, 0, 0, 0);
    final DateTime dec31 = DateTime(now.year, 12, 31, 23, 59, 59, 999);
    return TimespanRange(start: jan1, end: dec31, scope: TimespanScope.yearly);
  }

  /// Resolves range for any given [TimespanScope]
  factory TimespanRange.fromScope(TimespanScope scope, [DateTime? referenceDate]) {
    switch (scope) {
      case TimespanScope.weekly:
        return TimespanRange.weekly(referenceDate);
      case TimespanScope.monthly:
        return TimespanRange.monthly(referenceDate);
      case TimespanScope.yearly:
        return TimespanRange.yearly(referenceDate);
    }
  }
}

/// Controller for managing active timespan scope and computing temporal aggregations.
class TimespanController extends ChangeNotifier {
  TimespanController({
    TimespanScope initialScope = TimespanScope.monthly,
    DateTime? referenceDate,
  })  : _scope = initialScope,
        _referenceDate = referenceDate ?? DateTime.now() {
    _currentRange = TimespanRange.fromScope(_scope, _referenceDate);
  }

  TimespanScope _scope;
  DateTime _referenceDate;
  late TimespanRange _currentRange;

  TimespanScope get scope => _scope;
  DateTime get referenceDate => _referenceDate;
  TimespanRange get currentRange => _currentRange;

  void setScope(TimespanScope newScope) {
    if (_scope != newScope) {
      _scope = newScope;
      _currentRange = TimespanRange.fromScope(newScope, _referenceDate);
      notifyListeners();
    }
  }

  void setReferenceDate(DateTime date) {
    _referenceDate = date;
    _currentRange = TimespanRange.fromScope(_scope, date);
    notifyListeners();
  }
}

/// Segmented selector control for switching between Weekly, Monthly, and Yearly scopes.
class TimespanScopeSelector extends StatelessWidget {
  const TimespanScopeSelector({
    super.key,
    required this.selectedScope,
    required this.onScopeChanged,
    this.height = 42,
  });

  final TimespanScope selectedScope;
  final ValueChanged<TimespanScope> onScopeChanged;
  final double height;

  Alignment _getAlignment(TimespanScope scope) {
    switch (scope) {
      case TimespanScope.weekly:
        return Alignment.centerLeft;
      case TimespanScope.monthly:
        return Alignment.center;
      case TimespanScope.yearly:
        return Alignment.centerRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _getAlignment(selectedScope),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              heightFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.accentIndigo.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.accentIndigo.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _buildSegment(TimespanScope.weekly, 'Weekly'),
              _buildSegment(TimespanScope.monthly, 'Monthly'),
              _buildSegment(TimespanScope.yearly, 'Yearly'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(TimespanScope scope, String label) {
    final bool isSelected = selectedScope == scope;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isSelected) {
            HapticFeedback.selectionClick();
            onScopeChanged(scope);
          }
        },
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.indigoLight : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chart wrapper that smoothly interpolates height vectors using [Tween<double>]
/// instead of destroying and recreating the widget tree on scope changes.
class InterpolatedChartContainer extends StatelessWidget {
  const InterpolatedChartContainer({
    super.key,
    required this.height,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
  });

  final double height;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: height, end: height),
      duration: duration,
      curve: curve,
      builder: (BuildContext context, double currentHeight, Widget? animatedChild) {
        return SizedBox(
          height: currentHeight,
          child: animatedChild,
        );
      },
      child: child,
    );
  }
}
