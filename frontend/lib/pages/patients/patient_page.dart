import 'package:flutter/material.dart';
import 'package:frontend/shared/widgets/logo_bar.dart'; // Update with your actual import path

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  _PatientPageState createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  int selectedIndex = 0; // Tracks the selected navigation item

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: LogoLine(), // Using the shared LogoLine widget
      ),
      body: Column(
        children: [
          // Pink Navigation Row directly below the logo row
          Container(
            color: const Color.fromARGB(255, 218, 73, 143),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Navigation items
                Row(
                  children: [
                    _buildNavItem(Icons.account_circle, 'Account', 0),
                    const SizedBox(width: 20),
                    _buildNavItem(Icons.notifications, 'Notifications', 1),
                    const SizedBox(width: 20),
                    _buildNavItem(Icons.assignment, 'Results', 2),
                  ],
                ),
                // Three action buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Handle request for modification 1
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        // Handle request for modification 2
                      },
                      icon: const Icon(Icons.feedback, color: Colors.white),
                    ),
                    IconButton(
                      onPressed: () {
                        // Handle request for modification 3
                      },
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Patient Information Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Patient Profile Picture and Name
                            const Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      AssetImage('assets/images/patient_image.png'), // Replace with actual path
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Abbey Carter',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            // Patient Details in Two Columns
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDetailItem(Icons.phone, 'Mobile Number',
                                            '+91 9505999901'),
                                      ),
                                      Expanded(
                                        child: _buildDetailItem(Icons.medical_services, 'Problem',
                                            'Brain Tumor'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDetailItem(
                                            Icons.female, 'Gender', 'Female'),
                                      ),
                                      Expanded(
                                        child: _buildDetailItem(Icons.health_and_safety,
                                            'Patient Status', 'On Recovery'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDetailItem(Icons.email, 'Email Address',
                                            'abbey@gmail.com'),
                                      ),
                                      Expanded(
                                        child: _buildDetailItem(Icons.location_on, 'Address',
                                            'Hyderabad, Telangana'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDetailItem(
                                            Icons.person, 'Doctor', 'Dr Preethi'),
                                      ),
                                      Expanded(
                                        child: _buildDetailItem(
                                            Icons.local_hospital, 'Hospital', 'Somewhere, ?'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Device Information Section
                    const Text(
                      'Device information:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildDeviceInfoItem('Device ID', '102567'),
                            const SizedBox(width: 20),
                            _buildDeviceInfoItem('MAC ID', '3324'),
                            const SizedBox(width: 20),
                            _buildDeviceInfoItem('Status', 'ON'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to create navigation items
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index; // Update the selected navigation item
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 255, 200, 230) // Light pink background
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color.fromARGB(255, 218, 73, 143) // Pink icon when selected
                  : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color.fromARGB(255, 218, 73, 143)
                    : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create detail items
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color.fromARGB(255, 218, 73, 143), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to create device information items
  Widget _buildDeviceInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 218, 73, 143),
          ),
        ),
      ],
    );
  }
}
