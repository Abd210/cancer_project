import 'package:flutter/material.dart';
import '../../../models/patient_data.dart';
import 'patient_theme.dart';

class PatientHomeTab extends StatelessWidget {
  final PatientData patientData;

  const PatientHomeTab({
    Key? key,
    required this.patientData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health status overview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: PatientTheme.cardDecoration.copyWith(
              gradient: LinearGradient(
                colors: [
                  PatientTheme.lightPink.withOpacity(0.3),
                  PatientTheme.lightPink.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Health Status',
                        style: PatientTheme.subHeaderStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patientData.status,
                        style: const TextStyle(
                          fontSize: 14,
                          color: PatientTheme.textSecondary,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Clinic information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: PatientTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PatientTheme.primaryPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: PatientTheme.primaryPink,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Curanics Health Center',
                      style: PatientTheme.subHeaderStyle,
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

  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: PatientTheme.primaryPink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: PatientTheme.primaryPink,
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
                  color: PatientTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: PatientTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 