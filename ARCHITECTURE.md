# 🏗️ BookKeep Architecture Documentation

## Overview

BookKeep follows a clean architecture pattern with clear separation of concerns, making it maintainable, testable, and scalable. The application uses Flutter's Material 3 design system with comprehensive state management.

## Architecture Layers

### 1. **Presentation Layer** (`lib/pages/`)

- **Responsibility**: UI components, user interactions, and state management
- **Key Files**:
  - `expense_master.dart` - Main expense and payment management interface
  - `dashboard.dart` - Application overview and analytics
  - `customer_master.dart` - Customer management interface
  - `customer_events.dart` - Event/project management
  - `daily_events.dart` - Daily expense tracking
  - `product.dart` - Product/service management
  - `settings.dart` - Application configuration

**Design Principles**:

- Reactive UI with StatefulWidget and proper lifecycle management
- Comprehensive filtering and search capabilities
- Responsive design for mobile and desktop
- Material 3 theming with dark/light mode support

### 2. **Business Logic Layer** (`lib/services/`)

- **Responsibility**: Data processing, business rules, and external integrations
- **Key Services**:
  - `payment_service.dart` - Payment operations and calculations
  - `expense_type_service.dart` - Expense category management
  - `customer_event_service.dart` - Event/project business logic
  - `payment_summary_service.dart` - Payment aggregation and reporting
  - `csv_export_service.dart` - Data export functionality
  - `theme_service.dart` - Application theming management

**Business Rules**:

- Payment validation and status calculation
- Event-payment relationship management
- Data aggregation for reporting
- Export format standardization

### 3. **Data Layer** (`lib/models/` + `lib/helpers/database_helper.dart`)

- **Responsibility**: Data models, database operations, and data persistence
- **Key Components**:
  - **Models**: Data structures with serialization/deserialization
  - **DatabaseHelper**: SQLite database management and migrations
  - **Cross-platform Support**: FFI implementation for desktop platforms

## Data Models

### Core Models

```dart
// Payment transaction record
class Payment {
  final String paymentId;
  final String customerEventNo;
  final String payingPersonName;
  final String paymentType;
  final double amount;
  final String status;
  // ... additional fields
}

// Expense category definition
class ExpenseType {
  final String expenseTypeId;
  final String expenseTypeName;
  final String category;
  final bool isActive;
  // ... additional fields
}

// Customer event/project
class CustomerEvent {
  final String eventNo;
  final String eventName;
  final String custId;
  final double agreedAmount;
  // ... additional fields
}
```

### Model Features

- **Immutable Design**: All models are immutable with copyWith methods
- **Serialization**: Built-in toMap/fromMap for database operations
- **Validation**: Static methods for data validation and display formatting
- **Type Safety**: Strong typing with proper null safety

## Database Schema

### Tables Overview

```sql
-- Customer information
customers (Cust_ID, Customer_Name, Location, Contact_Person, Mobile_No, GST_No)

-- Product/service definitions
products (Product_ID, Product_Name, Tax_Rate)

-- Customer events/projects
customer_events (Event_No, Event_Name, Cust_ID, Product_ID, Customer_Name,
                Quantity, Agreed_Amount, Event_Date, Expected_Finishing_Date, Status)

-- Payment transactions
payments (payment_id, customer_event_no, paying_person_name, payment_type,
         amount, status, reference, notes, payment_date, created_at, updated_at)

-- Expense categories
expense_types (expense_type_id, expense_type_name, category, description,
              is_active, created_at, updated_at)

-- Daily expense tracking
daily_events (Event_No, Event_Name, Cust_ID, Product_ID, Customer_Name,
             Expense_Type, Expense_Name, Amount, Event_Date, created_at)
```

### Database Features

- **Foreign Key Constraints**: Referential integrity between tables
- **Cross-platform Support**: Works on mobile and desktop platforms
- **Migration Support**: Version-based schema updates
- **Transaction Safety**: ACID compliance for data operations

## UI Architecture

### Component Hierarchy

```
MaterialApp (main.dart)
├── ResponsiveScaffold (navigation shell)
│   ├── Dashboard (overview)
│   ├── ExpenseMasterPage (main feature)
│   │   ├── TabController (expense types, payments)
│   │   ├── FilterChips (advanced filtering)
│   │   ├── DataTable/CardView (data display)
│   │   └── Export/Actions (operations)
│   ├── CustomerMaster (customer management)
│   └── Settings (configuration)
└── Dialog Helpers (modal operations)
```

### UI Design Principles

- **Material 3 Design**: Modern, accessible, and consistent
- **Responsive Layout**: Adapts to different screen sizes
- **Progressive Enhancement**: Advanced features for larger screens
- **Accessibility**: Proper semantic structure and navigation

## State Management

### State Architecture

- **Local State**: StatefulWidget for component-specific state
- **Service Layer**: Business logic and data management
- **Theme State**: Global theme management with persistence
- **Database State**: Reactive data updates with proper error handling

### State Flow

```
User Interaction → UI Component → Service Layer → Database → UI Update
```

## Error Handling

### Strategy

- **Graceful Degradation**: UI continues to function with partial failures
- **User Feedback**: Clear error messages and loading states
- **Logging**: Comprehensive error logging for debugging
- **Validation**: Input validation at multiple layers

## Performance Considerations

### Optimization Strategies

- **Lazy Loading**: Data loaded on demand
- **Efficient Queries**: Optimized database queries with proper indexing
- **Memory Management**: Proper disposal of controllers and listeners
- **Caching**: Strategic caching of frequently accessed data

### Scalability

- **Modular Design**: Easy to add new features and modules
- **Separation of Concerns**: Clear boundaries between layers
- **Testable Architecture**: Business logic separated from UI
- **Configuration-driven**: Easy to customize and extend

## Security Considerations

### Data Protection

- **Input Validation**: All user inputs validated and sanitized
- **SQL Injection Prevention**: Parameterized queries only
- **Data Persistence**: Local SQLite database for data privacy
- **Access Control**: Role-based access to features (future)

## Future Architecture Enhancements

### Planned Improvements

1. **State Management**: Consider Provider/Riverpod for complex state
2. **API Integration**: RESTful API support for cloud synchronization
3. **Testing**: Comprehensive unit and integration test coverage
4. **CI/CD**: Automated testing and deployment pipelines
5. **Monitoring**: Performance monitoring and analytics integration

## Contributing Guidelines

### Code Organization

1. **File Structure**: Follow established patterns in each layer
2. **Naming Conventions**: Clear, descriptive names for all components
3. **Documentation**: Comprehensive inline documentation required
4. **Testing**: Unit tests for business logic, widget tests for UI
5. **Code Review**: All changes require review and approval

### Best Practices

- Keep business logic in service layer
- Maintain immutable data models
- Use proper error handling and validation
- Follow Material Design guidelines
- Ensure cross-platform compatibility
- Document all public APIs and complex logic
