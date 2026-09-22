import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'auth/providers/auth_provider.dart';
import 'auth/screens/login_screen.dart';
import 'auth/screens/totp_setup_screen.dart';
import 'auth/screens/totp_verify_screen.dart';
import 'employee/providers/employee_home_provider.dart';
import 'employee/providers/leave_provider.dart';
import 'employee/screens/employee_shell.dart';
import 'manager/providers/manager_home_provider.dart';
import 'manager/providers/team_attendance_provider.dart';
import 'manager/providers/leave_approval_provider.dart';
import 'manager/screens/manager_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait for mobile
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: SentinelTheme.surfaceDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const SentinelApp());
}

class SentinelApp extends StatelessWidget {
  const SentinelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeHomeProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => ManagerHomeProvider()),
        ChangeNotifierProvider(create: (_) => TeamAttendanceProvider()),
        ChangeNotifierProvider(create: (_) => LeaveApprovalProvider()),
      ],
      child: MaterialApp(
        title: 'Sentinel',
        debugShowCheckedModeBanner: false,
        theme: SentinelTheme.darkTheme,
        navigatorKey: ApiClient.navigatorKey,
        home: const _SplashGate(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/totp-setup': (_) => const TotpSetupScreen(),
          '/totp-verify': (_) => const TotpVerifyScreen(),
          '/employee': (_) => const EmployeeShell(),
          '/manager': (_) => const ManagerShell(),
        },
      ),
    );
  }
}

/// Splash gate — tries to auto-login from stored JWT, then routes accordingly.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();

    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Brief delay for the splash animation to show
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final hasSession = await auth.tryAutoLogin();

    if (!mounted) return;

    if (hasSession && auth.user != null) {
      if (auth.user!.isManager) {
        Navigator.of(context).pushReplacementNamed('/manager');
      } else if (auth.user!.isEmployee) {
        Navigator.of(context).pushReplacementNamed('/employee');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: SentinelTheme.backgroundGradient,
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SentinelTheme.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color:
                            SentinelTheme.primaryCyan.withValues(alpha: 0.35),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'SENTINEL',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: SentinelTheme.textPrimary,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Employee Attendance Management',
                  style: TextStyle(
                    color: SentinelTheme.textMuted,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: SentinelTheme.primaryCyan,
                    strokeWidth: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
