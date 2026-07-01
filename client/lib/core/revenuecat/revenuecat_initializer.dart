import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:template_app/core/config/app_config.dart';
import 'package:template_app/core/logger/logger.dart';

/// Configures RevenueCat at app start. No-op when `ENABLE_REVENUECAT=false`.
///
/// When enabled, a dev build uses `REVENUECAT_API_KEY_TEST`; production
/// builds use the platform-specific Android or iOS public SDK key.
abstract final class RevenueCatInitializer {
  static Future<void> init() async {
    final config = AppConfig.instance;
    if (!config.enableRevenueCat) {
      logger.i('RevenueCat disabled via config — skipping init');
      return;
    }
    final key = config.revenueCatApiKey.trim();
    if (key.isEmpty || key.toLowerCase().contains('placeholder')) {
      logger.w(
        'RevenueCat enabled with a placeholder API key — purchases will not work. '
        'Set REVENUECAT_API_KEY_TEST, REVENUECAT_API_KEY_ANDROID, and '
        'REVENUECAT_API_KEY_IOS in .config.<flavor>.json before shipping.',
      );
    }
    if (config.flavor == AppFlavor.dev) {
      await Purchases.setLogLevel(LogLevel.debug);
    }
    await Purchases.configure(PurchasesConfiguration(key));
    logger.i('revenuecat_configured');
  }
}
