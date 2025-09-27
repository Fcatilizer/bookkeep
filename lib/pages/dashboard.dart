import 'package:flutter/material.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import '../services/event_service.dart';
import '../services/customer_event_service.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/event.dart';
import '../models/customer_event.dart';
import 'customer_master.dart';
import 'product.dart';
import 'customer_events.dart';
import 'daily_events.dart';
import 'expense_master.dart';

class DashboardPage extends StatefulWidget {
  final Function(int)? onNavigateToPage;

  const DashboardPage({Key? key, this.onNavigateToPage}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final CustomerService _customerService = CustomerService();
  final ProductService _productService = ProductService();
  final EventService _eventService = EventService();
  final CustomerEventService _customerEventService = CustomerEventService();

  // Dashboard metrics
  int _totalCustomers = 0;
  int _totalProducts = 0;
  int _totalEvents = 0;
  int _totalCustomerEvents = 0;
  double _totalRevenue = 0.0;
  double _pendingAmount = 0.0;

  // Recent data
  List<Event> _recentEvents = [];
  List<CustomerEvent> _recentCustomerEvents = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _customerService.getAllCustomers(),
        _productService.getAllProducts(),
        _eventService.getAllEvents(),
        _customerEventService.getAllCustomerEvents(),
      ]);

      final customers = results[0] as List<Customer>;
      final products = results[1] as List<Product>;
      final events = results[2] as List<Event>;
      final customerEvents = results[3] as List<CustomerEvent>;

      setState(() {
        // Basic counts
        _totalCustomers = customers.length;
        _totalProducts = products.length;
        _totalEvents = events.length;
        _totalCustomerEvents = customerEvents.length;

        // Calculate financial metrics
        _totalRevenue = customerEvents.fold(
          0.0,
          (sum, event) => sum + event.agreedAmount,
        );
        _pendingAmount = customerEvents
            .where((event) => event.status != 'completed')
            .fold(0.0, (sum, event) => sum + event.agreedAmount);

        // Recent data (last 5 items)
        _recentEvents = events.take(5).toList();
        _recentCustomerEvents = customerEvents.take(5).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading dashboard: $e')));
      }
    }
  }

  void _showFabOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Add New Customer'),
            onTap: () {
              Navigator.pop(context);
              // Handle Add New Customer
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Update Daily Expense'),
            onTap: () {
              Navigator.pop(context);
              // Handle Update Daily Expense
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6FAADB), Color(0xFF4A90C2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to BookKeep',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your business overview at a glance',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Stats Grid
              Text(
                'Quick Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildCompactStatCard(
                      'Total Customers',
                      _totalCustomers.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatCard(
                      'Total Products',
                      _totalProducts.toString(),
                      Icons.inventory_2,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatCard(
                      'Total Events',
                      _totalEvents.toString(),
                      Icons.event,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatCard(
                      'Active Projects',
                      _totalCustomerEvents.toString(),
                      Icons.work,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Financial Overview
              Text(
                'Financial Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildFinancialCard(
                      'Total Revenue',
                      '₹${_totalRevenue.toStringAsFixed(2)}',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFinancialCard(
                      'Pending Amount',
                      '₹${_pendingAmount.toStringAsFixed(2)}',
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Activity Section
              Text(
                'Recent Activity',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              if (_recentCustomerEvents.isNotEmpty) ...[
                _buildRecentSection(
                  'Recent Customer Events',
                  _recentCustomerEvents
                      .map(
                        (event) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.work,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(event.eventName),
                          subtitle: Text(
                            '${event.customerName} • ₹${event.agreedAmount.toStringAsFixed(2)}',
                          ),
                          trailing: Text(
                            event.eventDate != null
                                ? '${event.eventDate!.day}/${event.eventDate!.month}'
                                : '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
                  onViewAll: () {
                    if (widget.onNavigateToPage != null) {
                      widget.onNavigateToPage!(
                        4,
                      ); // Navigate to Customer Events (index 4)
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerEventsPage(),
                        ),
                      );
                    }
                  },
                ),
              ],

              if (_recentEvents.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildRecentSection(
                  'Recent Daily Events',
                  _recentEvents
                      .map(
                        (event) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            child: Icon(
                              Icons.event,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          title: Text(event.eventName),
                          subtitle: Text(
                            '${event.customerName} • ${event.expenseType}',
                          ),
                          trailing: Text('₹${event.amount.toStringAsFixed(2)}'),
                        ),
                      )
                      .toList(),
                  onViewAll: () {
                    if (widget.onNavigateToPage != null) {
                      widget.onNavigateToPage!(
                        3,
                      ); // Navigate to Daily Events (index 3)
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DailyExpensePage(),
                        ),
                      );
                    }
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'Add Customer',
                      Icons.person_add,
                      Colors.blue,
                      () {
                        if (widget.onNavigateToPage != null) {
                          widget.onNavigateToPage!(
                            1,
                          ); // Navigate to Customer Master (index 1)
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomerMasterPage(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      'Add Product',
                      Icons.add_box,
                      Colors.green,
                      () {
                        if (widget.onNavigateToPage != null) {
                          widget.onNavigateToPage!(
                            2,
                          ); // Navigate to Product Master (index 2)
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProductMasterPage(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      'New Event',
                      Icons.event_note,
                      Colors.orange,
                      () {
                        if (widget.onNavigateToPage != null) {
                          widget.onNavigateToPage!(
                            4,
                          ); // Navigate to Customer Events (index 4)
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomerEventsPage(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      'Expense Master',
                      Icons.analytics,
                      Colors.purple,
                      () {
                        if (widget.onNavigateToPage != null) {
                          widget.onNavigateToPage!(
                            5,
                          ); // Navigate to Expense Master (index 5)
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExpenseMasterPage(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 100), // Extra space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "dashboard_fab",
        onPressed: () => _showFabOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCompactStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(
    String title,
    List<Widget> items, {
    VoidCallback? onViewAll,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...items.take(3), // Show only first 3 items
            if (items.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: TextButton(
                    onPressed:
                        onViewAll ??
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DailyExpensePage(),
                            ),
                          );
                        },
                    child: Text('View All (${items.length})'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
