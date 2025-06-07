import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CacheException implements Exception {
  final String message;
  final dynamic data;
  CacheException(this.message, {this.data});
  @override
  String toString() => 'CacheException: $message';
}

class CacheManager {
  static const Duration defaultExpiration = Duration(minutes: 3);
  late Box _box;
  final String boxName;
  bool _isInitialized = false;
  CacheManager({required this.boxName});
  Future<void> init() async {
    if (_isInitialized) return;
    final directory = await getApplicationDocumentsDirectory();
    Hive.init(directory.path);
    _box = await Hive.openBox(boxName);
    _isInitialized = true;
  }

  String generateKey({
    required String prefix,
    String? coinId,
    String vsCurrency = 'idr',
    String? ids,
    int? perPage,
    int? page,
    int? days,
  }) {
    if (prefix.startsWith("detail_")) {
      return "${prefix}_${coinId}_$vsCurrency";
    } else if (prefix.startsWith("detailcache")) {
      return "${prefix}_${coinId}_$vsCurrency";
    } else if (prefix.startsWith("chart_")) {
      return "${prefix}_${coinId}_${vsCurrency}_${days ?? '1'}d";
    }
    return "${prefix}_${vsCurrency}_ids-${ids ?? "all"}_p-${page ?? 1}_pp-${perPage ?? 100}";
  }

  Future<T?> get<T>(String key) async {
    await _ensureInitialized();
    final data = _box.get(key);
    if (data == null) return null;
    if (boxName.contains('ttl')) {
      return data as T;
    }
    final cacheData = json.decode(data);
    final expiryTime = DateTime.parse(cacheData['expiryTime']);
    if (DateTime.now().isAfter(expiryTime)) {
      await _box.delete(key);
      return null;
    }
    return cacheData['data'] as T;
  }

  Future<void> set(String key, dynamic data, {Duration? expiration}) async {
    await _ensureInitialized();
    if (boxName.contains('ttl')) {
      await _box.put(key, data);
      return;
    }

    final expiryTime = DateTime.now().add(expiration ?? defaultExpiration);
    final cacheData = {
      'data': data,
      'expiryTime': expiryTime.toIso8601String(),
    };

    await _box.put(key, json.encode(cacheData));
  }

  Future<void> delete(String key) async {
    await _ensureInitialized();
    await _box.delete(key);
  }

  Future<void> clear() async {
    await _ensureInitialized();
    await _box.clear();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await init();
    }
  }

  Future<void> close() async {
    if (_isInitialized) {
      await _box.close();
      _isInitialized = false;
    }
  }
}
