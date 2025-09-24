# 🧑‍💻 Developer Contribution Guide

## Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Dart SDK (bundled with Flutter)
- VS Code or Android Studio with Flutter extensions
- Git for version control

### Development Environment Setup

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
   flutter run
   ```

## Code Organization

### File Structure Guidelines

```
lib/
├── config/           # Application configuration
├── helpers/          # UI helpers and dialog components
├── models/           # Data models and structures
├── pages/            # UI pages and screens
├── services/         # Business logic and data services
├── main.dart         # Application entry point
└── reset_database.dart  # Database utilities
```

### Naming Conventions

- **Files**: snake_case (e.g., `payment_service.dart`)
- **Classes**: PascalCase (e.g., `PaymentService`)
- **Variables**: camelCase (e.g., `paymentAmount`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `DEFAULT_TIMEOUT`)
- **Private members**: prefix with underscore (e.g., `_database`)

## Code Style Guidelines

### Documentation Standards

Every public class, method, and complex function should have comprehensive documentation:

````dart
/// PaymentService - Business logic layer for payment operations
///
/// This service provides comprehensive payment management including:
/// - CRUD operations for payment records
/// - Payment validation and business rule enforcement
/// - Calculation methods for totals and summaries
///
/// Example usage:
/// ```dart
/// final service = PaymentService();
/// final payments = await service.getAllPayments();
/// ```
class PaymentService {
  /// Create a new payment record in the database
  ///
  /// Validates payment data and ensures referential integrity
  /// with customer events before insertion.
  ///
  /// [payment] - Payment object to create
  /// Returns: true if successful, false if error occurred
  Future<bool> createPayment(Payment payment) async {
    // Implementation...
  }
}
````

### Code Organization Within Files

Use section headers to organize code logically:

```dart
class ExampleService {
  // ══════════════════════════════════════════════════════════════
  // Constructor & Initialization
  // ══════════════════════════════════════════════════════════════

  ExampleService();

  // ══════════════════════════════════════════════════════════════
  // Public API Methods
  // ══════════════════════════════════════════════════════════════

  Future<List<Item>> getItems() async { }

  // ══════════════════════════════════════════════════════════════
  // Private Helper Methods
  // ══════════════════════════════════════════════════════════════

  void _validateInput(String input) { }
}
```

## Architecture Patterns

### Service Layer Pattern

All business logic should be in service classes:

```dart
// ✅ Good: Business logic in service
class PaymentService {
  Future<bool> validatePayment(Payment payment) async {
    // Validation logic here
  }
}

// ❌ Bad: Business logic in UI
class PaymentWidget extends StatefulWidget {
  void _validatePayment() {
    // Validation logic should not be here
  }
}
```

### Model Immutability

All data models should be immutable:

```dart
// ✅ Good: Immutable model with copyWith
class Payment {
  final String paymentId;
  final double amount;

  const Payment({required this.paymentId, required this.amount});

  Payment copyWith({String? paymentId, double? amount}) {
    return Payment(
      paymentId: paymentId ?? this.paymentId,
      amount: amount ?? this.amount,
    );
  }
}

// ❌ Bad: Mutable model
class Payment {
  String paymentId;
  double amount;
}
```

### Error Handling

Implement comprehensive error handling:

```dart
Future<bool> createPayment(Payment payment) async {
  try {
    // Validate input
    if (payment.amount <= 0) {
      throw ArgumentError('Amount must be positive');
    }

    // Perform operation
    final result = await _database.insert('payments', payment.toMap());
    return result > 0;

  } catch (e) {
    // Log error for debugging
    print('Error creating payment: $e');

    // Return safe failure state
    return false;
  }
}
```

## UI Development Guidelines

### Material 3 Design System

Use Material 3 components and theming:

```dart
// ✅ Good: Material 3 components with proper theming
Widget buildActionButton(BuildContext context) {
  return FilledButton.icon(
    onPressed: _handleAction,
    icon: Icon(Icons.add),
    label: Text('Add Payment'),
    style: FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
    ),
  );
}

// ✅ Good: Responsive design
Widget buildLayout(BuildContext context) {
  final isDesktop = MediaQuery.of(context).size.width > 768;

  return isDesktop
    ? _buildDesktopLayout()
    : _buildMobileLayout();
}
```

### State Management

Use StatefulWidget with proper lifecycle management:

```dart
class PaymentListWidget extends StatefulWidget {
  @override
  State<PaymentListWidget> createState() => _PaymentListWidgetState();
}

class _PaymentListWidgetState extends State<PaymentListWidget> {
  final ScrollController _scrollController = ScrollController();
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Prevent memory leaks
    super.dispose();
  }

  // Implementation...
}
```

## Testing Guidelines

### Unit Testing

Write tests for all business logic:

