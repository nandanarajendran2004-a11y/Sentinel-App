import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sentinel_app/employee/providers/employee_home_provider.dart';
import 'package:sentinel_app/employee/screens/scanner_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScannerScreen Widget Tests', () {
    testWidgets('renders placeholder when isActive is false', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => EmployeeHomeProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ScannerScreen(
                isActive: false,
              ),
            ),
          ),
        ),
      );

      // When inactive, camera preview is not mounted, placeholder icon is rendered
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });

    testWidgets('ScannerScreen accepts onNavigateToHome callback', (tester) async {
      bool navigatedHome = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => EmployeeHomeProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ScannerScreen(
                isActive: false,
                onNavigateToHome: () {
                  navigatedHome = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(navigatedHome, isFalse);
    });
  });
}
