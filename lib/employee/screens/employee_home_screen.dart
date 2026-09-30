import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../shared_widgets/error_view.dart';
import '../providers/employee_home_provider.dart';

/// Employee home screen — shows today's attendance status and a contextual
/// Check In / Check Out button.
class EmployeeHomeScreen extends StatefulWidget {
  final VoidCallback? onGoToScanner;

  const EmployeeHomeScreen({super.key, this.onGoToScanner});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeHomeProvider>().fetchTodayAttendance();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmployeeHomeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.attendance == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: SentinelTheme.primaryCyan,
            ),
          );
        }

        if (provider.error != null && provider.attendance == null) {
          return ErrorView(
            message: provider.error!,
            onRetry: () => provider.fetchTodayAttendance(),
          );
        }

        final att = provider.attendance;

        return RefreshIndicator(
          color: SentinelTheme.primaryCyan,
          backgroundColor: SentinelTheme.surfaceDark,
          onRefresh: () => provider.fetchTodayAttendance(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Date display
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: SentinelTheme.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('yyyy').format(DateTime.now()),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: SentinelTheme.textMuted,
                  ),
                ),

                const SizedBox(height: 36),

                // Status Card
                _buildStatusCard(att),

                const SizedBox(height: 28),

                // Time details
                if (att != null && !att.isNotCheckedIn) ...[
                  _buildTimeRow(
                    icon: Icons.login_rounded,
                    label: 'Check In',
                    time: att.checkInTime,
                    color: SentinelTheme.accentGreen,
                  ),
                  if (att.checkOutTime != null) ...[
                    const SizedBox(height: 12),
                    _buildTimeRow(
                      icon: Icons.logout_rounded,
                      label: 'Check Out',
                      time: att.checkOutTime,
                      color: SentinelTheme.accentAmber,
                    ),
                  ],
                  if (att.workingHours != null) ...[
                    const SizedBox(height: 12),
                    _buildTimeRow(
                      icon: Icons.timer_outlined,
                      label: 'Working Hours',
                      time: '${att.workingHours!.toStringAsFixed(1)}h',
                      color: SentinelTheme.accentPurple,
                    ),
                  ],
                ],

                const SizedBox(height: 36),

                // Action hint
                if (att == null || att.isNotCheckedIn || att.isCheckedIn)
                  InkWell(
                    onTap: widget.onGoToScanner,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SentinelTheme.primaryCyan.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              SentinelTheme.primaryCyan.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            color:
                                SentinelTheme.primaryCyan.withValues(alpha: 0.7),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              att == null || att.isNotCheckedIn
                                  ? 'Go to the Scanner tab to check in by scanning the QR code'
                                  : 'Go to the Scanner tab to check out by scanning the QR code',
                              style: const TextStyle(
                                color: SentinelTheme.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (widget.onGoToScanner != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: SentinelTheme.primaryCyan
                                  .withValues(alpha: 0.6),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(dynamic att) {
    IconData icon;
    String label;
    Color color;
    String subtitle;

    if (att == null || att.isNotCheckedIn) {
      icon = Icons.circle_outlined;
      label = 'Not Checked In';
      color = SentinelTheme.textMuted;
      subtitle = 'Scan the QR code to check in';
    } else if (att.isCheckedIn) {
      icon = Icons.check_circle_rounded;
      label = 'Checked In';
      color = SentinelTheme.accentGreen;
      subtitle = _formatTime(att.checkInTime) ?? 'Checked in';
    } else {
      icon = Icons.task_alt_rounded;
      label = 'Checked Out';
      color = SentinelTheme.accentAmber;
      subtitle = 'You\'re done for today!';
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowIntensity =
            att != null && att.isCheckedIn ? _pulseController.value * 0.3 : 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            gradient: SentinelTheme.cardGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withValues(alpha: 0.2 + glowIntensity),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1 + glowIntensity * 0.2),
                blurRadius: 20 + glowIntensity * 10,
                spreadRadius: glowIntensity * 4,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 64, color: color),
              const SizedBox(height: 16),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: SentinelTheme.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeRow({
    required IconData icon,
    required String label,
    required String? time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: SentinelTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: SentinelTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            _formatTime(time) ?? '—',
            style: GoogleFonts.firaCode(
              fontSize: 16,
              color: SentinelTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String? _formatTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final dt = DateTime.parse(timeStr);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      // Already formatted or just a time string
      return timeStr;
    }
  }
}
