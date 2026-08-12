import 'package:hive_flutter/hive_flutter.dart';

/// Hive offline persistence service managing outbox, entity cache & sync boxes
class HiveService {
  static const String outboxBoxName = 'outbox_box';
  static const String cacheBoxName = 'cache_box';
  static const String syncBoxName = 'sync_box';

  static late Box _outboxBox;
  static late Box _cacheBox;
  static late Box _syncBox;

  static Box get outboxBox => _outboxBox;
  static Box get cacheBox => _cacheBox;
  static Box get syncBox => _syncBox;

  /// Initialize Hive Flutter and open standard boxes
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _outboxBox = await Hive.openBox(outboxBoxName);
    _cacheBox = await Hive.openBox(cacheBoxName);
    _syncBox = await Hive.openBox(syncBoxName);
  }

  /// Write item to cache box with specific key (e.g. 'customer:123')
  static Future<void> setCache(String key, Map<String, dynamic> value) async {
    if (!Hive.isBoxOpen(cacheBoxName)) return;
    await _cacheBox.put(key, value);
  }

  /// Read item from cache box
  static Map<String, dynamic>? getCache(String key) {
    if (!Hive.isBoxOpen(cacheBoxName)) return null;
    final raw = _cacheBox.get(key);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw as Map);
  }

  /// Remove item from cache box (targeted local cache mutation)
  static Future<void> deleteCache(String key) async {
    if (!Hive.isBoxOpen(cacheBoxName)) return;
    await _cacheBox.delete(key);
  }
}
