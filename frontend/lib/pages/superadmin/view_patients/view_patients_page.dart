import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/patient.dart';
import '../../../models/hospital.dart';
import '../../../models/doctor.dart';
import '../../../shared/components/loading_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({Key? key}) : super(key: key);

  @override
  _PatientsPageState createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  String _searchQuery = '';
  bool _isLoading = false;

  /// We'll pick the Hospital first, then filter Doctors to that hospital
  void _showAddPatientDialog(BuildContext context, List<Hospital> allHospitals) {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    int age = 0;
    String diagnosis = '';
    String? selectedHospitalId;
    String? selectedDoctorId;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Patient'),
          content: Form(
            key: _formKey,
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Patient Name'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter name' : null,
                        onSaved: (value) => name = value!,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Age'),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter age';
                          if (int.tryParse(value) == null) return 'Enter valid age';
                          return null;
                        },
                        onSaved: (value) => age = int.parse(value!),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Diagnosis'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter diagnosis' : null,
                        onSaved: (value) => diagnosis = value!,
                      ),
                      SizedBox(height: 10),
                      // 1) Hospital Dropdown
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Select Hospital'),
                        items: allHospitals.map((hospital) {
                          return DropdownMenuItem<String>(
                            value: hospital.id,
                            child: Text(hospital.name),
                          );
                        }).toList(),
                        validator: (value) => value == null ? 'Pick a hospital' : null,
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedHospitalId = value;
                            selectedDoctorId = null; // reset
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      // 2) Doctor Dropdown, filtered by the chosen Hospital
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Select Doctor'),
                        // If no hospital chosen, show empty list
                        items: (selectedHospitalId == null
                                ? <Doctor>[]
                                : Provider.of<DataProvider>(context, listen: false)
                                    .doctors
                                    .where((doc) => doc.hospitalId == selectedHospitalId)
                                    .toList())
                            .map((doctor) {
                          return DropdownMenuItem<String>(
                            value: doctor.id,
                            child: Text(doctor.name),
                          );
                        }).toList(),
                        validator: (value) => value == null ? 'Pick a doctor' : null,
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedDoctorId = value;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  final newPatient = Patient(
                    id: 'p${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    age: age,
                    diagnosis: diagnosis,
                    doctorId: selectedDoctorId!,
                    deviceId: '', // optional
                  );

                  // Add to DataProvider => instantly shows in the correct hospital
                  Provider.of<DataProvider>(context, listen: false)
                      .addPatient(newPatient);

                  Navigator.pop(context);
                  Fluttertoast.showToast(msg: 'Patient added successfully.');
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        if (_isLoading) {
          return LoadingIndicator();
        }

        List<Hospital> allHospitals = dataProvider.hospitals;

        // If you want to filter patients or not
        List<Patient> patients = dataProvider.patients.where((p) {
          return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.diagnosis.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search Patients',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPatientDialog(context, allHospitals),
                    icon: Icon(Icons.add),
                    label: Text('Add Patient'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // DataTable
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Age')),
                      DataColumn(label: Text('Diagnosis')),
                      DataColumn(label: Text('Doctor')),
                      DataColumn(label: Text('Hospital')),
                    ],
                    rows: patients.map((patient) {
                      final doctor = dataProvider.doctors.firstWhere(
                        (d) => d.id == patient.doctorId,
                        orElse: () => Doctor(id: '', name: 'Unknown', specialization: '', hospitalId: ''),
                      );
                      final hospital = dataProvider.hospitals.firstWhere(
                        (h) => h.id == doctor.hospitalId,
                        orElse: () => Hospital(id: '', name: 'Unknown', address: ''),
                      );
                      return DataRow(cells: [
                        DataCell(Text(patient.id)),
                        DataCell(Text(patient.name)),
                        DataCell(Text('${patient.age}')),
                        DataCell(Text(patient.diagnosis)),
                        DataCell(Text(doctor.name)),
                        DataCell(Text(hospital.name)),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
