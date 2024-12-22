// lib/pages/superadmin/hospitals/hospitals_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/hospital.dart';
import '../../../shared/components/loading_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HospitalsPage extends StatefulWidget {
  const HospitalsPage({Key? key}) : super(key: key);

  @override
  _HospitalsPageState createState() => _HospitalsPageState();
}

class _HospitalsPageState extends State<HospitalsPage> {
  String _searchQuery = '';
  bool _isLoading = false;

  void _showAddHospitalDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String address = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Hospital'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Hospital Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                onSaved: (value) => name = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) => value == null || value.isEmpty ? 'Enter address' : null,
                onSaved: (value) => address = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
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
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditHospitalDialog(BuildContext context, Hospital hospital) {
    final _formKey = GlobalKey<FormState>();
    String name = hospital.name;
    String address = hospital.address;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Hospital'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: hospital.name,
                decoration: InputDecoration(labelText: 'Hospital Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter name' : null,
                onSaved: (value) => name = value!,
              ),
              TextFormField(
                initialValue: hospital.address,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) => value == null || value.isEmpty ? 'Enter address' : null,
                onSaved: (value) => address = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
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
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteHospital(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Hospital'),
        content: Text('Are you sure you want to delete this hospital?'),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteHospital(id);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Hospital deleted successfully.');
            },
            child: Text('Yes', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
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
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                    onPressed: () => _showAddHospitalDialog(context),
                    icon: Icon(Icons.add),
                    label: Text('Add Hospital'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Hospitals DataTable with Edit and Delete
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Address')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: hospitals.map((hospital) {
                      return DataRow(cells: [
                        DataCell(Text(hospital.id)),
                        DataCell(Text(hospital.name)),
                        DataCell(Text(hospital.address)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditHospitalDialog(context, hospital),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteHospital(context, hospital.id),
                            ),
                          ],
                        )),
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
