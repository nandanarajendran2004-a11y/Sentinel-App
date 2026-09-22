import 'package:flutter/material.dart';
import '../../shared_widgets/sentinel_app_bar.dart';
import '../../shared_widgets/profile_screen.dart';
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

  final List<Widget> _screens = const [
    EmployeeHomeScreen(),
    ScannerScreen(),
    LeaveListScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    'Home',
    'Scanner',
    'Leave',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SentinelAppBar(title: _titles[_currentIndex]),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
