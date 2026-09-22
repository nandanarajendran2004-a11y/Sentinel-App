import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../shared_widgets/error_view.dart';
import '../providers/manager_home_provider.dart';

/// Manager home screen — team summary cards for today.
class ManagerHomeScreen extends StatefulWidget {
  const ManagerHomeScreen({super.key});

  @override
  State<ManagerHomeScreen> createState() => _ManagerHomeScreenState();
}

class _ManagerHomeScreenState extends State<ManagerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerHomeProvider>().fetchTeamSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagerHomeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.summary == null) {
          return const Center(
            child: CircularProgressIndicator(
              color: SentinelTheme.primaryCyan,
            ),
          );
        }

        if (provider.error != null && provider.summary == null) {
          return ErrorView(
            message: provider.error!,
            onRetry: () => provider.fetchTeamSummary(),
          );
        }

        final summary = provider.summary;

        return RefreshIndicator(
          color: SentinelTheme.primaryCyan,
          backgroundColor: SentinelTheme.surfaceDark,
          onRefresh: () => provider.fetchTeamSummary(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: SentinelTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Team Overview',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: SentinelTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 28),

                // Summary grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.3,
                  children: [
                    _buildSummaryCard(
                      icon: Icons.check_circle_rounded,
                      label: 'On Time',
                      count: summary?.onTime ?? 0,
                      color: SentinelTheme.statusOnTime,
                    ),
                    _buildSummaryCard(
                      icon: Icons.watch_later_rounded,
                      label: 'Late',
                      count: summary?.late_ ?? 0,
                      color: SentinelTheme.statusLate,
                    ),
                    _buildSummaryCard(
                      icon: Icons.event_busy_rounded,
                      label: 'On Leave',
                      count: summary?.onLeave ?? 0,
                      color: SentinelTheme.statusOnLeave,
                    ),
                    _buildSummaryCard(
                      icon: Icons.person_off_rounded,
                      label: 'Not Checked In',
                      count: summary?.notCheckedIn ?? 0,
                      color: SentinelTheme.statusAbsent,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Total employees
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: SentinelTheme.cardGradient,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: SentinelTheme.primaryCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: SentinelTheme.primaryCyan,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Employees',
                            style: TextStyle(
                              color: SentinelTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${summary?.total ?? 0}',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: SentinelTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SentinelTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: count),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, _) {
              return Text(
                '$value',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: SentinelTheme.textPrimary,
                ),
              );
            },
          ),
          Text(
            label,
            style: const TextStyle(
              color: SentinelTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
