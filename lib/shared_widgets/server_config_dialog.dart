import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/theme.dart';

/// Modal dialog for configuring and testing the backend API base URL at runtime.
///
/// Enables changing the Ngrok or local backend tunnel without rebuilding the app.
class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  /// Displays the server configuration dialog. Returns `true` if URL was updated.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  final ApiClient _api = ApiClient();
  late final TextEditingController _urlController;
  final _formKey = GlobalKey<FormState>();

  bool _isTesting = false;
  bool _isSaving = false;
  ({bool success, String message, int latencyMs})? _testResult;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _api.currentBaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      setState(() {
        _urlController.text = text;
        _testResult = null;
      });
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    final targetUrl = _urlController.text.trim();
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final result = await _api.testConnection(targetUrl);

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testResult = result;
    });
  }

  Future<void> _saveAndApply() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final targetUrl = _urlController.text.trim();
    await _api.updateBaseUrl(targetUrl);

    if (!mounted) return;

    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: SentinelTheme.accentGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Server URL updated:\n${_api.currentBaseUrl}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: SentinelTheme.surfaceElevated,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _resetToDefault() async {
    setState(() {
      _urlController.text = AppConstants.apiBaseUrl;
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCustomized =
        _api.currentBaseUrl != AppConstants.apiBaseUrl;

    return Dialog(
      backgroundColor: SentinelTheme.surfaceDark,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: SentinelTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: SentinelTheme.primaryCyan
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.dns_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Server Settings',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: SentinelTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Change backend API or Ngrok tunnel',
                            style: TextStyle(
                              fontSize: 12,
                              color: SentinelTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: SentinelTheme.textMuted),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Current Active URL Card
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: SentinelTheme.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCustomized
                              ? SentinelTheme.accentAmber
                              : SentinelTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isCustomized ? 'Active (Custom):' : 'Active (Default):',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SentinelTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _api.currentBaseUrl,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: SentinelTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // URL Input Label
                const Text(
                  'API Base URL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SentinelTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                // Text field with Paste & Clear actions
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: SentinelTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'https://xxxx.ngrok-free.app/api',
                    prefixIcon: const Icon(Icons.link_rounded, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Paste from clipboard',
                          icon: const Icon(
                            Icons.content_paste_rounded,
                            size: 19,
                            color: SentinelTheme.primaryCyan,
                          ),
                          onPressed: _pasteFromClipboard,
                        ),
                        if (_urlController.text.isNotEmpty)
                          IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(
                              Icons.cancel_rounded,
                              size: 18,
                              color: SentinelTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() {
                                _urlController.clear();
                                _testResult = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'API URL is required';
                    }
                    final trimmed = v.trim();
                    if (!trimmed.contains('.') || trimmed.length < 5) {
                      return 'Enter a valid URL (e.g. https://xyz.ngrok-free.app)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Note: If /api is omitted, it will automatically be appended.',
                  style: TextStyle(
                    fontSize: 11,
                    color: SentinelTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 16),

                // Test Connection Button & Result Banner
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: SentinelTheme.primaryCyan,
                              ),
                            )
                          : const Icon(Icons.network_check_rounded, size: 18),
                      label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        side: BorderSide(
                          color: SentinelTheme.primaryCyan
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _resetToDefault,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reset Default'),
                      style: TextButton.styleFrom(
                        foregroundColor: SentinelTheme.textMuted,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),

                // Test result display
                if (_testResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _testResult!.success
                          ? SentinelTheme.accentGreen.withValues(alpha: 0.12)
                          : SentinelTheme.accentRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _testResult!.success
                            ? SentinelTheme.accentGreen.withValues(alpha: 0.4)
                            : SentinelTheme.accentRed.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _testResult!.success
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: _testResult!.success
                              ? SentinelTheme.accentGreen
                              : SentinelTheme.accentRed,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _testResult!.message,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _testResult!.success
                                      ? SentinelTheme.accentGreen
                                      : SentinelTheme.accentRed,
                                ),
                              ),
                              if (_testResult!.success)
                                Text(
                                  'Latency: ${_testResult!.latencyMs}ms',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: SentinelTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Save & Cancel Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: SentinelTheme.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAndApply,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF003544),
                                ),
                              )
                            : const Text('Save & Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
