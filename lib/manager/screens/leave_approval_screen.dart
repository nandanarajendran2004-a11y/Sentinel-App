import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../shared_widgets/status_badge.dart';
import '../../shared_widgets/error_view.dart';
import '../providers/leave_approval_provider.dart';
import '../models/leave_approval_model.dart';

/// Manager leave approval screen — master-detail list of pending requests.
class LeaveApprovalScreen extends StatefulWidget {
  const LeaveApprovalScreen({super.key});

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveApprovalProvider>().fetchPendingRequests();
    });
  }

  void _showDetail(LeaveApprovalModel request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SentinelTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DetailSheet(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaveApprovalProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.pendingRequests.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: SentinelTheme.primaryCyan,
            ),
          );
        }

        if (provider.error != null && provider.pendingRequests.isEmpty) {
          return ErrorView(
            message: provider.error!,
            onRetry: () => provider.fetchPendingRequests(),
          );
        }

        if (provider.pendingRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: SentinelTheme.accentGreen.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'All caught up!',
                  style: TextStyle(
                    color: SentinelTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'No pending leave requests',
                  style: TextStyle(
                    color: SentinelTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: SentinelTheme.primaryCyan,
          backgroundColor: SentinelTheme.surfaceDark,
          onRefresh: () => provider.fetchPendingRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.pendingRequests.length,
            itemBuilder: (context, index) {
              final req = provider.pendingRequests[index];
              return _buildRequestCard(req);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(LeaveApprovalModel req) {
    return GestureDetector(
      onTap: () => _showDetail(req),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SentinelTheme.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SentinelTheme.statusPending.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SentinelTheme.accentAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _initials(req.employeeName ?? '?'),
                      style: const TextStyle(
                        color: SentinelTheme.accentAmber,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.employeeName ?? 'Unknown Employee',
                        style: const TextStyle(
                          color: SentinelTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatLeaveType(req.leaveType),
                        style: const TextStyle(
                          color: SentinelTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: req.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: SentinelTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${_formatDate(req.startDate)} — ${_formatDate(req.endDate)}',
                  style: const TextStyle(
                    color: SentinelTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    color: SentinelTheme.textMuted.withValues(alpha: 0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
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
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}

/// Bottom sheet showing leave request details with approve/reject buttons.
class _DetailSheet extends StatefulWidget {
  final LeaveApprovalModel request;
  const _DetailSheet({required this.request});

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  bool _isProcessing = false;

  Future<void> _handleAction(bool approve) async {
    setState(() => _isProcessing = true);

    final provider = context.read<LeaveApprovalProvider>();
    bool success;
    if (approve) {
      success = await provider.approveRequest(widget.request.leaveId);
    } else {
      success = await provider.rejectRequest(widget.request.leaveId);
    }

    if (!mounted) return;

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Leave ${approve ? 'approved' : 'rejected'} successfully'
              : provider.error ?? 'Action failed',
        ),
        backgroundColor:
            success ? SentinelTheme.accentGreen : SentinelTheme.accentRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SentinelTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Leave Request Details',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: SentinelTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            _detailRow('Employee', req.employeeName ?? 'Unknown'),
            _detailRow('Type',
                req.leaveType.replaceAll('_', ' ')),
            _detailRow('Start', _formatDate(req.startDate)),
            _detailRow('End', _formatDate(req.endDate)),
            if (req.reason != null && req.reason!.isNotEmpty)
              _detailRow('Reason', req.reason!),

            const SizedBox(height: 28),

            // Action buttons
            if (_isProcessing)
              const Center(
                child: CircularProgressIndicator(
                  color: SentinelTheme.primaryCyan,
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleAction(false),
                        icon: const Icon(Icons.close_rounded,
                            color: SentinelTheme.accentRed),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: SentinelTheme.accentRed),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: SentinelTheme.accentRed
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAction(true),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SentinelTheme.accentGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: SentinelTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: SentinelTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }
}
