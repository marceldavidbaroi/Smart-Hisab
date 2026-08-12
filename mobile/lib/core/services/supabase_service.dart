import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client wrapper & helper for Smart-Hisab
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase Flutter SDK
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Check if Supabase instance is initialized
  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get current user ID
  static String? get currentUserId => isInitialized ? client.auth.currentUser?.id : null;

  /// Check if user is authenticated
  static bool get isAuthenticated => isInitialized && client.auth.currentUser != null;

  /// Call Supabase RPC endpoint with parameters
  static Future<T?> callRpc<T>(
    String rpcName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await client.rpc(rpcName, params: params);
      return response as T?;
    } catch (e) {
      rethrow;
    }
  }
}
