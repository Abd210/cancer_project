import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../../providers/data_provider.dart';
import '../../../models/ticket.dart';
import '../../../shared/components/components.dart';
import '../../../shared/components/page_header.dart';
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
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
                  child: Text(
                    ticket.id,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
                  child: Text(
                    ticket.userId,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 100, maxWidth: 120),
                  child: Text(
                    ticket.role,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 250, maxWidth: 400),
                  child: Text(
                    ticket.issue,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 100, maxWidth: 150),
                  child: Text(
                    ticket.createdAt != null 
                      ? DateFormat('yyyy-MM-dd').format(ticket.createdAt!)
                      : "N/A",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 100, maxWidth: 120),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ticket.status == 'open' ? Colors.orange : 
                             ticket.status == 'in_progress' ? Colors.blue : 
                             ticket.status == 'closed' ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ticket.status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  constraints: const BoxConstraints(minWidth: 120, maxWidth: 150),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ticket.status == 'open' || ticket.status == 'in_progress')
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            dataProvider.approveTicket(ticket.id);
                            Fluttertoast.showToast(msg: 'Ticket closed.');
                          },
                          tooltip: 'Close Ticket',
                        ),
                      if (ticket.status == 'open')
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            dataProvider.rejectTicket(ticket.id);
                            Fluttertoast.showToast(msg: 'Ticket rejected.');
                          },
                          tooltip: 'Reject Ticket',
                        ),
                      IconButton(
                        icon: const Icon(Icons.info, color: Colors.blueGrey),
                        onPressed: () => _showTicketDetails(context, ticket),
                        tooltip: 'View Details',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const PageHeader(icon: Icons.rocket, title: 'Tickets Management'),
              SizedBox(height: 24),
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
