import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable header row with colored icon and bold title.
///
/// Example:
///   const PageHeader(icon: Icons.admin_panel_settings, title: 'Admins Management'),
class PageHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const PageHeader({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 32, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }
} 