import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared_widgets/sentinel_app_bar.dart';
import '../../shared_widgets/profile_screen.dart';
import '../providers/employee_home_provider.dart';
import 'employee_home_screen.dart';
import 'scanner_screen.dart';
import 'leave_list_screen.dart';

/// Bottom navigation shell for employees.
///
/// 4 tabs: Home, Scanner, Leave, Profile. Uses [IndexedStack] to preserve state.
class EmployeeShell extends StatefulWidget {
  const EmployeeShell({super.key});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _currentIndex = 0;

  final List<String> _titles = const [
    'Home',
    'Scanner',
    'Leave',
    'Profile',
  ];

  void _navigateToHome() {
    setState(() => _currentIndex = 0);
    // Refresh today's attendance data to ensure home screen displays the latest status
    context.read<EmployeeHomeProvider>().fetchTodayAttendance();
  }

  void _navigateToScanner() {
    setState(() => _currentIndex = 1);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      EmployeeHomeScreen(onGoToScanner: _navigateToScanner),
      ScannerScreen(
        isActive: _currentIndex == 1,
        onNavigateToHome: _navigateToHome,
      ),
      const LeaveListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: SentinelAppBar(title: _titles[_currentIndex]),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              activeIcon: Icon(Icons.qr_code_scanner_rounded),
              label: 'Scanner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_rounded),
              activeIcon: Icon(Icons.event_note_rounded),
              label: 'Leave',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
