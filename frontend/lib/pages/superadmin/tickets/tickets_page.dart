// lib/pages/superadmin/tickets/tickets_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/data_provider.dart';
import '../../../models/ticket.dart';
import '../../../shared/components/loading_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({Key? key}) : super(key: key);

  @override
  _TicketsPageState createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  String _searchQuery = '';
  bool _showOnlyPending = true;

  void _showTicketDetails(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ticket Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requester: ${ticket.requester}'),
            SizedBox(height: 10),
            Text('Type: ${ticket.requestType}'),
            SizedBox(height: 10),
            Text('Description: ${ticket.description}'),
            SizedBox(height: 10),
            Text('Date: ${DateFormat('yyyy-MM-dd').format(ticket.date)}'),
            SizedBox(height: 10),
            Text('Status: ${ticket.isApproved ? "Approved" : "Pending"}'),
          ],
        ),
        actions: [
          if (!ticket.isApproved)
            TextButton(
              onPressed: () {
                Provider.of<DataProvider>(context, listen: false).approveTicket(ticket.id);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Ticket approved.');
              },
              child: Text('Approve', style: TextStyle(color: Colors.green)),
            ),
          if (!ticket.isApproved)
            TextButton(
              onPressed: () {
                Provider.of<DataProvider>(context, listen: false).rejectTicket(ticket.id);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Ticket rejected.');
              },
              child: Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleShowOnlyPending(bool? value) {
    setState(() {
      _showOnlyPending = value ?? false;
    });
  }

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
              // Search and Toggle Pending
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Search Tickets',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _showOnlyPending,
                        onChanged: _toggleShowOnlyPending,
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      Text('Show Only Pending'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Tickets DataTable with Actions
              Expanded(
                child: ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final Ticket ticket = tickets[index];
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
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
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () => dataProvider.approveTicket(ticket.id),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => dataProvider.rejectTicket(ticket.id),
                            ),
                          ],
                        )
                            : null,
                        onTap: () => _showTicketDetails(context, ticket),
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
