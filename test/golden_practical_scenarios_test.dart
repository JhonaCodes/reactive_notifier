import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'config/alchemist_config.dart';

/// Practical Golden Tests for ReactiveNotifier
///
/// These tests demonstrate real-world usage patterns with stable states
/// that show the practical benefits of ReactiveNotifier:
/// 1. E-commerce App Components
/// 2. User Interface States
/// 3. Form Management
/// 4. Data Display Patterns
/// 5. Error and Loading States
/// 6. Cross-Component Communication

// Models
class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool isAvailable;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.isAvailable,
    required this.rating,
  });
}

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get total => product.price * quantity;
}

class User {
  final String id;
  final String name;
  final String email;
  final String membershipLevel;
  final double discountRate;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.membershipLevel,
    required this.discountRate,
  });
}

class OrderSummary {
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double shipping;
  final double total;

  OrderSummary({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.shipping,
    required this.total,
  });
}

// Services
mixin ProductCatalogService {
  static final ReactiveNotifier<List<Product>> products =
      ReactiveNotifier<List<Product>>(() => []);

  static final ReactiveNotifier<String> selectedCategory =
      ReactiveNotifier<String>(() => 'All');

  static final ReactiveNotifier<String> sortBy =
      ReactiveNotifier<String>(() => 'name');
}

mixin ShoppingCartService {
  static final ReactiveNotifier<List<CartItem>> cartItems =
      ReactiveNotifier<List<CartItem>>(() => []);

  static final ReactiveNotifier<bool> isCheckingOut =
      ReactiveNotifier<bool>(() => false);
}

mixin UserService {
  static final ReactiveNotifier<User?> currentUser =
      ReactiveNotifier<User?>(() => null);

  static final ReactiveNotifier<bool> isLoggedIn =
      ReactiveNotifier<bool>(() => false);
}

mixin OrderService {
  static final ReactiveNotifier<OrderSummary?> currentOrder =
      ReactiveNotifier<OrderSummary?>(() => null);

  static final ReactiveNotifier<String> orderStatus =
      ReactiveNotifier<String>(() => 'pending');
}

mixin UIStateService {
  static final ReactiveNotifier<bool> isDarkMode =
      ReactiveNotifier<bool>(() => false);

  static final ReactiveNotifier<double> fontSize =
      ReactiveNotifier<double>(() => 16.0);

  static final ReactiveNotifier<bool> showNotifications =
      ReactiveNotifier<bool>(() => true);
}

