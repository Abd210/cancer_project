import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/ticket.dart';
import 'package:intl/intl.dart';

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
        List<Ticket> tickets = dataProvider.tickets
            .where((t) =>
        t.requester.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.requestType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.description.toLowerCase().contains(_searchQuery.toLowerCase()))
            .where((t) => !_showOnlyPending || !t.isApproved)
            .toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search and Toggle
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search Tickets',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _showOnlyPending,
                        onChanged: (value) {
                          setState(() {
                            _showOnlyPending = value!;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      const Text('Show Only Pending'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Tickets List
              Expanded(
                child: ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final Ticket ticket = tickets[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(ticket.requestType),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Requester: ${ticket.requester}'),
                            Text('Description: ${ticket.description}'),
                            Text('Date: ${DateFormat('yyyy-MM-dd').format(ticket.date)}'),
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
