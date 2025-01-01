import 'package:flutter/material.dart';

class ResponsiveDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double? dataRowHeight;
  final double? columnSpacing;

  const ResponsiveDataTable({
    Key? key,
    required this.columns,
    required this.rows,
    this.dataRowHeight,
    this.columnSpacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowHeight: dataRowHeight ?? 60,
            columnSpacing: columnSpacing ?? 20,
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }
}
