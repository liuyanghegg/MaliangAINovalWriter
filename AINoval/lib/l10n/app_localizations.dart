import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Novel Assistant'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'My Novels'**
  String get homeTitle;

  /// No description provided for @createNovel.
  ///
  /// In en, this message translates to:
  /// **'Create New Novel'**
  String get createNovel;

  /// No description provided for @importNovel.
  ///
  /// In en, this message translates to:
  /// **'Import Novel'**
  String get importNovel;

  /// No description provided for @editNovel.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editNovel;

  /// No description provided for @deleteNovel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteNovel;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \'{title}\'? This action cannot be undone.'**
  String deleteConfirmation(Object title);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @novelTitle.
  ///
  /// In en, this message translates to:
  /// **'Novel Title'**
  String get novelTitle;

  /// No description provided for @novelTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Enter novel title'**
  String get novelTitleHint;

  /// No description provided for @seriesName.
  ///
  /// In en, this message translates to:
  /// **'Series Name (Optional)'**
  String get seriesName;

  /// No description provided for @seriesNameHint.
  ///
  /// In en, this message translates to:
  /// **'If part of a series, enter series name'**
  String get seriesNameHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @lastEdited.
  ///
  /// In en, this message translates to:
  /// **'Last edited: {date}'**
  String lastEdited(Object date);

  /// No description provided for @wordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String wordCount(Object count);

  /// No description provided for @completionPercentage.
  ///
  /// In en, this message translates to:
  /// **'Completion: {percentage}%'**
  String completionPercentage(Object percentage);

  /// No description provided for @noNovels.
  ///
  /// In en, this message translates to:
  /// **'No novels yet. Click the button in the bottom right to create one.'**
  String get noNovels;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loadingError.
  ///
  /// In en, this message translates to:
  /// **'Loading failed: {message}'**
  String loadingError(Object message);

  /// No description provided for @unknownState.
  ///
  /// In en, this message translates to:
  /// **'Unknown state'**
  String get unknownState;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @editorSettings.
  ///
  /// In en, this message translates to:
  /// **'Editor Settings'**
  String get editorSettings;

  /// No description provided for @startWriting.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get startWriting;

  /// No description provided for @wordCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Word Count'**
  String get wordCountTitle;

  /// No description provided for @charactersWithSpaces.
  ///
  /// In en, this message translates to:
  /// **'Characters (with spaces)'**
  String get charactersWithSpaces;

  /// No description provided for @charactersNoSpaces.
  ///
  /// In en, this message translates to:
  /// **'Characters (no spaces)'**
  String get charactersNoSpaces;

  /// No description provided for @paragraphs.
  ///
  /// In en, this message translates to:
  /// **'Paragraphs'**
  String get paragraphs;

  /// No description provided for @readTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated reading time'**
  String get readTime;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
