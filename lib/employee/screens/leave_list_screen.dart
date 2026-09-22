import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../shared_widgets/status_badge.dart';
import '../../shared_widgets/error_view.dart';
import '../providers/leave_provider.dart';
import 'leave_form_screen.dart';

/// Employee leave request list — shows own requests with status badges.
class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({super.key});

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().fetchLeaveRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaveProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: SentinelTheme.backgroundDark,
          body: _buildBody(provider),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: const LeaveFormScreen(),
                  ),
                ),
              );
              if (result == true) {
                provider.fetchLeaveRequests();
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Request'),
          ),
        );
      },
    );
  }

  Widget _buildBody(LeaveProvider provider) {
    if (provider.isLoading && provider.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: SentinelTheme.primaryCyan,
        ),
      );
    }

    if (provider.error != null && provider.requests.isEmpty) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.fetchLeaveRequests(),
      );
    }

    if (provider.requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 64,
              color: SentinelTheme.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No leave requests yet',
              style: TextStyle(
                color: SentinelTheme.textMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to submit a request',
              style: TextStyle(
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
      onRefresh: () => provider.fetchLeaveRequests(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: provider.requests.length,
        itemBuilder: (context, index) {
          final req = provider.requests[index];
          return _buildRequestCard(req);
        },
      ),
    );
  }

  Widget _buildRequestCard(dynamic req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SentinelTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SentinelTheme.primaryCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatLeaveType(req.leaveType),
                  style: const TextStyle(
                    color: SentinelTheme.primaryCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              StatusBadge(status: req.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 15, color: SentinelTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                '${_formatDate(req.startDate)} — ${_formatDate(req.endDate)}',
                style: const TextStyle(
                  color: SentinelTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (req.reason != null && req.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              req.reason!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SentinelTheme.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLeaveType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
