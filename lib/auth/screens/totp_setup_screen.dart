import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme.dart';
import '../providers/auth_provider.dart';

/// TOTP setup screen — shown on first login for managers who haven't
/// set up two-factor authentication yet.
///
/// Displays the TOTP secret as a QR code + copyable text, then asks
/// for a 6-digit confirmation code.
class TotpSetupScreen extends StatefulWidget {
  const TotpSetupScreen({super.key});

  @override
  State<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends State<TotpSetupScreen> {
  String? _secret;
  String? _otpauthUrl;
  bool _isLoadingSetup = true;
  bool _isVerifying = false;
  String? _error;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _loadTotpSetup();
  }

  Future<void> _loadTotpSetup() async {
    final auth = context.read<AuthProvider>();
    final data = await auth.setupTotp();

    if (!mounted) return;

    if (data != null) {
      setState(() {
        _secret = data['secret']?.toString() ?? data['base32']?.toString();
        _otpauthUrl =
            data['otpauth_url']?.toString() ?? data['qr_code']?.toString();
        _isLoadingSetup = false;
      });
    } else {
      setState(() {
        _error = auth.error ?? 'Failed to set up TOTP';
        _isLoadingSetup = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_code.length != 6) return;

    setState(() => _isVerifying = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.verifyTotp(_code);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed('/manager');
    } else {
      setState(() {
        _error = auth.error ?? 'Invalid code. Try again.';
        _isVerifying = false;
        _code = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: SentinelTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                // Header
                Icon(
                  Icons.security_rounded,
                  size: 56,
                  color: SentinelTheme.primaryCyan.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  'Set Up 2FA',
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: SentinelTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Two-factor authentication is required for\nmanager accounts. Scan the QR code below\nwith your authenticator app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SentinelTheme.textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                if (_isLoadingSetup)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(
                      color: SentinelTheme.primaryCyan,
                    ),
                  )
                else if (_error != null && _secret == null)
                  _buildError()
                else ...[
                  // QR code
                  if (_otpauthUrl != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: _otpauthUrl!,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Secret key (copyable)
                  if (_secret != null) ...[
                    const Text(
                      'Or enter this key manually:',
                      style: TextStyle(
                        color: SentinelTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: SentinelTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: SelectableText(
                              _secret!,
                              style: GoogleFonts.firaCode(
                                fontSize: 14,
                                color: SentinelTheme.accentAmber,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Verification code input
                  Text(
                    'Enter the 6-digit code',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: SentinelTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    onChanged: (value) => _code = value,
                    onCompleted: (_) => _verifyCode(),
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 52,
                      fieldWidth: 44,
                      activeFillColor: SentinelTheme.surfaceLight,
                      inactiveFillColor: SentinelTheme.surfaceLight,
                      selectedFillColor: SentinelTheme.surfaceLight,
                      activeColor: SentinelTheme.primaryCyan,
                      inactiveColor: SentinelTheme.dividerColor,
                      selectedColor: SentinelTheme.primaryCyan,
                    ),
                    cursorColor: SentinelTheme.primaryCyan,
                    enableActiveFill: true,
                    textStyle: GoogleFonts.firaCode(
                      fontSize: 20,
                      color: SentinelTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: SentinelTheme.accentRed,
                        fontSize: 13,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          _isVerifying || _code.length != 6 ? null : _verifyCode,
                      child: _isVerifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF003544),
                              ),
                            )
                          : const Text('Verify & Continue'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: SentinelTheme.accentRed,
        ),
        const SizedBox(height: 12),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: SentinelTheme.textSecondary),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            setState(() {
              _isLoadingSetup = true;
              _error = null;
            });
            _loadTotpSetup();
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }
}
