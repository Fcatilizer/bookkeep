# BookKeep - Manage Accounting

<p align="center">
   <img src="assets/icon.png" alt="BookKeep App Screenshot" width="180" />
</p>

A comprehensive Flutter application for managing expenses, payments, customer events, and financial tracking. Built with clean architecture and modern UI/UX principles.

## Screenshots
![App Screenshot](lib/Screenshots/Screenshot%202025-09-24%20090812.png)

## 🚀 Features

### 💳 Payment Management

- **Multiple Payment Types**: Cash, Cheque, Bank Transfer, UPI, Card, Net Banking, Adjustment
- **Enhanced Search & Filtering**:
  - Multi-criteria search by Payment ID, Event Number, Paying Person Name, Payment Type, and Reference
  - Real-time filtering with instant results
  - Case-insensitive partial matching across all fields
- **Date Range Filtering**: Filter payments by custom date ranges
- **Payment Status Tracking**: Pending, Partial, Full payment statuses with color-coded indicators
- **Individual & Grouped Views**: Toggle between detailed individual payments and summarized grouped views
- **Export Functionality**: Export payment data to CSV format with comprehensive data

### 📊 Expense Types Management

- **Category Management**: Create and manage expense categories
- **Active/Inactive Status**: Enable/disable expense types as needed
- **Bulk Operations**: Export, filter, and sort expense types
- **Search Functionality**: Quick search through expense types

### 🎯 Advanced UI Features

- **Chip-based Filters**: Modern, intuitive filtering with chips
- **Expandable Filter Section**: Collapsible advanced filters to save screen space
- **Enhanced Desktop Experience**:
  - Proper horizontal and vertical scrolling with mouse wheel support
  - ScrollController-based navigation for large data tables
  - Desktop-optimized table layouts and interactions
- **Improved Theme Support**:
  - Complete dark/light mode adaptation for all UI components
  - Material 3 design with proper color theming
  - Fixed text and button contrast issues across themes
- **Cross-platform Optimization**:
  - Runs on Android, iOS, Web, Desktop (Windows, macOS, Linux)
  - Platform-specific optimizations and integrations
  - Linux desktop integration with proper GTK icon support

### 📈 Data Visualization & Navigation

- **Enhanced Dashboard**:
  - Improved navigation with conditional UI elements
  - Quick Actions panel with direct access to Expense Master
  - Smart button visibility (Table View only in individual contexts)
- **Payment Summaries**: Comprehensive overview of customer payments
- **Remaining Balance Tracking**: Real-time calculation of outstanding amounts
- **Status Color Coding**: Visual indicators for payment status and remaining amounts

### ℹ️ About & Configuration

- **Configurable About Page**:
  - Easy-to-update content management system
  - Icon-based design replacing emojis for better compatibility
  - Modular configuration structure for quick content updates
- **Application Branding**:
  - Professional package naming (com.ashish.bookkeep)
  - Cross-platform icon integration and desktop environment support

## 🏗️ Architecture & Project Structure

```
lib/
├── config/                 # Configuration files
│   ├── about_config.dart
│   └── README_ABOUT_CONFIG.md
├── helpers/                # Dialog helpers and utilities
│   ├── customer_dialog.dart
│   ├── customer_event_dialog.dart
│   ├── customer_notifier.dart
│   ├── database_helper.dart
│   ├── event_dialog.dart
│   ├── expense_type_dialog.dart
│   ├── export_preview_dialog.dart
│   ├── payment_dialog.dart
│   ├── payment_mode_dialog.dart
│   └── product_dialog.dart
├── models/                 # Data models
│   ├── customer_event.dart
│   ├── customer.dart
│   ├── event.dart
│   ├── expense_type.dart
│   ├── payment_mode.dart
│   ├── payment_summary.dart
│   └── payment.dart
├── pages/                  # UI pages/screens
│   └── expense_master.dart
├── services/               # Business logic & data services
│   ├── csv_export_service.dart
│   ├── customer_event_service.dart
│   ├── expense_type_service.dart
│   ├── payment_mode_service.dart
│   ├── payment_service.dart
│   └── payment_summary_service.dart
├── main.dart              # Application entry point
└── reset_database.dart    # Database reset utility
```

## 🛠️ Technical Stack

### Core Technologies

- **Framework**: Flutter 3.9.2+
- **Language**: Dart
- **Database**: SQLite (via sqflite)
- **State Management**: StatefulWidget with proper lifecycle management

### Key Dependencies

