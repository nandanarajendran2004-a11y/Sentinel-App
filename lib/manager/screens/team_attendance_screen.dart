import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../shared_widgets/status_badge.dart';
import '../../shared_widgets/error_view.dart';
import '../providers/team_attendance_provider.dart';

/// Manager team attendance screen — date-filterable list of department records.
class TeamAttendanceScreen extends StatefulWidget {
  const TeamAttendanceScreen({super.key});

  @override
  State<TeamAttendanceScreen> createState() => _TeamAttendanceScreenState();
}

class _TeamAttendanceScreenState extends State<TeamAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamAttendanceProvider>().fetchTeamAttendance();
    });
  }

  Future<void> _pickDate() async {
    final provider = context.read<TeamAttendanceProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: SentinelTheme.primaryCyan,
              surface: SentinelTheme.surfaceDark,
              onSurface: SentinelTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamAttendanceProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Date filter bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: SentinelTheme.surfaceDark,
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: SentinelTheme.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy')
                        .format(provider.selectedDate),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: SentinelTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                    label: const Text('Change'),
                    style: TextButton.styleFrom(
                      foregroundColor: SentinelTheme.primaryCyan,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: SentinelTheme.dividerColor),

            // Content
            Expanded(child: _buildContent(provider)),
          ],
        );
      },
    );
  }

  Widget _buildContent(TeamAttendanceProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: SentinelTheme.primaryCyan,
        ),
      );
    }

    if (provider.error != null && provider.records.isEmpty) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.fetchTeamAttendance(),
      );
    }

    if (provider.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: SentinelTheme.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No attendance records',
              style: TextStyle(
                color: SentinelTheme.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'for ${DateFormat('MMM d, yyyy').format(provider.selectedDate)}',
              style: const TextStyle(
                color: SentinelTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: SentinelTheme.primaryCyan,
      backgroundColor: SentinelTheme.surfaceDark,
      onRefresh: () => provider.fetchTeamAttendance(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.records.length,
        itemBuilder: (context, index) {
          final record = provider.records[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SentinelTheme.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: SentinelTheme.primaryCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _initials(record.employeeName ?? '?'),
                      style: const TextStyle(
                        color: SentinelTheme.primaryCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.employeeName ?? 'Unknown',
                        style: const TextStyle(
                          color: SentinelTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (record.checkInTime != null) ...[
                            Icon(Icons.login_rounded,
                                size: 13,
                                color: SentinelTheme.accentGreen
                                    .withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(record.checkInTime),
                              style: const TextStyle(
                                color: SentinelTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (record.checkOutTime != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.logout_rounded,
                                size: 13,
                                color: SentinelTheme.accentAmber
                                    .withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(record.checkOutTime),
                              style: const TextStyle(
                                color: SentinelTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (record.checkInTime == null)
                            const Text(
                              'No check-in',
                              style: TextStyle(
                                color: SentinelTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                StatusBadge(status: record.status, fontSize: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '—';
    try {
      final dt = DateTime.parse(timeStr);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }
}
