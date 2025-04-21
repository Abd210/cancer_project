import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/models/appointment_data.dart';
import 'package:frontend/providers/appointment_provider.dart';
import 'package:intl/intl.dart';

class HospitalAppointmentsTab extends StatefulWidget {
  final String token;
  final String hospitalId;
  const HospitalAppointmentsTab({
    super.key,
    required this.token,
    required this.hospitalId,
  });

  @override
  State<HospitalAppointmentsTab> createState() =>
      _HospitalAppointmentsTabState();
}

class _HospitalAppointmentsTabState extends State<HospitalAppointmentsTab> {
  final _provider = AppointmentProvider();
  bool _loading = false;
  List<AppointmentData> _list = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      _list = await _provider.getHospitalUpcoming(
        token: widget.token,
        hospitalId: widget.hospitalId,
        suspendfilter: 'all',
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Load appointments failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final df = DateFormat('yyyy‑MM‑dd HH:mm');
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetch,
          ),
        ),
        Expanded(
          child: _list.isEmpty
              ? const Center(child: Text('No upcoming appointments.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Patient')),
                      DataColumn(label: Text('Doctor')),
                      DataColumn(label: Text('Start')),
                      DataColumn(label: Text('End')),
                      DataColumn(label: Text('Purpose')),
                    ],
                    rows: _list.map((a) => DataRow(cells: [
                      DataCell(Text(a.patientName)),
                      DataCell(Text(a.doctorName)),
                      DataCell(Text(df.format(a.start))),
                      DataCell(Text(df.format(a.end))),
                      DataCell(Text(a.purpose)),
                    ])).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}
