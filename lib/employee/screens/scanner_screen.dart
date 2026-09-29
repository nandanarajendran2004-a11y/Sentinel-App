import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../providers/employee_home_provider.dart';

/// QR code scanner screen for employee check-in/check-out.
///
/// Opens the camera, scans the kiosk's rotating QR code, captures
/// a fresh high-accuracy GPS fix, and submits it to the backend.
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
    _checkInitialLocationPermission();
  }

  @override
  void dispose() {
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
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);

    final qrCode = barcode.rawValue!;
    final provider = context.read<EmployeeHomeProvider>();
    final att = provider.attendance;

    if (att != null && att.isCheckedOut) {
      _showResult(
        message: 'You have already checked out for today.',
        success: false,
      );
      return;
    }

    // Acquire fresh high-accuracy position before submitting
    final position = await _determinePosition();
    if (position == null) {
      // Error banner already triggered by _determinePosition
      return;
    }

    final bool isCheckIn = (att == null || att.isNotCheckedIn);

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
      final newAtt = provider.attendance;
      if (newAtt?.isCheckedOut == true || !isCheckIn) {
        _showResult(
          message: 'Check-out successful!',
          success: true,
        );
      } else {
        _showResult(
          message: 'Check-in successful!',
          success: true,
        );
      }
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

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _resultMessage = null;
          _resultSuccess = null;
        });
      }
    });
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
