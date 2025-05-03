// lib/shared/components/responsive_data_table.dart
import 'package:flutter/material.dart';

/// A reusable table with both horizontal and vertical scrolling.
/// Looks like a normal DataTable (no pagination controls).
/// For very large data sets, consider using pagination or lazy-loading
/// to avoid performance issues.
class BetterDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const BetterDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // or any background color you prefer
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // scroll sideways if many columns
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical, // scroll vertically if many rows
          child: DataTable(
            columns: columns,
            rows: rows,
            // Optional styling
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold),
            dataRowHeight: 56,
            headingRowHeight: 56,
            columnSpacing: 24,
            horizontalMargin: 16,
            // If you want to adjust row color or striping, do so here
          ),
        ),
      ),
    );
  }
}

/// A paginated data table with pink theme
/// Provides horizontal and vertical scrolling as well as pagination
/// Use this for tables where you want to show a fixed number of rows per page
class BetterPaginatedDataTable extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final int rowsPerPage;
  final Color themeColor;
  final double width;
  final List<int> availableRowsPerPage;

  const BetterPaginatedDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowsPerPage = 10, // Default to 10 rows per page
    this.themeColor = const Color(0xFFF48FB1), // Pink color by default
    this.width = double.infinity, // Allow table to specify width
    this.availableRowsPerPage = const [5, 10, 25, 50], // Options for rows per page
  });

  @override
  State<BetterPaginatedDataTable> createState() => _BetterPaginatedDataTableState();
}

class _BetterPaginatedDataTableState extends State<BetterPaginatedDataTable> {
  int _currentPage = 0;
  late int _rowsPerPage;
  
  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.rowsPerPage;
  }
  
  @override
  Widget build(BuildContext context) {
    // Calculate the total number of pages
    final int totalPages = (widget.rows.length / _rowsPerPage).ceil();
    
    // Reset current page if it's out of bounds after changing rows per page
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }
    
    // Calculate start and end indices for current page
    final int startIndex = _currentPage * _rowsPerPage;
    final int endIndex = (startIndex + _rowsPerPage < widget.rows.length)
        ? startIndex + _rowsPerPage
        : widget.rows.length;
    
    // Get rows for the current page
    final List<DataRow> paginatedRows = 
        widget.rows.isEmpty ? [] : widget.rows.sublist(startIndex, endIndex);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            width: widget.width,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: widget.themeColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 40, // Full width minus padding
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: widget.columns,
                    rows: paginatedRows,
                    headingRowColor: WidgetStateProperty.all(widget.themeColor.withOpacity(0.2)),
                    headingTextStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.themeColor.withOpacity(0.8),
                    ),
                    dataRowHeight: 56,
                    headingRowHeight: 56,
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    decoration: BoxDecoration(
                      border: Border.all(color: widget.themeColor.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Pagination controls
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(
            color: widget.themeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rows per page selector
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Rows per page: ',
                      style: TextStyle(
                        color: widget.themeColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: widget.themeColor.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton<int>(
                        value: _rowsPerPage,
                        underline: const SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: widget.themeColor),
                        style: TextStyle(color: widget.themeColor.withOpacity(0.8)),
                        items: widget.availableRowsPerPage
                            .map((int value) => DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value'),
                                ))
                            .toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _rowsPerPage = newValue;
                              // Reset to first page when changing rows per page
                              _currentPage = 0;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Navigation controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage = 0)
                        : null,
                    color: widget.themeColor,
                    disabledColor: Colors.grey,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                    color: widget.themeColor,
                    disabledColor: Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Page ${_currentPage + 1} of $totalPages',
                    style: TextStyle(
                      color: widget.themeColor.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                    color: widget.themeColor,
                    disabledColor: Colors.grey,
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    onPressed: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage = totalPages - 1)
                        : null,
                    color: widget.themeColor,
                    disabledColor: Colors.grey,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
