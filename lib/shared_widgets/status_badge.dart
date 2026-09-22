import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A color-coded badge for attendance/leave statuses.
class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusInfo(status);

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static (Color, String) _statusInfo(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')) {
      case 'on_time':
      case 'ontime':
      case 'approved':
      case 'checked_in':
        return (SentinelTheme.statusOnTime, _formatLabel(status));
      case 'late':
        return (SentinelTheme.statusLate, 'Late');
      case 'pending':
        return (SentinelTheme.statusPending, 'Pending');
      case 'on_leave':
      case 'onleave':
        return (SentinelTheme.statusOnLeave, 'On Leave');
      case 'denied':
      case 'rejected':
        return (SentinelTheme.statusDenied, _formatLabel(status));
      case 'absent':
      case 'not_checked_in':
        return (SentinelTheme.statusAbsent, 'Absent');
      case 'incomplete':
      case 'early_leave':
        return (SentinelTheme.statusIncomplete, _formatLabel(status));
      default:
        return (SentinelTheme.textMuted, _formatLabel(status));
    }
  }

  static String _formatLabel(String s) {
    return s
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
