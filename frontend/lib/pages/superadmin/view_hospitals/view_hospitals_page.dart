import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/providers/hospital_provider.dart';
import 'package:frontend/models/hospital_data.dart';
import '../../../shared/components/loading_indicator.dart';

// hospital‑scoped tabs
import 'tabs/patients_tab.dart';
import 'tabs/doctors_tab.dart';
import 'tabs/appointments_tab.dart';
import 'tabs/devices_tab.dart';

class HospitalsPage extends StatefulWidget {
  final String token;
  const HospitalsPage({super.key, required this.token});

  @override
  State<HospitalsPage> createState() => _HospitalsPageState();
}

class _HospitalsPageState extends State<HospitalsPage>
    with SingleTickerProviderStateMixin {
  final HospitalProvider _provider = HospitalProvider();

  // ------------------------------------------------------------------
  //  STATE
  // ------------------------------------------------------------------
  bool _isLoading = false;
  String _searchQuery = '';
  String _filter = 'unsuspended';          // suspended | unsuspended
  List<HospitalData> _list = [];
  HospitalData? _selected;                 // non‑null => detail view
  late final TabController _tabs = TabController(length: 4, vsync: this);

  // ------------------------------------------------------------------
  //  INIT
  // ------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _fetch();
  }

  // ------------------------------------------------------------------
  //  API
  // ------------------------------------------------------------------
  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      _list = await _provider.getHospitals(
        token: widget.token,
        filter: _filter,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to load hospitals: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ------------------------------------------------------------------
  //  DIALOGS  — CRUD
  // ------------------------------------------------------------------
  // ADD
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
                _txt('Hospital Name', save: (v) => name = v),
                _txt('Address', save: (v) => address = v),
                _txt('Mobile Numbers (comma‑separated)',
                    save: (v) => mobileNumbers = v, required: false),
                _txt('Emails (comma‑separated)',
                    save: (v) => emails = v, required: false),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              Navigator.pop(context);

              final mobiles = mobileNumbers
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final emailList = emails
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              setState(() => _isLoading = true);
              try {
                await _provider.createHospital(
                  token: widget.token,
                  hospitalName: name,
                  hospitalAddress: address,
                  mobileNumbers: mobiles,
                  emails: emailList,
                );
                Fluttertoast.showToast(msg: 'Hospital added.');
                await _fetch();
              } catch (e) {
                Fluttertoast.showToast(msg: 'Add failed: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // EDIT
  void _showEditHospitalDialog(BuildContext context, HospitalData h) {
    final formKey = GlobalKey<FormState>();

    String name = h.name;
    String address = h.address;
    String mobileNumbers = h.mobileNumbers.join(', ');
    String emails = h.emails.join(', ');
    bool suspended = h.isSuspended;

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
                _txt('Hospital Name',
                    initial: name, save: (v) => name = v),
                _txt('Address', initial: address, save: (v) => address = v),
                _txt('Mobile Numbers (comma‑separated)',
                    initial: mobileNumbers,
                    save: (v) => mobileNumbers = v,
                    required: false),
                _txt('Emails (comma‑separated)',
                    initial: emails,
                    save: (v) => emails = v,
                    required: false),
                Row(
                  children: [
                    const Text('Suspended?'),
                    Checkbox(
                      value: suspended,
                      onChanged: (v) => setState(() => suspended = v ?? false),
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
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              Navigator.pop(context);

              final mobiles = mobileNumbers
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final emailList = emails
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              setState(() => _isLoading = true);
              try {
                await _provider.updateHospital(
                  token: widget.token,
                  hospitalId: h.id,
                  updatedFields: {
                    'name': name,
                    'address': address,
                    'mobileNumbers': mobiles,
                    'emails': emailList,
                    'suspended': suspended,
                  },
                );
                Fluttertoast.showToast(msg: 'Hospital updated.');
                await _fetch();
              } catch (e) {
                Fluttertoast.showToast(msg: 'Update failed: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // DELETE
  void _deleteHospital(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hospital'),
        content: const Text('Are you sure you want to delete this hospital?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _provider.deleteHospital(
                  token: widget.token,
                  hospitalId: id,
                );
                if (_selected?.id == id) _selected = null;
                Fluttertoast.showToast(msg: 'Hospital deleted.');
                await _fetch();
              } catch (e) {
                Fluttertoast.showToast(msg: 'Delete failed: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  //  DETAIL VIEW  (tab bar with Patients / Doctors / Appointments / Devices)
  // ------------------------------------------------------------------
  Widget _detail() {
    if (_selected == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(_selected!.name,
            style: const TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selected = null),
        ),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: Colors.black,
          tabs: const [
            Tab(text: 'Patients'),
            Tab(text: 'Doctors'),
            Tab(text: 'Appointments'),
            Tab(text: 'Devices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          HospitalPatientsTab(
            token: widget.token,
            hospitalId: _selected!.id,
          ),
          HospitalDoctorsTab(
            token: widget.token,
            hospitalId: _selected!.id,
          ),
          HospitalAppointmentsTab(
            token: widget.token,
            hospitalId: _selected!.id,
          ),
          const HospitalDevicesTab(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  //  LIST VIEW  (all hospitals)
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingIndicator();
    if (_selected != null) return _detail();

    final filtered = _list.where((h) {
      final q = _searchQuery.toLowerCase();
      return h.name.toLowerCase().contains(q) ||
          h.address.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ------------------------ toolbar ------------------------
            Row(
              children: [
                DropdownButton<String>(
                  value: _filter,
                  underline: const SizedBox(),
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _filter = v);
                    await _fetch();
                  },
                  items: const [
                    DropdownMenuItem(
                        value: 'unsuspended', child: Text('Unsuspended')),
                    DropdownMenuItem(
                        value: 'suspended', child: Text('Suspended')),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search hospitals',
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddHospitalDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _fetch,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // -------------------- data table ------------------------
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No hospitals found.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Address')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filtered.map((h) => DataRow(cells: [
                          DataCell(
                            GestureDetector(
                              onTap: () => setState(() => _selected = h),
                              child: Text(h.name,
                                  style: const TextStyle(
                                      decoration: TextDecoration.underline)),
                            ),
                          ),
                          DataCell(Text(h.address)),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue),
                                onPressed: () =>
                                    _showEditHospitalDialog(context, h),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => _deleteHospital(context, h.id),
                              ),
                            ],
                          )),
                        ])).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  //  TEXT‑FIELD HELPER
  // ------------------------------------------------------------------
  Widget _txt(String label,
      {String initial = '',
      required void Function(String) save,
      bool required = true}) {
    return TextFormField(
      initialValue: initial,
      decoration: InputDecoration(labelText: label),
      validator:
          required ? (v) => (v == null || v.trim().isEmpty) ? 'Enter $label' : null : null,
      onSaved: (v) => save(v!.trim()),
    );
  }
}
