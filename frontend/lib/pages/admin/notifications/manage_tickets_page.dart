import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/ticket.dart';
import 'package:intl/intl.dart';

// Import the new shared widget
import '../../../shared/components/components.dart';

class ManageTicketsPage extends StatefulWidget {
  const ManageTicketsPage({super.key});

  @override
  _ManageTicketsPageState createState() => _ManageTicketsPageState();
}

class _ManageTicketsPageState extends State<ManageTicketsPage> {
  String _searchQuery = '';
  bool _showOnlyPending = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        // Filter tickets by search query + pending
        final List<Ticket> tickets = dataProvider.tickets
            .where((t) =>
        t.userId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.issue.toLowerCase().contains(_searchQuery.toLowerCase()))
            .where((t) => !_showOnlyPending || t.status != 'resolved')
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // (A) Our reusable "SearchAndPendingRow"
              SearchAndPendingRow(
                searchLabel: 'Search Tickets',
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                showOnlyPending: _showOnlyPending,
                onTogglePending: (value) {
                  setState(() {
                    _showOnlyPending = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 20),

              // (B) The tickets list
              Expanded(
                child: ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final Ticket ticket = tickets[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(ticket.role),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User ID: ${ticket.userId}'),
                            Text('Issue: ${ticket.issue}'),
                            Text('Date: ${ticket.createdAt != null ? DateFormat('yyyy-MM-dd').format(ticket.createdAt!) : 'N/A'}'),
                          ],
                        ),
                        trailing: _showOnlyPending
                            ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                dataProvider.approveTicket(ticket.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ticket Approved')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                dataProvider.rejectTicket(ticket.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ticket Rejected')),
                                );
                              },
                            ),
                          ],
                        )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
