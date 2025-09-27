import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/csv_export_service.dart';

enum ViewMode { card, table }

class ProductMasterPage extends StatefulWidget {
  const ProductMasterPage({super.key});

  @override
  State<ProductMasterPage> createState() => _ProductMasterPageState();
}

class _ProductMasterPageState extends State<ProductMasterPage> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  ViewMode _currentViewMode = ViewMode.card;

  // Sorting and filtering state
  String _sortBy = 'name'; // name, id, tax_rate
  bool _sortAscending = true;
  String _filterBy = 'all'; // all, name, id, tax_rate

  // ScrollControllers for table view
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = List.from(products);
        _sortProducts();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  void _filterProducts(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredProducts = List.from(_products);
      } else {
        _filteredProducts = _products.where((product) {
          final searchLower = searchTerm.toLowerCase();

          switch (_filterBy) {
            case 'name':
              return product.productName.toLowerCase().contains(searchLower);
            case 'id':
              return product.productId.toLowerCase().contains(searchLower);
            case 'tax_rate':
              return product.taxRate.toString().contains(searchLower);
            case 'all':
            default:
              return product.productName.toLowerCase().contains(searchLower) ||
                  product.productId.toLowerCase().contains(searchLower) ||
                  product.taxRate.toString().contains(searchLower);
          }
        }).toList();
      }
      _sortProducts();
    });
  }

  void _sortProducts() {
    _filteredProducts.sort((a, b) {
      dynamic aValue, bValue;

      switch (_sortBy) {
        case 'id':
          aValue = a.productId;
          bValue = b.productId;
          break;
        case 'tax_rate':
          aValue = a.taxRate;
          bValue = b.taxRate;
          break;
        case 'name':
        default:
          aValue = a.productName;
          bValue = b.productName;
          break;
      }

      final comparison = aValue is num
          ? aValue.compareTo(bValue)
          : aValue.toString().toLowerCase().compareTo(
              bValue.toString().toLowerCase(),
            );
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _changeSortOrder(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
      _sortProducts();
    });
  }

  void _changeFilterBy(String filterBy) {
    setState(() {
      _filterBy = filterBy;
      _filterProducts(_searchController.text);
    });
  }

  Future<void> _exportToCSV() async {
    try {
      final filePath = await CsvExportService.exportProductsToCSV(
        _filteredProducts,
      );
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

  void _showAddProductDialog([Product? product]) async {
    final isEdit = product != null;

    // Generate ID only for new products
    final String productId;
    if (isEdit) {
      productId = product.productId;
    } else {
      productId = await _productService.generateProductId();
    }

    final productNameController = TextEditingController(
      text: product?.productName ?? '',
    );
    final taxRateController = TextEditingController(
      text: product?.taxRate.toString() ?? '0.0',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Product' : 'Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show product ID (auto-generated for new, read-only for edit)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Product ID' : 'Product ID (Auto-generated)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      productId,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: taxRateController,
                decoration: const InputDecoration(
                  labelText: 'Tax Rate (%)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final productName = productNameController.text.trim();
              final taxRateText = taxRateController.text.trim();

              if (productName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product name is required')),
                );
                return;
              }

              final taxRate = double.tryParse(taxRateText) ?? 0.0;

              final newProduct = Product(
                productId: productId,
                productName: productName,
                taxRate: taxRate,
              );

              bool success;
              if (isEdit) {
                success = await _productService.updateProduct(newProduct);
              } else {
                success = await _productService.createProduct(newProduct);
              }

              if (success) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? 'Product updated successfully!'
                            : 'Product created successfully!',
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                  );
                  _loadProducts();
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit
                            ? 'Failed to update product'
                            : 'Failed to create product',
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                    ),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.productName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await _productService.deleteProduct(
                product.productId,
              );
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Product deleted successfully!'),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                  );
                  _loadProducts();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to delete product'),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_currentViewMode == ViewMode.table) ...[
                        IconButton(
                          onPressed: _exportToCSV,
                          icon: Icon(Icons.download, size: 18),
                          tooltip: 'Export to CSV',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        onPressed: _loadProducts,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddProductDialog(),
                          icon: Icon(Icons.add, size: 18),
                          label: Text('Add Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6FAADB),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
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
                    labelText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _filterProducts('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: _filterProducts,
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
                              _buildFilterChip('Name', 'name'),
                              _buildFilterChip('ID', 'id'),
                              _buildFilterChip('Tax Rate', 'tax_rate'),
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
                              _buildSortChip('Name', 'name'),
                              _buildSortChip('ID', 'id'),
                              _buildSortChip('Tax Rate', 'tax_rate'),
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
          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _products.isEmpty
                              ? 'No products found.\nTap + to add your first product!'
                              : 'No products match your search.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (_products.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              _filterProducts('');
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear Search'),
                          ),
                        ],
                      ],
                    ),
                  )
                : _currentViewMode == ViewMode.table
                ? _buildTableView()
                : _buildCardView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "product_master_fab",
        onPressed: () => _showAddProductDialog(),
        tooltip: 'Add Product',
        child: const Icon(Icons.add),
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
                    'Product ID',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Product Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Tax Rate (%)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: _filteredProducts.map((product) {
                return DataRow(
                  cells: [
                    DataCell(Text(product.productId)),
                    DataCell(
                      SizedBox(
                        width: 200,
                        child: Text(
                          product.productName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        product.taxRate.toStringAsFixed(2),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, size: 18),
                            onPressed: () => _showAddProductDialog(product),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => _showDeleteConfirmation(product),
                            tooltip: 'Delete',
                          ),
                        ],
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
      onRefresh: _loadProducts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.inventory_2,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                product.productName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: ${product.productId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Tax Rate: ${product.taxRate.toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showAddProductDialog(product);
                      break;
                    case 'delete':
                      _showDeleteConfirmation(product);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              onTap: () => _showAddProductDialog(product),
            ),
          );
        },
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
