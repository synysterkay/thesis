// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome => 'Academic Writing Assistant';

  @override
  String get onboardDescription1 =>
      'Learn to develop professional academic thesis structure';

  @override
  String get smartContent => 'Smart Learning Framework';

  @override
  String get onboardDescription2 =>
      'Practice organizing chapters and content effectively';

  @override
  String get onboardDescription3 =>
      'Export your learning materials in professional PDF format';

  @override
  String get easyExport => 'Easy Export In PDF';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Start Learning';

  @override
  String get startWritingHere => 'Begin your practice here...';

  @override
  String get reportContent => 'Report Content';

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get saveChangesQuestion => 'Do you want to save your progress?';

  @override
  String get discard => 'Discard';

  @override
  String get save => 'Save';

  @override
  String get reportContentIssue =>
      'Please describe the issue with this content:';

  @override
  String get enterConcern => 'Enter your concern...';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get reportSubmitted => 'Report submitted successfully';

  @override
  String get changesSaved => 'Progress saved';

  @override
  String get initializationError => 'Initialization Error';

  @override
  String get retry => 'Retry';

  @override
  String get exportThesis => 'Export Document';

  @override
  String get exportAsPdf => 'Export as PDF';

  @override
  String get exportDescription =>
      'Your academic work will be exported as a PDF file and saved to your Downloads folder.';

  @override
  String pdfSavedToDownloads(String path) {
    return 'PDF saved to Downloads: $path';
  }

  @override
  String get ok => 'OK';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get thesis => 'Academic Structure';

  @override
  String get generateAll => 'Generate All';

  @override
  String get pleaseCompleteAllSections =>
      'Please complete all sections before exporting';

  @override
  String get generatedSuccessfully =>
      'Structure created successfully! Click On PDF to export';

  @override
  String errorGeneratingContent(Object error) {
    return 'Error creating content: $error';
  }

  @override
  String failedToGenerateContent(Object error) {
    return 'Failed to create content: $error';
  }

  @override
  String get loadingMessage1 => 'Preparing your academic structure...';

  @override
  String get loadingMessage2 => 'Organizing your learning materials...';

  @override
  String get loadingMessage3 => 'Building your academic framework...';

  @override
  String get loadingMessage4 => 'Structuring your research outline...';

  @override
  String get loadingMessage5 => 'Creating your learning foundation...';

  @override
  String get loadingMessage6 => 'Almost there, finalizing your structure...';

  @override
  String get createThesis => 'Create Structure';

  @override
  String get thesisTopic => 'Research Topic';

  @override
  String get enterThesisTopic => 'Enter your research topic';

  @override
  String get pleaseEnterTopic => 'Please enter a topic';

  @override
  String get generateChapters => 'Create Sections';

  @override
  String get generatedChapters => 'Created Sections';

  @override
  String chapter(Object number) {
    return 'Section $number';
  }

  @override
  String get pleaseEnterChapterTitle => 'Please enter section title';

  @override
  String get writingStyle => 'Academic Style';

  @override
  String get format => 'Format';

  @override
  String get generateThesis => 'Create Structure';

  @override
  String get pleaseEnterThesisTopicFirst =>
      'Please enter a research topic first';

  @override
  String failedToGenerateChapters(Object error) {
    return 'Failed to create sections: $error';
  }

  @override
  String errorGeneratingThesis(Object error) {
    return 'Error creating structure: $error';
  }

  @override
  String get generatingContent => 'Creating content...';

  @override
  String get pleaseCompleteAllChapters => 'Please complete all section titles';

  @override
  String get requiredChaptersMissing =>
      'Introduction and Conclusion sections are required';

  @override
  String get openFile => 'Open File';

  @override
  String get errorGeneratingOutlines => 'Error Creating Outline';

  @override
  String get edit => 'Edit';

  @override
  String get addText => 'Add Text';

  @override
  String get highlight => 'Highlight';

  @override
  String get delete => 'Delete';

  @override
  String get savePdf => 'Save PDF';

  @override
  String get share => 'Share';

  @override
  String get thesisOutline => 'Academic Outline';
}
