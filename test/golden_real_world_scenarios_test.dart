import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'config/alchemist_config.dart';

/// Real-World Scenario Golden Tests
///
/// These tests demonstrate practical use cases of ReactiveNotifier:
/// 1. Shopping Cart Management
/// 2. User Authentication Flow
/// 3. Theme Management
/// 4. Settings Management
/// 5. Data Loading and Error Handling
/// 6. Multi-state Dashboard
///
/// Each test shows how ReactiveNotifier works in realistic scenarios
/// that developers would actually implement in their apps.

// Models for real-world scenarios
class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  double get total => price * quantity;
}

class ShoppingCart {
  final List<CartItem> items;
  final double discount;
  final double tax;

  ShoppingCart({
    this.items = const [],
    this.discount = 0.0,
    this.tax = 0.0,
  });

  ShoppingCart copyWith({
    List<CartItem>? items,
    double? discount,
    double? tax,
  }) {
    return ShoppingCart(
      items: items ?? this.items,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
    );
  }

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get discountAmount => subtotal * discount;
  double get taxAmount => (subtotal - discountAmount) * tax;
  double get total => subtotal - discountAmount + taxAmount;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

class User {
  final String id;
  final String name;
  final String email;
  final bool isVerified;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.isVerified = false,
    this.avatarUrl,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    bool? isVerified,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class AppTheme {
  final bool isDark;
  final Color primaryColor;
  final String fontFamily;
  final double fontSize;

  AppTheme({
    required this.isDark,
    required this.primaryColor,
    required this.fontFamily,
    required this.fontSize,
  });

  AppTheme copyWith({
    bool? isDark,
    Color? primaryColor,
    String? fontFamily,
    double? fontSize,
  }) {
    return AppTheme(
      isDark: isDark ?? this.isDark,
      primaryColor: primaryColor ?? this.primaryColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class AppSettings {
  final bool notifications;
  final bool autoSync;
  final String language;
  final double volume;

  AppSettings({
    required this.notifications,
    required this.autoSync,
    required this.language,
    required this.volume,
  });

  AppSettings copyWith({
    bool? notifications,
    bool? autoSync,
    String? language,
    double? volume,
  }) {
    return AppSettings(
      notifications: notifications ?? this.notifications,
      autoSync: autoSync ?? this.autoSync,
      language: language ?? this.language,
      volume: volume ?? this.volume,
    );
  }
}

// Service classes following CLAUDE.md patterns
mixin ShoppingCartService {
  static final ReactiveNotifier<ShoppingCart> cart =
      ReactiveNotifier<ShoppingCart>(() => ShoppingCart());

  static void addItem(CartItem item) {
    cart.transformState((currentCart) {
      final existingIndex =
          currentCart.items.indexWhere((i) => i.id == item.id);
      if (existingIndex >= 0) {
        final items = List<CartItem>.from(currentCart.items);
        items[existingIndex] = items[existingIndex].copyWith(
          quantity: items[existingIndex].quantity + item.quantity,
        );
        return currentCart.copyWith(items: items);
      } else {
        return currentCart.copyWith(
          items: [...currentCart.items, item],
        );
      }
    });
  }

  static void removeItem(String itemId) {
    cart.transformState((currentCart) {
      return currentCart.copyWith(
        items: currentCart.items.where((item) => item.id != itemId).toList(),
      );
    });
  }

  static void updateQuantity(String itemId, int quantity) {
    cart.transformState((currentCart) {
      final items = currentCart.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();
      return currentCart.copyWith(items: items);
    });
  }

  static void clearCart() {
    cart.updateState(ShoppingCart());
  }
}

mixin UserService {
  static final ReactiveNotifier<User?> currentUser =
      ReactiveNotifier<User?>(() => null);

  static void login(User user) {
    currentUser.updateState(user);
  }

  static void logout() {
    currentUser.updateState(null);
  }

  static void updateProfile(User updatedUser) {
    currentUser.updateState(updatedUser);
  }
}

mixin ThemeService {
  static final ReactiveNotifier<AppTheme> theme =
      ReactiveNotifier<AppTheme>(() => AppTheme(
            isDark: false,
            primaryColor: Colors.blue,
            fontFamily: 'System',
            fontSize: 16.0,
          ));

  static void toggleTheme() {
    theme
        .transformState((current) => current.copyWith(isDark: !current.isDark));
  }

  static void updatePrimaryColor(Color color) {
    theme.transformState((current) => current.copyWith(primaryColor: color));
  }

  static void updateFontSize(double size) {
    theme.transformState((current) => current.copyWith(fontSize: size));
  }
}

mixin SettingsService {
  static final ReactiveNotifier<AppSettings> settings =
      ReactiveNotifier<AppSettings>(() => AppSettings(
            notifications: true,
            autoSync: true,
            language: 'en',
            volume: 0.5,
          ));

  static void toggleNotifications() {
    settings.transformState(
        (current) => current.copyWith(notifications: !current.notifications));
  }

  static void toggleAutoSync() {
    settings.transformState(
        (current) => current.copyWith(autoSync: !current.autoSync));
  }

  static void updateLanguage(String language) {
    settings.transformState((current) => current.copyWith(language: language));
  }

  static void updateVolume(double volume) {
    settings.transformState((current) => current.copyWith(volume: volume));
  }
}

// Widget components for the scenarios
class ShoppingCartWidget extends StatelessWidget {
  const ShoppingCartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<ShoppingCart>(
      notifier: ShoppingCartService.cart,
      build: (cart, notifier, keep) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shopping Cart',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (cart.items.isEmpty)
                const Center(
                  child: Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ...cart.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
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
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '\$${item.price.toStringAsFixed(2)} x ${item.quantity}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${cart.total.toStringAsFixed(2)}',
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
            ],
          ),
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: user == null
              ? const Column(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Not logged in',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please log in to access your profile',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (user.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class ThemePreviewWidget extends StatelessWidget {
  const ThemePreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<AppTheme>(
      notifier: ThemeService.theme,
      build: (theme, notifier, keep) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Theme Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Icon(
                    theme.isDark ? Icons.dark_mode : Icons.light_mode,
                    color: theme.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Primary Color',
                      style: TextStyle(
                        fontSize: theme.fontSize,
                        color: theme.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Font Size',
                      style: TextStyle(
                        fontSize: theme.fontSize,
                        color: theme.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '${theme.fontSize.toInt()}px',
                      style: TextStyle(
                        fontSize: theme.fontSize,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mode: ${theme.isDark ? 'Dark' : 'Light'}',
                style: TextStyle(
                  fontSize: theme.fontSize,
                  color: theme.isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsWidget extends StatelessWidget {
  const SettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder<AppSettings>(
      notifier: SettingsService.settings,
      build: (settings, notifier, keep) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildSettingRow(
                icon: Icons.notifications,
                title: 'Notifications',
                value: settings.notifications,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildSettingRow(
                icon: Icons.sync,
                title: 'Auto Sync',
                value: settings.autoSync,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.language,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Language',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      settings.language.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.volume_up,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Volume',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(settings.volume * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required bool value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: value ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value ? 'ON' : 'OFF',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('Real-World Scenarios Golden Tests', () {
    setUp(() {
      ReactiveNotifier.cleanup();
      ShoppingCartService.cart.updateSilently(ShoppingCart());
      UserService.currentUser.updateSilently(null);
      ThemeService.theme.updateSilently(AppTheme(
        isDark: false,
        primaryColor: Colors.blue,
        fontFamily: 'System',
        fontSize: 16.0,
      ));
      SettingsService.settings.updateSilently(AppSettings(
        notifications: true,
        autoSync: true,
        language: 'en',
        volume: 0.5,
      ));
    });

    tearDown(() {
      ReactiveNotifier.cleanup();
    });

    group('Shopping Cart Management', () {
      goldenTest(
        'Empty shopping cart should show empty state',
        fileName: 'shopping_cart_empty',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:
              ReactiveNotifierAlchemistConfig.mobileConstraints,
          children: [
            GoldenTestScenario(
              name: 'Empty Cart',
              child: MaterialApp(
                home: Scaffold(
                  backgroundColor: Colors.grey[100],
                  body: const Center(
                    child: ShoppingCartWidget(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      goldenTest(
        'Shopping cart with items should show items and total',
        fileName: 'shopping_cart_with_items',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          // Add items to cart
          ShoppingCartService.addItem(CartItem(
            id: '1',
            name: 'iPhone 15',
            price: 999.99,
            quantity: 1,
          ));
          ShoppingCartService.addItem(CartItem(
            id: '2',
            name: 'AirPods Pro',
            price: 249.99,
            quantity: 2,
          ));

          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: 'Cart with Items',
                child: MaterialApp(
                  home: Scaffold(
                    backgroundColor: Colors.grey[100],
                    body: const Center(
                      child: ShoppingCartWidget(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });

    group('User Authentication Flow', () {
      goldenTest(
        'User profile should show logged out state',
        fileName: 'user_profile_logged_out',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:
              ReactiveNotifierAlchemistConfig.mobileConstraints,
          children: [
            GoldenTestScenario(
              name: 'Logged Out',
              child: MaterialApp(
                home: Scaffold(
                  backgroundColor: Colors.grey[100],
                  body: const Center(
                    child: UserProfileWidget(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      goldenTest(
        'User profile should show logged in user details',
        fileName: 'user_profile_logged_in',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          // Log in a user
          UserService.login(User(
            id: '1',
            name: 'John Doe',
            email: 'john.doe@example.com',
            isVerified: true,
          ));

          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: 'Logged In User',
                child: MaterialApp(
                  home: Scaffold(
                    backgroundColor: Colors.grey[100],
                    body: const Center(
                      child: UserProfileWidget(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });

    group('Theme Management', () {
      goldenTest(
        'Theme settings should show light theme configuration',
        fileName: 'theme_settings_light',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () => GoldenTestGroup(
          scenarioConstraints:
              ReactiveNotifierAlchemistConfig.mobileConstraints,
          children: [
            GoldenTestScenario(
              name: 'Light Theme',
              child: MaterialApp(
                home: Scaffold(
                  backgroundColor: Colors.grey[100],
                  body: const Center(
                    child: ThemePreviewWidget(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

      goldenTest(
        'Theme settings should show dark theme configuration',
        fileName: 'theme_settings_dark',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          // Switch to dark theme
          ThemeService.toggleTheme();
          ThemeService.updatePrimaryColor(Colors.purple);
          ThemeService.updateFontSize(18.0);

          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: 'Dark Theme',
                child: MaterialApp(
                  home: Scaffold(
                    backgroundColor: Colors.grey[100],
                    body: const Center(
                      child: ThemePreviewWidget(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });

    group('Settings Management', () {
      goldenTest(
        'Settings should show complete configuration flow',
        fileName: 'settings_configuration_flow',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: '1. Default Settings',
                child: MaterialApp(
                  home: Scaffold(
                    backgroundColor: Colors.grey[100],
                    body: Builder(
                      builder: (context) {
                        // Reset to default settings
                        SettingsService.settings.updateSilently(AppSettings(
                          notifications: true,
                          autoSync: true,
                          language: 'en',
                          volume: 0.5,
                        ));
                        return const Center(child: SettingsWidget());
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '2. Notifications Off',
                child: MaterialApp(
                  home: Scaffold(
                    backgroundColor: Colors.grey[100],
                    body: Builder(
                      builder: (context) {
                        // Turn off notifications
                        SettingsService.settings.updateSilently(AppSettings(
                          notifications: false,
                          autoSync: true,
                          language: 'en',
                          volume: 0.5,
                        ));
                        return const Center(child: SettingsWidget());
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '3. Spanish + High Volume',
                child: MaterialApp(
                  home: Scaffold(
                    backgroundColor: Colors.grey[100],
                    body: Builder(
                      builder: (context) {
                        // Change language and volume
                        SettingsService.settings.updateSilently(AppSettings(
                          notifications: false,
                          autoSync: true,
                          language: 'es',
                          volume: 0.85,
                        ));
                        return const Center(child: SettingsWidget());
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '4. All Customized',
                child: MaterialApp(
                  home: Scaffold(
                    backgroundColor: Colors.grey[100],
                    body: Builder(
                      builder: (context) {
                        // Fully customized settings
                        SettingsService.settings.updateSilently(AppSettings(
                          notifications: false,
                          autoSync: false,
                          language: 'fr',
                          volume: 0.25,
                        ));
                        return const Center(child: SettingsWidget());
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

    group('Combined Multi-State Dashboard', () {
      goldenTest(
        'Dashboard should show complete multi-state interaction',
        fileName: 'dashboard_multi_state_flow',
        constraints: ReactiveNotifierAlchemistConfig.mobileConstraints,
        builder: () {
          return GoldenTestGroup(
            scenarioConstraints:
                ReactiveNotifierAlchemistConfig.mobileConstraints,
            children: [
              GoldenTestScenario(
                name: '1. Fresh Start',
                child: MaterialApp(
                  home: Scaffold(
                    backgroundColor: Colors.grey[100],
                    appBar:
                        AppBar(title: const Text('Dashboard - Fresh Start')),
                    body: Builder(
                      builder: (context) {
                        // Reset all states
                        ShoppingCartService.cart.updateSilently(ShoppingCart());
                        UserService.currentUser.updateSilently(null);
                        ThemeService.theme.updateSilently(AppTheme(
                          isDark: false,
                          primaryColor: Colors.blue,
                          fontFamily: 'System',
                          fontSize: 16.0,
                        ));
                        return const SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              UserProfileWidget(),
                              SizedBox(height: 16),
                              ShoppingCartWidget(),
                              SizedBox(height: 16),
                              ThemePreviewWidget(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '2. User Logged In',
                child: MaterialApp(
                  home: Scaffold(
                    backgroundColor: Colors.grey[100],
                    appBar: AppBar(title: const Text('Dashboard - User Login')),
                    body: Builder(
                      builder: (context) {
                        // Log in user
                        UserService.currentUser.updateSilently(User(
                          id: '1',
                          name: 'Alice Johnson',
                          email: 'alice@example.com',
                          isVerified: true,
                        ));
                        return const SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              UserProfileWidget(),
                              SizedBox(height: 16),
                              ShoppingCartWidget(),
                              SizedBox(height: 16),
                              ThemePreviewWidget(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '3. Shopping + Dark Theme',
                child: MaterialApp(
                  home: Scaffold(
                    backgroundColor: Colors.grey[100],
                    appBar: AppBar(title: const Text('Dashboard - Shopping')),
                    body: Builder(
                      builder: (context) {
                        // Add items to cart and switch theme
                        ShoppingCartService.cart.updateSilently(ShoppingCart(
                          items: [
                            CartItem(
                              id: '1',
                              name: 'MacBook Pro',
                              price: 1999.99,
                              quantity: 1,
                            ),
                            CartItem(
                              id: '2',
                              name: 'iPhone 15',
                              price: 999.99,
                              quantity: 1,
                            ),
                          ],
                        ));
                        ThemeService.theme.updateSilently(AppTheme(
                          isDark: true,
                          primaryColor: Colors.purple,
                          fontFamily: 'System',
                          fontSize: 18.0,
                        ));
                        return const SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              UserProfileWidget(),
                              SizedBox(height: 16),
                              ShoppingCartWidget(),
                              SizedBox(height: 16),
                              ThemePreviewWidget(),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              GoldenTestScenario(
                name: '4. Full Cart + Premium User',
                child: MaterialApp(
                  home: Scaffold(
                    backgroundColor: Colors.grey[100],
                    appBar: AppBar(
                        title: const Text('Dashboard - Full Experience')),
                    body: Builder(
                      builder: (context) {
                        // Full cart with premium user
                        UserService.currentUser.updateSilently(User(
                          id: '1',
                          name: 'Premium User',
                          email: 'premium@example.com',
                          isVerified: true,
                        ));
                        ShoppingCartService.cart.updateSilently(ShoppingCart(
                          items: [
                            CartItem(
                              id: '1',
                              name: 'MacBook Pro',
                              price: 1999.99,
                              quantity: 1,
                            ),
                            CartItem(
                              id: '2',
                              name: 'iPhone 15',
                              price: 999.99,
                              quantity: 2,
                            ),
                            CartItem(
                              id: '3',
                              name: 'AirPods Pro',
                              price: 249.99,
                              quantity: 1,
                            ),
                          ],
                          discount: 0.1, // 10% discount
                          tax: 0.08, // 8% tax
                        ));
                        return const SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              UserProfileWidget(),
                              SizedBox(height: 16),
                              ShoppingCartWidget(),
                              SizedBox(height: 16),
                              ThemePreviewWidget(),
                            ],
                          ),
                        );
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
