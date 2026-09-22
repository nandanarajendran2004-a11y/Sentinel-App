import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../providers/employee_home_provider.dart';

/// QR code scanner screen for employee check-in/check-out.
///
/// Opens the camera, scans the kiosk's rotating QR code, and submits
/// it to the appropriate check-in or check-out endpoint.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  String? _resultMessage;
  bool? _resultSuccess;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);

    final qrCode = barcode.rawValue!;
    final provider = context.read<EmployeeHomeProvider>();
    final att = provider.attendance;

    bool success;
    if (att == null || att.isNotCheckedIn) {
      success = await provider.checkIn(qrCode);
    } else if (att.isCheckedIn) {
      success = await provider.checkOut(qrCode);
    } else {
      setState(() {
        _resultMessage = 'You have already checked out for today.';
        _resultSuccess = false;
        _isProcessing = false;
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      if (success) {
        final newAtt = provider.attendance;
        if (newAtt?.isCheckedOut == true) {
          _resultMessage = 'Check-out successful!';
        } else {
          _resultMessage = 'Check-in successful!';
        }
        _resultSuccess = true;
      } else {
        _resultMessage = provider.error ?? 'QR verification failed';
        _resultSuccess = false;
      }
    });

    // Auto-reset after showing the result
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _resultMessage = null;
        _resultSuccess = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera preview
        if (_scannerController != null)
          MobileScanner(
            controller: _scannerController!,
            onDetect: _onDetect,
          ),

        // Overlay
        _buildOverlay(),

        // Result banner
        if (_resultMessage != null) _buildResultBanner(),
      ],
    );
  }

  Widget _buildOverlay() {
    return Column(
      children: [
        // Top overlay
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _isProcessing
                      ? 'Processing...'
                      : 'Point your camera at the\nkiosk QR code',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Scanner window (transparent middle)
        SizedBox(
          height: 260,
          child: Row(
            children: [
              Expanded(
                child: Container(
                    color: Colors.black.withValues(alpha: 0.6)),
              ),
              SizedBox(
                width: 260,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: SentinelTheme.primaryCyan,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                    color: Colors.black.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),

        // Bottom overlay
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: Center(
              child: Consumer<EmployeeHomeProvider>(
                builder: (context, provider, _) {
                  final att = provider.attendance;
                  String statusText;
                  if (att == null || att.isNotCheckedIn) {
                    statusText = 'Ready to Check In';
                  } else if (att.isCheckedIn) {
                    statusText = 'Ready to Check Out';
                  } else {
                    statusText = 'Already Checked Out';
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: SentinelTheme.surfaceLight.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: SentinelTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultBanner() {
    final isSuccess = _resultSuccess == true;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        opacity: _resultMessage != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSuccess
                ? SentinelTheme.accentGreen.withValues(alpha: 0.9)
                : SentinelTheme.accentRed.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (isSuccess
                        ? SentinelTheme.accentGreen
                        : SentinelTheme.accentRed)
                    .withValues(alpha: 0.4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _resultMessage!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