```yaml
dependencies:
  flutter: sdk
  sqflite: ^2.4.2 # Local database with enhanced foreign key constraints
  path_provider: ^2.1.4 # File system access
  csv: ^6.0.0 # CSV export functionality
  file_picker: ^8.1.2 # File operations
  pdf: ^3.11.3 # PDF generation
  printing: ^5.14.2 # Print functionality
  permission_handler: ^11.3.1 # System permissions
  change_app_package_name: ^1.5.0 # Package name management
```

### Performance Features

- **Smart Search Algorithm**: Efficient multi-field filtering for large datasets
- **ScrollController Optimization**: Proper memory management for scrollable content
- **Database Integrity**: Enhanced foreign key constraints and validation
- **Theme Caching**: Optimized theme switching with minimal rebuilds

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Git

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/Fcatilizer/bookkeep.git
   cd bookkeep
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the application**

   ```bash
   # For development
   flutter run

   # For web
   flutter run -d web-server --web-port 8080

   # For desktop (Windows)
   flutter run -d windows
   ```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Web
flutter build web --release

# Windows Desktop
flutter build windows --release

# macOS Desktop
flutter build macos --release

# Linux Desktop
flutter build linux --release
```

## 📱 Usage Guide

### Payment Management

1. **Adding Payments**: Click the "Add Payment" button and fill in the required details
2. **Filtering**: Use the expandable filter section for advanced filtering options
3. **Enhanced Search**: Use the powerful search bar to find payments by:
   - Payment ID or reference number
   - Event number or event details
   - Paying person name
   - Payment type (Cash, UPI, Card, etc.)
   - Reference notes or descriptions
4. **View Modes**: Toggle between individual payments and grouped summaries
5. **Desktop Navigation**: Use mouse wheel or scrollbars for horizontal and vertical navigation
6. **Export**: Use the export button to generate comprehensive CSV reports

### Expense Types

1. **Managing Categories**: Add, edit, or deactivate expense type categories
2. **Filtering**: Use filter chips to view active/inactive categories
3. **Sorting**: Sort by name, category, or date created

### Advanced Features

- **Date Range Filtering**: Select custom date ranges for payment analysis
- **Payment Mode Filtering**: Filter by specific payment methods
- **Status Tracking**: Monitor payment completion status
- **Responsive Design**: Optimized for both mobile and desktop use

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Add tests if applicable**
5. **Commit with conventional commits**
   ```bash
   git commit -m "feat: add new payment filtering feature"
   ```
6. **Push to your fork**
7. **Create a Pull Request**

### Code Style Guidelines

- Follow Dart/Flutter style guidelines
- Use meaningful variable and function names
- Add documentation for complex functions
- Maintain consistent file structure
- Use proper error handling

### Commit Convention

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation updates
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Test additions/updates
- `chore:` - Maintenance tasks

## 📖 API Documentation

### Models

- **Payment**: Represents payment transactions
- **ExpenseType**: Category definitions for expenses
- **CustomerEvent**: Customer event information
- **PaymentSummary**: Aggregated payment data

### Services

- **PaymentService**: CRUD operations for payments
- **ExpenseTypeService**: Expense type management
- **CustomerEventService**: Customer event operations
- **CsvExportService**: Data export functionality

## 🐛 Known Issues & Limitations

- SQLite database limitations for very large datasets
- Web version may have limited file system access
- Print functionality requires platform-specific permissions

## 📝 Changelog

### Version 1.2.0 (Current - September 2025)

- **Enhanced Search System**: Multi-criteria search across 5 different payment fields
- **Desktop Experience**: Improved horizontal scrolling and mouse wheel support
- **UI Theme Fixes**: Complete dark/light mode adaptation for all components
- **Dashboard Improvements**: Enhanced navigation and Quick Actions panel
- **About Page Redesign**: Configurable content system with icon-based design
- **Linux Integration**: Proper GTK desktop environment support
- **Package Optimization**: Professional branding with com.ashish.bookkeep identifier

### Version 1.1.0 (August 2025)

- Improved payment validation and database constraints
- Enhanced customer event tracking and status management
- Better error handling and user feedback
- Performance optimizations for large datasets

### Version 1.0.0 (Initial Release)

- Initial release with core payment management
- Advanced filtering and search capabilities
- Multi-platform support
- CSV export functionality
- Responsive UI with Material 3 design

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Authors

- **Ashish Gaurav** - _Initial work_ - [Fcatilizer](https://github.com/Fcatilizer)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Contributors to the open-source packages used
- My family and friends for their support

## 📞 Support

For support, please:

1. Check the [Issues](https://github.com/Fcatilizer/bookkeep/issues) page
2. Create a new issue with detailed description
3. Email is provided in the app's about section

---

**Happy Bookkeeping! 📚💰**
