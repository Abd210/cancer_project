import 'dart:async';
import 'package:flutter/material.dart';
import '../../../providers/patient_provider.dart';
import '../../../models/patient_data.dart';
import 'patient_profile_page.dart';
import 'patient_appointments_page.dart';
import 'patient_diagnosis_page.dart';
import 'components/patient_theme.dart';
import 'components/patient_app_bar.dart';
import 'components/patient_bottom_nav.dart';
import 'components/patient_home_tab.dart';
import 'patient_platform_page.dart';

/// ---------------------------------------------------------------------------
/// MODERN PATIENT PAGE WITH ADVANCED UI
/// - Modern gradient theme with pink accents
/// - Clean card designs with shadows and rounded corners
/// - Advanced bottom navigation with modern styling
/// - Professional typography and spacing
/// - Mobile-first responsive design
/// - Separated into reusable components
/// ---------------------------------------------------------------------------
class PatientPage extends StatefulWidget {
  final String? doctorId;
  final String? token;
  final String? patientId;

  const PatientPage({
    Key? key,
    this.doctorId,
    this.token,
    this.patientId,
  }) : super(key: key);

  @override
  State<PatientPage> createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final PatientProvider _patientProvider = PatientProvider();
  late Future<PatientData> _patientDataFuture;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    
    _patientDataFuture = _patientProvider
        .getPatients(
      token: widget.token ?? '',
      patientId: widget.patientId ?? '',
    )
        .then((list) {
      if (list.isEmpty) {
        throw Exception("Patient data not found.");
      }
      return list.first;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PatientTheme.backgroundColor,
      body: FutureBuilder<PatientData>(
        future: _patientDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }
          if (snapshot.hasError) {
            return _buildErrorScreen(snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return _buildErrorScreen('No patient data available');
          }

          final patientData = snapshot.data!;

          return FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                PatientAppBar(
                  patientData: patientData,
                  currentIndex: _currentIndex,
                  doctorId: widget.doctorId,
                  token: widget.token,
                  patientDataFuture: _patientDataFuture,
                  onNavigateToTab: (index) => setState(() => _currentIndex = index),
                  onSwitchLayout: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => PatientPlatformPage(
                          token: widget.token ?? '',
                          patientId: widget.patientId ?? '',
                          doctorId: widget.doctorId,
                        ),
                      ),
                    );
                  },
                ),
                SliverFillRemaining(
                  child: _buildPageContent(patientData),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: PatientBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: PatientTheme.gradientBackground,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(PatientTheme.primaryPink),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Loading your health dashboard...',
              style: TextStyle(
                fontSize: 16,
                color: PatientTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Container(
      decoration: PatientTheme.gradientBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: PatientTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: TextStyle(
                  fontSize: 16,
                  color: PatientTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => setState(() {
                  _patientDataFuture = _patientProvider
                      .getPatients(
                    token: widget.token ?? '',
                    patientId: widget.patientId ?? '',
                  )
                      .then((list) {
                    if (list.isEmpty) {
                      throw Exception("Patient data not found.");
                    }
                    return list.first;
                  });
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PatientTheme.primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildPageContent(PatientData patientData) {
          final List<Widget> pages = [
      PatientHomeTab(patientData: patientData),
            PatientAppointmentsPage(
              token: widget.token ?? '',
              patientId: widget.patientId ?? '',
            ),
            PatientDiagnosisPage(
              token: widget.token ?? '',
              patientId: widget.patientId ?? '',
              patientData: patientData,
            ),
            PatientProfilePage(
              token: widget.token ?? '',
              patientId: widget.patientId ?? '',
            ),
          ];

          return IndexedStack(
            index: _currentIndex,
            children: pages,
    );
  }
} 