import 'package:flutter/material.dart';

class StreakCalendar extends StatefulWidget {
  final List<DateTime> checkedDates;
  final int streakDays;
  final Color accentColor;
  final Color cardBgColor;
  final Color streakBadgeColor;
  final Function(DateTime date)? onDateTap;

  const StreakCalendar({
    super.key,
    required this.checkedDates,
    required this.streakDays,
    this.accentColor = const Color(0xFF8A9EDB),
    this.cardBgColor = Colors.white,
    this.streakBadgeColor = const Color(0xFFFFB74D),
    this.onDateTap,
  });

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  late final Animation<double> _scaleAnim;
  int? _activeTapIndex;

  List<DateTime> get _weekDates {
    final now = DateTime.now();
    final int currentWeekday = now.weekday;
    final DateTime monday = now.subtract(Duration(days: currentWeekday - 1));
    return List.generate(7, (i) {
      return DateTime(monday.year, monday.month, monday.day).add(Duration(days: i));
    });
  }

  bool _isDateChecked(DateTime date) {
    return widget.checkedDates.any((d) =>
    d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _hasPrevStreak(int index) {
    if (index == 0) return false;
    return _isDateChecked(_weekDates[index - 1]);
  }

  bool _hasNextStreak(int index) {
    if (index == 6) return false;
    return _isDateChecked(_weekDates[index + 1]);
  }

  BorderRadius _calcBorderRadius(int index, bool isChecked) {
    if (!isChecked) return BorderRadius.circular(10);
    final prev = _hasPrevStreak(index);
    final next = _hasNextStreak(index);
    return BorderRadius.only(
      topLeft: Radius.circular(prev ? 0 : 10),
      bottomLeft: Radius.circular(prev ? 0 : 10),
      topRight: Radius.circular(next ? 0 : 10),
      bottomRight: Radius.circular(next ? 0 : 10),
    );
  }

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _tapController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  void _onTapDown(int index) {
    setState(() => _activeTapIndex = index);
    _tapController.forward();
  }

  void _onTapUp(int index, DateTime date) {
    _tapController.reverse();
    Future.delayed(const Duration(milliseconds: 90), () {
      if (mounted) setState(() => _activeTapIndex = null);
    });
    widget.onDateTap?.call(date);
  }

  @override
  Widget build(BuildContext context) {
    const weekLabels = ['一', '二', '三', '四', '五', '六', '日'];
    const primaryText = Color(0xFF2D3142);
    const secondaryText = Color(0xFF9AA0B4);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '本周打卡',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.streakBadgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 14, color: widget.streakBadgeColor),
                    const SizedBox(width: 4),
                    Text(
                      '连续 ${widget.streakDays} 天',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.streakBadgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              return SizedBox(
                width: 36,
                child: Center(
                  child: Text(
                    weekLabels[i],
                    style: const TextStyle(fontSize: 11, color: secondaryText),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final date = _weekDates[i];
              final isChecked = _isDateChecked(date);
              final isToday = _isToday(date);
              final isTapping = _activeTapIndex == i;

              return GestureDetector(
                onTapDown: (_) => _onTapDown(i),
                onTapUp: (_) => _onTapUp(i, date),
                onTapCancel: () {
                  _tapController.reverse();
                  if (mounted) setState(() => _activeTapIndex = null);
                },
                child: AnimatedBuilder(
                  animation: _scaleAnim,
                  builder: (ctx, child) {
                    final scale = isTapping ? _scaleAnim.value : 1.0;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: isChecked
                          ? LinearGradient(
                        colors: [
                          widget.accentColor,
                          widget.accentColor.withOpacity(0.75)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      borderRadius: _calcBorderRadius(i, isChecked),
                      border: isToday && !isChecked
                          ? Border.all(color: widget.accentColor, width: 1.5)
                          : null,
                      boxShadow: isChecked
                          ? [
                        BoxShadow(
                          color: widget.accentColor.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          isChecked ? FontWeight.w600 : FontWeight.normal,
                          color: isChecked ? Colors.white : primaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}