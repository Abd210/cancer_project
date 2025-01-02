// lib/shared/components/custom_paginated_table.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomPaginatedTable extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final List<String> columns;
  final String tableTitle;
  final int initialRowsPerPage;
  final List<int> availableRowsPerPage;
  final Function(int)? onRowsPerPageChanged;
  final Function(Map<String, dynamic>)? onRowTap;

  const CustomPaginatedTable({
    required this.data,
    required this.columns,
    required this.tableTitle,
    this.initialRowsPerPage = 10,
    this.availableRowsPerPage = const [5, 10, 20],
    this.onRowsPerPageChanged,
    this.onRowTap,
    super.key,
  });

  @override
  _CustomPaginatedTableState createState() => _CustomPaginatedTableState();
}

class _CustomPaginatedTableState extends State<CustomPaginatedTable> {
  late int _rowsPerPage;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _rowsPerPage = widget.initialRowsPerPage;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      String column = widget.columns[columnIndex];
      widget.data.sort((a, b) {
        var aValue = a[column];
        var bValue = b[column];
        if (aValue is num && bValue is num) {
          return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        } else if (aValue is DateTime && bValue is DateTime) {
          return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        } else {
          return ascending
              ? aValue.toString().compareTo(bValue.toString())
              : bValue.toString().compareTo(aValue.toString());
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Enables horizontal scrolling for wide tables
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        // Ensures the table takes at least the width of the screen
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: PaginatedDataTable(
          header: Text(widget.tableTitle),
          columns: widget.columns.asMap().entries.map((entry) {
            int idx = entry.key;
            String col = entry.value;
            return DataColumn(
              label: Text(
                col.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onSort: (int columnIndex, bool ascending) {
                _onSort(columnIndex, ascending);
              },
            );
          }).toList(),
          source: _DataSource(widget.data, widget.columns, widget.onRowTap),
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          rowsPerPage: _rowsPerPage,
          availableRowsPerPage: widget.availableRowsPerPage,
          onRowsPerPageChanged: widget.onRowsPerPageChanged != null
              ? (int? newRows) {
            setState(() {
              _rowsPerPage = newRows ?? _rowsPerPage;
            });
            widget.onRowsPerPageChanged!(newRows!);
          }
              : null,
          showCheckboxColumn: false,
          columnSpacing: 30.0,
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
          dataRowHeight: 56.0,
        ),
      ),
    );
  }
}

class _DataSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final List<String> columns;
  final Function(Map<String, dynamic>)? onRowTap;

  _DataSource(this.data, this.columns, this.onRowTap);

  @override
  DataRow getRow(int index) {
    final row = data[index];
    return DataRow(
      cells: columns.map((col) {
        var value = row[col];
        if (value is DateTime) {
          value = DateFormat('yyyy-MM-dd').format(value);
        }
        return DataCell(
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onSelectChanged: onRowTap != null
          ? (selected) {
        if (selected == true) {
          onRowTap!(row);
        }
      }
          : null,
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
