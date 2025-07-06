import 'package:flutter/material.dart';
import '../../models/patient_data.dart';
import '../../models/hospital_data.dart';
import '../../models/doctor_data.dart';
import '../../providers/patient_provider.dart';
import '../../providers/hospital_provider.dart';
import '../../providers/doctor_provider.dart';

class PatientProfilePage extends StatefulWidget {
  final String token;
  final String patientId;

  const PatientProfilePage({
    Key? key,
    required this.token,
    required this.patientId,
  }) : super(key: key);

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  // Modern color palette (matching patient_page.dart)
  static const Color primaryPink = Color(0xFFEC407A);
  static const Color lightPink = Color(0xFFFFE0E6);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  final PatientProvider _patientProvider = PatientProvider();
  final HospitalProvider _hospitalProvider = HospitalProvider();
  final DoctorProvider _doctorProvider = DoctorProvider();

  late Future<PatientData> _patientData;
  Future<HospitalData>? _hospitalData;
  Future<List<DoctorData>>? _doctorsData;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  void _loadPatientData() {
    _patientData = _patientProvider
        .getPatients(token: widget.token, patientId: widget.patientId)
        .then((patients) {
      if (patients.isNotEmpty) {
        final patient = patients.first;
        setState(() {
          _hospitalData = _hospitalProvider
              .getHospitals(token: widget.token, hospitalId: patient.hospitalId)
              .then((hospitals) {
            if (hospitals.isNotEmpty) {
              return hospitals.first;
            } else {
              throw Exception('Hospital data not found');
            }
          });
          // Fetch all doctors assigned to the patient
          if (patient.doctorIds.isNotEmpty) {
            _doctorsData = Future.wait(
              patient.doctorIds.map((doctorId) => 
                _doctorProvider.getDoctorPublicData(
                  token: widget.token, 
                  doctorId: doctorId
                )
              ).toList()
            );
          } else {
            _doctorsData = Future.value(<DoctorData>[]);
          }
        });
        return patient;
      } else {
        throw Exception('Patient data not found');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Section
            FutureBuilder<PatientData>(
              future: _patientData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCard();
                }
                if (snapshot.hasError) {
                  return _buildErrorCard(snapshot.error.toString());
                }
                if (!snapshot.hasData) {
                  return _buildErrorCard('No data available');
                }

                final patient = snapshot.data!;
                return _buildProfileHeader(patient);
              },
            ),
            const SizedBox(height: 24),

            // Personal Information Section
            _buildModernCard(
              'Personal Information',
              Icons.person,
              primaryPink,
              child: FutureBuilder<PatientData>(
                future: _patientData,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const Text('No data available');
                  }

                  final patient = snapshot.data!;
                  return Column(
                    children: [
                      _buildModernInfoRow(
                        Icons.person_outline,
                        'Full Name',
                        patient.name,
                      ),
                      const SizedBox(height: 16),
                      _buildModernInfoRow(
                        Icons.email_outlined,
                        'Email Address',
                        patient.email,
                      ),
                      const SizedBox(height: 16),
                      _buildModernInfoRow(
                        Icons.phone_outlined,
                        'Phone Number',
                        patient.mobileNumber,
                      ),
                      const SizedBox(height: 16),
                      _buildModernInfoRow(
                        Icons.cake_outlined,
                        'Date of Birth',
                        patient.birthDate.toString().split(' ')[0],
                      ),
                      const SizedBox(height: 16),
                      _buildModernInfoRow(
                        Icons.badge_outlined,
                        'Patient ID',
                        patient.id,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Hospital Information Section
            _buildModernCard(
              'Healthcare Facility',
              Icons.local_hospital,
              Colors.blue,
              child: FutureBuilder<HospitalData>(
                future: _hospitalData,
                builder: (context, snapshot) {
                  if (_hospitalData == null) {
                    return _buildNoDataMessage('No hospital assigned');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildNoDataMessage('Error loading hospital data');
                  }
                  if (!snapshot.hasData) {
                    return _buildNoDataMessage('No hospital assigned');
                  }
                  
                  final hospital = snapshot.data!;
                  return Column(
                    children: [
                      _buildModernInfoRow(
                        Icons.business,
                        'Hospital Name',
                        hospital.name,
                      ),
                      const SizedBox(height: 16),
                      _buildModernInfoRow(
                        Icons.location_on_outlined,
                        'Address',
                        hospital.address,
                      ),
                      if (hospital.mobileNumbers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildModernInfoRow(
                          Icons.phone_outlined,
                          'Phone',
                          hospital.mobileNumbers.first,
                        ),
                      ],
                      if (hospital.emails.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildModernInfoRow(
                          Icons.email_outlined,
                          'Email',
                          hospital.emails.first,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Doctors Section
            _buildModernCard(
              'Healthcare Team',
              Icons.medical_services,
              Colors.green,
              child: FutureBuilder<List<DoctorData>>(
                future: _doctorsData,
                builder: (context, snapshot) {
                  if (_doctorsData == null) {
                    return _buildNoDataMessage('No doctors assigned');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildNoDataMessage('Error loading doctors data');
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildNoDataMessage('No doctors assigned');
                  }
                  
                  final doctors = snapshot.data!;
                  return Column(
                    children: doctors.asMap().entries.map((entry) {
                      final index = entry.key;
                      final doctor = entry.value;
                      return Column(
                        children: [
                          if (index > 0) const SizedBox(height: 20),
                          _buildDoctorCard(doctor),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Account Actions
            _buildModernCard(
              'Account Settings',
              Icons.settings,
              Colors.orange,
              child: Column(
                children: [
                  _buildActionButton(
                    'Edit Profile',
                    Icons.edit,
                    primaryPink,
                    () {
                      // Navigate to edit profile
                      _showEditProfileDialog();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    'Change Password',
                    Icons.lock,
                    Colors.blue,
                    () {
                      // Navigate to change password
                      _showChangePasswordDialog();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    'Privacy Settings',
                    Icons.privacy_tip,
                    Colors.green,
                    () {
                      // Navigate to privacy settings
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    'Sign Out',
                    Icons.logout,
                    Colors.red,
                    () {
                      // Sign out logic
                      _showSignOutDialog();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(PatientData patient) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryPink,
            primaryPink.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: primaryPink,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            patient.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Patient ID: ${patient.id}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard(
    String title,
    IconData icon,
    Color accentColor, {
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
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
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
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
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: textSecondary,
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
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(DoctorData doctor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.medical_services,
              color: Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.phone,
              color: Colors.green,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: primaryPink,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade400,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: textSecondary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
        content: const Text('Profile editing functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: const Text('Password change functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Add sign out logic here
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
