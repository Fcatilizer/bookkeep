// 📚 BookKeep - Main Application Entry Point
//
// This file initializes the Flutter application with Material 3 theming,
// responsive design, and cross-platform SQLite support. It sets up the
// main navigation structure and theme management for the entire app.
//
// Author: Ashish Gaurav (@Fcatilizer)
// Created: 2025
// Last Updated: September 24, 2025

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Application Pages
import 'pages/dashboard.dart';
import 'pages/customer_master.dart';
import 'pages/product.dart';
import 'pages/daily_events.dart';
import 'pages/customer_events.dart';
import 'pages/expense_master.dart';
import 'pages/settings.dart';

// Dialog Helpers
import 'helpers/customer_dialog.dart';
import 'helpers/product_dialog.dart';
import 'helpers/event_dialog.dart';
import 'helpers/customer_event_dialog.dart';

// Services
import 'services/theme_service.dart';

/// Application entry point with platform-specific database initialization
///
/// Handles:
/// - Platform detection and SQLite FFI setup for desktop platforms
/// - Widget binding initialization for database access
/// - Main application launch
void main() async {
  // Ensure Flutter widget binding is initialized before database operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite FFI for desktop platforms (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    print('SQLite factory initialized successfully');
  }

  runApp(const MyApp());
}

/// Main Application Widget with Material 3 theming and responsive design
///
/// Provides:
/// - Material 3 design system with light/dark theme support
/// - Theme persistence and dynamic switching
/// - Cross-platform responsive layout
/// - Centralized navigation and routing
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// State management for MyApp with theme service integration
class _MyAppState extends State<MyApp> {
  /// Theme service for managing light/dark mode and persistence
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  /// Handle theme changes and trigger UI rebuilds
  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Build the main MaterialApp with theming and routing
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookKeep Accounting',
      debugShowCheckedModeBanner: false,

      // Light theme configuration with Material 3
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),

      // Dark theme configuration with Material 3
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
      ),

      // Dynamic theme mode from theme service
      themeMode: _themeService.themeMode,
      home: const ResponsiveScaffold(title: 'BookKeep Accounting'),
    );
  }
}

class ResponsiveScaffold extends StatefulWidget {
  const ResponsiveScaffold({super.key, required this.title});
  final String title;

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).maybePop();
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return DashboardPage(onNavigateToPage: _onTabSelected);
      case 1:
        return const CustomerMasterPage();
      case 2:
        return const ProductMasterPage();
      case 3:
        return const DailyEventsPage();
      case 4:
        return const CustomerEventsPage();
      case 5:
        return const ExpenseMasterPage();
      case 6:
        return const SettingsPage();
      default:
        return DashboardPage(onNavigateToPage: _onTabSelected);
    }
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Customer Master';
      case 2:
        return 'Products';
      case 3:
        return 'Daily Activity';
      case 4:
        return 'Customer Events';
      case 5:
        return 'Expense Master';
      case 6:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 800;

        final drawerContent = SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                          Text(
                            'Business Management',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.dashboard,
                        color: _selectedIndex == 0
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        'Dashboard',
                        style: TextStyle(
                          fontWeight: _selectedIndex == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedIndex == 0
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      selected: _selectedIndex == 0,
                      onTap: () => _onTabSelected(0),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.people,
                        color: _selectedIndex == 1
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        'Customer Master',
                        style: TextStyle(
                          fontWeight: _selectedIndex == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedIndex == 1
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      selected: _selectedIndex == 1,
                      onTap: () => _onTabSelected(1),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.inventory,
                        color: _selectedIndex == 2
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        'Products',
                        style: TextStyle(
                          fontWeight: _selectedIndex == 2
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedIndex == 2
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      selected: _selectedIndex == 2,
                      onTap: () => _onTabSelected(2),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.event,
                        color: _selectedIndex == 3
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        'Daily Activity',
                        style: TextStyle(
                          fontWeight: _selectedIndex == 3
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedIndex == 3
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      selected: _selectedIndex == 3,
                      onTap: () => _onTabSelected(3),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.assignment,
                        color: _selectedIndex == 4
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        'Customer Events',
                        style: TextStyle(
                          fontWeight: _selectedIndex == 4
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedIndex == 4
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      selected: _selectedIndex == 4,
                      onTap: () => _onTabSelected(4),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.receipt,
                        color: _selectedIndex == 5
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        'Expense Master',
                        style: TextStyle(
                          fontWeight: _selectedIndex == 5
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedIndex == 5
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      selected: _selectedIndex == 5,
                      onTap: () => _onTabSelected(5),
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(
                        Icons.settings,
                        color: _selectedIndex == 6
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        'Settings',
                        style: TextStyle(
                          fontWeight: _selectedIndex == 6
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedIndex == 6
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      selected: _selectedIndex == 6,
                      onTap: () => _onTabSelected(6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(_getPageTitle()),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            elevation: isWide ? 0 : 1,
            actions: isWide ? [] : null,
          ),
          drawer: isWide ? null : Drawer(child: drawerContent),
          body: Row(
            children: [
              if (isWide)
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: drawerContent,
                ),
              Expanded(
                child: Stack(
                  children: [
                    _getSelectedPage(),
                    if (isWide)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.extended(
                          onPressed: () => _showFabOptions(context),
                          tooltip: 'Quick Actions',
                          icon: const Icon(Icons.add),
                          label: const Text('New'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: isWide
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showFabOptions(context),
                  tooltip: 'Quick Actions',
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                ),
        );
      },
    );
  }

  void _showFabOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.person_add, color: Colors.indigo),
            title: const Text('Add New Customer'),
            onTap: () {
              Navigator.pop(context);
              CustomerDialog.showAddCustomerDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory, color: Colors.indigo),
            title: const Text('Add New Product'),
            onTap: () {
              Navigator.pop(context);
              ProductDialog.showAddProductDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.event, color: Colors.indigo),
            title: const Text('Update Daily Activity'),
            onTap: () {
              Navigator.pop(context);
              EventDialog.showAddEventDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment, color: Colors.indigo),
            title: const Text('Add Customer Event'),
            onTap: () {
              Navigator.pop(context);
              CustomerEventDialog.showAddCustomerEventDialog(context);
            },
          ),
        ],
      ),
    );
  }
}
