import '../datasources/local_storage.dart';
import '../datasources/database_helper.dart';
import '../../core/constants/database_constants.dart';

class AppSettings {
  final String themeMode; // 'light', 'dark', 'system'
  final String language; // 'en', 'tr'
  final String sortOrder;
  final String contactViewMode; // 'grid', 'list'
  final bool autoBackup;
  final int backupFrequency; // days
  final bool backupNotifications;
  final bool showStarredFirst;
  final bool autoScanEnabled;
  final double scanConfidenceThreshold;

  AppSettings({
    required this.themeMode,
    required this.language,
    required this.sortOrder,
    required this.contactViewMode,
    required this.autoBackup,
    required this.backupFrequency,
    required this.backupNotifications,
    required this.showStarredFirst,
    required this.autoScanEnabled,
    required this.scanConfidenceThreshold,
  });

  AppSettings copyWith({
    String? themeMode,
    String? language,
    String? sortOrder,
    String? contactViewMode,
    bool? autoBackup,
    int? backupFrequency,
    bool? backupNotifications,
    bool? showStarredFirst,
    bool? autoScanEnabled,
    double? scanConfidenceThreshold,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      sortOrder: sortOrder ?? this.sortOrder,
      contactViewMode: contactViewMode ?? this.contactViewMode,
      autoBackup: autoBackup ?? this.autoBackup,
      backupFrequency: backupFrequency ?? this.backupFrequency,
      backupNotifications: backupNotifications ?? this.backupNotifications,
      showStarredFirst: showStarredFirst ?? this.showStarredFirst,
      autoScanEnabled: autoScanEnabled ?? this.autoScanEnabled,
      scanConfidenceThreshold: scanConfidenceThreshold ?? this.scanConfidenceThreshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'language': language,
      'sortOrder': sortOrder,
      'contactViewMode': contactViewMode,
      'autoBackup': autoBackup,
      'backupFrequency': backupFrequency,
      'backupNotifications': backupNotifications,
      'showStarredFirst': showStarredFirst,
      'autoScanEnabled': autoScanEnabled,
      'scanConfidenceThreshold': scanConfidenceThreshold,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: json['themeMode'] ?? 'system',
      language: json['language'] ?? 'tr',
      sortOrder: json['sortOrder'] ?? DatabaseConstants.sortByName,
      contactViewMode: json['contactViewMode'] ?? 'grid',
      autoBackup: json['autoBackup'] ?? true,
      backupFrequency: json['backupFrequency'] ?? 7,
      backupNotifications: json['backupNotifications'] ?? true,
      showStarredFirst: json['showStarredFirst'] ?? false,
      autoScanEnabled: json['autoScanEnabled'] ?? true,
      scanConfidenceThreshold: json['scanConfidenceThreshold']?.toDouble() ?? 0.8,
    );
  }

  factory AppSettings.defaultSettings() {
    return AppSettings(
      themeMode: 'system',
      language: 'en',
      sortOrder: DatabaseConstants.sortByName,
      contactViewMode: 'grid',
      autoBackup: true,
      backupFrequency: 7,
      backupNotifications: true,
      showStarredFirst: false,
      autoScanEnabled: true,
      scanConfidenceThreshold: 0.8,
    );
  }
}

abstract class SettingsRepositoryInterface {
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);
  Future<void> updateThemeMode(String themeMode);
  Future<void> updateLanguage(String language);
  Future<void> updateSortOrder(String sortOrder);
  Future<void> updateContactViewMode(String viewMode);
  Future<void> resetToDefaults();
}

class SettingsRepository implements SettingsRepositoryInterface {
  final LocalStorage _localStorage;
  final DatabaseHelper _databaseHelper;

  SettingsRepository({
    LocalStorage? localStorage,
    DatabaseHelper? databaseHelper,
  })  : _localStorage = localStorage ?? LocalStorage(),
        _databaseHelper = databaseHelper ?? DatabaseHelper();

