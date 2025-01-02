// lib/pages/superadmin/hospitals/hospitals_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/hospital.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'hospital_details_page.dart';

class HospitalsPage extends StatefulWidget {
  const HospitalsPage({super.key});

  @override
  _HospitalsPageState createState() => _HospitalsPageState();
}

class _HospitalsPageState extends State<HospitalsPage> {
  String _searchQuery = '';
  final bool _isLoading = false;

  void _showAddHospitalDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String address = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Hospital'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Hospital Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                onSaved: (value) => name = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value == null || value.isEmpty ? 'Enter address' : null,
                onSaved: (value) => address = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final newHospital = Hospital(
                  id: 'h${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  address: address,
                );
                Provider.of<DataProvider>(context, listen: false).addHospital(newHospital);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Hospital added successfully.');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditHospitalDialog(BuildContext context, Hospital hospital) {
    final formKey = GlobalKey<FormState>();
    String name = hospital.name;
    String address = hospital.address;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Hospital'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: hospital.name,
                decoration: const InputDecoration(labelText: 'Hospital Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                onSaved: (value) => name = value!,
              ),
              TextFormField(
                initialValue: hospital.address,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (value) => value == null || value.isEmpty ? 'Enter address' : null,
                onSaved: (value) => address = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final updatedHospital = Hospital(
                  id: hospital.id,
                  name: name,
                  address: address,
                );
                Provider.of<DataProvider>(context, listen: false).updateHospital(updatedHospital);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Hospital updated successfully.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteHospital(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hospital'),
        content: const Text('Are you sure you want to delete this hospital?'),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteHospital(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Hospital deleted successfully.');
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        List<Hospital> hospitals = dataProvider.hospitals
            .where((h) => h.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            h.address.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search and Add Button
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search Hospitals',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showAddHospitalDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Hospital'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Hospitals List with Improved UI
              Expanded(
                child: ListView.builder(
                  itemCount: hospitals.length,
                  itemBuilder: (context, index) {
                    final hospital = hospitals[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          hospital.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          hospital.address,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditHospitalDialog(context, hospital),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteHospital(context, hospital.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Navigate to Hospital Details Page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HospitalDetailsPage(hospital: hospital),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
