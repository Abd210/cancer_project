import 'package:flutter/material.dart';

import 'package:frontend/providers/admin_provider.dart';
import 'package:frontend/providers/hospital_provider.dart';
import 'package:frontend/models/admin_data.dart';
import 'package:frontend/models/hospital_data.dart';

import '../../../shared/components/loading_indicator.dart';
import '../../../shared/components/components.dart';
import '../../../shared/components/responsive_data_table.dart'
    show BetterPaginatedDataTable;

class AdminsPage extends StatefulWidget {
  final String token;
  const AdminsPage({super.key, required this.token});

  @override
  _AdminsPageState createState() => _AdminsPageState();
}

class _AdminsPageState extends State<AdminsPage> {
  final AdminProvider _adminProvider = AdminProvider();
  final HospitalProvider _hospitalProvider = HospitalProvider();

  bool _isLoading = false;
  String _searchQuery = '';
  String _filter = 'unsuspended'; // "unsuspended", "suspended", "all"

  List<AdminData> _adminList = [];
  List<HospitalData> _hospitalList = [];
  
  @override
  void initState() {
    super.initState();
    _fetchAdmins();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    try {
      final hospitals = await _hospitalProvider.getHospitals(
        token: widget.token,
        filter: 'all',
      );
      setState(() {
        _hospitalList = hospitals;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load hospitals: $e')),
        );
      }
    }
  }

