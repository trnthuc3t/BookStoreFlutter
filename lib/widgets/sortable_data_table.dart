import 'package:flutter/material.dart';

class SortableDataTable extends StatefulWidget {
  final List<DataColumnConfig> columns;
  final List<Map<String, dynamic>> data;
  final bool allowReorder;

  const SortableDataTable({
    Key? key,
    required this.columns,
    required this.data,
    this.allowReorder = true,
  }) : super(key: key);

  @override
  State<SortableDataTable> createState() => _SortableDataTableState();
}

class _SortableDataTableState extends State<SortableDataTable> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  List<DataColumnConfig> _columns = [];
  List<Map<String, dynamic>> _sortedData = [];

  @override
  void initState() {
    super.initState();
    _columns = List.from(widget.columns);
    _sortedData = List.from(widget.data);
  }

  @override
  void didUpdateWidget(SortableDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _sortedData = List.from(widget.data);
      if (_sortColumnIndex != null) {
        _sort(_sortColumnIndex!, _sortAscending);
      }
    }
  }

  void _sort(int columnIndex, bool ascending) {
    final column = _columns[columnIndex];
    _sortedData.sort((a, b) {
      final aValue = a[column.key] ?? '';
      final bValue = b[column.key] ?? '';

      int compare;
      if (aValue is num && bValue is num) {
        compare = aValue.compareTo(bValue);
      } else {
        compare = aValue.toString().compareTo(bValue.toString());
      }

      return ascending ? compare : -compare;
    });

    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  void _reorderColumns(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _columns.removeAt(oldIndex);
      _columns.insert(newIndex, item);

      // Update sort column index if affected
      if (_sortColumnIndex == oldIndex) {
        _sortColumnIndex = newIndex;
      } else if (_sortColumnIndex != null) {
        if (oldIndex < _sortColumnIndex! && newIndex >= _sortColumnIndex!) {
          _sortColumnIndex = _sortColumnIndex! - 1;
        } else if (oldIndex > _sortColumnIndex! && newIndex <= _sortColumnIndex!) {
          _sortColumnIndex = _sortColumnIndex! + 1;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: widget.allowReorder
          ? ReorderableTableView(
              columns: _columns,
              data: _sortedData,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              onSort: _sort,
              onReorder: _reorderColumns,
            )
          : StandardTableView(
              columns: _columns,
              data: _sortedData,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              onSort: _sort,
            ),
    );
  }
}

class DataColumnConfig {
  final String key;
  final String label;
  final double? width;
  final bool numeric;
  final String Function(dynamic value)? formatter;

  DataColumnConfig({
    required this.key,
    required this.label,
    this.width,
    this.numeric = false,
    this.formatter,
  });
}

class ReorderableTableView extends StatelessWidget {
  final List<DataColumnConfig> columns;
  final List<Map<String, dynamic>> data;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Function(int, bool) onSort;
  final Function(int, int) onReorder;

  const ReorderableTableView({
    Key? key,
    required this.columns,
    required this.data,
    this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onReorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DataTable(
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      columns: List.generate(columns.length, (index) {
        final column = columns[index];
        return DataColumn(
          label: Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    column.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (sortColumnIndex == index)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
          numeric: column.numeric,
          onSort: (columnIndex, ascending) => onSort(index, ascending),
        );
      }),
      rows: data.map((row) {
        return DataRow(
          cells: columns.map((column) {
            final value = row[column.key];
            final displayValue = column.formatter != null
                ? column.formatter!(value)
                : value?.toString() ?? '-';
            return DataCell(
              SizedBox(
                width: column.width,
                child: Text(
                  displayValue,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class StandardTableView extends StatelessWidget {
  final List<DataColumnConfig> columns;
  final List<Map<String, dynamic>> data;
  final int? sortColumnIndex;
  final bool sortAscending;
  final Function(int, bool) onSort;

  const StandardTableView({
    Key? key,
    required this.columns,
    required this.data,
    this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DataTable(
      sortColumnIndex: sortColumnIndex,
      sortAscending: sortAscending,
      columns: List.generate(columns.length, (index) {
        final column = columns[index];
        return DataColumn(
          label: Expanded(
            child: Text(
              column.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          numeric: column.numeric,
          onSort: (columnIndex, ascending) => onSort(index, ascending),
        );
      }),
      rows: data.map((row) {
        return DataRow(
          cells: columns.map((column) {
            final value = row[column.key];
            final displayValue = column.formatter != null
                ? column.formatter!(value)
                : value?.toString() ?? '-';
            return DataCell(
              SizedBox(
                width: column.width,
                child: Text(
                  displayValue,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
