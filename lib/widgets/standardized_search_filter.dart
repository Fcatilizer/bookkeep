import 'package:flutter/material.dart';

/// Standardized search and filter section for consistent UI across pages
class StandardizedSearchFilter extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final String searchHint;
  final List<FilterOption> filterOptions;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final List<SortOption> sortOptions;
  final String selectedSort;
  final bool sortAscending;
  final Function(String) onSortChanged;

  const StandardizedSearchFilter({
    Key? key,
    required this.searchController,
    required this.onSearchChanged,
    this.searchHint = 'Search...',
    this.filterOptions = const [],
    this.selectedFilter = 'all',
    required this.onFilterChanged,
    this.sortOptions = const [],
    this.selectedSort = 'name',
    this.sortAscending = true,
    required this.onSortChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Search Bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: onSearchChanged,
          ),

          if (filterOptions.isNotEmpty || sortOptions.isNotEmpty) ...[
            const SizedBox(height: 16),

            // Filter and Sort Controls
            Row(
              children: [
                // Filter Options
                if (filterOptions.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter by:',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: filterOptions.map((filter) {
                            return FilterChip(
                              label: Text(filter.label),
                              selected: selectedFilter == filter.value,
                              onSelected: (selected) {
                                if (selected) {
                                  onFilterChanged(filter.value);
                                }
                              },
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                if (filterOptions.isNotEmpty && sortOptions.isNotEmpty)
                  const SizedBox(width: 16),

                // Sort Options
                if (sortOptions.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sort by:',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: sortOptions.map((sort) {
                            final isSelected = selectedSort == sort.value;
                            return FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(sort.label),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      sortAscending
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  onSortChanged(sort.value);
                                }
                              },
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Data class for filter options
class FilterOption {
  final String label;
  final String value;

  const FilterOption({required this.label, required this.value});
}

/// Data class for sort options
class SortOption {
  final String label;
  final String value;

  const SortOption({required this.label, required this.value});
}
