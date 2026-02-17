import 'package:flutter/material.dart';

/// Column definition for the reusable stats table.
class StatsColumnDef {
  final String key;
  final String label;
  final bool isNumeric;

  const StatsColumnDef({
    required this.key,
    required this.label,
    this.isNumeric = true,
  });
}

/// Row data for the stats table.
class StatsRowData {
  final String playerId;
  final Map<String, dynamic> values;

  const StatsRowData({required this.playerId, required this.values});
}

/// Reusable sortable stats table with sticky header and horizontal scroll.
class StatsTable extends StatelessWidget {
  final List<StatsColumnDef> columns;
  final List<StatsRowData> rows;
  final String? sortColumnKey;
  final bool sortAscending;
  final void Function(String key, bool ascending)? onSort;
  final void Function(String playerId)? onRowTap;

  const StatsTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnKey,
    this.sortAscending = false,
    this.onSort,
    this.onRowTap,
  });

  int? _resolveSortIndex() {
    if (sortColumnKey == null) return null;
    final idx = columns.indexWhere((c) => c.key == sortColumnKey);
    return idx >= 0 ? idx : null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          sortColumnIndex: _resolveSortIndex(),
          sortAscending: sortAscending,
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(
            colorScheme.surfaceContainerHighest,
          ),
          columns: columns.map((col) {
            return DataColumn(
              label: Text(
                col.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              numeric: col.isNumeric,
              onSort: onSort != null
                  ? (index, ascending) => onSort!(col.key, ascending)
                  : null,
            );
          }).toList(),
          rows: List.generate(rows.length, (index) {
            final row = rows[index];
            final isEvenRow = index % 2 == 0;

            return DataRow(
              color: WidgetStateProperty.all(
                isEvenRow
                    ? Colors.transparent
                    : colorScheme.surfaceContainerLow,
              ),
              onSelectChanged: onRowTap != null
                  ? (_) => onRowTap!(row.playerId)
                  : null,
              cells: columns.map((col) {
                final value = row.values[col.key];
                String displayValue;

                if (col.key == 'hittingPercentage' && value is double) {
                  displayValue =
                      '.${(value * 1000).round().toString().padLeft(3, '0')}';
                } else {
                  displayValue = '$value';
                }

                return DataCell(Text(displayValue));
              }).toList(),
            );
          }),
        ),
      ),
    );
  }
}
