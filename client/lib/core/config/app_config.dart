import 'package:flutter/foundation.dart';

enum AppFlavor {
  dev,
  prod;

  static AppFlavor fromString(String value) {
    final normalized = value.trim().toLowerCase();
    return AppFlavor.values.firstWhere(
      (flavor) => flavor.name == normalized,
      orElse: () => throw StateError('Unknown FLAVOR value "$value". Expected "dev" or "prod".'),
    );
  }
}

/// Single source of truth for runtime configuration.
///
/// Values come from `--dart-define-from-file=../.config.<flavor>.json`.
/// Required keys are validated at startup; optional integrations are
/// disabled by default so a fresh template can run without external
/// services.
final class AppConfig {
  AppConfig._({
    required this.env,
    required this.flavor,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.oauthRedirectUri,
    required this.isOtpEnabled,
    required this.enableFirebase,
    required this.enableRevenueCat,
    required this.revenueCatApiKey,
    required this.logApiResponses,
  });

  static AppConfig? _instance;

  static const _requiredKeys = <String>[
    'ENV',
    'FLAVOR',
    'SUPABASE_URL',
    'SUPABASE_PUBLISHABLE_KEY',
  ];

  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('AppConfig not initialized. Call AppConfig.init() in main() before use.');
    }
    return config;
  }

  final String env;
  final AppFlavor flavor;
  final String supabaseUrl;
  final String supabasePublishableKey;

  /// Deep-link URL Supabase Auth redirects to after OAuth / magic-link.
  /// Empty string means OAuth is not configured — only email/password sign-in
  /// is exposed to the user. Format: `myapp://login-callback/`.
  final String oauthRedirectUri;

  /// When true, sign-up requires email OTP verification before the session
  /// becomes usable. When false, the user is signed in immediately after
  /// sign-up. Default: false.
  final bool isOtpEnabled;

  final bool enableFirebase;
  final bool enableRevenueCat;
  final String revenueCatApiKey;
  final bool logApiResponses;

  bool get isProdRelease => flavor == AppFlavor.prod && kReleaseMode;
  bool get analyticsActive => enableFirebase && isProdRelease;

  /// True when at least one OAuth provider can be attempted. Drives whether
  /// the auth UI shows social sign-in buttons.
  bool get isOAuthConfigured => oauthRedirectUri.trim().isNotEmpty;

  static void init() {
    _instance = _fromEnvironment();
  }

  @visibleForTesting
  static void overrideForTesting(AppConfig config) {
    _instance = config;
  }

  static AppConfig _fromEnvironment() {
    final values = <String, String>{
      'ENV': const String.fromEnvironment('ENV'),
      'FLAVOR': const String.fromEnvironment('FLAVOR'),
      'SUPABASE_URL': const String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_PUBLISHABLE_KEY': const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
      'REVENUECAT_API_KEY_ANDROID': const String.fromEnvironment('REVENUECAT_API_KEY_ANDROID'),
      'REVENUECAT_API_KEY_IOS': const String.fromEnvironment('REVENUECAT_API_KEY_IOS'),
      'REVENUECAT_API_KEY_TEST': const String.fromEnvironment('REVENUECAT_API_KEY_TEST'),
    };
    final missing = _requiredKeys
        .where((k) => (values[k] ?? '').trim().isEmpty)
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing app config keys: ${missing.join(', ')}. '
        'Provide them via --dart-define-from-file=../.config.<flavor>.json.',
      );
    }
    final flavor = AppFlavor.fromString(values['FLAVOR']!);
    return AppConfig._(
      env: values['ENV']!,
      flavor: flavor,
      supabaseUrl: values['SUPABASE_URL']!,
      supabasePublishableKey: values['SUPABASE_PUBLISHABLE_KEY']!,
      oauthRedirectUri: const String.fromEnvironment('OAUTH_REDIRECT_URI'),
      isOtpEnabled: const bool.fromEnvironment('IS_OTP_ENABLED'),
      enableFirebase: const bool.fromEnvironment('ENABLE_FIREBASE'),
      enableRevenueCat: const bool.fromEnvironment('ENABLE_REVENUECAT'),
      revenueCatApiKey: _resolveRevenueCatApiKey(flavor, values),
      logApiResponses: const bool.fromEnvironment('LOG_API_RESPONSES'),
    );
  }

  static String _resolveRevenueCatApiKey(AppFlavor flavor, Map<String, String> values) {
    final testKey = values['REVENUECAT_API_KEY_TEST']?.trim() ?? '';
    final androidKey = values['REVENUECAT_API_KEY_ANDROID']?.trim() ?? '';
    final iosKey = values['REVENUECAT_API_KEY_IOS']?.trim() ?? '';
    if (flavor == AppFlavor.dev) {
      return testKey;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidKey,
      TargetPlatform.iOS => iosKey,
      _ => '',
    };
  }
}
