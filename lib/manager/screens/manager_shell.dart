import 'package:flutter/material.dart';
import '../../shared_widgets/sentinel_app_bar.dart';
import '../../shared_widgets/profile_screen.dart';
import 'manager_home_screen.dart';
import 'team_attendance_screen.dart';
import 'leave_approval_screen.dart';

/// Bottom navigation shell for managers.
///
/// 4 tabs: Home, Team, Approvals, Profile. Uses [IndexedStack] to preserve state.
class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ManagerHomeScreen(),
    TeamAttendanceScreen(),
    LeaveApprovalScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Team Attendance',
    'Leave Approvals',
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
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded),
              activeIcon: Icon(Icons.groups_rounded),
              label: 'Team',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.approval_rounded),
              activeIcon: Icon(Icons.approval_rounded),
              label: 'Approvals',
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
