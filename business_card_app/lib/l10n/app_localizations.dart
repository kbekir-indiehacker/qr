import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Business Card App'**
  String get appTitle;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Business card label
  ///
  /// In en, this message translates to:
  /// **'Business Card'**
  String get businessCard;

  /// Create new business card button
  ///
  /// In en, this message translates to:
  /// **'Create Card'**
  String get createCard;

  /// Scan business card button
  ///
  /// In en, this message translates to:
  /// **'Scan Card'**
  String get scanCard;

  /// My cards page title
  ///
  /// In en, this message translates to:
  /// **'My Cards'**
  String get myCards;

  /// Contacts page title
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Company field label
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// Position field label
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Website field label
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// Address field label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Share button
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// QR Code label
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// Generate QR code button
  ///
  /// In en, this message translates to:
  /// **'Generate QR'**
  String get generateQR;

  /// Scan QR code button
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQR;

  /// NFC share feature
  ///
  /// In en, this message translates to:
  /// **'NFC Share'**
  String get nfcShare;

  /// Dark mode setting
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Profile page title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// About page title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Contact view setting
  ///
  /// In en, this message translates to:
  /// **'Contact View'**
  String get contactView;

  /// Default sorting setting
  ///
  /// In en, this message translates to:
  /// **'Default Sorting'**
  String get defaultSorting;

  /// App settings section
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// Data management section
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// Create backup button
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// Backup all data subtitle
  ///
  /// In en, this message translates to:
  /// **'Backup all your data'**
  String get backupAllData;

  /// Restore from backup button
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreFromBackup;

  /// Restore previous backup subtitle
  ///
  /// In en, this message translates to:
  /// **'Restore from previous backup'**
  String get restorePrevious;

  /// Export data button
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// Export JSON/CSV subtitle
  ///
  /// In en, this message translates to:
  /// **'Export in JSON/CSV format'**
  String get exportJsonCsv;

  /// Import data button
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// Import from file subtitle
  ///
  /// In en, this message translates to:
  /// **'Import data from file'**
  String get importFromFile;

  /// Delete all data button
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllData;

  /// Irreversible action warning
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone'**
  String get irreversibleAction;

  /// Default user name
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Premium member status
  ///
  /// In en, this message translates to:
  /// **'Premium Member'**
  String get premiumMember;

  /// Free version status
  ///
  /// In en, this message translates to:
  /// **'Free Version'**
  String get freeVersion;

  /// Premium features message
  ///
  /// In en, this message translates to:
  /// **'You have access to all features'**
  String get allFeaturesAccess;

  /// Upgrade to premium message
  ///
  /// In en, this message translates to:
  /// **'Upgrade to premium and use all features'**
  String get upgradeToPremium;

  /// Upgrade button
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// Premium features title
  ///
  /// In en, this message translates to:
  /// **'Premium Features:'**
  String get premiumFeatures;

  /// Unlimited contacts feature
  ///
  /// In en, this message translates to:
  /// **'Unlimited contact addition'**
  String get unlimitedContacts;

  /// Unlimited QR codes feature
  ///
  /// In en, this message translates to:
  /// **'Unlimited QR code generation'**
  String get unlimitedQrCodes;

  /// Unlimited OCR feature
  ///
  /// In en, this message translates to:
  /// **'Unlimited OCR scanning'**
  String get unlimitedOcr;

  /// Automatic backup feature
  ///
  /// In en, this message translates to:
  /// **'Automatic backup'**
  String get automaticBackup;

  /// Select theme dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Select view dialog title
  ///
  /// In en, this message translates to:
  /// **'Select View'**
  String get selectView;

  /// List view option
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// Grid view option
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// Select sorting dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Sorting'**
  String get selectSorting;

  /// Date sorting option
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Delete all data dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get deleteAllDataTitle;

  /// Delete all data confirmation message
  ///
  /// In en, this message translates to:
  /// **'This action will delete all your contacts and settings. This action cannot be undone. Are you sure you want to continue?'**
  String get deleteAllDataMessage;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// Privacy policy label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Terms of service label
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Help and support label
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// Rate app label
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get rateApp;

  /// Try again button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Error label
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Creating backup message
  ///
  /// In en, this message translates to:
  /// **'Creating backup...'**
  String get creatingBackup;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
