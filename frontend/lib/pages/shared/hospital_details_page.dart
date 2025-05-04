import 'package:flutter/material.dart';
import '../../models/hospital_data.dart';
import '../../providers/hospital_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HospitalDetailsPage extends StatefulWidget {
  final String hospitalId;
  final String token;

  const HospitalDetailsPage({
    Key? key,
    required this.hospitalId,
    required this.token,
  }) : super(key: key);

  @override
  State<HospitalDetailsPage> createState() => _HospitalDetailsPageState();
}

class _HospitalDetailsPageState extends State<HospitalDetailsPage> {
  final HospitalProvider _hospitalProvider = HospitalProvider();

  bool _isLoading = true;
  HospitalData? _hospitalData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHospitalData();
  }

  Future<void> _fetchHospitalData() async {
    setState(() => _isLoading = true);

    try {
      print(
          'HOSPITAL PAGE: Fetching data for hospital ID: ${widget.hospitalId}');

      // Use the permission-safe method that handles 403 errors gracefully
      final hospitalData = await _hospitalProvider.getHospitalSafe(
        token: widget.token,
        hospitalId: widget.hospitalId,
      );

      setState(() {
        _hospitalData = hospitalData;
        _isLoading = false;
        _errorMessage = null;
      });

      print(
          'HOSPITAL PAGE: Successfully fetched hospital: ${_hospitalData?.name}');
    } catch (e) {
      print('HOSPITAL PAGE: Error fetching hospital data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load hospital details: $e';
      });

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Failed to load hospital details: $e',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHospitalData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchHospitalData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_hospitalData == null) {
      return const Center(child: Text('Hospital data not available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hospital Card
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.local_hospital,
                            size: 50, color: Colors.blue),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hospitalData!.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _hospitalData!.suspended
                                    ? Colors.red.shade100
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _hospitalData!.suspended
                                    ? 'Suspended'
                                    : 'Active',
                                style: TextStyle(
                                  color: _hospitalData!.suspended
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Hospital Information
                  _buildInfoRow('Hospital ID', _hospitalData!.id),
                  const SizedBox(height: 10),
                  _buildInfoRow('Address', _hospitalData!.address),
                  const SizedBox(height: 10),

                  // Contact Information
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Email Addresses
                  if (_hospitalData!.emails.isNotEmpty) ...[
                    const Text(
                      'Email Addresses:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    ..._hospitalData!.emails.map((email) => Padding(
                          padding: const EdgeInsets.only(left: 10, bottom: 5),
                          child: Row(
                            children: [
                              const Icon(Icons.email,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(email),
                            ],
                          ),
                        )),
                    const SizedBox(height: 10),
                  ],

                  // Mobile Numbers
                  if (_hospitalData!.mobileNumbers.isNotEmpty) ...[
                    const Text(
                      'Phone Numbers:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    ..._hospitalData!.mobileNumbers.map((phone) => Padding(
                          padding: const EdgeInsets.only(left: 10, bottom: 5),
                          child: Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(phone),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
