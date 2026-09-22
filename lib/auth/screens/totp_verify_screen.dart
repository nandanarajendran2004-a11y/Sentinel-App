import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/theme.dart';
import '../providers/auth_provider.dart';

/// TOTP verification screen — shown for managers who already have TOTP set up.
///
/// Simple 6-digit code entry. Auto-submits on completion.
class TotpVerifyScreen extends StatefulWidget {
  const TotpVerifyScreen({super.key});

  @override
  State<TotpVerifyScreen> createState() => _TotpVerifyScreenState();
}

class _TotpVerifyScreenState extends State<TotpVerifyScreen> {
  String _code = '';
  bool _isVerifying = false;
  String? _error;

  Future<void> _verify() async {
    if (_code.length != 6) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyTotp(_code);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed('/manager');
    } else {
      setState(() {
        _error = auth.error ?? 'Invalid code. Please try again.';
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SentinelTheme.primaryCyan.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      size: 36,
                      color: SentinelTheme.primaryCyan,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Two-Factor\nAuthentication',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: SentinelTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enter the 6-digit code from your\nauthenticator app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SentinelTheme.textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // PIN input
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    onChanged: (value) => _code = value,
                    onCompleted: (_) => _verify(),
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.scale,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(14),
                      fieldHeight: 56,
                      fieldWidth: 46,
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
                      fontSize: 22,
                      color: SentinelTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: SentinelTheme.accentRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: SentinelTheme.accentRed, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: SentinelTheme.accentRed,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          _isVerifying || _code.length != 6 ? null : _verify,
                      child: _isVerifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF003544),
                              ),
                            )
                          : const Text('Verify'),
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(color: SentinelTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
