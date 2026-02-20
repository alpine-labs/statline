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
  final Set<String> selectedPlayerIds;
  final void Function(String playerId, bool selected)? onRowSelected;

  const StatsTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortColumnKey,
    this.sortAscending = false,
    this.onSort,
    this.onRowTap,
    this.selectedPlayerIds = const {},
    this.onRowSelected,
  });

  int? _resolveSortIndex([bool hasCheckboxColumn = false]) {
    if (sortColumnKey == null) return null;
    final idx = columns.indexWhere((c) => c.key == sortColumnKey);
    if (idx < 0) return null;
    return hasCheckboxColumn ? idx + 1 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Build column list: prepend checkbox column if selection is enabled
    final hasSelection = onRowSelected != null;
    final tableColumns = <DataColumn>[
      if (hasSelection)
        const DataColumn(label: SizedBox.shrink(), numeric: false),
      ...columns.map((col) {
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
      }),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          sortColumnIndex: _resolveSortIndex(hasSelection),
          sortAscending: sortAscending,
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(
            colorScheme.surfaceContainerHighest,
          ),
          columns: tableColumns,
          rows: List.generate(rows.length, (index) {
            final row = rows[index];
            final isEvenRow = index % 2 == 0;
            final isSelected = selectedPlayerIds.contains(row.playerId);

            final dataCells = <DataCell>[
              if (hasSelection)
                DataCell(
                  Checkbox(
                    value: isSelected,
                    onChanged: (val) =>
                        onRowSelected!(row.playerId, val ?? false),
                  ),
                ),
              ...columns.map((col) {
                final value = row.values[col.key];
                String displayValue;

                if (col.key == 'hittingPercentage' && value is double) {
                  final attempts = row.values['totalAttempts'];
                  if (attempts is num && attempts == 0) {
                    displayValue = '---';
                  } else {
                    displayValue =
                        '.${(value * 1000).round().toString().padLeft(3, '0')}';
                  }
                } else if ((col.key == 'perfectPassPct' || col.key == 'serveEfficiency') && value is double) {
                  final attempts = col.key == 'perfectPassPct'
                      ? row.values['passAttempts']
                      : row.values['serveAttempts'];
                  if (attempts is num && attempts == 0) {
                    displayValue = '---';
                  } else {
                    displayValue =
                        '.${(value * 1000).round().toString().padLeft(3, '0')}';
                  }
                } else {
                  displayValue = '$value';
                }

                if (col.key == 'player' && onRowTap != null) {
                  return DataCell(
                    Text(
                      displayValue,
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onTap: () => onRowTap!(row.playerId),
                  );
                }
                return DataCell(Text(displayValue));
              }),
            ];

            return DataRow(
              selected: isSelected,
              color: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colorScheme.primaryContainer.withAlpha(100);
                }
                return isEvenRow
                    ? Colors.transparent
                    : colorScheme.surfaceContainerLow;
              }),
              cells: dataCells,
            );
          }),
        ),
      ),
    );
  }
}
