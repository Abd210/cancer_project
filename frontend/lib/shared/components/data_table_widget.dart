import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DataTableWidget extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final List<String> columns;
  final bool isPaginated;
  final int initialRowsPerPage;
  final List<int> availableRowsPerPage;
  final ValueChanged<int?>? onRowsPerPageChanged; // Updated type
  final bool sortAscending;
  final int? sortColumnIndex;
  final Function(Map<String, dynamic>)? onRowTap; // Optional row tap callback

  const DataTableWidget({
    required this.data,
    required this.columns,
    this.isPaginated = false,
    this.initialRowsPerPage = 10,
    this.availableRowsPerPage = const [5, 10, 20],
    this.onRowsPerPageChanged, // Ensure type matches
    this.sortAscending = true,
    this.sortColumnIndex,
    this.onRowTap,
    super.key,
  });

  @override
  _DataTableWidgetState createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  late List<Map<String, dynamic>> _data;
  late int _sortColumnIndex;
  late bool _sortAscending;

  @override
  void initState() {
    super.initState();
    _data = List.from(widget.data);
    _sortAscending = widget.sortAscending;
    _sortColumnIndex = widget.sortColumnIndex ?? 0;
    _sortData();
  }

  void _sortData() {
    String column = widget.columns[_sortColumnIndex];
    _data.sort((a, b) {
      var aValue = a[column];
      var bValue = b[column];

      // Handle different data types
      if (aValue is num && bValue is num) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      } else {
        return _sortAscending
            ? aValue.toString().compareTo(bValue.toString())
            : bValue.toString().compareTo(aValue.toString());
      }
    });
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _sortData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isPaginated) {
      return PaginatedDataTable(
        header: const Text('Data Table'),
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
            numeric: false, // Adjust based on column data
          );
        }).toList(),
        source: _DataSource(_data, widget.columns, widget.onRowTap),
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        rowsPerPage: widget.initialRowsPerPage,
        availableRowsPerPage: widget.availableRowsPerPage,
        onRowsPerPageChanged: widget.onRowsPerPageChanged, // Type matches now
        showCheckboxColumn: false,
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
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
          rows: _data.map((row) {
            return DataRow(
              cells: widget.columns.map((col) {
                var value = row[col];
                if (value is DateTime) {
                  value = DateFormat('yyyy-MM-dd').format(value);
                }
                return DataCell(Text(value.toString()));
              }).toList(),
              onSelectChanged: widget.onRowTap != null
                  ? (selected) {
                if (selected == true) {
                  widget.onRowTap!(row);
                }
              }
                  : null,
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
  final Function(Map<String, dynamic>)? onRowTap;

  _DataSource(this.data, this.columns, this.onRowTap);

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