// Components
class ProductCatalogWidget extends StatelessWidget {
  const ProductCatalogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category Filter
        ReactiveBuilder<String>(
          notifier: ProductCatalogService.selectedCategory,
          build: (category, notifier, keep) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Category: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(category,
                          style: const TextStyle(color: Colors.blue)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Products List
        Expanded(
          child: ReactiveBuilder<List<Product>>(
            notifier: ProductCatalogService.products,
            build: (products, notifier, keep) {
              if (products.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No products available',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: product.isAvailable
                              ? Colors.green.withAlpha(100)
                              : Colors.red.withAlpha(100),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.shopping_bag,
                          color:
                              product.isAvailable ? Colors.green : Colors.red,
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.category,
                              style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber),
                              Text(' ${product.rating.toStringAsFixed(1)}'),
                            ],
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            product.isAvailable ? 'In Stock' : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: product.isAvailable
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ShoppingCartWidget extends StatelessWidget {
  const ShoppingCartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<List<CartItem>>(
      notifier: ShoppingCartService.cartItems,
      build: (items, notifier, keep) {
        final subtotal = items.fold(0.0, (sum, item) => sum + item.total);
        final tax = subtotal * 0.08;
        final total = subtotal + tax;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(100),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shopping Cart',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${items.length} items',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Your cart is empty',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add some products to get started!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(100),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.shopping_bag,
                                    color: Colors.blue),
                              ),
                              title: Text(
                                item.product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Quantity: ${item.quantity} × \$${item.product.price.toStringAsFixed(2)}',
                              ),
                              trailing: Text(
                                '\$${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal:',
                                  style: TextStyle(fontSize: 16)),
                              Text('\$${subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tax (8%):',
                                  style: TextStyle(fontSize: 16)),
                              Text('\$${tax.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<User?>(
      notifier: UserService.currentUser,
      build: (user, notifier, keep) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: user == null
              ? const Column(
                  children: [
                    Icon(Icons.person_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Guest User',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please sign in to access your profile',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.blue,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getMembershipColor(user.membershipLevel),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${user.membershipLevel} Member',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(user.discountRate * 100).toInt()}% Discount',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Color _getMembershipColor(String level) {
    switch (level.toLowerCase()) {
      case 'premium':
        return Colors.purple;
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}

class OrderSummaryWidget extends StatelessWidget {
  const OrderSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<OrderSummary?>(
      notifier: OrderService.currentOrder,
      build: (order, notifier, keep) {
        if (order == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No order summary available',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(100),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...order.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Qty: ${item.quantity} × \$${item.product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${item.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                const Divider(),
                _buildSummaryRow('Subtotal', order.subtotal),
                _buildSummaryRow('Discount', -order.discount,
                    color: Colors.green),
                _buildSummaryRow('Tax', order.tax),
                _buildSummaryRow('Shipping', order.shipping),
                const Divider(),
                _buildSummaryRow('Total', order.total, isTotal: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isTotal ? Colors.green : null),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Practical ReactiveNotifier Golden Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
    });

    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('E-commerce Product Catalog', () {
      goldenTest(
        'Product catalog should show different states',
        fileName: 'ecommerce_product_catalog_states',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: '1. Empty Catalog',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Products - Empty')),
                    body: const ProductCatalogWidget(),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '2. Electronics Category',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Products - Electronics')),
                    body: Builder(
                      builder: (context) {
                        ProductCatalogService.selectedCategory
                            .updateSilently('Electronics');
                        ProductCatalogService.products.updateSilently([
                          Product(
                            id: '1',
                            name: 'iPhone 15 Pro',
                            price: 999.99,
                            category: 'Electronics',
                            isAvailable: true,
                            rating: 4.8,
                          ),
                          Product(
                            id: '2',
                            name: 'MacBook Pro',
                            price: 1999.99,
                            category: 'Electronics',
                            isAvailable: true,
                            rating: 4.9,
                          ),
                          Product(
                            id: '3',
                            name: 'AirPods Pro',
                            price: 249.99,
                            category: 'Electronics',
                            isAvailable: false,
                            rating: 4.7,
                          ),
                        ]);
                        return const ProductCatalogWidget();
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '3. Books Category',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Products - Books')),
                    body: Builder(
                      builder: (context) {
                        ProductCatalogService.selectedCategory
                            .updateSilently('Books');
                        ProductCatalogService.products.updateSilently([
                          Product(
                            id: '4',
                            name: 'Clean Code',
                            price: 29.99,
                            category: 'Books',
                            isAvailable: true,
                            rating: 4.6,
                          ),
                          Product(
                            id: '5',
                            name: 'Design Patterns',
                            price: 34.99,
                            category: 'Books',
                            isAvailable: true,
                            rating: 4.5,
                          ),
                        ]);
                        return const ProductCatalogWidget();
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '4. Mixed Availability',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Products - Mixed')),
                    body: Builder(
                      builder: (context) {
                        ProductCatalogService.selectedCategory
                            .updateSilently('All');
                        ProductCatalogService.products.updateSilently([
                          Product(
                            id: '6',
                            name: 'Gaming Laptop',
                            price: 1599.99,
                            category: 'Electronics',
                            isAvailable: true,
                            rating: 4.4,
                          ),
                          Product(
                            id: '7',
                            name: 'Wireless Mouse',
                            price: 79.99,
                            category: 'Electronics',
                            isAvailable: false,
                            rating: 4.2,
                          ),
                          Product(
                            id: '8',
                            name: 'Programming Book',
                            price: 39.99,
                            category: 'Books',
                            isAvailable: true,
                            rating: 4.7,
                          ),
                        ]);
                        return const ProductCatalogWidget();
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });

    group('Shopping Cart Management', () {
      goldenTest(
        'Shopping cart should show different states',
        fileName: 'shopping_cart_states',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: '1. Empty Cart',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Cart - Empty')),
                    body: const ShoppingCartWidget(),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '2. Single Item',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Cart - Single Item')),
                    body: Builder(
                      builder: (context) {
                        ShoppingCartService.cartItems.updateSilently([
                          CartItem(
                            product: Product(
                              id: '1',
                              name: 'iPhone 15 Pro',
                              price: 999.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.8,
                            ),
                            quantity: 1,
                          ),
                        ]);
                        return const ShoppingCartWidget();
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '3. Multiple Items',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Cart - Multiple Items')),
                    body: Builder(
                      builder: (context) {
                        ShoppingCartService.cartItems.updateSilently([
                          CartItem(
                            product: Product(
                              id: '1',
                              name: 'iPhone 15 Pro',
                              price: 999.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.8,
                            ),
                            quantity: 1,
                          ),
                          CartItem(
                            product: Product(
                              id: '2',
                              name: 'AirPods Pro',
                              price: 249.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.7,
                            ),
                            quantity: 2,
                          ),
                        ]);
                        return const ShoppingCartWidget();
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '4. Full Cart',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Cart - Full')),
                    body: Builder(
                      builder: (context) {
                        ShoppingCartService.cartItems.updateSilently([
                          CartItem(
                            product: Product(
                              id: '1',
                              name: 'MacBook Pro 16"',
                              price: 1999.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.9,
                            ),
                            quantity: 1,
                          ),
                          CartItem(
                            product: Product(
                              id: '2',
                              name: 'iPhone 15 Pro',
                              price: 999.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.8,
                            ),
                            quantity: 1,
                          ),
                          CartItem(
                            product: Product(
                              id: '3',
                              name: 'AirPods Pro',
                              price: 249.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.7,
                            ),
                            quantity: 2,
                          ),
                          CartItem(
                            product: Product(
                              id: '4',
                              name: 'Magic Mouse',
                              price: 79.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.2,
                            ),
                            quantity: 1,
                          ),
                        ]);
                        return const ShoppingCartWidget();
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });

    group('User Profile Management', () {
      goldenTest(
        'User profile should show different membership levels',
        fileName: 'user_profile_membership_levels',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: '1. Guest User',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Profile - Guest')),
                    body: const Center(child: UserProfileWidget()),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '2. Regular Member',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Profile - Regular')),
                    body: Builder(
                      builder: (context) {
                        UserService.currentUser.updateSilently(User(
                          id: '1',
                          name: 'John Doe',
                          email: 'john@example.com',
                          membershipLevel: 'Regular',
                          discountRate: 0.05,
                        ));
                        return const Center(child: UserProfileWidget());
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '3. Gold Member',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Profile - Gold')),
                    body: Builder(
                      builder: (context) {
                        UserService.currentUser.updateSilently(User(
                          id: '2',
                          name: 'Alice Johnson',
                          email: 'alice@example.com',
                          membershipLevel: 'Gold',
                          discountRate: 0.15,
                        ));
                        return const Center(child: UserProfileWidget());
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '4. Premium Member',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Profile - Premium')),
                    body: Builder(
                      builder: (context) {
                        UserService.currentUser.updateSilently(User(
                          id: '3',
                          name: 'Bob Smith',
                          email: 'bob@example.com',
                          membershipLevel: 'Premium',
                          discountRate: 0.25,
                        ));
                        return const Center(child: UserProfileWidget());
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });

    group('Order Summary Display', () {
      goldenTest(
        'Order summary should show different order complexities',
        fileName: 'order_summary_complexities',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: '1. No Order',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Order - None')),
                    body: const OrderSummaryWidget(),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '2. Simple Order',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Order - Simple')),
                    body: Builder(
                      builder: (context) {
                        final items = [
                          CartItem(
                            product: Product(
                              id: '1',
                              name: 'iPhone 15',
                              price: 799.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.8,
                            ),
                            quantity: 1,
                          ),
                        ];
                        const subtotal = 799.99;
                        const discount = 0.0;
                        const tax = subtotal * 0.08;
                        const shipping = 9.99;
                        const total = subtotal - discount + tax + shipping;

                        OrderService.currentOrder.updateSilently(OrderSummary(
                          items: items,
                          subtotal: subtotal,
                          discount: discount,
                          tax: tax,
                          shipping: shipping,
                          total: total,
                        ));
                        return const OrderSummaryWidget();
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '3. Order with Discount',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Order - Discount')),
                    body: Builder(
                      builder: (context) {
                        final items = [
                          CartItem(
                            product: Product(
                              id: '1',
                              name: 'MacBook Pro',
                              price: 1999.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.9,
                            ),
                            quantity: 1,
                          ),
                          CartItem(
                            product: Product(
                              id: '2',
                              name: 'AirPods Pro',
                              price: 249.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.7,
                            ),
                            quantity: 1,
                          ),
                        ];
                        const subtotal = 2249.98;
                        const discount = 224.99; // 10% discount
                        const tax = (subtotal - discount) * 0.08;
                        const shipping = 0.0; // Free shipping
                        const total = subtotal - discount + tax + shipping;

                        OrderService.currentOrder.updateSilently(OrderSummary(
                          items: items,
                          subtotal: subtotal,
                          discount: discount,
                          tax: tax,
                          shipping: shipping,
                          total: total,
                        ));
                        return const OrderSummaryWidget();
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '4. Large Order',
                child: MaterialApp(
                  home: Scaffold(
                    appBar: AppBar(title: const Text('Order - Large')),
                    body: Builder(
                      builder: (context) {
                        final items = [
                          CartItem(
                            product: Product(
                              id: '1',
                              name: 'MacBook Pro 16"',
                              price: 1999.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.9,
                            ),
                            quantity: 2,
                          ),
                          CartItem(
                            product: Product(
                              id: '2',
                              name: 'iPhone 15 Pro',
                              price: 999.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.8,
                            ),
                            quantity: 3,
                          ),
                          CartItem(
                            product: Product(
                              id: '3',
                              name: 'AirPods Pro',
                              price: 249.99,
                              category: 'Electronics',
                              isAvailable: true,
                              rating: 4.7,
                            ),
                            quantity: 4,
                          ),
                        ];
                        const subtotal = 8998.92;
                        const discount = 1349.84; // 15% discount
                        const tax = (subtotal - discount) * 0.08;
                        const shipping = 0.0; // Free shipping
                        const total = subtotal - discount + tax + shipping;

                        OrderService.currentOrder.updateSilently(OrderSummary(
                          items: items,
                          subtotal: subtotal,
                          discount: discount,
                          tax: tax,
                          shipping: shipping,
                          total: total,
                        ));
                        return const OrderSummaryWidget();
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  });
}
