import 'package:flutter/material.dart';
import 'theme.dart';

class Sidebar extends StatelessWidget {
  final Function(int) onMenuItemClicked;
  final int selectedIndex;

  const Sidebar({required this.onMenuItemClicked, required this.selectedIndex, super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppTheme.primaryColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
              ),
              child: Center(
                child: Text(
                  'Super Admin',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            _buildDrawerItem(Icons.local_hospital, 'Hospitals', 0, context),
            _buildDrawerItem(Icons.person, 'Doctors', 1, context),
            _buildDrawerItem(Icons.group, 'Patients', 2, context),
            _buildDrawerItem(Icons.rocket, 'Tickets', 3, context),
            const Divider(color: Colors.white70),
            _buildDrawerItem(Icons.logout, 'Logout', 4, context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      selected: selectedIndex == index,
      selectedTileColor: AppTheme.accentColor,
      onTap: () {
        Navigator.pop(context); // Close the drawer
        onMenuItemClicked(index);
      },
    );
  }
}
