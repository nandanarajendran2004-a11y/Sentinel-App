import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../providers/employee_home_provider.dart';

/// QR code scanner screen for employee check-in/check-out.
///
/// Opens the camera, scans the kiosk's rotating QR code, captures
/// a fresh high-accuracy GPS fix, and submits it to the backend.
///
/// Features double-scan lockouts, animated success confirmation,
/// and automatic routing back to the home view.
class ScannerScreen extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onNavigateToHome;

  const ScannerScreen({
    super.key,
    this.isActive = true,
    this.onNavigateToHome,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _resultMessage;
  bool? _resultSuccess;

  String? _successType;
  String? _successTime;
  DateTime? _lastActionTime;

  late AnimationController _successAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );

    _initAnimations();
    _checkInitialLocationPermission();
  }

  void _initAnimations() {
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 50,
      ),
    ]).animate(_successAnimController);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.45)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 70,
      ),
    ]).animate(_successAnimController);

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimController,
        curve: const Interval(0.2, 1.0, curve: Curves.linear),
      ),
    );

    _successAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && _isSuccess) {
        _navigateToHome();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _resetScannerForNewScan();
      } else {
        _pauseScanner();
      }
    }
  }

  void _pauseScanner() {
    _successAnimController.reset();
    _scannerController?.stop();
  }

  void _resetScannerForNewScan() {
    _successAnimController.reset();
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _resultMessage = null;
        _resultSuccess = null;
        _successType = null;
        _successTime = null;
      });
    }
    _scannerController?.start();
  }

  @override
  void dispose() {
    _successAnimController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  /// Request foreground location permission upon entering the scanner screen.
  Future<void> _checkInitialLocationPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied && mounted) {
          _showResult(
            message: AppConstants.locationPermissionDenied,
            success: false,
          );
        } else if (permission == LocationPermission.deniedForever && mounted) {
          _showResult(
            message: AppConstants.locationPermissionPermanentlyDenied,
            success: false,
          );
        }
      } else if (permission == LocationPermission.deniedForever && mounted) {
        _showResult(
          message: AppConstants.locationPermissionPermanentlyDenied,
          success: false,
        );
      }
    } catch (e) {
      debugPrint('[Sentinel] Initial location permission check error: $e');
    }
  }

  /// Verifies location services and permissions, returning a fresh high-accuracy position.
  Future<Position?> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showResult(
        message: AppConstants.locationServiceDisabled,
        success: false,
      );
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showResult(
          message: AppConstants.locationPermissionDenied,
          success: false,
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showResult(
        message: AppConstants.locationPermissionPermanentlyDenied,
        success: false,
      );
      return null;
    }

    try {
      // Fresh high-accuracy location fix (not cached/stale)
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('[Sentinel] GPS location fix error: $e');
      _showResult(
        message: AppConstants.gpsSignalWeak,
        success: false,
      );
      return null;
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    // Strict guard against concurrent execution or double-scanning
    if (!widget.isActive || _isProcessing || _isSuccess) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final qrCode = barcode.rawValue!;
    final provider = context.read<EmployeeHomeProvider>();
    final att = provider.attendance;

    // Immediately stop camera scan feed to prevent rapid double-scanning frames
    setState(() => _isProcessing = true);
    await _scannerController?.stop();
    if (!mounted) return;

    if (att != null && att.isCheckedOut) {
      _showResult(
        message: 'You have already checked out for today.',
        success: false,
      );
      return;
    }

    final bool isCheckIn = (att == null || att.isNotCheckedIn);

    // Cooldown guard: prevent accidental check-out immediately after check-in
    if (!isCheckIn && _lastActionTime != null) {
      final elapsed = DateTime.now().difference(_lastActionTime!).inSeconds;
      if (elapsed < 30) {
        _showResult(
          message:
              'Check-in was just recorded. Please wait ${30 - elapsed}s before checking out.',
          success: false,
        );
        return;
      }
    }

    // Acquire fresh high-accuracy position before submitting
    final position = await _determinePosition();
    if (position == null) {
      // Error banner already triggered by _determinePosition
      return;
    }

    bool success = await _executeAttendanceCall(
      provider: provider,
      isCheckIn: isCheckIn,
      qrCode: qrCode,
      position: position,
    );

    // If backend returns 400 MOCK_LOCATION_FLAG_REQUIRED: client bug, log and retry once
    if (!success) {
      final statusCode = provider.lastStatusCode;
      final errorData = provider.lastErrorData;
      final errorCode = errorData?['error']?.toString();

      if (statusCode == 400 && errorCode == 'MOCK_LOCATION_FLAG_REQUIRED') {
        debugPrint(
          '[Sentinel] Client bug: 400 MOCK_LOCATION_FLAG_REQUIRED returned by backend. '
          'Retrying location fetch and resubmitting once automatically...',
        );
        try {
          final freshPosition = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
          success = await _executeAttendanceCall(
            provider: provider,
            isCheckIn: isCheckIn,
            qrCode: qrCode,
            position: freshPosition,
          );
        } catch (e) {
          debugPrint('[Sentinel] Retry location fetch failed: $e');
        }
      }
    }

    if (!mounted) return;

    if (success) {
      // Haptic confirmation
      HapticFeedback.heavyImpact();

      final newAtt = provider.attendance;
      final bool wasCheckOut = (newAtt?.isCheckedOut == true || !isCheckIn);
      final formattedTime = DateFormat('hh:mm a').format(DateTime.now());

      setState(() {
        _isSuccess = true;
        _isProcessing = false;
        _successType = wasCheckOut ? 'Check-Out' : 'Check-In';
        _successTime = formattedTime;
        _lastActionTime = DateTime.now();
      });

      // Launch rich success animation and countdown
      _successAnimController.forward(from: 0.0);
    } else {
      _showResult(
        message: _mapErrorMessage(provider),
        success: false,
      );
    }
  }

  Future<bool> _executeAttendanceCall({
    required EmployeeHomeProvider provider,
    required bool isCheckIn,
    required String qrCode,
    required Position position,
  }) async {
    if (isCheckIn) {
      return await provider.checkIn(
        qrCode,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy_m: position.accuracy,
        is_mock_location: position.isMocked,
      );
    } else {
      return await provider.checkOut(
        qrCode,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy_m: position.accuracy,
        is_mock_location: position.isMocked,
      );
    }
  }

  /// Maps API and geofencing responses to clear in-screen error banners.
  String _mapErrorMessage(EmployeeHomeProvider provider) {
    final statusCode = provider.lastStatusCode;
    final errorData = provider.lastErrorData;
    final errorCode = errorData?['error']?.toString();

    // 403 OUTSIDE_GEOFENCE -> show the distance versus the allowed radius from the response body
    if (statusCode == 403 && errorCode == 'OUTSIDE_GEOFENCE') {
      final distance = errorData?['distance_m'];
      final radius = errorData?['allowed_radius_m'];
      if (distance != null && radius != null) {
        return 'Outside geofence: ${distance}m from office (allowed: ${radius}m)';
      }
      return 'Outside allowed geofence boundary';
    }

    // 403 MOCK_LOCATION -> "Mock location detected - please disable it and try again"
    if (statusCode == 403 && errorCode == 'MOCK_LOCATION') {
      return 'Mock location detected - please disable it and try again';
    }

    // 422 -> "GPS signal too weak, move to open sky and retry"
    if (statusCode == 422 || errorCode == 'ACCURACY_TOO_LOW') {
      return 'GPS signal too weak, move to open sky and retry';
    }

    // 400 LOCATION_REQUIRED -> "Location is required, please enable GPS"
    if (statusCode == 400 && errorCode == 'LOCATION_REQUIRED') {
      return 'Location is required, please enable GPS';
    }

    // 400 MOCK_LOCATION_FLAG_REQUIRED fallback if retry also failed
    if (statusCode == 400 && errorCode == 'MOCK_LOCATION_FLAG_REQUIRED') {
      return 'Location verification failed. Please try again.';
    }

    return provider.error ?? 'QR verification failed';
  }

  void _showResult({required String message, required bool success}) {
    if (!mounted) return;
    setState(() {
      _resultMessage = message;
      _resultSuccess = success;
    });

    // For failures, allow user to read error and restart scanner after 3s delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.isActive && !_isSuccess) {
        setState(() {
          _isProcessing = false;
          _resultMessage = null;
          _resultSuccess = null;
        });
        _scannerController?.start();
      }
    });
  }

  void _navigateToHome() {
    if (!mounted) return;
    _pauseScanner();

    if (widget.onNavigateToHome != null) {
      widget.onNavigateToHome!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera preview (only mounted when active and not in success state)
        if (_scannerController != null && widget.isActive)
          MobileScanner(
            controller: _scannerController!,
            onDetect: _onDetect,
          )
        else
          Container(
            color: SentinelTheme.backgroundDark,
            child: const Center(
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 64,
                color: SentinelTheme.textMuted,
              ),
            ),
          ),

        // Default viewfinder overlay
        if (!_isSuccess) _buildOverlay(),

        // Error / status banner (when active and not in success view)
        if (_resultMessage != null && !_isSuccess) _buildResultBanner(),

        // Success Confirmation and Auto-Route Animation View
        if (_isSuccess) _buildSuccessView(),
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
                      ? 'Verifying location & QR session...'
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
                  color: Colors.black.withValues(alpha: 0.6),
                ),
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
                  color: Colors.black.withValues(alpha: 0.6),
                ),
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
                      horizontal: 20,
                      vertical: 10,
                    ),
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
                ? SentinelTheme.accentGreen.withValues(alpha: 0.95)
                : SentinelTheme.accentRed.withValues(alpha: 0.95),
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
                    fontSize: 14,
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

  /// Full-screen animated success view with elastic checkmark, details card,
  /// progress bar, and instant home redirection.
  Widget _buildSuccessView() {
    final isCheckIn = _successType == 'Check-In';
    final accentColor =
        isCheckIn ? SentinelTheme.accentGreen : SentinelTheme.primaryCyan;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: SentinelTheme.backgroundDark.withValues(alpha: 0.96),
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _successAnimController,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Animated Checkmark Icon with Glowing Rings
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing outer glow ring
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(
                            alpha: 0.12 * _glowAnimation.value,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(
                                alpha: 0.25 * _glowAnimation.value,
                              ),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),

                      // Middle border ring
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.35),
                            width: 2.5,
                          ),
                          color: SentinelTheme.surfaceLight,
                        ),
                      ),

                      // Bouncing Checkmark
                      Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                accentColor,
                                accentColor.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_rounded,
                              color: SentinelTheme.backgroundDark,
                              size: 52,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    '$_successType Successful!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    isCheckIn
                        ? 'Your check-in has been verified and recorded.'
                        : 'Your check-out has been verified. See you tomorrow!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: SentinelTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: SentinelTheme.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          icon: Icons.access_time_filled_rounded,
                          iconColor: SentinelTheme.primaryCyan,
                          label: 'Time Recorded',
                          value: _successTime ?? '--:--',
                        ),
                        const Divider(
                          color: SentinelTheme.dividerColor,
                          height: 24,
                        ),
                        _buildSummaryRow(
                          icon: Icons.satellite_alt_rounded,
                          iconColor: SentinelTheme.accentGreen,
                          label: 'Location Verification',
                          value: 'GPS Geofence Verified',
                        ),
                        const Divider(
                          color: SentinelTheme.dividerColor,
                          height: 24,
                        ),
                        _buildSummaryRow(
                          icon: isCheckIn
                              ? Icons.login_rounded
                              : Icons.logout_rounded,
                          iconColor: accentColor,
                          label: 'Attendance State',
                          value: isCheckIn ? 'Checked In' : 'Checked Out',
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Redirection countdown progress bar
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Returning to Home...',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: SentinelTheme.textMuted,
                            ),
                          ),
                          Text(
                            'Auto-redirecting',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          minHeight: 6,
                          backgroundColor:
                              SentinelTheme.surfaceLight.withValues(alpha: 0.8),
                          valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // "Back to Home Now" Button for instant return
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SentinelTheme.surfaceElevated,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: accentColor.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.home_rounded, size: 20),
                      label: Text(
                        'Back to Home Now',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: SentinelTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
