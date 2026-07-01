import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:template_app/core/config/app_config.dart';

abstract final class SupabaseInitializer {
  static Future<void> init() {
    final config = AppConfig.instance;
    final debug = config.env.toLowerCase() == 'dev';
    return Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
      debug: debug,
    );
  }
}
