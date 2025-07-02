import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:frontend/providers/hospital_provider.dart';
import 'package:frontend/providers/admin_provider.dart';
import 'package:frontend/models/hospital_data.dart';
import 'package:frontend/models/admin_data.dart';
import '../../../shared/components/loading_indicator.dart';

class AdminHospitalPage extends StatefulWidget {
  final String token;
  
  const AdminHospitalPage({
    Key? key, 
    required this.token,
  }) : super(key: key);

  @override
  State<AdminHospitalPage> createState() => _AdminHospitalPageState();
}

class _AdminHospitalPageState extends State<AdminHospitalPage> {
  final HospitalProvider _hospitalProvider = HospitalProvider();
  final AdminProvider _adminProvider = AdminProvider();
  
  bool _isLoading = false;
  HospitalData? _hospital;
  AdminData? _admin;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHospitalData();
  }

  Future<void> _loadHospitalData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get all admins (the current admin should be in the list since they're authenticated)
      final admins = await _adminProvider.getAdmins(
        token: widget.token,
      );
      
      if (admins.isNotEmpty) {
        // For now, take the first admin (assuming single admin per token)
        // In a proper implementation, you'd decode the JWT to get the specific admin ID
        _admin = admins.first;
        
        // If admin has a hospital assigned, get hospital data
        if (_admin!.hospitalId.isNotEmpty) {
          final hospitals = await _hospitalProvider.getHospitals(
            token: widget.token,
            hospitalId: _admin!.hospitalId,
          );
          
          if (hospitals.isNotEmpty) {
            _hospital = hospitals.first;
          } else {
            _error = 'Hospital not found';
          }
        } else {
          _error = 'No hospital assigned to your account';
        }
      } else {
        _error = 'Admin data not found';
      }
    } catch (e) {
      _error = 'Failed to load hospital data: $e';
      Fluttertoast.showToast(msg: _error!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingIndicator();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Hospital'),
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFEC407A).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _error != null
            ? _buildErrorState()
            : _hospital != null
                ? _buildHospitalInfo()
                : _buildNoHospitalState(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loadHospitalData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC407A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoHospitalState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Hospital Assigned',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You are not currently assigned to any hospital.\nPlease contact your administrator.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hospital Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC407A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        size: 32,
                        color: Color(0xFFEC407A),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hospital!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _hospital!.suspended ? Colors.red[100] : Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _hospital!.suspended ? 'Suspended' : 'Active',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _hospital!.suspended ? Colors.red[700] : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Address Card
          _buildInfoCard(
            icon: Icons.location_on,
            title: 'Address',
            content: _hospital!.address,
            iconColor: Colors.blue[600]!,
          ),

          const SizedBox(height: 16),

          // Contact Information
          if (_hospital!.mobileNumbers.isNotEmpty || _hospital!.emails.isNotEmpty) ...[
            _buildContactCard(),
            const SizedBox(height: 16),
          ],

          // Hospital ID Card
          _buildInfoCard(
            icon: Icons.fingerprint,
            title: 'Hospital ID',
            content: _hospital!.id,
            iconColor: Colors.purple[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[600]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.contact_phone,
                  size: 24,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          
          if (_hospital!.mobileNumbers.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Phone Numbers',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...(_hospital!.mobileNumbers.map((phone) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ))),
          ],

          if (_hospital!.emails.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Email Addresses',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            ...(_hospital!.emails.map((email) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ))),
          ],
        ],
      ),
    );
  }
} 