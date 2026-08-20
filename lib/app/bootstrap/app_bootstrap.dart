import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:openfoodfacts/openfoodfacts.dart';

import '../../features/history/data/daily_nutrition_analytics_repository.dart';
import '../../features/history/data/history_repository.dart';
import '../../features/history/data/meal_entry_repository.dart';
import '../../features/history/data/product_history.dart';
import '../../features/history/data/product_history_adapter.dart';
import '../../features/history/data/weekly_stats_repository.dart';
import '../../features/product/data/product_cache.dart';
import '../../features/pantry/data/pantry_repository.dart';
import '../../features/product/data/product_cache_adapter.dart';
import '../../features/product/data/product_cache_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.historyRepository,
    required this.weeklyStatsRepository,
    required this.dailyNutritionAnalyticsRepository,
    required this.mealEntryRepository,
    required this.productCacheRepository,
    required this.pantryRepository,
  });

  final HistoryRepository historyRepository;
  final WeeklyStatsRepository weeklyStatsRepository;
  final DailyNutritionAnalyticsRepository dailyNutritionAnalyticsRepository;
  final MealEntryRepository mealEntryRepository;
  final ProductCacheRepository productCacheRepository;
  final PantryRepository pantryRepository;
}

class AppBootstrap {
  // [NEW] Key yang digunakan untuk menyimpan encryption key di secure storage
  static const _hiveEncryptionKeyName = 'hive_encryption_key';

  Future<AppDependencies> initialize() async {
    return _initializeInternal().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException(
        'Inisialisasi terlalu lama. Periksa data lokal (Hive) atau storage perangkat.',
      ),
    );
  }

  Future<AppDependencies> _initializeInternal() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(ProductHistoryAdapter.adapterTypeId)) {
      Hive.registerAdapter(ProductHistoryAdapter());
    }

    if (!Hive.isAdapterRegistered(ProductCacheAdapter.adapterTypeId)) {
      Hive.registerAdapter(ProductCacheAdapter());
    }

    // [NEW] Ambil atau buat encryption key, lalu simpan di secure storage
    final cipher = await _getOrCreateHiveCipher();

    // [NEW] Box sensitif (history dan analytics) dibuka dengan cipher enkripsi
    final box = await _openBoxWithRecovery<ProductHistory>(
      HistoryRepository.boxName,
      encryptionCipher: cipher,
    );
    final analyticsBox = await _openBoxWithRecovery<dynamic>(
      DailyNutritionAnalyticsRepository.boxName,
      encryptionCipher: cipher,
    );
    final mealEntryBox = await _openBoxWithRecovery<dynamic>(
      MealEntryRepository.boxName,
      encryptionCipher: cipher,
    );
    final pantryBox = await _openBoxWithRecovery<dynamic>(
      PantryRepository.boxName,
      encryptionCipher: cipher,
    );

    // [NOTE] weeklyStatsBox dan productCacheBox menyimpan data agregat / cache
    // non-sensitif, tidak perlu enkripsi wajib, tapi bisa ditambahkan.
    final weeklyStatsBox = await _openBoxWithRecovery<double>(
      WeeklyStatsRepository.boxName,
    );
    final productCacheBox = await _openBoxWithRecovery<ProductCache>(
      ProductCacheRepository.boxName,
    );

    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'food_nutritions',
      version: '1.0.0',
    );

    final productCacheRepository = ProductCacheRepository(productCacheBox);
    await productCacheRepository.clearExpired();

    return AppDependencies(
      historyRepository: HistoryRepository(box),
      weeklyStatsRepository: WeeklyStatsRepository(weeklyStatsBox),
      dailyNutritionAnalyticsRepository: DailyNutritionAnalyticsRepository(
        analyticsBox,
      ),
      mealEntryRepository: MealEntryRepository(mealEntryBox),
      productCacheRepository: productCacheRepository,
      pantryRepository: PantryRepository(pantryBox),
    );
  }

  // [NEW] Ambil key dari FlutterSecureStorage; jika belum ada, generate dan simpan
  Future<HiveAesCipher> _getOrCreateHiveCipher() async {
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    final existingKey = await secureStorage.read(key: _hiveEncryptionKeyName);

    if (existingKey != null) {
      final keyBytes = base64Decode(existingKey);
      return HiveAesCipher(keyBytes);
    }

    // Generate 256-bit random key baru
    final newKey = Hive.generateSecureKey();
    await secureStorage.write(
      key: _hiveEncryptionKeyName,
      value: base64Encode(newKey),
    );
    return HiveAesCipher(newKey);
  }

  Future<Box<T>> _openBoxWithRecovery<T>(
    String boxName, {
    HiveAesCipher? encryptionCipher,
  }) async {
    try {
      return await Hive.openBox<T>(boxName, encryptionCipher: encryptionCipher);
    } on HiveError {
      // Jika box korup (misal: key berubah), hapus dan buat ulang
      await Hive.deleteBoxFromDisk(boxName);
      return Hive.openBox<T>(boxName, encryptionCipher: encryptionCipher);
    }
  }
}
