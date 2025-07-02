import 'package:flutter/material.dart';
import '../../../services/static_data.dart';
import '../../../models/ticket.dart';
import '../../../shared/widgets/background.dart';
import '../../../shared/theme/app_theme.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  void _showTicketDetails(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ticket Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('User ID: ${ticket.userId}'),
            Text('Role: ${ticket.role}'),
            Text('Issue: ${ticket.issue}'),
            Text('Date: ${ticket.createdAt?.toLocal() ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Handle ticket resolution or other logic
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Ticket Requests',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: StaticData.tickets.length,
              itemBuilder: (context, index) {
                final Ticket ticket = StaticData.tickets[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: ListTile(
                    title: Text(ticket.role),
                    subtitle: Text('User ID: ${ticket.userId}'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _showTicketDetails(context, ticket),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