  @override
  Future<AppSettings> getSettings() async {
    try {
      final themeMode = await _localStorage.getThemeMode();
      final language = await _localStorage.getLanguage();
      final sortOrder = await _localStorage.getSortOrder();
      final contactViewMode = await _localStorage.getContactViewMode();
      final autoBackup = await _localStorage.getAutoBackup();
      final backupFrequency = await _localStorage.getBackupFrequency();
      final backupNotifications = await _localStorage.getBackupNotifications();
      final showStarredFirst = await _localStorage.getShowStarredFirst();
      final autoScanEnabled = await _localStorage.getAutoScanEnabled();
      final scanConfidenceThreshold = await _localStorage.getScanConfidenceThreshold();

      return AppSettings(
        themeMode: themeMode,
        language: language,
        sortOrder: sortOrder,
        contactViewMode: contactViewMode,
        autoBackup: autoBackup,
        backupFrequency: backupFrequency,
        backupNotifications: backupNotifications,
        showStarredFirst: showStarredFirst,
        autoScanEnabled: autoScanEnabled,
        scanConfidenceThreshold: scanConfidenceThreshold,
      );
    } catch (e) {
      // Return default settings on error
      return AppSettings.defaultSettings();
    }
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    try {
      await _localStorage.setThemeMode(settings.themeMode);
      await _localStorage.setLanguage(settings.language);
      await _localStorage.setSortOrder(settings.sortOrder);
      await _localStorage.setContactViewMode(settings.contactViewMode);
      await _localStorage.setAutoBackup(settings.autoBackup);
      await _localStorage.setBackupFrequency(settings.backupFrequency);
      await _localStorage.setBackupNotifications(settings.backupNotifications);
      await _localStorage.setShowStarredFirst(settings.showStarredFirst);
      await _localStorage.setAutoScanEnabled(settings.autoScanEnabled);
      await _localStorage.setScanConfidenceThreshold(settings.scanConfidenceThreshold);

      // Also update database settings for backup purposes
      await _updateDatabaseSettings(settings);
    } catch (e) {
      throw SettingsRepositoryException('Ayarlar güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> updateThemeMode(String themeMode) async {
    try {
      if (!_isValidThemeMode(themeMode)) {
        throw SettingsRepositoryException('Geçersiz tema modu: $themeMode');
      }

      await _localStorage.setThemeMode(themeMode);
      await _databaseHelper.setSetting(
        DatabaseConstants.settingThemeMode,
        themeMode,
        DatabaseConstants.settingTypeString,
      );
    } catch (e) {
      if (e is SettingsRepositoryException) rethrow;
      throw SettingsRepositoryException('Tema modu güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> updateLanguage(String language) async {
    try {
      if (!_isValidLanguage(language)) {
        throw SettingsRepositoryException('Geçersiz dil kodu: $language');
      }

      await _localStorage.setLanguage(language);
      await _databaseHelper.setSetting(
        DatabaseConstants.settingLanguage,
        language,
        DatabaseConstants.settingTypeString,
      );
    } catch (e) {
      if (e is SettingsRepositoryException) rethrow;
      throw SettingsRepositoryException('Dil güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> updateSortOrder(String sortOrder) async {
    try {
      if (!_isValidSortOrder(sortOrder)) {
        throw SettingsRepositoryException('Geçersiz sıralama düzeni: $sortOrder');
      }

      await _localStorage.setSortOrder(sortOrder);
      await _databaseHelper.setSetting(
        DatabaseConstants.settingSortOrder,
        sortOrder,
        DatabaseConstants.settingTypeString,
      );
    } catch (e) {
      if (e is SettingsRepositoryException) rethrow;
      throw SettingsRepositoryException('Sıralama düzeni güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> updateContactViewMode(String viewMode) async {
    try {
      if (!_isValidViewMode(viewMode)) {
        throw SettingsRepositoryException('Geçersiz görünüm modu: $viewMode');
      }

      await _localStorage.setContactViewMode(viewMode);
    } catch (e) {
      if (e is SettingsRepositoryException) rethrow;
      throw SettingsRepositoryException('Görünüm modu güncellenirken hata oluştu: $e');
    }
  }

  Future<void> updateAutoBackup(bool enabled) async {
    try {
      await _localStorage.setAutoBackup(enabled);
      await _databaseHelper.setSetting(
        DatabaseConstants.settingAutoBackup,
        enabled.toString(),
        DatabaseConstants.settingTypeBool,
      );
    } catch (e) {
      throw SettingsRepositoryException('Otomatik yedekleme ayarı güncellenirken hata oluştu: $e');
    }
  }

  Future<void> updateBackupFrequency(int days) async {
    try {
      if (days < 1 || days > 365) {
        throw SettingsRepositoryException('Yedekleme sıklığı 1-365 gün arasında olmalıdır');
      }

      await _localStorage.setBackupFrequency(days);
      await _databaseHelper.setSetting(
        DatabaseConstants.settingBackupFrequency,
        days.toString(),
        DatabaseConstants.settingTypeInt,
      );
    } catch (e) {
      if (e is SettingsRepositoryException) rethrow;
      throw SettingsRepositoryException('Yedekleme sıklığı güncellenirken hata oluştu: $e');
    }
  }

  Future<void> updateShowStarredFirst(bool showFirst) async {
    try {
      await _localStorage.setShowStarredFirst(showFirst);
    } catch (e) {
      throw SettingsRepositoryException('Favori gösterim ayarı güncellenirken hata oluştu: $e');
    }
  }

  Future<void> updateAutoScanEnabled(bool enabled) async {
    try {
      await _localStorage.setAutoScanEnabled(enabled);
    } catch (e) {
      throw SettingsRepositoryException('Otomatik tarama ayarı güncellenirken hata oluştu: $e');
    }
  }

  Future<void> updateScanConfidenceThreshold(double threshold) async {
    try {
      if (threshold < 0.0 || threshold > 1.0) {
        throw SettingsRepositoryException('Güven eşiği 0.0-1.0 arasında olmalıdır');
      }

      await _localStorage.setScanConfidenceThreshold(threshold);
    } catch (e) {
      if (e is SettingsRepositoryException) rethrow;
      throw SettingsRepositoryException('Tarama güven eşiği güncellenirken hata oluştu: $e');
    }
  }

  @override
  Future<void> resetToDefaults() async {
    try {
      final defaultSettings = AppSettings.defaultSettings();
      await updateSettings(defaultSettings);
    } catch (e) {
      throw SettingsRepositoryException('Ayarlar varsayılan değerlere sıfırlanırken hata oluştu: $e');
    }
  }

  Future<List<String>> getRecentSearches() async {
    try {
      return await _localStorage.getRecentSearches();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearRecentSearches() async {
    try {
      await _localStorage.clearRecentSearches();
    } catch (e) {
      throw SettingsRepositoryException('Son aramalar temizlenirken hata oluştu: $e');
    }
  }

  Future<DateTime?> getLastBackupTime() async {
    try {
      return await _localStorage.getLastBackupTime();
    } catch (e) {
      return null;
    }
  }

  Future<void> setLastBackupTime(DateTime dateTime) async {
    try {
      await _localStorage.setLastBackupTime(dateTime);
    } catch (e) {
      throw SettingsRepositoryException('Son yedekleme zamanı güncellenirken hata oluştu: $e');
    }
  }

  Future<bool> shouldAutoBackup() async {
    try {
      final settings = await getSettings();
      if (!settings.autoBackup) return false;

      final lastBackupTime = await getLastBackupTime();
      if (lastBackupTime == null) return true;

      final daysSinceLastBackup = DateTime.now().difference(lastBackupTime).inDays;
      return daysSinceLastBackup >= settings.backupFrequency;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final settings = await getSettings();
      return {
        'settings': settings.toJson(),
        'recentSearches': await getRecentSearches(),
        'lastBackupTime': (await getLastBackupTime())?.toIso8601String(),
        'exportDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw SettingsRepositoryException('Ayarlar dışa aktarılırken hata oluştu: $e');
    }
  }

  Future<void> importSettings(Map<String, dynamic> data) async {
    try {
      if (data['settings'] != null) {
        final settings = AppSettings.fromJson(data['settings']);
        await updateSettings(settings);
      }

      if (data['lastBackupTime'] != null) {
        final lastBackupTime = DateTime.parse(data['lastBackupTime']);
        await setLastBackupTime(lastBackupTime);
      }
    } catch (e) {
      throw SettingsRepositoryException('Ayarlar içe aktarılırken hata oluştu: $e');
    }
  }

  Future<void> _updateDatabaseSettings(AppSettings settings) async {
    await _databaseHelper.setSetting(
      DatabaseConstants.settingThemeMode,
      settings.themeMode,
      DatabaseConstants.settingTypeString,
    );
    await _databaseHelper.setSetting(
      DatabaseConstants.settingLanguage,
      settings.language,
      DatabaseConstants.settingTypeString,
    );
    await _databaseHelper.setSetting(
      DatabaseConstants.settingSortOrder,
      settings.sortOrder,
      DatabaseConstants.settingTypeString,
    );
    await _databaseHelper.setSetting(
      DatabaseConstants.settingAutoBackup,
      settings.autoBackup.toString(),
      DatabaseConstants.settingTypeBool,
    );
    await _databaseHelper.setSetting(
      DatabaseConstants.settingBackupFrequency,
      settings.backupFrequency.toString(),
      DatabaseConstants.settingTypeInt,
    );
  }

  bool _isValidThemeMode(String themeMode) {
    return ['light', 'dark', 'system'].contains(themeMode);
  }

  bool _isValidLanguage(String language) {
    return ['en', 'tr'].contains(language);
  }

  bool _isValidSortOrder(String sortOrder) {
    return [
      DatabaseConstants.sortByName,
      DatabaseConstants.sortByCompany,
      DatabaseConstants.sortByCreatedAt,
      DatabaseConstants.sortByUpdatedAt,
      DatabaseConstants.sortByStarred,
    ].contains(sortOrder);
  }

  bool _isValidViewMode(String viewMode) {
    return ['grid', 'list'].contains(viewMode);
  }
}

class SettingsRepositoryException implements Exception {
  final String message;
  SettingsRepositoryException(this.message);

  @override
  String toString() => 'SettingsRepositoryException: $message';
}