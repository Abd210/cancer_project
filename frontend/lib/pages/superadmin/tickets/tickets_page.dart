import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../../providers/data_provider.dart';
import '../../../models/ticket.dart';
import '../../../shared/components/components.dart';
import '../../../shared/components/responsive_data_table.dart' show BetterDataTable;

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

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
        title: const Text('Ticket Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requester: ${ticket.requester}'),
            const SizedBox(height: 10),
            Text('Type: ${ticket.requestType}'),
            const SizedBox(height: 10),
            Text('Description: ${ticket.description}'),
            const SizedBox(height: 10),
            Text('Date: ${DateFormat('yyyy-MM-dd').format(ticket.date)}'),
            const SizedBox(height: 10),
            Text('Status: ${ticket.isApproved ? "Approved" : "Pending"}'),
          ],
        ),
        actions: [
          if (!ticket.isApproved)
            TextButton(
              onPressed: () {
                Provider.of<DataProvider>(context, listen: false)
                    .approveTicket(ticket.id);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Ticket approved.');
              },
              child: const Text('Approve', style: TextStyle(color: Colors.green)),
            ),
          if (!ticket.isApproved)
            TextButton(
              onPressed: () {
                Provider.of<DataProvider>(context, listen: false)
                    .rejectTicket(ticket.id);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Ticket rejected.');
              },
              child: const Text('Reject', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
        // Filter tickets by query + showOnlyPending
        List<Ticket> tickets = dataProvider.tickets
            .where((t) =>
        t.requester.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.requestType
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            t.description
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .where((t) => !_showOnlyPending || !t.isApproved)
            .toList();

        // Convert tickets to DataRow
        final rows = tickets.map((ticket) {
          return DataRow(
            cells: [
              DataCell(Text(ticket.id)),
              DataCell(Text(ticket.requester)),
              DataCell(Text(ticket.requestType)),
              DataCell(Text(ticket.description)),
              DataCell(Text(DateFormat('yyyy-MM-dd').format(ticket.date))),
              DataCell(Text(ticket.isApproved ? 'Approved' : 'Pending')),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!ticket.isApproved)
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          dataProvider.approveTicket(ticket.id);
                          Fluttertoast.showToast(msg: 'Ticket approved.');
                        },
                      ),
                    if (!ticket.isApproved)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          dataProvider.rejectTicket(ticket.id);
                          Fluttertoast.showToast(msg: 'Ticket rejected.');
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.info, color: Colors.blueGrey),
                      onPressed: () => _showTicketDetails(context, ticket),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Our new search + pending row
              SearchAndPendingRow(
                searchLabel: 'Search Tickets',
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                showOnlyPending: _showOnlyPending,
                onTogglePending: _toggleShowOnlyPending,
              ),
              const SizedBox(height: 20),

              // Display the table
              Expanded(
                child: BetterDataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Requester')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Description')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: rows,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
