import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

/// Branded app bar with the Sentinel gradient accent line.
class SentinelAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const SentinelAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 2);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: showBackButton,
          actions: actions,
          backgroundColor: SentinelTheme.surfaceDark,
          elevation: 0,
        ),
        // Gradient accent line
        Container(
          height: 2,
          decoration: const BoxDecoration(
            gradient: SentinelTheme.primaryGradient,
          ),
        ),
      ],
    );
  }
}
