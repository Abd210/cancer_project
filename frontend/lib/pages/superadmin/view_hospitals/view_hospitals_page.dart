import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/providers/hospital_provider.dart';
import 'package:frontend/models/hospital_data.dart';
import 'package:frontend/pages/superadmin/view_hospitals/tabs/view_data_hospital.dart';
import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterPaginatedDataTable;

class HospitalsPage extends StatefulWidget {
  final String token;
  const HospitalsPage({Key? key, required this.token}) : super(key: key);

  @override
  State<HospitalsPage> createState() => _HospitalsPageState();
}

class _HospitalsPageState extends State<HospitalsPage> {
  final HospitalProvider _provider = HospitalProvider();
  bool _isLoading = false;
  String _filter = 'unsuspended';
  List<HospitalData> _list = [];
  HospitalData? _selected;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      _list = await _provider.getHospitals(
        token: widget.token,
        filter: _filter,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: 'Load failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddHospitalDialog(BuildContext ctx) {
    final formKey = GlobalKey<FormState>();
    String name = '', addr = '', mobiles = '', emails = '', adminId = '';

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_hospital, color: const Color(0xFFEC407A)),
            const SizedBox(width: 10),
            const Text('Add Hospital', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: MediaQuery.of(ctx).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Hospital Name',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Enter hospital name' : null,
                    onSaved: (val) => name = val!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Enter address' : null,
                    onSaved: (val) => addr = val!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Mobile Numbers (comma-separated)',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                      hintText: 'e.g., +1234567890, +0987654321',
                    ),
                    onSaved: (val) => mobiles = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Email Addresses (comma-separated)',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                      hintText: 'e.g., info@hospital.com, admin@hospital.com',
                    ),
                    onSaved: (val) => emails = val?.trim() ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Admin ID (optional)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      hintText: 'Leave empty if no admin assigned',
                    ),
                    onSaved: (val) => adminId = val?.trim() ?? '',
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              Navigator.pop(ctx);

              setState(() => _isLoading = true);
              try {
                await _provider.createHospital(
                  token: widget.token,
                  hospitalName: name,
                  hospitalAddress: addr,
                  mobileNumbers: mobiles
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  emails: emails
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                  admin: adminId.isNotEmpty ? adminId : null,
                );
                Fluttertoast.showToast(msg: 'Hospital added.');
                await _fetch();
              } catch (e) {
                Fluttertoast.showToast(msg: 'Add failed: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditHospitalDialog(BuildContext ctx, HospitalData h) {
    final formKey = GlobalKey<FormState>();
    String name = h.name;
    String addr = h.address;
    String mobiles = h.mobileNumbers.join(', ');
    String emails = h.emails.join(', ');
    String adminId = h.adminId;
    bool suspended = h.suspended;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: const Color(0xFFEC407A)),
              const SizedBox(width: 10),
              const Text('Edit Hospital', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            width: MediaQuery.of(ctx).size.width * 0.8,
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(
                        labelText: 'Hospital Name',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Enter hospital name' : null,
                      onSaved: (val) => name = val!.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: addr,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Enter address' : null,
                      onSaved: (val) => addr = val!.trim(),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: mobiles,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Numbers (comma-separated)',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                        hintText: 'e.g., +1234567890, +0987654321',
                      ),
                      onSaved: (val) => mobiles = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: emails,
                      decoration: const InputDecoration(
                        labelText: 'Email Addresses (comma-separated)',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                        hintText: 'e.g., info@hospital.com, admin@hospital.com',
                      ),
                      onSaved: (val) => emails = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: adminId,
                      decoration: const InputDecoration(
                        labelText: 'Admin ID (optional)',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        hintText: 'Leave empty if no admin assigned',
                      ),
                      onSaved: (val) => adminId = val?.trim() ?? '',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Suspended?'),
                        const SizedBox(width: 10),
                        Checkbox(
                          value: suspended,
                          onChanged: (v) => setDialogState(() => suspended = v!),
                          activeColor: const Color(0xFFEC407A),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              formKey.currentState!.save();
              Navigator.pop(ctx);

              setState(() => _isLoading = true);
              try {
                await _provider.updateHospital(
                  token: widget.token,
                  hospitalId: h.id,
                  updatedFields: {
                    'name': name,
                    'address': addr,
                    'mobileNumbers': mobiles
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                    'emails': emails
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                    'admin': adminId.isNotEmpty ? adminId : null,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ));
  }

  void _deleteHospital(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this hospital?', style: TextStyle(color: Color(0xFFEC407A))),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFEC407A), width: 1),
        ),
        content: const Text('Are you sure you want to delete this hospital? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Cancel', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _provider.deleteHospital(
                  token: widget.token,
                  hospitalId: id,
                );
                Fluttertoast.showToast(msg: 'Hospital deleted.');
                await _fetch();
              } catch (e) {
                Fluttertoast.showToast(msg: 'Delete failed: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingIndicator();
    // if a hospital is selected, show detail tabs in-place
    if (_selected != null) {
      return ViewHospitalTabs(
        token: widget.token,
        hospitalId: _selected!.id,
        hospitalName: _selected!.name,
        initialTabIndex: 1,
        onBack: () => setState(() => _selected = null),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospitals'),
        backgroundColor: const Color(0xFFEC407A), // Pink theme color
        foregroundColor: Colors.white, // White text
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Container(
              width: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEC407A).withOpacity(0.5)),
                color: const Color(0xFFEC407A).withOpacity(0.1),
              ),
              child: DropdownButtonFormField<String>(
                value: _filter,
                decoration: const InputDecoration(
                  labelText: 'Filter Status',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFEC407A)),
                style: TextStyle(color: const Color(0xFFEC407A).withOpacity(0.8)),
                items: const [
                  DropdownMenuItem(value: 'unsuspended', child: Text('Unsuspended')),
                  DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                  DropdownMenuItem(value: 'all', child: Text('All')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _filter = v);
                  await _fetch();
                },
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showAddHospitalDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Hospital'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: _list.isEmpty 
                ? const Center(child: Text('No hospitals found.'))
                : BetterPaginatedDataTable(
                    themeColor: const Color(0xFFEC407A), // Pinkish color
                    rowsPerPage: 10, // Show 10 rows per page
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Address')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _list.map((h) => DataRow(cells: [
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          constraints: const BoxConstraints(
                            minWidth: 250,
                            maxWidth: 300,
                          ),
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = h),
                            child: Text(
                              h.name,
                              style: const TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          constraints: const BoxConstraints(
                            minWidth: 350,
                            maxWidth: 500,
                          ),
                          child: Text(
                            h.address,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditHospitalDialog(context, h),
                                tooltip: 'Edit Hospital',
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteHospital(h.id),
                                tooltip: 'Delete Hospital',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ])).toList(),
                  ),
          ),
        ]),
      ),
    );
  }


}