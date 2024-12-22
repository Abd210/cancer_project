// lib/shared/components/data_table_widget.dart
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isPaginated) {
      return PaginatedDataTable(
        header: Text('Data Table'),
        columns: customColumns ??
            columns
                .map(
                  (col) => DataColumn(
                label: Text(
                  col.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
                .toList(),
        source: _DataSource(data, columns),
        rowsPerPage: 10,
        availableRowsPerPage: [5, 10, 20],
        onRowsPerPageChanged: (value) {},
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: customColumns ??
              columns
                  .map(
                    (col) => DataColumn(
                  label: Text(
                    col.toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
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
}

class _DataSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final List<String> columns;

  _DataSource(this.data, this.columns);

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final row = data[index];
    return DataRow.byIndex(
      index: index,
      cells: columns.map((col) {
        var value = row[col];
        if (value is DateTime) {
          value = DateFormat('yyyy-MM-dd').format(value);
        }
        return DataCell(Text(value.toString()));
      }).toList(),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
