import 'package:flutter/material.dart';

/// Standardized page header widget providing consistent UI across all master pages
class StandardizedPageHeader extends StatelessWidget {
  final bool showViewToggle;
  final int? selectedViewIndex;
  final List<String>? viewOptions;
  final Function(int)? onViewChanged;
  final VoidCallback? onRefresh;
  final VoidCallback? onAdd;
  final String addButtonLabel;
  final IconData addButtonIcon;
  final VoidCallback? onExport;
  final bool showExportButton;
  final String exportButtonLabel;
  final Color? exportButtonColor;
  final List<Widget>? additionalActions;

  const StandardizedPageHeader({
    Key? key,
    this.showViewToggle = true,
    this.selectedViewIndex = 0,
    this.viewOptions,
    this.onViewChanged,
    this.onRefresh,
    this.onAdd,
    this.addButtonLabel = 'Add Item',
    this.addButtonIcon = Icons.add,
    this.onExport,
    this.showExportButton = false,
    this.exportButtonLabel = 'Export CSV',
    this.exportButtonColor = Colors.green,
    this.additionalActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // View Mode Toggle
          if (showViewToggle) ...[
            Text(
              'View:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            ToggleButtons(
              children: [
                Icon(Icons.view_list, size: 18),
                Icon(Icons.table_chart, size: 18),
              ],
              isSelected: [selectedViewIndex == 0, selectedViewIndex == 1],
              onPressed: onViewChanged ?? (int index) {},
              borderRadius: BorderRadius.circular(8),
              constraints: BoxConstraints(minWidth: 35, minHeight: 35),
            ),
          ],

          const Spacer(),

          // Additional Actions
          if (additionalActions != null) ...[
            ...additionalActions!,
            const SizedBox(width: 8),
          ],

          // Export Button
          if (showExportButton && onExport != null) ...[
            IconButton(
              onPressed: onExport,
              icon: Icon(Icons.download, size: 18),
              tooltip: exportButtonLabel,
              style: IconButton.styleFrom(
                backgroundColor: exportButtonColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Refresh Button
          if (onRefresh != null) ...[
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 8),
          ],

          // Add Button
          if (onAdd != null)
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: Icon(addButtonIcon, size: 18),
              label: Text(addButtonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6FAADB),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
