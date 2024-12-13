import 'package:flutter/material.dart';

class SuperAdminMainPage extends StatefulWidget {
  const SuperAdminMainPage({super.key});

  @override
  State<SuperAdminMainPage> createState() => _SuperAdminMainPageState();
}

class _SuperAdminMainPageState extends State<SuperAdminMainPage> {
  int selectedIndex = 0; // Tracks the selected button (0 = Dashboard, 1 = Problems)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
              appBar: AppBar(
          toolbarHeight: 110,
          flexibleSpace: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.white,
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/pic.png',
                            height: 40,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'CURANICS',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: Text(
                        'Super Admin',
                        style: TextStyle(
                          color: Color.fromARGB(255, 229, 45, 134),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Color.fromARGB(255, 229, 45, 134),
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildNavItem(0, Icons.local_hospital, "Dashboard"),
                    _buildNavItem(1, Icons.warning_amber_outlined, "Problems"),
                  ],
                ),
              ),
            ],
          ),
          elevation: 0,
          backgroundColor: Colors.transparent, // Ensure transparency
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/back.png'),
              fit: BoxFit.cover,
              alignment: Alignment.topLeft,
              scale: 4.0,
            ),
          ),
        
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 223, 47, 132),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                  ),
                ),
                onPressed: () {
                  // Navigate to View Patients Page
                },
                child: const Text('View patients'),
              ),
              const SizedBox(height: 70),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 223, 47, 132),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                  ),
                ),
                onPressed: () {
                  // Navigate to View Doctors Page
                },
                child: const Text('View doctors'),
              ),
              const SizedBox(height: 70),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 223, 47, 132),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 20,
                  ),
                ),
                onPressed: () {
                  // Navigate to View Hospitals Page
                },
                child: const Text('View hospitals'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget for each navigation item
  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index; // Update the selected index
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color.fromARGB(255, 232, 142, 173) : Color.fromARGB(255, 223, 47, 132),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
