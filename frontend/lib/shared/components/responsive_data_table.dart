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
    return Expanded(
      // We use Expanded so the table takes available space
      child: Container(
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
      ),
    );
  }
}
