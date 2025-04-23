import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/providers/hospital_provider.dart';
import 'package:frontend/models/hospital_data.dart';
import 'package:frontend/pages/superadmin/view_hospitals/tabs/view_data_hospital.dart';
import '../../../shared/components/loading_indicator.dart';

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
    String name = '', addr = '', mobiles = '', emails = '';

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Add Hospital'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _txt('Name', (v) => name = v),
                _txt('Address', (v) => addr = v),
                _txt('Mobiles (comma‑sep)', (v) => mobiles = v, required: false),
                _txt('Emails (comma‑sep)', (v) => emails = v, required: false),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
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

  void _showEditHospitalDialog(BuildContext ctx, HospitalData h) {
    final formKey = GlobalKey<FormState>();
    String name = h.name;
    String addr = h.address;
    String mobiles = h.mobileNumbers.join(', ');
    String emails = h.emails.join(', ');
    bool suspended = h.isSuspended;

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Edit Hospital'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _txt('Name', (v) => name = v, initial: name),
                _txt('Address', (v) => addr = v, initial: addr),
                _txt('Mobiles', (v) => mobiles = v, initial: mobiles, required: false),
                _txt('Emails', (v) => emails = v, initial: emails, required: false),
                Row(children: [
                  const Text('Suspended?'),
                  Checkbox(
                    value: suspended,
                    onChanged: (v) => setState(() => suspended = v!),
                  ),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
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

  void _deleteHospital(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this hospital?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
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
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
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
      appBar: AppBar(title: const Text('Hospitals')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            DropdownButton<String>(
              value: _filter,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'unsuspended', child: Text('Unsuspended')),
                DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _filter = v);
                await _fetch();
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showAddHospitalDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Address')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: _list.map((h) => DataRow(cells: [
                  DataCell(
                    GestureDetector(
                      onTap: () => setState(() => _selected = h),
                      child: Text(
                        h.name,
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(h.address)),
                  DataCell(Row(children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditHospitalDialog(context, h),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteHospital(h.id),
                    ),
                  ])),
                ])).toList(),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _txt(
    String label,
    void Function(String) save, {
    String initial = '',
    bool required = true,
  }) {
    return TextFormField(
      initialValue: initial,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Enter $label' : null
          : null,
      onSaved: (v) => save(v!.trim()),
    );
  }
}
