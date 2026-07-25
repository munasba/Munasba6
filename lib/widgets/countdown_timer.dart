import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// عداد تنازلي يعرض كم يوم / ساعة / دقيقة بقي على المناسبة
class CountdownTimer extends StatefulWidget {
  final DateTime targetDate;
  final bool compact;
  const CountdownTimer({super.key, required this.targetDate, this.compact = false});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remaining = _calc());
    });
  }

  Duration _calc() {
    final diff = widget.targetDate.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return Text(
        'حانت المناسبة الآن 🎉',
        style: TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.bold,
          fontSize: widget.compact ? 12 : 15,
        ),
      );
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    if (widget.compact) {
      return Text(
        'بعد $days يوم و $hours س',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TimeBox(value: days, label: 'يوم'),
        const SizedBox(width: 8),
        _TimeBox(value: hours, label: 'ساعة'),
        const SizedBox(width: 8),
        _TimeBox(value: minutes, label: 'دقيقة'),
        const SizedBox(width: 8),
        _TimeBox(value: seconds, label: 'ثانية'),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  final int value;
  final String label;
  const _TimeBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}
