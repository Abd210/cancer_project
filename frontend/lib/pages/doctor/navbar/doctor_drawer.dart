import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class DoctorDrawer extends StatelessWidget {
  final Function(int) onMenuItemClicked;
  final int selectedIndex;

  const DoctorDrawer({
    required this.onMenuItemClicked,
    required this.selectedIndex,
    super.key,
  });

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
                  'Doctor Portal',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Notifications
            _buildDrawerItem(Icons.notifications, 'Notifications', 0),
            // Appointments
            _buildDrawerItem(Icons.event, 'Appointments', 1),
            // Patients
            _buildDrawerItem(Icons.group, 'Patients', 2),
            // Reports
            _buildDrawerItem(Icons.description, 'Reports', 3),
            const Divider(color: Colors.white70),
            // Logout
            _buildDrawerItem(Icons.logout, 'Logout', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    bool isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white70,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.accentColor,
      onTap: () => onMenuItemClicked(index),
    );
  }
}
