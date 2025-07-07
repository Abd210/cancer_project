import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'patient_page.dart';
import 'patient_page_web.dart';

class PatientPlatformPage extends StatefulWidget {
  final String? doctorId;
  final String token;
  final String patientId;

  const PatientPlatformPage({
    Key? key,
    this.doctorId,
    required this.token,
    required this.patientId,
  }) : super(key: key);

  @override
  State<PatientPlatformPage> createState() => _PatientPlatformPageState();
}

class _PatientPlatformPageState extends State<PatientPlatformPage> {
  bool _forceMobile = false;

  void _toggle() => setState(() => _forceMobile = !_forceMobile);

  @override
  Widget build(BuildContext context) {
    final bool useWeb = kIsWeb && !_forceMobile;
    if (useWeb) {
      return PatientPageWeb(
        token: widget.token,
        patientId: widget.patientId,
        doctorId: widget.doctorId,
        onSwitchToMobile: _toggle,
      );
    }
    return PatientPage(
      token: widget.token,
      patientId: widget.patientId,
      doctorId: widget.doctorId,
    );
  }
} 