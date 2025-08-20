import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_card_app/presentation/screens/main_screen.dart';
import 'package:business_card_app/presentation/providers/data_providers.dart';
import 'package:business_card_app/data/repositories/settings_repository.dart';
import 'package:business_card_app/data/repositories/user_repository.dart';
import 'package:business_card_app/l10n/app_localizations.dart';

/// Settings screen with app preferences and user options
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final userDataState = ref.watch(userDataProvider);
    final premiumStatus = ref.watch(premiumStatusProvider);
    
    // Debug: Check if AppLocalizations is working
    final localizations = AppLocalizations.of(context);
    print('🌐 AppLocalizations: ${localizations?.settings} (locale: ${localizations?.localeName})');

    return MainScreenWrapper(
      title: localizations?.settings ?? 'Ayarlar',
      child: settingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Hata: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(settingsProvider);
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
        data: (settings) => ListView(
          children: [
            // User info section
            userDataState.when(
              loading: () => const _LoadingSection(),
              error: (_, __) => const SizedBox.shrink(),
              data: (userData) => _UserSection(userData: userData, ref: ref),
            ),

            const SizedBox(height: 16),

            // Premium section
            premiumStatus.when(
              loading: () => const _LoadingSection(),
              error: (_, __) => const SizedBox.shrink(),
              data: (isPremium) => _PremiumSection(isPremium: isPremium),
            ),

            const SizedBox(height: 16),

            // App settings
            _AppSettingsSection(settings: settings, ref: ref),

            const SizedBox(height: 16),

            // Data management
            _DataManagementSection(ref: ref),

            const SizedBox(height: 16),

            // About section
            const _AboutSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _UserSection extends StatelessWidget {
  final UserData userData;
  final WidgetRef ref;

  const _UserSection({required this.userData, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar and basic info
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    userData.name.isNotEmpty ? userData.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData.name.isEmpty ? (AppLocalizations.of(context)?.user ?? 'Kullanıcı') : userData.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (userData.email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          userData.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Navigate to profile edit
                  },
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumSection extends StatelessWidget {
  final bool isPremium;

  const _PremiumSection({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: isPremium ? Colors.amber[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.upgrade,
                  color: isPremium ? Colors.amber : Colors.blue,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPremium ? (AppLocalizations.of(context)?.premiumMember ?? 'Premium Üye') : (AppLocalizations.of(context)?.freeVersion ?? 'Ücretsiz Sürüm'),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPremium ? Colors.amber[800] : Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPremium
                            ? (AppLocalizations.of(context)?.allFeaturesAccess ?? 'Tüm özelliklere erişiminiz var')
                            : (AppLocalizations.of(context)?.upgradeToPremium ?? 'Premium\'a yükseltin ve tüm özellikleri kullanın'),
                        style: TextStyle(
                          color: isPremium ? Colors.amber[700] : Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPremium)
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to premium upgrade
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(AppLocalizations.of(context)?.upgrade ?? 'Yükselt'),
                  ),
              ],
            ),
            if (!isPremium) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)?.premiumFeatures ?? 'Premium Özellikleri:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _FeatureItem(
                icon: Icons.contacts,
                text: AppLocalizations.of(context)?.unlimitedContacts ?? 'Sınırsız kişi ekleme',
              ),
              _FeatureItem(
                icon: Icons.qr_code,
                text: AppLocalizations.of(context)?.unlimitedQrCodes ?? 'Sınırsız QR kod oluşturma',
              ),
              _FeatureItem(
                icon: Icons.document_scanner,
                text: AppLocalizations.of(context)?.unlimitedOcr ?? 'Sınırsız OCR tarama',
              ),
              _FeatureItem(
                icon: Icons.backup,
                text: AppLocalizations.of(context)?.automaticBackup ?? 'Otomatik yedekleme',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppSettingsSection extends StatelessWidget {
  final AppSettings settings;
  final WidgetRef ref;

  const _AppSettingsSection({required this.settings, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)?.appSettings ?? 'Uygulama Ayarları',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Theme setting
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text(AppLocalizations.of(context)?.theme ?? 'Tema'),
            subtitle: Text(_getThemeLabel(settings.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
          // Language setting
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppLocalizations.of(context)?.language ?? 'Dil'),
            subtitle: Text(_getLanguageLabel(settings.language)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context),
          ),
          // Contact view mode
          ListTile(
            leading: const Icon(Icons.view_list),
            title: Text(AppLocalizations.of(context)?.contactView ?? 'Kişi Görünümü'),
            subtitle: Text(_getViewModeLabel(settings.contactViewMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showViewModeDialog(context),
          ),
          // Sort order
          ListTile(
            leading: const Icon(Icons.sort),
            title: Text(AppLocalizations.of(context)?.defaultSorting ?? 'Varsayılan Sıralama'),
            subtitle: Text(_getSortLabel(settings.sortOrder)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSortDialog(context),
          ),
        ],
      ),
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Açık';
      case 'dark':
        return 'Koyu';
      case 'system':
        return 'Sistem';
      default:
        return 'Sistem';
    }
  }

  String _getLanguageLabel(String language) {
    switch (language) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      default:
        return 'Türkçe';
    }
  }

  String _getViewModeLabel(String viewMode) {
    switch (viewMode) {
      case 'grid':
        return 'Izgara';
      case 'list':
        return 'Liste';
      default:
        return 'Liste';
    }
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'name':
        return 'İsim';
      case 'company':
        return 'Şirket';
      case 'date':
        return 'Tarih';
      default:
        return 'İsim';
    }
  }

  void _showThemeDialog(BuildContext context) {
    final currentTheme = ref.read(settingsProvider).value?.themeMode ?? 'system';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.selectTheme ?? 'Tema Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppLocalizations.of(context)?.light ?? 'Açık'),
              leading: Radio<String>(
                value: 'light',
                groupValue: currentTheme,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateThemeMode(value);
                  }
                },
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)?.dark ?? 'Koyu'),
              leading: Radio<String>(
                value: 'dark',
                groupValue: currentTheme,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateThemeMode(value);
                  }
                },
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)?.system ?? 'Sistem'),
              leading: Radio<String>(
                value: 'system',
                groupValue: currentTheme,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateThemeMode(value);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'İptal'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLanguage = ref.read(settingsProvider).value?.language ?? 'tr';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.language ?? 'Dil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Türkçe'),
              leading: Radio<String>(
                value: 'tr',
                groupValue: currentLanguage,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateLanguage(value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: currentLanguage,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateLanguage(value);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'İptal'),
          ),
        ],
      ),
    );
  }

  void _showViewModeDialog(BuildContext context) {
    final currentViewMode = ref.read(settingsProvider).value?.contactViewMode ?? 'list';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görünüm Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Liste'),
              leading: Radio<String>(
                value: 'list',
                groupValue: currentViewMode,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateContactViewMode(value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Izgara'),
              leading: Radio<String>(
                value: 'grid',
                groupValue: currentViewMode,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateContactViewMode(value);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'İptal'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    final currentSortOrder = ref.read(settingsProvider).value?.sortOrder ?? 'name';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sıralama Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('İsim'),
              leading: Radio<String>(
                value: 'name',
                groupValue: currentSortOrder,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateSortOrder(value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Şirket'),
              leading: Radio<String>(
                value: 'company',
                groupValue: currentSortOrder,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateSortOrder(value);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Tarih'),
              leading: Radio<String>(
                value: 'date',
                groupValue: currentSortOrder,
                onChanged: (value) {
                  Navigator.of(context).pop();
                  if (value != null) {
                    ref.read(settingsProvider.notifier).updateSortOrder(value);
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'İptal'),
          ),
        ],
      ),
    );
  }
}

class _DataManagementSection extends StatelessWidget {
  final WidgetRef ref;

  const _DataManagementSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)?.dataManagement ?? 'Veri Yönetimi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(AppLocalizations.of(context)?.createBackup ?? 'Yedek Oluştur'),
            subtitle: Text(AppLocalizations.of(context)?.backupAllData ?? 'Tüm verilerinizi yedeğe alın'),
            onTap: () => _createBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(AppLocalizations.of(context)?.restoreFromBackup ?? 'Yedekten Geri Yükle'),
            subtitle: Text(AppLocalizations.of(context)?.restorePrevious ?? 'Önceki yedekten geri yükleyin'),
            onTap: () => _restoreBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(AppLocalizations.of(context)?.exportData ?? 'Verileri Dışa Aktar'),
            subtitle: Text(AppLocalizations.of(context)?.exportJsonCsv ?? 'JSON/CSV formatında dışa aktarın'),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: Text(AppLocalizations.of(context)?.importData ?? 'Veri İçe Aktar'),
            subtitle: Text(AppLocalizations.of(context)?.importFromFile ?? 'Dosyadan veri içe aktarın'),
            onTap: () => _importData(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(AppLocalizations.of(context)?.deleteAllData ?? 'Tüm Verileri Sil', style: const TextStyle(color: Colors.red)),
            subtitle: Text(AppLocalizations.of(context)?.irreversibleAction ?? 'Bu işlem geri alınamaz'),
            onTap: () => _showDeleteAllDialog(context),
          ),
        ],
      ),
    );
  }

  void _createBackup(BuildContext context) {
    // Backup creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yedek oluşturuluyor...')),
    );
  }

  void _restoreBackup(BuildContext context) {
    // Backup restoration
  }

  void _exportData(BuildContext context) {
    // Data export
  }

  void _importData(BuildContext context) {
    // Data import
  }

  void _showDeleteAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Verileri Sil'),
        content: const Text(
          'Bu işlem tüm kişilerinizi ve ayarlarınızı silecek. Bu işlem geri alınamaz. Devam etmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Delete all data
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Hakkında',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Uygulama Sürümü'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Gizlilik Politikası'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // Open privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Kullanım Koşulları'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // Open terms of service
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Yardım & Destek'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // Open help center
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_rate),
            title: const Text('Uygulamayı Değerlendir'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // Open app store rating
            },
          ),
        ],
      ),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }
}

