import 'package:hive_flutter/hive_flutter.dart';

class CacheManager {
  final String boxName;
  final int cacheDurationMinutes;

  CacheManager({
    required this.boxName,
    this.cacheDurationMinutes = 2,
  });

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  Future<T?> get<T>(String key) async {
    final box = await _getBox();
    final data = box.get('data_$key');
    final timestamp = box.get('ts_$key') as int?;

    if (data != null && timestamp != null) {
      final cacheAgeMinutes =
          (DateTime.now().millisecondsSinceEpoch - timestamp) / (1000 * 60);

      if (cacheAgeMinutes < cacheDurationMinutes) {
        return data as T;
      }
    }
    return null;
  }

  Future<void> set<T>(String key, T data) async {
    final box = await _getBox();
    await box.put('data_$key', data);
    await box.put('ts_$key', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> invalidate(String key) async {
    final box = await _getBox();
    await box.delete('data_$key');
    await box.delete('ts_$key');
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
    } else if (prefix.startsWith("chart_")) {
      return "${prefix}_${coinId}_${vsCurrency}_${days ?? '1'}d";
    }
    return "${prefix}_${vsCurrency}_ids-${ids ?? "all"}_p-${page ?? 1}_pp-${perPage ?? 100}";
  }
}
