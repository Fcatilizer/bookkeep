import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/csv_export_service.dart';
import '../helpers/event_dialog.dart';

enum ViewMode { card, table }

class DailyEventsPage extends StatefulWidget {
  const DailyEventsPage({super.key});

  @override
  State<DailyEventsPage> createState() => _DailyEventsPageState();
}

class _DailyEventsPageState extends State<DailyEventsPage> {
  final EventService _eventService = EventService();
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  Map<String, List<Event>> _groupedEvents = {};
  Map<String, double> _customerTotals = {};
  bool _isLoading = true;
  ViewMode _currentViewMode = ViewMode.card;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'date'; // date, customer, amount, product
  bool _sortAscending = false; // Default to newest first for events
  String _filterBy = 'all'; // all, customer, product, date

  // ScrollControllers for table view
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _eventService.getAllEvents();
      _groupEventsByCustomer(events);
      setState(() {
        _events = events;
        _filteredEvents = List.from(events);
        _sortEvents();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading events: $e')));
      }
    }
  }

  void _groupEventsByCustomer(List<Event> events) {
    _groupedEvents.clear();
    _customerTotals.clear();

    for (final event in events) {
      final custId = event.custId;

      if (!_groupedEvents.containsKey(custId)) {
        _groupedEvents[custId] = [];
        _customerTotals[custId] = 0.0;
      }

      _groupedEvents[custId]!.add(event);
      _customerTotals[custId] = _customerTotals[custId]! + event.amount;
    }
  }

  void _filterEvents(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredEvents = List.from(_events);
      } else {
        _filteredEvents = _events.where((event) {
          final searchLower = searchTerm.toLowerCase();

          switch (_filterBy) {
            case 'customer':
              return event.custId.toLowerCase().contains(searchLower) ||
                  event.customerName.toLowerCase().contains(searchLower);
            case 'product':
              return event.productId.toLowerCase().contains(searchLower);
            case 'all':
            default:
              return event.custId.toLowerCase().contains(searchLower) ||
                  event.customerName.toLowerCase().contains(searchLower) ||
                  event.productId.toLowerCase().contains(searchLower) ||
                  event.expenseName.toLowerCase().contains(searchLower) ||
                  (event.eventDate?.toString().contains(searchLower) ?? false);
          }
        }).toList();
      }
      _sortEvents();
      _groupEventsByCustomer(_filteredEvents);
    });
  }

  void _sortEvents() {
    _filteredEvents.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          final dateA = a.eventDate ?? DateTime(1900);
          final dateB = b.eventDate ?? DateTime(1900);
          comparison = dateA.compareTo(dateB);
          break;
        case 'customer':
          comparison = a.custId.compareTo(b.custId);
          break;
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'product':
          comparison = a.productId.compareTo(b.productId);
          break;
        default:
          final dateA = a.eventDate ?? DateTime(1900);
          final dateB = b.eventDate ?? DateTime(1900);
          comparison = dateA.compareTo(dateB);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _changeFilterBy(String newFilter) {
    setState(() {
      _filterBy = newFilter;
      _filterEvents(_searchController.text);
    });
  }

  void _changeSortOrder(String newSort) {
    setState(() {
      if (_sortBy == newSort) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSort;
        _sortAscending = newSort == 'date'
            ? false
            : true; // Events default to newest first
      }
      _sortEvents();
      _groupEventsByCustomer(_filteredEvents);
    });
  }

  Future<void> _exportToCSV() async {
    try {
      final filePath = await CsvExportService.exportEventsToCSV(_events);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported successfully to: $filePath'),
            duration: Duration(seconds: 4),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.eventName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${event.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        EventDialog.showEditEventDialog(context, event);
                        // Reload events after a short delay
                        await Future.delayed(const Duration(milliseconds: 500));
                        _loadEvents();
                      },
                      icon: const Icon(Icons.edit),
                      iconSize: 20,
                      tooltip: 'Edit Event',
                    ),
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(event),
                      icon: const Icon(Icons.delete),
                      iconSize: 20,
                      color: Colors.red,
                      tooltip: 'Delete Event',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.confirmation_number,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Event No: ${event.eventNo}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Product: ${event.productId}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Type: ${event.expenseType}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.description,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Expense: ${event.expenseName}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (event.eventDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Date: ${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Event event) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: Text(
            'Are you sure you want to delete the event "${event.eventName}"?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteEvent(event);
    }
  }

  Future<void> _deleteEvent(Event event) async {
    try {
      final success = await _eventService.deleteEvent(event.eventNo);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${event.eventName}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadEvents(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete event'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // View Mode and Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
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
                  isSelected: [
                    _currentViewMode == ViewMode.card,
                    _currentViewMode == ViewMode.table,
                  ],
                  onPressed: (int index) {
                    setState(() {
                      _currentViewMode = index == 0
                          ? ViewMode.card
                          : ViewMode.table;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  constraints: BoxConstraints(minWidth: 35, minHeight: 35),
                ),
                const Spacer(),
                if (_currentViewMode == ViewMode.table)
                  ElevatedButton.icon(
                    onPressed: _exportToCSV,
                    icon: Icon(Icons.download, size: 18),
                    label: Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_currentViewMode == ViewMode.table)
                  const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadEvents,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    EventDialog.showAddEventDialog(context);
                    // Reload events after a short delay to allow for database updates
                    Future.delayed(
                      const Duration(milliseconds: 500),
                      () => _loadEvents(),
                    );
                  },
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Add Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6FAADB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Search and Filter Controls
          Container(
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
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search daily events...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _filterEvents('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: _filterEvents,
                ),
                const SizedBox(height: 16),
                // Filter and Sort Controls
                Row(
                  children: [
                    // Filter dropdown
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
                            children: [
                              _buildFilterChip('All', 'all'),
                              _buildFilterChip('Customer', 'customer'),
                              _buildFilterChip('Product', 'product'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sort controls
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
                            children: [
                              _buildSortChip('Date', 'date'),
                              _buildSortChip('Customer', 'customer'),
                              _buildSortChip('Amount', 'amount'),
                              _buildSortChip('Product', 'product'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events found.\nTap + to add your first event!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )
                : _currentViewMode == ViewMode.table
                ? _buildTableView()
                : _buildCardView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView() {
    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    'Event No',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Event Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Customer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Expense Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Expense Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Amount (₹)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Event Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: _events.map((event) {
                return DataRow(
                  cells: [
                    DataCell(Text(event.eventNo)),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          event.eventName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          event.customerName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          event.expenseType,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          event.expenseName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        event.amount.toStringAsFixed(2),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        event.eventDate != null
                            ? '${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year}'
                            : 'N/A',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ), // closes DataTable
          ), // closes inner SingleChildScrollView
        ), // closes inner Scrollbar
      ), // closes outer SingleChildScrollView
    ); // closes outer Scrollbar
  }

  Widget _buildCardView() {
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _groupedEvents.entries.map((entry) {
          final custId = entry.key;
          final customerEvents = entry.value;
          final customerName = customerEvents.isNotEmpty
              ? customerEvents.first.customerName
              : 'Unknown Customer';
          final total = _customerTotals[custId] ?? 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                customerName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Customer ID: $custId',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              children: customerEvents
                  .map((event) => _buildEventCard(event))
                  .toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _changeFilterBy(value),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
          ],
        ],
      ),
      onPressed: () => _changeSortOrder(value),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerLow,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
