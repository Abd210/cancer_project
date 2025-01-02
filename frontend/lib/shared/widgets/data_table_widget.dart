import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DataTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<String> columns;
  final List<DataColumn>? customColumns;
  final List<DataRow>? customRows;
  final bool isPaginated;

  const DataTableWidget({
    required this.data,
    required this.columns,
    this.customColumns,
    this.customRows,
    this.isPaginated = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: customColumns ??
            columns
                .map((col) => DataColumn(
              label: Text(
                col.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ))
                .toList(),
        rows: customRows ??
            data.map((row) {
              return DataRow(
                cells: columns.map((col) {
                  var value = row[col];
                  if (value is DateTime) {
                    value = DateFormat('yyyy-MM-dd').format(value);
                  }
                  return DataCell(Text(value.toString()));
                }).toList(),
              );
            }).toList(),
      ),
    );
  }
}
