import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcome => 'Professional Academic Thesis';

  @override
  String get onboardDescription1 => 'Create professional academic thesis with AI assistance';

  @override
  String get smartContent => 'Smart Content Generation';

  @override
  String get onboardDescription2 => 'Generate well-structured chapters and content automatically';

  @override
  String get onboardDescription3 => 'Export your thesis in professional PDF format';

  @override
  String get easyExport => 'Easy Export In PDF';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get startWritingHere => 'Start writing here...';

  @override
  String get reportContent => 'Report Content';

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get saveChangesQuestion => 'Do you want to save your changes?';

  @override
  String get discard => 'Discard';

  @override
  String get save => 'Save';

  @override
  String get reportContentIssue => 'Please describe the issue with this content:';

  @override
  String get enterConcern => 'Enter your concern...';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get reportSubmitted => 'Report submitted successfully';

  @override
  String get changesSaved => 'Changes saved';

  @override
  String get initializationError => 'Initialization Error';

  @override
  String get retry => 'Retry';

  @override
  String get exportThesis => 'Export Thesis';

  @override
  String get exportAsPdf => 'Export as PDF';

  @override
  String get exportDescription => 'Your thesis will be exported as a PDF file and saved to your Downloads folder.';

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
  String get thesis => 'Thesis';

  @override
  String get generateAll => 'Generate All';

  @override
  String get pleaseCompleteAllSections => 'Please complete all sections before exporting';

  @override
  String get generatedSuccessfully => 'Generated successfully! Click On Pdf To export';

  @override
  String errorGeneratingContent(Object error) {
    return 'Error generating content: $error';
  }

  @override
  String failedToGenerateContent(Object error) {
    return 'Failed to generate content: $error';
  }

  @override
  String get loadingMessage1 => 'We are generating your thesis structure...';

  @override
  String get loadingMessage2 => 'This process takes about 4-7 minutes...';

  @override
  String get loadingMessage3 => 'Crafting your academic journey...';

  @override
  String get loadingMessage4 => 'Organizing your research framework...';

  @override
  String get loadingMessage5 => 'Building a solid foundation for your thesis...';

  @override
  String get loadingMessage6 => 'Almost there, finalizing your outline...';

  @override
  String get createThesis => 'Create Thesis';

  @override
  String get thesisTopic => 'Thesis Topic';

  @override
  String get enterThesisTopic => 'Enter your thesis topic';

  @override
  String get pleaseEnterTopic => 'Please enter a topic';

  @override
  String get generateChapters => 'Generate Chapters';

  @override
  String get generatedChapters => 'Generated Chapters';

  @override
  String chapter(Object number) {
    return 'Chapter $number';
  }

  @override
  String get pleaseEnterChapterTitle => 'Please enter chapter title';

  @override
  String get writingStyle => 'Writing Style';

  @override
  String get format => 'Format';

  @override
  String get generateThesis => 'Generate Thesis';

  @override
  String get pleaseEnterThesisTopicFirst => 'Please enter a thesis topic first';

  @override
  String failedToGenerateChapters(Object error) {
    return 'Failed to generate chapters: $error';
  }

  @override
  String errorGeneratingThesis(Object error) {
    return 'Error generating thesis: $error';
  }

  @override
  String get generatingContent => 'Generating content...';
}
