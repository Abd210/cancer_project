// lib/shared/components/custom_drawer.dart
import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';

class CustomDrawer extends StatelessWidget {
  final Function(int) onMenuItemClicked;
  final int selectedIndex;

  const CustomDrawer({
    required this.onMenuItemClicked,
    required this.selectedIndex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppTheme.primaryColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
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
            _buildDrawerItem(Icons.local_hospital, 'Hospitals', 0),
            _buildDrawerItem(Icons.person, 'Doctors', 1),
            _buildDrawerItem(Icons.group, 'Patients', 2),
            _buildDrawerItem(Icons.device_hub, 'Devices', 3),
            _buildDrawerItem(Icons.event, 'Appointments', 4),
            _buildDrawerItem(Icons.rocket, 'Tickets', 5),
            Divider(color: Colors.white70),
            _buildDrawerItem(Icons.logout, 'Logout', 6),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      selected: selectedIndex == index,
      selectedTileColor: AppTheme.accentColor,
      onTap: () {
        onMenuItemClicked(index);
      },
    );
  }
}
