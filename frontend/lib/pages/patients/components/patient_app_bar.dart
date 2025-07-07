import 'package:flutter/material.dart';
import '../../../models/patient_data.dart';
import 'patient_theme.dart';
import 'patient_search.dart';
import '../../authentication/log_reg.dart';

class PatientAppBar extends StatelessWidget {
  final PatientData patientData;
  final int currentIndex;
  final String? doctorId;
  final String? token;
  final Future<PatientData> patientDataFuture;
  final Function(int) onNavigateToTab;
  final VoidCallback? onSwitchLayout;

  const PatientAppBar({
    Key? key,
    required this.patientData,
    required this.currentIndex,
    required this.doctorId,
    required this.token,
    required this.patientDataFuture,
    required this.onNavigateToTab,
    this.onSwitchLayout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: PatientTheme.primaryPink,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                PatientTheme.primaryPink,
                PatientTheme.darkPink,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // User info section
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              patientData.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Notification button removed until functionality is ready
                          _buildActionButton(
                            icon: Icons.search,
                            onPressed: () {
                              PatientSearch.showSearchDialog(context, patientDataFuture, onNavigateToTab);
                            },
                          ),
                          if (onSwitchLayout != null) ...[
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.desktop_windows,
                              onPressed: onSwitchLayout!,
                            ),
                          ],
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.logout,
                            onPressed: () => _showSignOutDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Dynamic page title
                  Text(
                    _titleForIndex(currentIndex),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (doctorId != null && token != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: _buildActionButton(
              icon: Icons.refresh,
              onPressed: () {
                // Add refresh functionality here if needed
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Refreshing data...'),
                    backgroundColor: PatientTheme.primaryPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        if (doctorId == null || token == null)
          const SizedBox(width: 16),
      ],
    );
  }

  // Helper method to build consistent action buttons
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced signout dialog with proper logout functionality
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                PatientTheme.backgroundColor,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PatientTheme.primaryPink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  color: PatientTheme.primaryPink,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: PatientTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to sign out of your account?',
                style: TextStyle(
                  fontSize: 16,
                  color: PatientTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: PatientTheme.textSecondary.withOpacity(0.3)),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PatientTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _performSignOut(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PatientTheme.primaryPink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Perform actual logout
  void _performSignOut(BuildContext context) {
    // Use root navigator to ensure dialogs are shown above all content
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    // Show loading indicator briefly
    rootNavigator.push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => Container(
          color: Colors.black54,
          child: const Center(
            child: CircularProgressIndicator(
              color: PatientTheme.primaryPink,
            ),
          ),
        ),
      ),
    );

    // After a short delay perform navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (rootNavigator.canPop()) {
        rootNavigator.pop(); // Remove loading overlay
      }

      // Navigate to login screen, removing all previous routes
      rootNavigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LogIn()),
        (route) => false,
      );

      // Show feedback (use snackbar on new Login page's scaffold)
      // Delay to ensure the new page is built first
      Future.delayed(const Duration(milliseconds: 300), () {
        if (rootNavigator.context.mounted) {
          ScaffoldMessenger.of(rootNavigator.context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Successfully signed out'),
                ],
              ),
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    });
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return "Health Dashboard";
      case 1:
        return "My Appointments";
      case 2:
        return "Diagnosis & Reports";
      case 3:
      default:
        return "My Profile";
    }
  }
} 