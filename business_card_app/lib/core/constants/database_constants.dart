// Database configuration
class DatabaseConstants {
  // Database info
  static const String databaseName = 'business_card_app.db';
  static const int databaseVersion = 1;

  // Table names
  static const String contactsTable = 'contacts';
  static const String userSettingsTable = 'user_settings';
  static const String backupHistoryTable = 'backup_history';

  // Contacts table columns
  static const String contactsId = 'id';
  static const String contactsName = 'name';
  static const String contactsCompany = 'company';
  static const String contactsTitle = 'title';
  static const String contactsPhone = 'phone';
  static const String contactsEmail = 'email';
  static const String contactsWebsite = 'website';
  static const String contactsTags = 'tags';
  static const String contactsNotes = 'notes';
  static const String contactsCreatedAt = 'created_at';
  static const String contactsUpdatedAt = 'updated_at';
  static const String contactsIsStarred = 'is_starred';
  static const String contactsCardImagePath = 'card_image_path';
  static const String contactsSocialMedia = 'social_media';

  // User settings table columns
  static const String settingsId = 'id';
  static const String settingsKey = 'key';
  static const String settingsValue = 'value';
  static const String settingsType = 'type';
  static const String settingsUpdatedAt = 'updated_at';

  // Backup history table columns
  static const String backupId = 'id';
  static const String backupFileName = 'file_name';
  static const String backupFilePath = 'file_path';
  static const String backupContactCount = 'contact_count';
  static const String backupFileSize = 'file_size';
  static const String backupCreatedAt = 'created_at';
  static const String backupType = 'type'; // 'auto', 'manual'

  // Create table queries
  static const String createContactsTable = '''
    CREATE TABLE $contactsTable (
      $contactsId INTEGER PRIMARY KEY AUTOINCREMENT,
      $contactsName TEXT NOT NULL,
      $contactsCompany TEXT,
      $contactsTitle TEXT,
      $contactsPhone TEXT,
      $contactsEmail TEXT,
      $contactsWebsite TEXT,
      $contactsTags TEXT,
      $contactsNotes TEXT,
      $contactsCreatedAt INTEGER NOT NULL,
      $contactsUpdatedAt INTEGER,
      $contactsIsStarred INTEGER NOT NULL DEFAULT 0,
      $contactsCardImagePath TEXT,
      $contactsSocialMedia TEXT
    )
  ''';

  static const String createUserSettingsTable = '''
    CREATE TABLE $userSettingsTable (
      $settingsId INTEGER PRIMARY KEY AUTOINCREMENT,
      $settingsKey TEXT UNIQUE NOT NULL,
      $settingsValue TEXT NOT NULL,
      $settingsType TEXT NOT NULL,
      $settingsUpdatedAt INTEGER NOT NULL
    )
  ''';

  static const String createBackupHistoryTable = '''
    CREATE TABLE $backupHistoryTable (
      $backupId INTEGER PRIMARY KEY AUTOINCREMENT,
      $backupFileName TEXT NOT NULL,
      $backupFilePath TEXT NOT NULL,
      $backupContactCount INTEGER NOT NULL,
      $backupFileSize INTEGER NOT NULL,
      $backupCreatedAt INTEGER NOT NULL,
      $backupType TEXT NOT NULL
    )
  ''';

  // Indexes for better performance
  static const String createContactsNameIndex = '''
    CREATE INDEX idx_contacts_name ON $contactsTable($contactsName)
  ''';

  static const String createContactsCreatedAtIndex = '''
    CREATE INDEX idx_contacts_created_at ON $contactsTable($contactsCreatedAt)
  ''';

  static const String createContactsIsStarredIndex = '''
    CREATE INDEX idx_contacts_is_starred ON $contactsTable($contactsIsStarred)
  ''';

  static const String createUserSettingsKeyIndex = '''
    CREATE INDEX idx_user_settings_key ON $userSettingsTable($settingsKey)
  ''';

  // Default settings keys
  static const String settingThemeMode = 'theme_mode';
  static const String settingLanguage = 'language';
  static const String settingSortOrder = 'sort_order';
  static const String settingAutoBackup = 'auto_backup';
  static const String settingBackupFrequency = 'backup_frequency';
  static const String settingOcrUsageCount = 'ocr_usage_count';
  static const String settingOcrResetDate = 'ocr_reset_date';
  static const String settingPremiumStatus = 'premium_status';
  static const String settingFirstLaunch = 'first_launch';
  static const String settingTutorialCompleted = 'tutorial_completed';

  // Limits and constraints
  static const int maxContactsForFree = 100;
  static const int maxOcrUsagePerMonth = 10;
  static const int maxBackupHistory = 50;
  static const int maxTagsPerContact = 10;
  static const int maxContactNameLength = 100;
  static const int maxCompanyNameLength = 100;
  static const int maxNotesLength = 1000;

  // Backup settings
  static const String backupTypeAuto = 'auto';
  static const String backupTypeManual = 'manual';
  static const String backupFileExtension = '.json';
  static const String backupFolderName = 'business_card_backups';

  // Sort orders
  static const String sortByName = 'name';
  static const String sortByCompany = 'company';
  static const String sortByCreatedAt = 'created_at';
  static const String sortByUpdatedAt = 'updated_at';
  static const String sortByStarred = 'starred';

  // Setting value types
  static const String settingTypeString = 'string';
  static const String settingTypeInt = 'int';
  static const String settingTypeBool = 'bool';
  static const String settingTypeDouble = 'double';

  // Error messages
  static const String errorDatabaseConnection = 'Veritabanı bağlantısı kurulamadı';
  static const String errorContactNotFound = 'Kişi bulunamadı';
  static const String errorInvalidContactData = 'Geçersiz kişi verisi';
  static const String errorBackupFailed = 'Yedekleme başarısız';
  static const String errorRestoreFailed = 'Geri yükleme başarısız';
  static const String errorDuplicateContact = 'Bu kişi zaten mevcut';

  // Success messages
  static const String successContactAdded = 'Kişi başarıyla eklendi';
  static const String successContactUpdated = 'Kişi başarıyla güncellendi';
  static const String successContactDeleted = 'Kişi başarıyla silindi';
  static const String successBackupCreated = 'Yedekleme başarıyla oluşturuldu';
  static const String successDataRestored = 'Veriler başarıyla geri yüklendi';
}