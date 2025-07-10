import 'package:flutter/material.dart';
import '../../../models/patient_data.dart';
import 'patient_theme.dart';

class PatientSearch {
  static void showSearchDialog(
    BuildContext context,
    Future<PatientData> patientDataFuture,
    Function(int) onNavigateToTab,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PatientTheme.primaryPink.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search,
                      color: PatientTheme.primaryPink,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Search Health Records',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: PatientTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search appointments, reports, diagnoses...',
                  prefixIcon: const Icon(Icons.search, color: PatientTheme.primaryPink),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: PatientTheme.textSecondary.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: PatientTheme.primaryPink, width: 2),
                  ),
                  filled: true,
                  fillColor: PatientTheme.backgroundColor,
                ),
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    Navigator.pop(context);
                    _performSearch(context, query, patientDataFuture, onNavigateToTab);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Quick searches:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: PatientTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSearchChip(context, 'Recent Appointments', patientDataFuture, onNavigateToTab),
                  _buildSearchChip(context, 'Lab Results', patientDataFuture, onNavigateToTab),
                  _buildSearchChip(context, 'Prescriptions', patientDataFuture, onNavigateToTab),
                  _buildSearchChip(context, 'Medical History', patientDataFuture, onNavigateToTab),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildSearchChip(
    BuildContext context,
    String label,
    Future<PatientData> patientDataFuture,
    Function(int) onNavigateToTab,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _performSearch(context, label, patientDataFuture, onNavigateToTab);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: PatientTheme.primaryPink.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: PatientTheme.primaryPink.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: PatientTheme.primaryPink,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static void _performSearch(
    BuildContext context,
    String query,
    Future<PatientData> patientDataFuture,
    Function(int) onNavigateToTab,
  ) {
    // Perform actual search through patient data
    List<Map<String, dynamic>> searchResults = [];
    
    // Search through patient data
    patientDataFuture.then((patientData) {
      String lowerQuery = query.toLowerCase();
      
      // Search in patient name
      if (patientData.name.toLowerCase().contains(lowerQuery)) {
        searchResults.add({
          'type': 'Patient Info',
          'title': 'Patient Name',
          'content': patientData.name,
          'icon': Icons.person,
        });
      }
      
      // Search in diagnosis
      if (patientData.diagnosis.toLowerCase().contains(lowerQuery)) {
        searchResults.add({
          'type': 'Diagnosis',
          'title': 'Medical Diagnosis',
          'content': patientData.diagnosis,
          'icon': Icons.medical_services,
        });
      }
      
      // Search in medical history
      for (String history in patientData.medicalHistory) {
        if (history.toLowerCase().contains(lowerQuery)) {
          searchResults.add({
            'type': 'Medical History',
            'title': 'Medical Record',
            'content': history,
            'icon': Icons.history,
          });
        }
      }
      
      // Search in status
      if (patientData.status.toLowerCase().contains(lowerQuery)) {
        searchResults.add({
          'type': 'Status',
          'title': 'Current Status',
          'content': patientData.status,
          'icon': Icons.info,
        });
      }
      
      // Add common search terms
      if (lowerQuery.contains('appointment') || lowerQuery.contains('appt')) {
        searchResults.add({
          'type': 'Navigation',
          'title': 'View Appointments',
          'content': 'Navigate to your appointments page',
          'icon': Icons.calendar_today,
          'action': () => onNavigateToTab(1),
        });
      }
      
      if (lowerQuery.contains('report') || lowerQuery.contains('diagnosis')) {
        searchResults.add({
          'type': 'Navigation',
          'title': 'View Reports & Diagnosis',
          'content': 'Navigate to your medical reports',
          'icon': Icons.description,
          'action': () => onNavigateToTab(2),
        });
      }
      
      if (lowerQuery.contains('profile') || lowerQuery.contains('personal')) {
        searchResults.add({
          'type': 'Navigation',
          'title': 'View Profile',
          'content': 'Navigate to your profile page',
          'icon': Icons.person_rounded,
          'action': () => onNavigateToTab(3),
        });
      }
      
      // Show search results
      _showSearchResults(context, query, searchResults);
    }).catchError((error) {
      // Handle error case
      _showSearchResults(context, query, []);
    });
  }
  
  static void _showSearchResults(BuildContext context, String query, List<Map<String, dynamic>> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, PatientTheme.backgroundColor],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PatientTheme.primaryPink.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: PatientTheme.primaryPink, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Search Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: PatientTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Results for "$query"',
                            style: TextStyle(
                              fontSize: 14,
                              color: PatientTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Results
              Flexible(
                child: results.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: PatientTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No results found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: PatientTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try searching for appointments, diagnosis, medical history, or status.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: PatientTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final result = results[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: PatientTheme.primaryPink.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: PatientTheme.primaryPink.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  result['icon'],
                                  color: PatientTheme.primaryPink,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                result['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: PatientTheme.textPrimary,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    result['type'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: PatientTheme.primaryPink,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    result['content'],
                                    style: TextStyle(
                                      color: PatientTheme.textSecondary,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                if (result['action'] != null) {
                                  result['action']();
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 