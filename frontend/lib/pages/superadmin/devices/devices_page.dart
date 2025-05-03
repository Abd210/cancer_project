import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/providers/device_provider.dart';
import 'package:frontend/models/device_data.dart';
import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/responsive_data_table.dart' show BetterDataTable;

class DevicesPage extends StatefulWidget {
  final String token;
  const DevicesPage({Key? key, required this.token}) : super(key: key);

  @override
  _DevicesPageState createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final DeviceProvider _deviceProvider = DeviceProvider();
  List<DeviceData> _deviceList = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'suspended', 'unsuspended'

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() => _isLoading = true);
    try {
      final list = await _deviceProvider.getDevices(
        token: widget.token,
        filter: _filter,
      );
      setState(() {
        _deviceList = list;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loaded ${_deviceList.length} devices')),
        );
      }
    } catch (e) {
      print('Error fetching devices: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load devices: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddDeviceDialog() {
    final formKey = GlobalKey<FormState>();
    String type = 'Breast Cancer Monitor'; // Default or fetch types?
    String? patientId;
    bool suspended = false;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Device'),
        content: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter device type' : null,
                      onSaved: (val) => type = val!.trim(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Patient ID (Optional)'),
                      onSaved: (val) => patientId = val?.trim().isEmpty ?? true ? null : val!.trim(), // Save null if empty
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Suspended?'),
                        Checkbox(
                          value: suspended,
                          onChanged: (val) {
                            setStateDialog(() {
                              suspended = val ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(ctx);

                setState(() => _isLoading = true);
                try {
                  await _deviceProvider.createDevice(
                    token: widget.token,
                    type: type,
                    patientId: patientId, // Pass null if not provided
                    suspended: suspended,
                  );
                  await _fetchDevices();
                  Fluttertoast.showToast(msg: 'Device added successfully.');
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Failed to add device: $e');
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

  void _showEditDeviceDialog(DeviceData device) {
    final formKey = GlobalKey<FormState>();
    String type = device.type;
    String? patientId = device.patientId;
    bool suspended = device.suspended;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Device'),
        content: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (ctx, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Enter device type' : null,
                      onSaved: (val) => type = val!.trim(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: patientId,
                      decoration:
                          const InputDecoration(labelText: 'Patient ID (Optional)'),
                      onSaved: (val) => patientId = val?.trim().isEmpty ?? true ? null : val!.trim(), // Save null if empty
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Suspended?'),
                        Checkbox(
                          value: suspended,
                          onChanged: (val) {
                            setStateDialog(() {
                              suspended = val ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(ctx);

                setState(() => _isLoading = true);
                try {
                  final updatedFields = {
                    'type': type,
                    'patient': patientId, // Send null or the ID
                    'suspended': suspended,
                  };
                  await _deviceProvider.updateDevice(
                    token: widget.token,
                    deviceId: device.id,
                    updatedFields: updatedFields,
                  );
                  await _fetchDevices();
                  Fluttertoast.showToast(msg: 'Device updated successfully.');
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Failed to update device: $e');
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

  void _showDeleteDialog(String deviceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Device'),
        content: const Text('Are you sure you want to delete this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _deviceProvider.deleteDevice(
                  token: widget.token,
                  deviceId: deviceId,
                );
                await _fetchDevices();
                Fluttertoast.showToast(msg: 'Device deleted successfully.');
              } catch (e) {
                Fluttertoast.showToast(msg: 'Failed to delete device: $e');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator when loading
    if (_isLoading) {
      return const LoadingIndicator();
    }

    // Filter devices based on search query and filter
    List<DeviceData> filteredDevices = _deviceList.where((device) {
      // First apply filter
      if (_filter == 'suspended' && !device.suspended) return false;
      if (_filter == 'unsuspended' && device.suspended) return false;

      // Then apply search
      if (_searchQuery.isEmpty) return true;
      return device.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          device.type.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (device.patientId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    // Create DataRows from filtered devices
    final rows = filteredDevices.map((device) {
      return DataRow(
        cells: [
          DataCell(Text(device.id)),
          DataCell(Text(device.type)),
          DataCell(
            device.patientId == null || device.patientId!.isEmpty
                ? const Text('Not assigned')
                : Text(device.patientId!),
          ),
          DataCell(Text(device.suspended ? 'Suspended' : 'Active')),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _showEditDeviceDialog(device),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(device.id),
              ),
            ],
          )),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter and search row
            Row(
              children: [
                // Filter dropdown
                DropdownButton<String>(
                  value: _filter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'unsuspended', child: Text('Active')),
                    DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                  ],
                  onChanged: (val) {
                    setState(() => _filter = val ?? 'all');
                    _fetchDevices();
                  },
                ),
                const SizedBox(width: 20),
                // Search field
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search devices...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 20),
                // Add button
                ElevatedButton.icon(
                  onPressed: _showAddDeviceDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Device'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Table
            Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('No devices found'))
                  : BetterDataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Patient ID')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: rows,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

