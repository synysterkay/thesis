// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get welcome => 'पेशेवर शैक्षणिक थीसिस';

  @override
  String get onboardDescription1 => 'AI सहायता से पेशेवर शैक्षणिक थीसिस बनाएं';

  @override
  String get smartContent => 'स्मार्ट सामग्री निर्माण';

  @override
  String get onboardDescription2 =>
      'स्वचालित रूप से सुव्यवस्थित अध्याय और सामग्री तैयार करें';

  @override
  String get onboardDescription3 =>
      'अपनी थीसिस को पेशेवर PDF प्रारूप में निर्यात करें';

  @override
  String get easyExport => 'PDF में आसान निर्यात';

  @override
  String get next => 'अगला';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get startWritingHere => 'यहाँ लिखना शुरू करें...';

  @override
  String get reportContent => 'सामग्री रिपोर्ट करें';

  @override
  String get unsavedChanges => 'असुरक्षित परिवर्तन';

  @override
  String get saveChangesQuestion =>
      'क्या आप अपने परिवर्तनों को सहेजना चाहते हैं?';

  @override
  String get discard => 'छोड़ें';

  @override
  String get save => 'सहेजें';

  @override
  String get reportContentIssue => 'कृपया इस सामग्री की समस्या का वर्णन करें:';

  @override
  String get enterConcern => 'अपनी चिंता दर्ज करें...';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get submit => 'जमा करें';

  @override
  String get reportSubmitted => 'रिपोर्ट सफलतापूर्वक जमा की गई';

  @override
  String get changesSaved => 'परिवर्तन सहेजे गए';

  @override
  String get initializationError => 'प्रारंभिक त्रुटि';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get exportThesis => 'थीसिस निर्यात करें';

  @override
  String get exportAsPdf => 'PDF के रूप में निर्यात करें';

  @override
  String get exportDescription =>
      'आपकी थीसिस PDF फ़ाइल के रूप में निर्यात की जाएगी और डाउनलोड फ़ोल्डर में सहेजी जाएगी।';

  @override
  String pdfSavedToDownloads(String path) {
    return 'PDF डाउनलोड में सहेजी गई: $path';
  }

  @override
  String get ok => 'ठीक है';

  @override
  String error(String message) {
    return 'त्रुटि: $message';
  }

  @override
  String get thesis => 'थीसिस';

  @override
  String get generateAll => 'सभी उत्पन्न करें';

  @override
  String get pleaseCompleteAllSections =>
      'निर्यात करने से पहले कृपया सभी खंड पूरे करें';

  @override
  String get generatedSuccessfully =>
      'सफलतापूर्वक उत्पन्न! निर्यात करने के लिए PDF पर क्लिक करें';

  @override
  String errorGeneratingContent(Object error) {
    return 'सामग्री उत्पन्न करने में त्रुटि: $error';
  }

  @override
  String failedToGenerateContent(Object error) {
    return 'सामग्री उत्पन्न करने में विफल: $error';
  }

  @override
  String get loadingMessage1 => 'हम आपकी थीसिस संरचना तैयार कर रहे हैं...';

  @override
  String get loadingMessage2 => 'इस प्रक्रिया में लगभग 4-7 मिनट लगते हैं...';

  @override
  String get loadingMessage3 => 'आपकी शैक्षणिक यात्रा को आकार दे रहे हैं...';

  @override
  String get loadingMessage4 => 'आपके शोध ढांचे को व्यवस्थित कर रहे हैं...';

  @override
  String get loadingMessage5 =>
      'आपकी थीसिस के लिए एक मजबूत आधार बना रहे हैं...';

  @override
  String get loadingMessage6 =>
      'बस थोड़ी देर और, आपकी रूपरेखा को अंतिम रूप दे रहे हैं...';

  @override
  String get createThesis => 'थीसिस बनाएं';

  @override
  String get thesisTopic => 'थीसिस विषय';

  @override
  String get enterThesisTopic => 'अपना थीसिस विषय दर्ज करें';

  @override
  String get pleaseEnterTopic => 'कृपया एक विषय दर्ज करें';

  @override
  String get generateChapters => 'अध्याय उत्पन्न करें';

  @override
  String get generatedChapters => 'उत्पन्न अध्याय';

  @override
  String chapter(Object number) {
    return 'अध्याय $number';
  }

  @override
  String get pleaseEnterChapterTitle => 'कृपया अध्याय का शीर्षक दर्ज करें';

  @override
  String get writingStyle => 'लेखन शैली';

  @override
  String get format => 'प्रारूप';

  @override
  String get generateThesis => 'थीसिस उत्पन्न करें';

  @override
  String get pleaseEnterThesisTopicFirst => 'कृपया पहले थीसिस विषय दर्ज करें';

  @override
  String failedToGenerateChapters(Object error) {
    return 'अध्याय उत्पन्न करने में विफल: $error';
  }

  @override
  String errorGeneratingThesis(Object error) {
    return 'थीसिस उत्पन्न करने में त्रुटि: $error';
  }

  @override
  String get generatingContent => 'सामग्री उत्पन्न हो रही है...';

  @override
  String get pleaseCompleteAllChapters =>
      'कृपया सभी अध्यायों के शीर्षक पूरे करें';

  @override
  String get requiredChaptersMissing => 'परिचय और निष्कर्ष अध्याय आवश्यक हैं';

  @override
  String get openFile => 'फ़ाइल खोलें';

  @override
  String get errorGeneratingOutlines => 'रूपरेखा उत्पन्न करने में त्रुटि';

  @override
  String get edit => 'संपादित करें';

  @override
  String get addText => 'टेक्स्ट जोड़ें';

  @override
  String get highlight => 'हाइलाइट करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get savePdf => 'PDF सहेजें';

  @override
  String get share => 'साझा करें';

  @override
  String get thesisOutline => 'थीसिस रूपरेखा';
}
