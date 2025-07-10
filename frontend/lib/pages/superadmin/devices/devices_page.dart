import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/providers/device_provider.dart';
import 'package:frontend/models/device_data.dart';
import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/page_header.dart';
import '../../../shared/components/responsive_data_table.dart' show BetterPaginatedDataTable;

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
        title: Row(
          children: [
            Icon(Icons.devices, color: const Color(0xFFEC407A)),
            const SizedBox(width: 10),
            const Text('Add Device', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (ctx, setStateDialog) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Device Type',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Enter device type' : null,
                        onSaved: (val) => type = val!.trim(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Patient ID (Optional)',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                          hintText: 'Leave empty if not assigned to patient',
                        ),
                        onSaved: (val) => patientId = val?.trim().isEmpty ?? true ? null : val!.trim(), // Save null if empty
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Suspended?'),
                          const SizedBox(width: 10),
                          Checkbox(
                            value: suspended,
                            onChanged: (val) {
                              setStateDialog(() {
                                suspended = val ?? false;
                              });
                            },
                            activeColor: const Color(0xFFEC407A),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Add Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
            ),
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
          ),
        ],
      ),
    );
  }

  void _showEditDeviceDialog(DeviceData device) {
    final formKey = GlobalKey<FormState>();
    String deviceCode = device.deviceCode;
    String? patientId = device.patientId;
    String purpose = device.purpose;
    String status = device.status;
    bool suspended = device.suspended;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: const Color(0xFFEC407A)),
            const SizedBox(width: 10),
            const Text('Edit Device', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (ctx, setStateDialog) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: deviceCode,
                        decoration: const InputDecoration(
                          labelText: 'Device Code',
                          prefixIcon: Icon(Icons.qr_code),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Enter device code' : null,
                        onSaved: (val) => deviceCode = val!.trim(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: purpose,
                        decoration: const InputDecoration(
                          labelText: 'Purpose',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Enter device purpose' : null,
                        onSaved: (val) => purpose = val!.trim(),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.info),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'operational', child: Text('Operational')),
                          DropdownMenuItem(value: 'malfunctioned', child: Text('Malfunctioned')),
                          DropdownMenuItem(value: 'standby', child: Text('Standby')),
                        ],
                        onChanged: (value) {
                          setStateDialog(() {
                            status = value ?? 'operational';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: patientId,
                        decoration: const InputDecoration(
                          labelText: 'Patient ID (Optional)',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                          hintText: 'Leave empty if not assigned to patient',
                        ),
                        onSaved: (val) => patientId = val?.trim().isEmpty ?? true ? null : val!.trim(), // Save null if empty
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Suspended?'),
                          const SizedBox(width: 10),
                          Checkbox(
                            value: suspended,
                            onChanged: (val) {
                              setStateDialog(() {
                                suspended = val ?? false;
                              });
                            },
                            activeColor: const Color(0xFFEC407A),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Save Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(ctx);

                setState(() => _isLoading = true);
                try {
                  final updatedFields = {
                    'deviceCode': deviceCode,
                    'purpose': purpose,
                    'status': status,
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
          device.deviceCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (device.patientId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    // Create DataRows from filtered devices
    final rows = filteredDevices.map((device) {
      return DataRow(
        cells: [
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
              child: Text(
                device.id,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
              child: Text(
                device.deviceCode,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
              child: Text(
                device.patientId == null || device.patientId!.isEmpty
                    ? 'Not assigned'
                    : device.patientId!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: device.patientId == null || device.patientId!.isEmpty
                      ? Colors.grey.shade600
                      : null,
                  fontStyle: device.patientId == null || device.patientId!.isEmpty
                      ? FontStyle.italic
                      : null,
                ),
              ),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
              child: Text(
                device.status,
                maxLines: 2,
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
              constraints: const BoxConstraints(minWidth: 80, maxWidth: 120),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: device.suspended ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  device.suspended ? 'Suspended' : 'Active',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              constraints: const BoxConstraints(minWidth: 100, maxWidth: 120),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDeviceDialog(device),
                    tooltip: 'Edit Device',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(device.id),
                    tooltip: 'Delete Device',
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Devices')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const PageHeader(icon: Icons.devices, title: 'Devices Management'),
            SizedBox(height: 24),
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
                  : BetterPaginatedDataTable(
                      themeColor: const Color(0xFFEC407A), // Pinkish color
                      rowsPerPage: 10, // Show 10 rows per page
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Patient ID')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Suspension')),
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

