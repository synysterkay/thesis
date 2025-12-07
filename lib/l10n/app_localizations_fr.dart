// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get welcome => 'Thèse Académique Professionnelle';

  @override
  String get onboardDescription1 => 'Créez des thèses académiques professionnelles avec l\'assistance de l\'IA';

  @override
  String get smartContent => 'Génération Intelligente de Contenu';

  @override
  String get onboardDescription2 => 'Générez automatiquement des chapitres et du contenu bien structurés';

  @override
  String get onboardDescription3 => 'Exportez votre thèse au format PDF professionnel';

  @override
  String get easyExport => 'Exportation Facile en PDF';

  @override
  String get next => 'Suivant';

  @override
  String get getStarted => 'Commencer';

  @override
  String get startWritingHere => 'Commencez à écrire ici...';

  @override
  String get reportContent => 'Signaler le Contenu';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get saveChangesQuestion => 'Voulez-vous enregistrer vos modifications ?';

  @override
  String get discard => 'Abandonner';

  @override
  String get save => 'Enregistrer';

  @override
  String get reportContentIssue => 'Veuillez décrire le problème avec ce contenu :';

  @override
  String get enterConcern => 'Entrez votre préoccupation...';

  @override
  String get cancel => 'Annuler';

  @override
  String get submit => 'Soumettre';

  @override
  String get reportSubmitted => 'Rapport soumis avec succès';

  @override
  String get changesSaved => 'Modifications enregistrées';

  @override
  String get initializationError => 'Erreur d\'initialisation';

  @override
  String get retry => 'Réessayer';

  @override
  String get exportThesis => 'Exporter la Thèse';

  @override
  String get exportAsPdf => 'Exporter en PDF';

  @override
  String get exportDescription => 'Votre thèse sera exportée au format PDF et enregistrée dans votre dossier Téléchargements.';

  @override
  String pdfSavedToDownloads(String path) {
    return 'PDF enregistré dans Téléchargements : $path';
  }

  @override
  String get ok => 'OK';

  @override
  String error(String message) {
    return 'Erreur : $message';
  }

  @override
  String get thesis => 'Thèse';

  @override
  String get generateAll => 'Tout Générer';

  @override
  String get pleaseCompleteAllSections => 'Veuillez compléter toutes les sections avant d\'exporter';

  @override
  String get generatedSuccessfully => 'Génération réussie ! Cliquez sur PDF pour exporter';

  @override
  String errorGeneratingContent(Object error) {
    return 'Erreur lors de la génération du contenu : $error';
  }

  @override
  String failedToGenerateContent(Object error) {
    return 'Échec de la génération du contenu : $error';
  }

  @override
  String get loadingMessage1 => 'Nous générons la structure de votre thèse...';

  @override
  String get loadingMessage2 => 'Ce processus prend environ 4-7 minutes...';

  @override
  String get loadingMessage3 => 'Création de votre parcours académique...';

  @override
  String get loadingMessage4 => 'Organisation de votre cadre de recherche...';

  @override
  String get loadingMessage5 => 'Construction d\'une base solide pour votre thèse...';

  @override
  String get loadingMessage6 => 'Presque terminé, finalisation de votre plan...';

  @override
  String get createThesis => 'Créer une Thèse';

  @override
  String get thesisTopic => 'Sujet de Thèse';

  @override
  String get enterThesisTopic => 'Entrez votre sujet de thèse';

  @override
  String get pleaseEnterTopic => 'Veuillez entrer un sujet';

  @override
  String get generateChapters => 'Générer les Chapitres';

  @override
  String get generatedChapters => 'Chapitres Générés';

  @override
  String chapter(Object number) {
    return 'Chapitre $number';
  }

  @override
  String get pleaseEnterChapterTitle => 'Veuillez entrer le titre du chapitre';

  @override
  String get writingStyle => 'Style d\'Écriture';

  @override
  String get format => 'Format';

  @override
  String get generateThesis => 'Générer la Thèse';

  @override
  String get pleaseEnterThesisTopicFirst => 'Veuillez d\'abord entrer un sujet de thèse';

  @override
  String failedToGenerateChapters(Object error) {
    return 'Échec de la génération des chapitres : $error';
  }

  @override
  String errorGeneratingThesis(Object error) {
    return 'Erreur lors de la génération de la thèse : $error';
  }

  @override
  String get generatingContent => 'Génération du contenu...';

  @override
  String get pleaseCompleteAllChapters => 'Veuillez compléter tous les titres des chapitres';

  @override
  String get requiredChaptersMissing => 'Les chapitres Introduction et Conclusion sont requis';

  @override
  String get openFile => 'Ouvrir le Fichier';

  @override
  String get errorGeneratingOutlines => 'Erreur lors de la Génération des Plans';

  @override
  String get edit => 'Modifier';

  @override
  String get addText => 'Ajouter du Texte';

  @override
  String get highlight => 'Surligner';

  @override
  String get delete => 'Supprimer';

  @override
  String get savePdf => 'Enregistrer le PDF';

  @override
  String get share => 'Partager';

  @override
  String get thesisOutline => 'Plan de Thèse';
}
