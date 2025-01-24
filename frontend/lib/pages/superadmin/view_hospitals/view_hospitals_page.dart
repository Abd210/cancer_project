// lib/pages/superadmin/view_hospitals/view_hospitals_page.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/components.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterDataTable, BetterPaginatedDataTable;

import 'package:frontend/providers/hospital_provider.dart';
import 'package:frontend/models/hospital_data.dart';

class HospitalsPage extends StatefulWidget {
  final String token;
  const HospitalsPage({super.key, required this.token});

  @override
  _HospitalsPageState createState() => _HospitalsPageState();
}

class _HospitalsPageState extends State<HospitalsPage>
    with SingleTickerProviderStateMixin {
  final HospitalProvider _hospitalProvider = HospitalProvider();

  bool _isLoading = false;
  String _searchQuery = '';
  String _filter = 'unsuspended'; // "unsuspended" or "suspended"

  List<HospitalData> _hospitalList = [];

  HospitalData? _selectedHospital;

  late TabController _tabController;

  // Optional placeholders if you need them for searching within tabs, etc.
  String _searchQueryPatients = '';
  String _searchQueryDoctors = '';
  String _searchQueryAppointments = '';
  String _searchQueryDevices = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchHospitals();
  }

  /// Fetches hospitals from backend
  Future<void> _fetchHospitals() async {
    setState(() => _isLoading = true);
    try {
      final data = await _hospitalProvider.getHospitals(
        token: widget.token,
        hospitalId: '',
        filter: _filter,
      );
      setState(() {
        _hospitalList = data;
      });
    } catch (e) {
      debugPrint('Error fetching hospitals: $e');
      Fluttertoast.showToast(msg: 'Failed to load hospitals: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Opens a dialog to create a new hospital
  void _showAddHospitalDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    String name = '';
    String address = '';
    String mobileNumbers = '';
    String emails = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Hospital'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hospital Name
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Hospital Name'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Enter name' : null,
                  onSaved: (value) => name = value!.trim(),
                ),
                // Address
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Enter address' : null,
                  onSaved: (value) => address = value!.trim(),
                ),
                // Mobile Numbers
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Mobile Numbers (comma-separated)',
                  ),
                  onSaved: (value) => mobileNumbers = value ?? '',
                ),
                // Emails
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Emails (comma-separated)',
                  ),
                  onSaved: (value) => emails = value ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();

                // Close the dialog
                Navigator.pop(context);

                final mobileList = mobileNumbers
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                final emailList = emails
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                setState(() => _isLoading = true);
                try {
                  await _hospitalProvider.createHospital(
                    token: widget.token,
                    hospitalName: name,
                    hospitalAddress: address,
                    mobileNumbers: mobileList,
                    emails: emailList,
                  );

                  // Automatically refresh list so newly-created hospital is visible immediately
                  await _fetchHospitals();

                  Fluttertoast.showToast(msg: 'Hospital added successfully.');
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Failed to add hospital: $e');
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Opens dialog to edit an existing hospital
  void _showEditHospitalDialog(BuildContext context, HospitalData hospital) {
    final formKey = GlobalKey<FormState>();

    // Pre-populate form fields
    String name = hospital.name;
    String address = hospital.address;
    bool isSuspended = hospital.isSuspended;

    String mobileNumbers = hospital.mobileNumbers.join(', ');
    String emails = hospital.emails.join(', ');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Hospital'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Hospital Name'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Enter name' : null,
                  onSaved: (value) => name = value!.trim(),
                ),
                TextFormField(
                  initialValue: address,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'Enter address' : null,
                  onSaved: (value) => address = value!.trim(),
                ),
                TextFormField(
                  initialValue: mobileNumbers,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Numbers (comma-separated)',
                  ),
                  onSaved: (value) => mobileNumbers = value ?? '',
                ),
                TextFormField(
                  initialValue: emails,
                  decoration: const InputDecoration(
                    labelText: 'Emails (comma-separated)',
                  ),
                  onSaved: (value) => emails = value ?? '',
                ),
                // Suspended checkbox
                Row(
                  children: [
                    const Text('Suspended?'),
                    Checkbox(
                      value: isSuspended,
                      onChanged: (val) {
                        setState(() {
                          isSuspended = val ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(context);

                final mobileList = mobileNumbers
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                final emailList = emails
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final updatedFields = <String, dynamic>{
                  'hospital_name': name,
                  'hospital_address': address,
                  'suspended': isSuspended,
                  'mobile_numbers': mobileList,
                  'emails': emailList,
                };

                setState(() => _isLoading = true);
                try {
                  await _hospitalProvider.updateHospital(
                    token: widget.token,
                    hospitalId: hospital.id,
                    updatedFields: updatedFields,
                  );
                  await _fetchHospitals();
                  Fluttertoast.showToast(msg: 'Hospital updated successfully.');
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Failed to update: $e');
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Delete a hospital
  void _deleteHospital(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hospital'),
        content: const Text('Are you sure you want to delete this hospital?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _hospitalProvider.deleteHospital(
                  token: widget.token,
                  hospitalId: id,
                );
                await _fetchHospitals();
                if (_selectedHospital?.id == id) {
                  _selectedHospital = null;
                }
                Fluttertoast.showToast(msg: 'Hospital deleted successfully.');
              } catch (e) {
                Fluttertoast.showToast(msg: 'Failed to delete hospital: $e');
              } finally {
                setState(() => _isLoading = false);
              }
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

  /// (Optional) Sub-pages for the selected hospital details
  Widget _buildPatientsSection() {
    return const Center(child: Text('No patient data integrated yet.'));
  }

  Widget _buildDoctorsSection() {
    return const Center(child: Text('No doctors data integrated yet.'));
  }

  Widget _buildAppointmentsSection() {
    return const Center(child: Text('No appointments data integrated yet.'));
  }

  Widget _buildDevicesSection() {
    return const Center(child: Text('No devices data integrated yet.'));
  }

  @override
  Widget build(BuildContext context) {
    // Loading spinner if needed
    if (_isLoading) {
      return const LoadingIndicator();
    }

    // If a hospital is selected => show detail tabs
    if (_selectedHospital != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Text(
            '${_selectedHospital!.name} Details',
            style: const TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() => _selectedHospital = null);
            },
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Patients'),
              Tab(text: 'Doctors'),
              Tab(text: 'Appointments'),
              Tab(text: 'Devices'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPatientsSection(),
            _buildDoctorsSection(),
            _buildAppointmentsSection(),
            _buildDevicesSection(),
          ],
        ),
      );
    }

    // Otherwise => show the main hospital list
    final filteredHospitals = _hospitalList.where((h) {
      final q = _searchQuery.toLowerCase();
      return h.name.toLowerCase().contains(q) ||
          h.address.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1) Row with filter, search, Add button, and now a Refresh button
            Row(
              children: [
                // Suspended/Unsuspended filter dropdown
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: DropdownButton<String>(
                    value: _filter,
                    underline: const SizedBox(),
                    onChanged: (val) async {
                      if (val != null) {
                        setState(() => _filter = val);
                        await _fetchHospitals();
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'unsuspended',
                        child: Text('Unsuspended'),
                      ),
                      DropdownMenuItem(
                        value: 'suspended',
                        child: Text('Suspended'),
                      ),
                    ],
                  ),
                ),

                // Search bar
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Hospitals',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // Add Hospital button
                ElevatedButton.icon(
                  onPressed: () => _showAddHospitalDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Hospital'),
                ),

                const SizedBox(width: 10),

                // REFRESH button => calls _fetchHospitals() like re-tapping the Hospitals tab
                ElevatedButton.icon(
                  onPressed: _fetchHospitals, // Just call the same method
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2) Hospital list
            Expanded(
              child: filteredHospitals.isEmpty
                  ? const Center(child: Text('No hospitals found.'))
                  : ListView.builder(
                      itemCount: filteredHospitals.length,
                      itemBuilder: (context, index) {
                        final hospital = filteredHospitals[index];
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              hospital.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              hospital.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () =>
                                      _showEditHospitalDialog(context, hospital),
                                ),
                                // Delete
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      _deleteHospital(context, hospital.id),
                                ),
                              ],
                            ),
                            // Tap to see detailed tabs
                            onTap: () {
                              setState(() => _selectedHospital = hospital);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
