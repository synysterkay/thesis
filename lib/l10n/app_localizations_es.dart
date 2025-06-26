import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get welcome => 'Bienvenido a Thesis Generator';

  @override
  String get onboardDescription1 => 'Crea tesis académicas profesionales con asistencia de IA';

  @override
  String get smartContent => 'Generación Inteligente de Contenido';

  @override
  String get onboardDescription2 => 'Genera capítulos y contenido bien estructurados automáticamente';

  @override
  String get onboardDescription3 => 'Exporta tu tesis en formato PDF profesional';

  @override
  String get easyExport => 'Exportación Fácil';

  @override
  String get next => 'Siguiente';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get startWritingHere => 'Empieza a escribir aquí...';

  @override
  String get reportContent => 'Reportar Contenido';

  @override
  String get unsavedChanges => 'Cambios sin guardar';

  @override
  String get saveChangesQuestion => '¿Deseas guardar tus cambios?';

  @override
  String get discard => 'Descartar';

  @override
  String get save => 'Guardar';

  @override
  String get reportContentIssue => 'Por favor describe el problema con este contenido:';

  @override
  String get enterConcern => 'Ingresa tu preocupación...';

  @override
  String get cancel => 'Cancelar';

  @override
  String get submit => 'Enviar';

  @override
  String get reportSubmitted => 'Reporte enviado exitosamente';

  @override
  String get changesSaved => 'Cambios guardados';

  @override
  String get initializationError => 'Error de inicialización';

  @override
  String get retry => 'Reintentar';

  @override
  String get exportThesis => 'Exportar Tesis';

  @override
  String get exportAsPdf => 'Exportar como PDF';

  @override
  String get exportDescription => 'Tu tesis será exportada como archivo PDF y guardada en tu carpeta de Descargas.';

  @override
  String pdfSavedToDownloads(String path) {
    return 'PDF guardado en Descargas: $path';
  }

  @override
  String get ok => 'OK';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String get thesis => 'Tesis';

  @override
  String get generateAll => 'Generar Todo';

  @override
  String get pleaseCompleteAllSections => 'Por favor completa todas las secciones antes de exportar';

  @override
  String get generatedSuccessfully => '¡Generado exitosamente! Haz clic en PDF para exportar';

  @override
  String errorGeneratingContent(Object error) {
    return 'Error generando contenido: $error';
  }

  @override
  String failedToGenerateContent(Object error) {
    return 'Error al generar contenido: $error';
  }

  @override
  String get loadingMessage1 => 'Estamos generando la estructura de tu tesis...';

  @override
  String get loadingMessage2 => 'Este proceso toma entre 4-7 minutos...';

  @override
  String get loadingMessage3 => 'Creando tu viaje académico...';

  @override
  String get loadingMessage4 => 'Organizando tu marco de investigación...';

  @override
  String get loadingMessage5 => 'Construyendo una base sólida para tu tesis...';

  @override
  String get loadingMessage6 => 'Casi listo, finalizando tu esquema...';

  @override
  String get createThesis => 'Crear Tesis';

  @override
  String get thesisTopic => 'Tema de Tesis';

  @override
  String get enterThesisTopic => 'Ingresa el tema de tu tesis';

  @override
  String get pleaseEnterTopic => 'Por favor ingresa un tema';

  @override
  String get generateChapters => 'Generar Capítulos';

  @override
  String get generatedChapters => 'Capítulos Generados';

  @override
  String chapter(Object number) {
    return 'Capítulo $number';
  }

  @override
  String get pleaseEnterChapterTitle => 'Por favor ingresa el título del capítulo';

  @override
  String get writingStyle => 'Estilo de Escritura';

  @override
  String get format => 'Formato';

  @override
  String get generateThesis => 'Generar Tesis';

  @override
  String get pleaseEnterThesisTopicFirst => 'Por favor ingresa primero el tema de la tesis';

  @override
  String failedToGenerateChapters(Object error) {
    return 'Error al generar capítulos: $error';
  }

  @override
  String errorGeneratingThesis(Object error) {
    return 'Error al generar tesis: $error';
  }

  @override
  String get generatingContent => 'Generando contenido...';
}
