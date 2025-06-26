import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
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
/// import 'gen_l10n/app_localizations.dart';
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
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('zh')
  ];

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Academic Writing Assistant'**
  String get welcome;

  /// No description provided for @onboardDescription1.
  ///
  /// In en, this message translates to:
  /// **'Learn to develop professional academic thesis structure'**
  String get onboardDescription1;

  /// No description provided for @smartContent.
  ///
  /// In en, this message translates to:
  /// **'Smart Learning Framework'**
  String get smartContent;

  /// No description provided for @onboardDescription2.
  ///
  /// In en, this message translates to:
  /// **'Practice organizing chapters and content effectively'**
  String get onboardDescription2;

  /// No description provided for @onboardDescription3.
  ///
  /// In en, this message translates to:
  /// **'Export your learning materials in professional PDF format'**
  String get onboardDescription3;

  /// No description provided for @easyExport.
  ///
  /// In en, this message translates to:
  /// **'Easy Export In PDF'**
  String get easyExport;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get getStarted;

  /// No description provided for @startWritingHere.
  ///
  /// In en, this message translates to:
  /// **'Begin your practice here...'**
  String get startWritingHere;

  /// No description provided for @reportContent.
  ///
  /// In en, this message translates to:
  /// **'Report Content'**
  String get reportContent;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @saveChangesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to save your progress?'**
  String get saveChangesQuestion;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @reportContentIssue.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue with this content:'**
  String get reportContentIssue;

  /// No description provided for @enterConcern.
  ///
  /// In en, this message translates to:
  /// **'Enter your concern...'**
  String get enterConcern;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully'**
  String get reportSubmitted;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Progress saved'**
  String get changesSaved;

  /// No description provided for @initializationError.
  ///
  /// In en, this message translates to:
  /// **'Initialization Error'**
  String get initializationError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @exportThesis.
  ///
  /// In en, this message translates to:
  /// **'Export Document'**
  String get exportThesis;

  /// No description provided for @exportAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// No description provided for @exportDescription.
  ///
  /// In en, this message translates to:
  /// **'Your academic work will be exported as a PDF file and saved to your Downloads folder.'**
  String get exportDescription;

  /// No description provided for @pdfSavedToDownloads.
  ///
  /// In en, this message translates to:
  /// **'PDF saved to Downloads: {path}'**
  String pdfSavedToDownloads(String path);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// No description provided for @thesis.
  ///
  /// In en, this message translates to:
  /// **'Academic Structure'**
  String get thesis;

  /// No description provided for @generateAll.
  ///
  /// In en, this message translates to:
  /// **'Generate All'**
  String get generateAll;

  /// No description provided for @pleaseCompleteAllSections.
  ///
  /// In en, this message translates to:
  /// **'Please complete all sections before exporting'**
  String get pleaseCompleteAllSections;

  /// No description provided for @generatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Structure created successfully! Click On PDF to export'**
  String get generatedSuccessfully;

  /// No description provided for @errorGeneratingContent.
  ///
  /// In en, this message translates to:
  /// **'Error creating content: {error}'**
  String errorGeneratingContent(Object error);

  /// No description provided for @failedToGenerateContent.
  ///
  /// In en, this message translates to:
  /// **'Failed to create content: {error}'**
  String failedToGenerateContent(Object error);

  /// No description provided for @loadingMessage1.
  ///
  /// In en, this message translates to:
  /// **'Preparing your academic structure...'**
  String get loadingMessage1;

  /// No description provided for @loadingMessage2.
  ///
  /// In en, this message translates to:
  /// **'Organizing your learning materials...'**
  String get loadingMessage2;

  /// No description provided for @loadingMessage3.
  ///
  /// In en, this message translates to:
  /// **'Building your academic framework...'**
  String get loadingMessage3;

  /// No description provided for @loadingMessage4.
  ///
  /// In en, this message translates to:
  /// **'Structuring your research outline...'**
  String get loadingMessage4;

  /// No description provided for @loadingMessage5.
  ///
  /// In en, this message translates to:
  /// **'Creating your learning foundation...'**
  String get loadingMessage5;

  /// No description provided for @loadingMessage6.
  ///
  /// In en, this message translates to:
  /// **'Almost there, finalizing your structure...'**
  String get loadingMessage6;

  /// No description provided for @createThesis.
  ///
  /// In en, this message translates to:
  /// **'Create Structure'**
  String get createThesis;

  /// No description provided for @thesisTopic.
  ///
  /// In en, this message translates to:
  /// **'Research Topic'**
  String get thesisTopic;

  /// No description provided for @enterThesisTopic.
  ///
  /// In en, this message translates to:
  /// **'Enter your research topic'**
  String get enterThesisTopic;

  /// No description provided for @pleaseEnterTopic.
  ///
  /// In en, this message translates to:
  /// **'Please enter a topic'**
  String get pleaseEnterTopic;

  /// No description provided for @generateChapters.
  ///
  /// In en, this message translates to:
  /// **'Create Sections'**
  String get generateChapters;

  /// No description provided for @generatedChapters.
  ///
  /// In en, this message translates to:
  /// **'Created Sections'**
  String get generatedChapters;

  /// No description provided for @chapter.
  ///
  /// In en, this message translates to:
  /// **'Section {number}'**
  String chapter(Object number);

  /// No description provided for @pleaseEnterChapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter section title'**
  String get pleaseEnterChapterTitle;

  /// No description provided for @writingStyle.
  ///
  /// In en, this message translates to:
  /// **'Academic Style'**
  String get writingStyle;

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @generateThesis.
  ///
  /// In en, this message translates to:
  /// **'Create Structure'**
  String get generateThesis;

  /// No description provided for @pleaseEnterThesisTopicFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter a research topic first'**
  String get pleaseEnterThesisTopicFirst;

  /// No description provided for @failedToGenerateChapters.
  ///
  /// In en, this message translates to:
  /// **'Failed to create sections: {error}'**
  String failedToGenerateChapters(Object error);

  /// No description provided for @errorGeneratingThesis.
  ///
  /// In en, this message translates to:
  /// **'Error creating structure: {error}'**
  String errorGeneratingThesis(Object error);

  /// No description provided for @generatingContent.
  ///
  /// In en, this message translates to:
  /// **'Creating content...'**
  String get generatingContent;

  /// No description provided for @pleaseCompleteAllChapters.
  ///
  /// In en, this message translates to:
  /// **'Please complete all section titles'**
  String get pleaseCompleteAllChapters;

  /// No description provided for @requiredChaptersMissing.
  ///
  /// In en, this message translates to:
  /// **'Introduction and Conclusion sections are required'**
  String get requiredChaptersMissing;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open File'**
  String get openFile;

  /// No description provided for @errorGeneratingOutlines.
  ///
  /// In en, this message translates to:
  /// **'Error Creating Outline'**
  String get errorGeneratingOutlines;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @addText.
  ///
  /// In en, this message translates to:
  /// **'Add Text'**
  String get addText;

  /// No description provided for @highlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get highlight;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @savePdf.
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get savePdf;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @thesisOutline.
  ///
  /// In en, this message translates to:
  /// **'Academic Outline'**
  String get thesisOutline;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'fr', 'hi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'hi': return AppLocalizationsHi();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