  Future<void> _fetchAdmins() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    try {
      final admins = await _adminProvider.getAdmins(
        token: widget.token,
        filter: _filter,
      );
      
      if (mounted) {
        setState(() {
          _adminList = admins;
          _isLoading = false;
        });
        
        // Force a small delay to ensure UI updates properly
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load admins: $e')),
        );
      }
    }
  }

  String _getHospitalName(String hospitalId) {
    if (hospitalId.isEmpty) return 'Unassigned';
    final hospital = _hospitalList.firstWhere(
      (h) => h.id == hospitalId,
      orElse: () => HospitalData(
        id: hospitalId,
        name: 'Unknown Hospital',
        address: '',
        mobileNumbers: [],
        emails: [],
        adminId: '',
        suspended: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return hospital.name;
  }

  // Helper method to check if a hospital already has an admin assigned
  AdminData? _getHospitalCurrentAdmin(String hospitalId) {
    if (hospitalId.isEmpty) return null;
    
    try {
      return _adminList.firstWhere(
        (admin) => admin.hospitalId == hospitalId,
      );
    } catch (e) {
      return null; // No admin found for this hospital
    }
  }

  // Helper method to get hospital data by ID
  HospitalData? _getHospitalById(String hospitalId) {
    if (hospitalId.isEmpty) return null;
    
    try {
      return _hospitalList.firstWhere(
        (hospital) => hospital.id == hospitalId,
      );
    } catch (e) {
      return null;
    }
  }

  // Show conflict resolution dialog for hospital assignment
  Future<dynamic> _showHospitalAssignmentConflictDialog({
    required String targetHospitalId,
    required String targetHospitalName,
    required AdminData currentAdminOfTargetHospital,
    AdminData? adminBeingEdited, // null if creating new admin
  }) async {
    final isCreating = adminBeingEdited == null;
    final isEditingAdminWithHospital = adminBeingEdited?.hospitalId.isNotEmpty ?? false;

    return await showDialog<dynamic>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 10),
            const Text('Hospital Assignment Conflict'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The hospital "$targetHospitalName" already has an admin assigned:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Admin: ${currentAdminOfTargetHospital.name}'),
                  Text('Email: ${currentAdminOfTargetHospital.email}'),
                  Text('ID: ${currentAdminOfTargetHospital.persId}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            if (isCreating || !isEditingAdminWithHospital) ...[
              const Text(
                'Would you like to proceed? This will:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• Assign the ${isCreating ? 'new' : 'selected'} admin to "$targetHospitalName"'),
              Text('• Remove "${currentAdminOfTargetHospital.name}" from "$targetHospitalName"'),
            ] else ...[
              Text(
                'You are editing "${adminBeingEdited!.name}" who is currently assigned to "${_getHospitalName(adminBeingEdited.hospitalId)}".',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('What would you like to do?'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          
          if (isCreating || !isEditingAdminWithHospital) ...[
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Proceed'),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true), // Regular assignment
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Assign Only'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop('swap'), // Swap hospitals
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Swap Hospitals'),
            ),
          ],
        ],
      ),
    ) ?? false;
  }

  // Perform hospital assignment with conflict resolution
  Future<void> _performHospitalAssignment({
    required String adminId,
    required String targetHospitalId,
    AdminData? currentAdminOfTargetHospital,
    AdminData? adminBeingEdited,
    bool isSwap = false,
  }) async {
    if (currentAdminOfTargetHospital == null) {
      // No conflict, just assign normally
      await _adminProvider.updateAdmin(
        token: widget.token,
        adminId: adminId,
        updatedFields: {'hospital': targetHospitalId},
      );
      return;
    }

    if (isSwap && adminBeingEdited != null) {
      // Swap hospitals between two admins
      final adminBeingEditedOldHospital = adminBeingEdited.hospitalId;
      
      // Update the admin being edited to the new hospital
      await _adminProvider.updateAdmin(
        token: widget.token,
        adminId: adminId,
        updatedFields: {'hospital': targetHospitalId},
      );
      
      // Update the current admin of target hospital to the old hospital
      await _adminProvider.updateAdmin(
        token: widget.token,
        adminId: currentAdminOfTargetHospital.id,
        updatedFields: {'hospital': adminBeingEditedOldHospital},
      );
    } else {
      // Regular assignment: assign new admin, unassign current admin
      await _adminProvider.updateAdmin(
        token: widget.token,
        adminId: adminId,
        updatedFields: {'hospital': targetHospitalId},
      );
      
      // Unassign the current admin
      await _adminProvider.updateAdmin(
        token: widget.token,
        adminId: currentAdminOfTargetHospital.id,
        updatedFields: {'hospital': ''},
      );
    }
  }

  void _showAddAdminDialog() {
    final formKey = GlobalKey<FormState>();
    
    // Form state variables
    String persId = '';
    String name = '';
    String password = '';
    String email = '';
    String mobileNumber = '';
    String? selectedHospitalId;
    bool suspended = false;
    
    // Controllers for search fields
    TextEditingController hospitalSearchController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          // Filter hospitals based on search
          List<HospitalData> filteredHospitals = _hospitalList.where((hospital) {
            final query = hospitalSearchController.text.toLowerCase();
            return query.isEmpty || 
              hospital.name.toLowerCase().contains(query) ||
              hospital.address.toLowerCase().contains(query);
          }).toList();

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: const Color(0xFFEC407A)),
                const SizedBox(width: 10),
                const Text('Add New Admin', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Personal Information', 
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )
                            ),
                            const SizedBox(height: 16),
                            
                            // Personal ID
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Personal ID',
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Enter Personal ID' : null,
                              onSaved: (val) => persId = val!.trim(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Name
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Enter Full Name' : null,
                              onSaved: (val) => name = val!.trim(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Enter Email';
                                if (!val.contains('@')) return 'Enter valid email';
                                return null;
                              },
                              onSaved: (val) => email = val!.trim(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Mobile Number
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Mobile Number',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Enter Mobile Number' : null,
                              onSaved: (val) => mobileNumber = val!.trim(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Password
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Enter Password' : null,
                              onSaved: (val) => password = val!.trim(),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Hospital Assignment Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hospital Assignment', 
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )
                            ),
                            const SizedBox(height: 16),
                            
                            // Hospital search field
                            TextField(
                              controller: hospitalSearchController,
                              decoration: InputDecoration(
                                labelText: 'Search Hospitals',
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                                suffixIcon: hospitalSearchController.text.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        hospitalSearchController.clear();
                                        setDialogState(() {});
                                      },
                                    )
                                  : null,
                              ),
                              onChanged: (query) {
                                setDialogState(() {});
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Hospital dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Hospital',
                                prefixIcon: Icon(Icons.local_hospital),
                                border: OutlineInputBorder(),
                              ),
                              value: selectedHospitalId,
                              hint: const Text('Choose a hospital (optional)'),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('No Hospital Assignment'),
                                ),
                                ...filteredHospitals.map((hospital) {
                                  return DropdownMenuItem<String>(
                                    value: hospital.id,
                                    child: Text('${hospital.name} - ${hospital.address}'),
                                  );
                                }).toList(),
                              ],
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedHospitalId = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Status Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status', 
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )
                            ),
                            const SizedBox(height: 16),
                            
                            // Suspended checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: suspended,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      suspended = val ?? false;
                                    });
                                  },
                                ),
                                const Text('Suspended'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  formKey.currentState!.save();
                  Navigator.of(context).pop();

                  // Check for hospital assignment conflicts
                  if (selectedHospitalId != null && selectedHospitalId!.isNotEmpty) {
                    final currentAdminOfTargetHospital = _getHospitalCurrentAdmin(selectedHospitalId!);
                    final targetHospital = _getHospitalById(selectedHospitalId!);
                    
                    if (currentAdminOfTargetHospital != null && targetHospital != null) {
                      // Show conflict dialog
                      final shouldProceed = await _showHospitalAssignmentConflictDialog(
                        targetHospitalId: selectedHospitalId!,
                        targetHospitalName: targetHospital.name,
                        currentAdminOfTargetHospital: currentAdminOfTargetHospital,
                        adminBeingEdited: null, // Creating new admin
                      );
                      
                      if (!shouldProceed) {
                        return; // User cancelled
                      }
                    }
                  }

                  // Show loading
                  setState(() => _isLoading = true);
                  
                  try {
                    // Create the admin first
                    await _adminProvider.createAdmin(
                      token: widget.token,
                      persId: persId,
                      name: name,
                      password: password,
                      email: email,
                      mobileNumber: mobileNumber,
                      hospitalId: '', // Initially unassigned
                      suspended: suspended,
                    );
                    
                    // Refresh admin list to get the new admin
                    await _fetchAdmins();
                    
                    // Find the newly created admin
                    final newAdmin = _adminList.firstWhere(
                      (admin) => admin.persId == persId && admin.email == email,
                    );
                    
                    // If hospital was selected, handle assignment with conflict resolution
                    if (selectedHospitalId != null && selectedHospitalId!.isNotEmpty) {
                      final currentAdminOfTargetHospital = _getHospitalCurrentAdmin(selectedHospitalId!);
                      
                      await _performHospitalAssignment(
                        adminId: newAdmin.id,
                        targetHospitalId: selectedHospitalId!,
                        currentAdminOfTargetHospital: currentAdminOfTargetHospital,
                        adminBeingEdited: null,
                        isSwap: false,
                      );
                      
                      // Refresh again after hospital assignment
                      await _fetchAdmins();
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Admin created successfully')),
                      );
                    }
                  } catch (e) {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to create admin: $e')),
                      );
                    }
                  }
                  // Note: _fetchAdmins() already manages _isLoading state
                },
                child: const Text('Create Admin'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditAdminDialog(AdminData admin) {
    final formKey = GlobalKey<FormState>();
    
    // Form state variables
    String persId = admin.persId;
    String name = admin.name;
    String email = admin.email;
    String mobileNumber = admin.mobileNumber;
    String? selectedHospitalId = admin.hospitalId.isNotEmpty ? admin.hospitalId : null;
    bool suspended = admin.suspended;
    String password = ''; // New password field
    
    // Controllers for search fields
    TextEditingController hospitalSearchController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          // Filter hospitals based on search
          List<HospitalData> filteredHospitals = _hospitalList.where((hospital) {
            final query = hospitalSearchController.text.toLowerCase();
            return query.isEmpty || 
              hospital.name.toLowerCase().contains(query) ||
              hospital.address.toLowerCase().contains(query);
          }).toList();

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.edit, color: const Color(0xFFEC407A)),
                const SizedBox(width: 10),
                const Text('Edit Admin', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Personal Information', 
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )
                            ),
                            const SizedBox(height: 16),
                            
                            // Personal ID
                            TextFormField(
                              initialValue: persId,
                              decoration: const InputDecoration(
                                labelText: 'Personal ID',
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Enter Personal ID' : null,
                              onSaved: (val) => persId = val!.trim(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Name
                            TextFormField(
                              initialValue: name,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Enter Full Name' : null,
                              onSaved: (val) => name = val!.trim(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email
                            TextFormField(
                              initialValue: email,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Enter Email';
                                if (!val.contains('@')) return 'Enter valid email';
                                return null;
                              },
                              onSaved: (val) => email = val!.trim(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Mobile Number
                            TextFormField(
                              initialValue: mobileNumber,
                              decoration: const InputDecoration(
                                labelText: 'Mobile Number',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Enter Mobile Number' : null,
                              onSaved: (val) => mobileNumber = val!.trim(),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Password
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'New Password (optional)',
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(),
                                helperText: 'Leave blank to keep current password',
                              ),
                              obscureText: true,
                              onSaved: (val) => password = val?.trim() ?? '',
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Hospital Assignment Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hospital Assignment', 
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )
                            ),
                            const SizedBox(height: 16),
                            
                            // Hospital search field
                            TextField(
                              controller: hospitalSearchController,
                              decoration: InputDecoration(
                                labelText: 'Search Hospitals',
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                                suffixIcon: hospitalSearchController.text.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        hospitalSearchController.clear();
                                        setDialogState(() {});
                                      },
                                    )
                                  : null,
                              ),
                              onChanged: (query) {
                                setDialogState(() {});
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Hospital dropdown
                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Select Hospital',
                                prefixIcon: Icon(Icons.local_hospital),
                                border: OutlineInputBorder(),
                              ),
                              value: selectedHospitalId,
                              hint: const Text('Choose a hospital (optional)'),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('No Hospital Assignment'),
                                ),
                                ...filteredHospitals.map((hospital) {
                                  return DropdownMenuItem<String>(
                                    value: hospital.id,
                                    child: Text('${hospital.name} - ${hospital.address}'),
                                  );
                                }).toList(),
                              ],
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedHospitalId = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Status Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status', 
                              style: TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEC407A),
                              )
                            ),
                            const SizedBox(height: 16),
                            
                            // Suspended checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: suspended,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      suspended = val ?? false;
                                    });
                                  },
                                ),
                                const Text('Suspended'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  formKey.currentState!.save();
                  Navigator.of(context).pop();

                  // Check for hospital assignment conflicts
                  bool isSwap = false;
                  if (selectedHospitalId != null && selectedHospitalId!.isNotEmpty) {
                    final currentAdminOfTargetHospital = _getHospitalCurrentAdmin(selectedHospitalId!);
                    final targetHospital = _getHospitalById(selectedHospitalId!);
                    
                    // Only check for conflicts if the target hospital has a different admin
                    if (currentAdminOfTargetHospital != null && 
                        currentAdminOfTargetHospital.id != admin.id && 
                        targetHospital != null) {
                      
                      // Show conflict dialog
                      final result = await _showHospitalAssignmentConflictDialog(
                        targetHospitalId: selectedHospitalId!,
                        targetHospitalName: targetHospital.name,
                        currentAdminOfTargetHospital: currentAdminOfTargetHospital,
                        adminBeingEdited: admin,
                      );
                      
                      if (result == false) {
                        return; // User cancelled
                      } else if (result == 'swap') {
                        isSwap = true;
                      }
                    }
                  }

                  // Show loading
                  setState(() => _isLoading = true);
                  
                  try {
                    // Prepare updated fields
                    Map<String, dynamic> updatedFields = {
                      'persId': persId,
                      'name': name,
                      'email': email,
                      'mobileNumber': mobileNumber,
                      'suspended': suspended,
                    };
                    
                    // Only include password if it's provided
                    if (password.isNotEmpty) {
                      updatedFields['password'] = password;
                    }
                    
                    // Update non-hospital fields first
                    await _adminProvider.updateAdmin(
                      token: widget.token,
                      adminId: admin.id,
                      updatedFields: updatedFields,
                    );
                    
                    // Handle hospital assignment with conflict resolution
                    final targetHospitalId = selectedHospitalId ?? '';
                    if (targetHospitalId != admin.hospitalId) {
                      // Hospital assignment is changing
                      if (targetHospitalId.isNotEmpty) {
                        final currentAdminOfTargetHospital = _getHospitalCurrentAdmin(targetHospitalId);
                        
                        await _performHospitalAssignment(
                          adminId: admin.id,
                          targetHospitalId: targetHospitalId,
                          currentAdminOfTargetHospital: currentAdminOfTargetHospital,
                          adminBeingEdited: admin,
                          isSwap: isSwap,
                        );
                      } else {
                        // Unassigning from hospital
                        await _adminProvider.updateAdmin(
                          token: widget.token,
                          adminId: admin.id,
                          updatedFields: {'hospital': ''},
                        );
                      }
                    }
                    
                    // Refresh the list immediately after successful update
                    await _fetchAdmins();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Admin updated successfully')),
                      );
                    }
                  } catch (e) {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update admin: $e')),
                      );
                    }
                  }
                  // Note: _fetchAdmins() already manages _isLoading state, so we don't need finally block
                },
                child: const Text('Update Admin'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(AdminData admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text('Are you sure you want to delete admin "${admin.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              // Show loading
              setState(() => _isLoading = true);
              
              try {
                await _adminProvider.deleteAdmin(
                  token: widget.token,
                  adminId: admin.id,
                );
                
                // Refresh the list immediately after successful deletion
                await _fetchAdmins();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin deleted successfully')),
                  );
                }
              } catch (e) {
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete admin: $e')),
                  );
                }
              }
              // Note: _fetchAdmins() already manages _isLoading state
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter admins based on search query
    List<AdminData> filteredAdmins = _adminList.where((admin) {
      final query = _searchQuery.toLowerCase();
      return query.isEmpty ||
          admin.name.toLowerCase().contains(query) ||
          admin.email.toLowerCase().contains(query) ||
          admin.persId.toLowerCase().contains(query) ||
          _getHospitalName(admin.hospitalId).toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 32, color: const Color(0xFFEC407A)),
                const SizedBox(width: 12),
                const Text(
                  'Admins Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEC407A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Controls Row
            Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search admins...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Admins')),
                        DropdownMenuItem(value: 'unsuspended', child: Text('Active')),
                        DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filter = value!;
                        });
                        _fetchAdmins();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Add Button
                ElevatedButton.icon(
                  onPressed: _showAddAdminDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEC407A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Results Info
            Text(
              'Showing ${filteredAdmins.length} of ${_adminList.length} admins',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Data Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredAdmins.isEmpty
                      ? const Center(
                          child: Text(
                            'No admins found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : BetterPaginatedDataTable(
                          themeColor: const Color(0xFFEC407A),
                          rowsPerPage: 10,
                          columns: const [
                            DataColumn(label: Text('Personal ID')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Mobile')),
                            DataColumn(label: Text('Hospital')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: filteredAdmins
                              .map(
                                (admin) => DataRow(
                                  cells: [
                                    DataCell(Text(admin.persId)),
                                    DataCell(Text(admin.name)),
                                    DataCell(Text(admin.email)),
                                    DataCell(Text(admin.mobileNumber)),
                                    DataCell(Text(_getHospitalName(admin.hospitalId))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: admin.suspended
                                              ? Colors.red.shade100
                                              : Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          admin.suspended ? 'Suspended' : 'Active',
                                          style: TextStyle(
                                            color: admin.suspended
                                                ? Colors.red.shade700
                                                : Colors.green.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _showEditAdminDialog(admin),
                                            tooltip: 'Edit Admin',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _showDeleteConfirmation(admin),
                                            tooltip: 'Delete Admin',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }
} 