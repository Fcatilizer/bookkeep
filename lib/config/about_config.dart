import 'package:flutter/material.dart';

/// Configuration class for About page content
/// Edit this file to easily update the About page information
class AboutConfig {
  // App Information
  static const String appName = 'BookKeep Accounting';
  static const String appVersion = 'Version 3.0.0';
  static const String appDescription =
      'BookKeep is a comprehensive accounting application designed to help you manage your business finances efficiently. Track customers, products, daily events, and customer transactions all in one place.';

  // App Icon
  static const IconData appIcon = Icons.account_balance_wallet;

  // Key Features with Icons
  static const List<FeatureItem> features = [
    FeatureItem(
      icon: Icons.dashboard,
      title: 'Dashboard with analytics and insights',
    ),
    FeatureItem(icon: Icons.people, title: 'Customer management system'),
    FeatureItem(icon: Icons.inventory, title: 'Product inventory tracking'),
    FeatureItem(icon: Icons.event, title: 'Daily event management'),
    FeatureItem(icon: Icons.business_center, title: 'Customer event tracking'),
    FeatureItem(icon: Icons.file_download, title: 'CSV export functionality'),
    FeatureItem(icon: Icons.backup, title: 'Data backup and restore'),
    FeatureItem(icon: Icons.palette, title: 'Multiple theme options'),
  ];

  // Technical Information
  static const List<TechItem> techInfo = [
    TechItem(label: 'Framework:', value: 'Flutter'),
    TechItem(label: 'Database:', value: 'SQLite'),
    TechItem(
      label: 'Platform:',
      value: 'Cross-platform (Android, iOS, Web, Desktop)',
    ),
    TechItem(label: 'License:', value: 'MIT License'),
    TechItem(label: 'Build Date:', value: 'September 2025'),
  ];

  // Contact Information
  static const List<ContactItem> contacts = [
    ContactItem(
      icon: Icons.email,
      title: 'Email Support',
      subtitle: 'ashish.gaurav2003@gmail.com',
      copyText: 'ashish.gaurav2003@gmail.com',
    ),
    ContactItem(
      icon: Icons.language,
      title: 'Website',
      subtitle: 'https://www.a3group.co.in/',
      copyText: 'https://www.a3group.co.in/',
    ),
    ContactItem(
      icon: Icons.bug_report,
      title: 'Report Issues',
      subtitle: 'Tap to copy email',
      copyText: 'ashish.gaurav2003@gmail.com',
    ),
  ];

  // Copyright Information
  static const String copyright =
      '© 2025 BookKeep Accounting. All rights reserved.';
}

// Data Models
class FeatureItem {
  final IconData icon;
  final String title;

  const FeatureItem({required this.icon, required this.title});
}

class TechItem {
  final String label;
  final String value;

  const TechItem({required this.label, required this.value});
}

class ContactItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String copyText;

  const ContactItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.copyText,
  });
}
