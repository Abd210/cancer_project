import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../../providers/data_provider.dart';
import '../../../models/ticket.dart';
import '../../../shared/components/components.dart';
import '../../../shared/components/responsive_data_table.dart' show BetterPaginatedDataTable;

class TicketsPage extends StatefulWidget {
  final String token;
  const TicketsPage({super.key, required this.token});

  @override
  _TicketsPageState createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  String _searchQuery = '';
  bool _showOnlyOpen = true;

  void _showTicketDetails(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ticket Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID: ${ticket.userId}'),
            const SizedBox(height: 10),
            Text('Role: ${ticket.role}'),
            const SizedBox(height: 10),
            Text('Issue: ${ticket.issue}'),
            const SizedBox(height: 10),
            Text('Created: ${ticket.createdAt != null ? DateFormat('yyyy-MM-dd').format(ticket.createdAt!) : "N/A"}'),
            const SizedBox(height: 10),
            Text('Status: ${ticket.status}'),
            if (ticket.solvedAt != null) ...[
              const SizedBox(height: 10),
              Text('Solved: ${DateFormat('yyyy-MM-dd').format(ticket.solvedAt!)}'),
            ],
            if (ticket.review.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Review: ${ticket.review}'),
            ],
          ],
        ),
        actions: [
          if (ticket.status == 'open' || ticket.status == 'in_progress')
            TextButton(
              onPressed: () {
                Provider.of<DataProvider>(context, listen: false)
                    .approveTicket(ticket.id);
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Ticket closed.');
              },
              child: const Text('Close Ticket', style: TextStyle(color: Colors.green)),
            ),
          if (ticket.status == 'open')
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

  void _toggleShowOnlyOpen(bool? value) {
    setState(() {
      _showOnlyOpen = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        // Filter tickets by query + showOnlyOpen
        List<Ticket> tickets = dataProvider.tickets
            .where((t) =>
                t.userId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.issue.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.role.toLowerCase().contains(_searchQuery.toLowerCase()))
            .where((t) => !_showOnlyOpen || (t.status == 'open' || t.status == 'in_progress'))
            .toList();

        // Convert tickets to DataRow
        final rows = tickets.map((ticket) {
          return DataRow(
            cells: [
              DataCell(Text(ticket.id)),
              DataCell(Text(ticket.userId)),
              DataCell(Text(ticket.role)),
              DataCell(Text(ticket.issue)),
              DataCell(Text(ticket.createdAt != null 
                ? DateFormat('yyyy-MM-dd').format(ticket.createdAt!)
                : "N/A")),
              DataCell(Text(ticket.status)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ticket.status == 'open' || ticket.status == 'in_progress')
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          dataProvider.approveTicket(ticket.id);
                          Fluttertoast.showToast(msg: 'Ticket closed.');
                        },
                      ),
                    if (ticket.status == 'open')
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
              // Our search + pending row
              SearchAndPendingRow(
                searchLabel: 'Search Tickets',
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                showOnlyPending: _showOnlyOpen,
                pendingLabel: 'Show Only Open Tickets',
                onTogglePending: _toggleShowOnlyOpen,
              ),
              const SizedBox(height: 20),

              // Display the table
              Expanded(
                child: BetterPaginatedDataTable(
                  themeColor: const Color(0xFFEC407A), // Pinkish color
                  rowsPerPage: 10, // Show 10 rows per page
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('User ID')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Issue')),
                    DataColumn(label: Text('Created Date')),
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
