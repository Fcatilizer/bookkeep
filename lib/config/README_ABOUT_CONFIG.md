# About Page Configuration Guide

## Overview

The About page content is now easily configurable through the `AboutConfig` class located in `/lib/config/about_config.dart`. This allows you to update all the content displayed on the About page without touching the UI code.

## How to Update the About Page

### 1. App Information

```dart
static const String appName = 'BookKeep Accounting';
static const String appVersion = 'Version 1.0.0';
static const String appDescription = 'Your app description here...';
```

### 2. App Icon

Change the icon displayed in the header:

```dart
static const IconData appIcon = Icons.account_balance_wallet;
```

### 3. Features List

Add, remove, or modify features by editing the `features` list:

```dart
static const List<FeatureItem> features = [
  FeatureItem(
    icon: Icons.dashboard,           // Choose any Material icon
    title: 'Your feature description',
  ),
  // Add more features here...
];
```

### 4. Technical Information

Update technical details in the `techInfo` list:

```dart
static const List<TechItem> techInfo = [
  TechItem(label: 'Framework:', value: 'Flutter'),
  TechItem(label: 'Database:', value: 'SQLite'),
  // Add more technical info here...
];
```

### 5. Contact Information

Modify contact details in the `contacts` list:

```dart
static const List<ContactItem> contacts = [
  ContactItem(
    icon: Icons.email,
    title: 'Email Support',
    subtitle: 'ashish.gaurav2003@gmail.com',
    copyText: 'ashish.gaurav2003@gmail.com',  // Text copied to clipboard
  ),
  // Add more contact methods here...
];
```

### 6. Copyright

Update the copyright notice:

```dart
static const String copyright = '© 2025 BookKeep Accounting. All rights reserved.';
```

## Available Icons

You can use any Material Design icon from Flutter's Icons class. Some popular choices:

- `Icons.dashboard` - For dashboard features
- `Icons.people` - For user management
- `Icons.inventory` - For inventory/products
- `Icons.analytics` - For analytics features
- `Icons.security` - For security features
- `Icons.cloud_upload` - For backup features
- `Icons.palette` - For theming features

## Design Features

The redesigned About page includes:

- **Modern Material 3 Design** with proper color schemes
- **Gradient header** with app icon and version
- **Icon-based features** instead of emojis
- **Better typography** and spacing
- **Improved contact section** with copy-to-clipboard functionality
- **Responsive design** that works on all screen sizes
- **Dark/Light theme support**

## Tips for Customization

1. **Keep descriptions concise** - Users prefer short, clear feature descriptions
2. **Use appropriate icons** - Choose icons that clearly represent the feature
3. **Update version numbers** regularly in production releases
4. **Test contact information** - Ensure email addresses and URLs are valid
5. **Consider accessibility** - Icon + text combinations are more accessible than emojis

## Hot Reload Support

Since all content is stored as constants, changes to the configuration file will be visible immediately during development with Flutter's hot reload feature.
