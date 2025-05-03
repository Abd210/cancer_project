import 'package:flutter/material.dart';

import 'package:frontend/providers/doctor_provider.dart';
import 'package:frontend/providers/patient_provider.dart';
import 'package:frontend/providers/hospital_provider.dart';
import 'package:frontend/models/doctor_data.dart';
import 'package:frontend/models/hospital_data.dart';
import 'package:frontend/models/patient_data.dart';

import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/components.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterPaginatedDataTable;

class DoctorsPage extends StatefulWidget {
  final String token;
  const DoctorsPage({super.key, required this.token});

  @override
  _DoctorsPageState createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  final DoctorProvider _doctorProvider = DoctorProvider();
  final PatientProvider _patientProvider = PatientProvider();
  final HospitalProvider _hospitalProvider = HospitalProvider();

  bool _isLoading = false;
  String _searchQuery = '';
  String _filter = 'unsuspended'; // "unsuspended", "suspended", "all"

  List<DoctorData> _doctorList = [];
  List<PatientData> _patientList = [];
  List<HospitalData> _hospitalList = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _fetchPatients();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    try {
      final hospitals = await _hospitalProvider.getHospitals(
        token: widget.token,
        filter: 'all',
      );
      setState(() {
        _hospitalList = hospitals;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load hospitals: $e')),
        );
      }
    }
  }

  // ... rest of the existing code ...
} 