```dart
// test/services/payment_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bookkeep/services/payment_service.dart';

void main() {
  group('PaymentService', () {
    late PaymentService paymentService;

    setUp(() {
      paymentService = PaymentService();
    });

    test('should validate positive payment amounts', () async {
      final payment = Payment(
        paymentId: 'test',
        amount: 100.0,
        // ... other required fields
      );

      final result = await paymentService.createPayment(payment);
      expect(result, isTrue);
    });

    test('should reject negative payment amounts', () async {
      final payment = Payment(
        paymentId: 'test',
        amount: -100.0,
        // ... other required fields
      );

      final result = await paymentService.createPayment(payment);
      expect(result, isFalse);
    });
  });
}
```

### Widget Testing

Test UI components and interactions:

```dart
// test/widgets/payment_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookkeep/widgets/payment_widget.dart';

void main() {
  testWidgets('PaymentWidget displays payment information', (tester) async {
    final payment = Payment(/* test data */);

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentWidget(payment: payment),
      ),
    );

    expect(find.text(payment.paymentId), findsOneWidget);
    expect(find.text('\$${payment.amount}'), findsOneWidget);
  });
}
```

## Database Guidelines

### Migration Management

When modifying database schema:

1. **Increment version** in `DatabaseHelper._initDB()`
2. **Add migration logic** in `_onUpgrade()` method
3. **Test thoroughly** with existing data
4. **Document changes** in commit message

```dart
Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 9) {
    // Add new column to payments table
    await db.execute('ALTER TABLE payments ADD COLUMN reference TEXT');
  }
}
```

### Query Optimization

Use parameterized queries and proper indexing:

```dart
// ✅ Good: Parameterized query
Future<List<Payment>> getPaymentsByStatus(String status) async {
  final db = await database;
  final maps = await db.query(
    'payments',
    where: 'status = ?',
    whereArgs: [status],
  );
  return maps.map((map) => Payment.fromMap(map)).toList();
}

// ❌ Bad: String interpolation (SQL injection risk)
Future<List<Payment>> getPaymentsByStatus(String status) async {
  final db = await database;
  final maps = await db.rawQuery('SELECT * FROM payments WHERE status = "$status"');
  // This is vulnerable to SQL injection!
}
```

## Performance Best Practices

### Memory Management

- Always dispose controllers and listeners
- Use const constructors where possible
- Implement proper ListView.builder for large lists
- Cache expensive computations

### Database Performance

- Use transactions for multiple operations
- Implement proper indexing for frequently queried columns
- Avoid N+1 query problems
- Use batch operations for bulk data

### UI Performance

- Use RepaintBoundary for expensive widgets
- Implement proper key usage in lists
- Avoid rebuilding expensive widgets unnecessarily
- Use ListView.builder for dynamic lists

## Debugging and Monitoring

### Logging Standards

Use structured logging for debugging:

```dart
import 'dart:developer' as developer;

void logPaymentOperation(String operation, Payment payment) {
  developer.log(
    'Payment operation: $operation',
    name: 'PaymentService',
    error: null,
    level: 800, // INFO level
    time: DateTime.now(),
    sequenceNumber: 0,
    zone: Zone.current,
  );
}
```

### Error Reporting

Implement comprehensive error reporting:

```dart
Future<void> handleError(Object error, StackTrace stackTrace) async {
  // Log error details
  developer.log(
    'Unhandled error occurred',
    name: 'ErrorHandler',
    error: error,
    stackTrace: stackTrace,
    level: 1000, // ERROR level
  );

  // Show user-friendly message
  if (context != null && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred. Please try again.'),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _retryOperation,
        ),
      ),
    );
  }
}
```

## Submission Process

### Pull Request Guidelines

1. **Create feature branch**: `git checkout -b feature/payment-validation`
2. **Write comprehensive tests** for new functionality
3. **Update documentation** for API changes
4. **Follow commit message conventions**:

   ```
   feat(payments): add payment validation logic

   - Implement amount validation
   - Add payment type verification
   - Update error handling

   Fixes #123
   ```

5. **Submit PR** with detailed description

### Code Review Process

- All code changes require review
- Address all reviewer feedback
- Ensure CI/CD pipeline passes
- Update documentation as needed
- Squash commits before merge

### Release Process

1. **Version bump** in pubspec.yaml
2. **Update CHANGELOG.md** with new features and fixes
3. **Create release tag** with semantic versioning
4. **Deploy** to appropriate environments
5. **Monitor** for issues post-deployment

## Resources

### Documentation

- [Flutter Documentation](https://flutter.dev/docs)
- [Material 3 Design System](https://m3.material.io/)
- [Dart Language Guide](https://dart.dev/guides/language)
- [SQLite Documentation](https://www.sqlite.org/docs.html)

### Tools

- [Flutter Inspector](https://flutter.dev/docs/development/tools/flutter-inspector)
- [Dart DevTools](https://dart.dev/tools/dart-devtools)
- [Very Good Analysis](https://pub.dev/packages/very_good_analysis)

### Community

- [Flutter Community](https://flutter.dev/community)
- [GitHub Discussions](https://github.com/Fcatilizer/bookkeep/discussions)
- [Issue Tracker](https://github.com/Fcatilizer/bookkeep/issues)

---

Thank you for contributing to BookKeep! Your efforts help make this project better for everyone. 🚀
