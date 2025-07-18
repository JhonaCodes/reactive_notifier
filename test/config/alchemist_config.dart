import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';

/// Alchemist configuration for ReactiveNotifier golden tests
/// 
/// This configuration ensures consistent golden test image generation
/// across all platforms and test scenarios.
class ReactiveNotifierAlchemistConfig {
  /// Standard configuration for ReactiveNotifier golden tests
  static const AlchemistConfig standard = AlchemistConfig(
    // Don't force update golden files by default
    forceUpdateGoldenFiles: false,
    
    // Configure platform-specific golden test settings
    platformGoldensConfig: PlatformGoldensConfig(
      enabled: true,
      renderShadows: true,
      obscureText: false,
    ),
  );

  /// Configuration for wide layout tests
  static const AlchemistConfig wideLayout = AlchemistConfig(
    forceUpdateGoldenFiles: false,
    platformGoldensConfig: PlatformGoldensConfig(
      enabled: true,
      renderShadows: true,
      obscureText: false,
    ),
  );

  /// Standard constraints for wide golden tests (now mobile-like)
  static const BoxConstraints wideConstraints = BoxConstraints(
    minWidth: 375,
    maxWidth: 375,
    minHeight: 667,
    maxHeight: 667,
  );

  /// Standard constraints for mobile golden tests
  static const BoxConstraints mobileConstraints = BoxConstraints(
    minWidth: 375,
    maxWidth: 375,
    minHeight: 667,
    maxHeight: 667,
  );

  /// Standard constraints for tablet golden tests
  static const BoxConstraints tabletConstraints = BoxConstraints(
    minWidth: 768,
    maxWidth: 768,
    minHeight: 1024,
    maxHeight: 1024,
  );

  /// Standard constraints for desktop golden tests
  static const BoxConstraints desktopConstraints = BoxConstraints(
    minWidth: 1440,
    maxWidth: 1440,
    minHeight: 900,
    maxHeight: 900,
  );

  /// Get constraints based on layout type
  static BoxConstraints getConstraints(LayoutType layoutType) {
    switch (layoutType) {
      case LayoutType.mobile:
        return mobileConstraints;
      case LayoutType.tablet:
        return tabletConstraints;
      case LayoutType.desktop:
        return desktopConstraints;
      case LayoutType.wide:
        return wideConstraints;
    }
  }
}

/// Layout types for golden tests
enum LayoutType {
  mobile,
  tablet,
  desktop,
  wide,
}