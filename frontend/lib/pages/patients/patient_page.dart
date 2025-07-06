import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../providers/patient_provider.dart';
import '../../../models/patient_data.dart';
import '../../../models/hospital_data.dart';
import '../../../models/doctor_data.dart';
import 'patient_profile_page.dart';
import 'patient_appointments_page.dart';
import 'patient_diagnosis_page.dart';

/// ---------------------------------------------------------------------------
/// MODERN PATIENT PAGE WITH ADVANCED UI
/// - Modern gradient theme with pink accents
/// - Clean card designs with shadows and rounded corners
/// - Advanced bottom navigation with modern styling
/// - Professional typography and spacing
/// - Mobile-first responsive design
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
  // Modern color palette
  static const Color primaryPink = Color(0xFFEC407A);
  static const Color lightPink = Color(0xFFFFE0E6);
  static const Color darkPink = Color(0xFFD81B60);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

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
      backgroundColor: backgroundColor,
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
                _buildModernAppBar(patientData),
                SliverFillRemaining(
                  child: _buildPageContent(patientData),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryPink.withOpacity(0.1),
            backgroundColor,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Loading your health dashboard...',
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryPink.withOpacity(0.1),
            backgroundColor,
          ],
        ),
      ),
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
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
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
                  backgroundColor: primaryPink,
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

  Widget _buildModernAppBar(PatientData patientData) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: primaryPink,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryPink,
                darkPink,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            const SizedBox(height: 2),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_none,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          _titleForIndex(_currentIndex),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
        ),
        ),
        centerTitle: false,
      ),
        actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _ModernSearchBottomSheet(),
            );
          },
        ),
          if (widget.doctorId != null && widget.token != null)
            IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 18,
              ),
            ),
              onPressed: () {
                print("Manually triggering API call");
                final patientProvider = PatientProvider();
                patientProvider
                    .getPatientsForDoctor(
                  token: widget.token!,
                  doctorId: widget.doctorId!,
                )
                    .then((patients) {
                  print("Manual API call returned ${patients.length} patients");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                    content: Text("Found ${patients.length} patients"),
                    backgroundColor: primaryPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                  );
                }).catchError((error) {
                  print("Manual API call error: $error");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Error: $error"),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                  );
                });
              },
            ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildPageContent(PatientData patientData) {
          final List<Widget> pages = [
      ModernHomeTab(patientData: patientData),
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

  Widget _buildModernBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildNavItem(0, Icons.home_rounded, 'Home')),
              Expanded(child: _buildNavItem(1, Icons.calendar_today_rounded, 'Appts')),
              Expanded(child: _buildNavItem(2, Icons.medical_services_rounded, 'Reports')),
              Expanded(child: _buildNavItem(3, Icons.person_rounded, 'Profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryPink.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? primaryPink : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryPink : textSecondary,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
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

// -----------------------------------------------------------------------------
// MODERN SEARCH BOTTOM SHEET
// -----------------------------------------------------------------------------
class _ModernSearchBottomSheet extends StatefulWidget {
  const _ModernSearchBottomSheet({Key? key}) : super(key: key);

  @override
  State<_ModernSearchBottomSheet> createState() => _ModernSearchBottomSheetState();
}

class _ModernSearchBottomSheetState extends State<_ModernSearchBottomSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
        return Container(
      decoration: const BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (ctx, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
              const Text(
                  "Search Health Records",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _PatientPageState.textPrimary,
                  ),
              ),
              const SizedBox(height: 8),
                Text(
                  "Find appointments, diagnoses, and more",
                  style: TextStyle(
                    fontSize: 16,
                    color: _PatientPageState.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: _PatientPageState.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                controller: _searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "Search your health records...",
                      hintStyle: TextStyle(
                        color: _PatientPageState.textSecondary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _PatientPageState.primaryPink,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Quick search options
                const Text(
                  "Quick Search",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _PatientPageState.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
                
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildQuickSearchChip("Appointments", Icons.calendar_today),
                    _buildQuickSearchChip("Diagnoses", Icons.medical_services),
                    _buildQuickSearchChip("Doctors", Icons.person),
                    _buildQuickSearchChip("Medications", Icons.medication),
                    _buildQuickSearchChip("Test Results", Icons.analytics),
                  ],
                ),
                
                const Spacer(),
                
                // Action buttons
              Row(
                children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _PatientPageState.primaryPink,
                          side: const BorderSide(color: _PatientPageState.primaryPink),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                              content: Text("Searching for: ${_searchCtrl.text}"),
                              backgroundColor: _PatientPageState.primaryPink,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                          backgroundColor: _PatientPageState.primaryPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Search",
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
        );
      },
      ),
    );
  }

  Widget _buildQuickSearchChip(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: _PatientPageState.lightPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _searchCtrl.text = label;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: _PatientPageState.primaryPink,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: _PatientPageState.primaryPink,
                    fontWeight: FontWeight.w500,
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

// -----------------------------------------------------------------------------
// MODERN HOME TAB
// -----------------------------------------------------------------------------
class ModernHomeTab extends StatelessWidget {
  final PatientData? patientData;
  const ModernHomeTab({Key? key, this.patientData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health status card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _PatientPageState.primaryPink.withOpacity(0.1),
                  _PatientPageState.lightPink.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _PatientPageState.primaryPink.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _PatientPageState.primaryPink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
                            'Health Status',
            style: TextStyle(
                              fontSize: 20,
              fontWeight: FontWeight.bold,
                              color: _PatientPageState.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            patientData?.status ?? 'Active',
                            style: TextStyle(
                              fontSize: 16,
                              color: _PatientPageState.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _PatientPageState.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'View Appointments',
                  Icons.calendar_today,
                  _PatientPageState.primaryPink,
                  () {
                    // Navigate to appointments tab
                    if (context.findAncestorStateOfType<_PatientPageState>() != null) {
                      context.findAncestorStateOfType<_PatientPageState>()!.setState(() {
                        context.findAncestorStateOfType<_PatientPageState>()!._currentIndex = 1;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  'View Reports',
                  Icons.description,
                  Colors.blue,
                  () {
                    // Navigate to reports tab
                    if (context.findAncestorStateOfType<_PatientPageState>() != null) {
                      context.findAncestorStateOfType<_PatientPageState>()!.setState(() {
                        context.findAncestorStateOfType<_PatientPageState>()!._currentIndex = 2;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Clinic information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _PatientPageState.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _PatientPageState.primaryPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: _PatientPageState.primaryPink,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                  const Text(
                      'Curanics Health Center',
                    style: TextStyle(
                        fontSize: 20,
                      fontWeight: FontWeight.bold,
                        color: _PatientPageState.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildModernInfoRow(
                  Icons.access_time,
                  'Operating Hours',
                  'Monday - Friday: 9:00 AM - 5:00 PM',
                  ),
                  const SizedBox(height: 16),
                _buildModernInfoRow(
                  Icons.phone,
                  'Contact',
                  '+1 (555) 123-4567',
                ),
                const SizedBox(height: 16),
                _buildModernInfoRow(
                  Icons.email,
                  'Email',
                  'info@curanics.com',
                ),
                const SizedBox(height: 16),
                _buildModernInfoRow(
                  Icons.location_on,
                  'Address',
                  '123 Health Street, Medical District, City 12345',
                ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _PatientPageState.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _PatientPageState.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _PatientPageState.primaryPink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: _PatientPageState.primaryPink,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                label,
            style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _PatientPageState.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: _PatientPageState.textSecondary,
                ),
          ),
        ],
      ),
        ),
      ],
    );
  }
}



// ... existing code (AppointmentsTab, TicketsTab, NotificationsTab, ProfileTab)
// ... existing SVG icons
