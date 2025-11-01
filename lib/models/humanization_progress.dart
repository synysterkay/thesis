class HumanizationProgress {
  final double percentage;
  final String currentStep;
  final List<String> processedChunks;
  final List<String> remainingChunks;
  final String? errorMessage;

  HumanizationProgress({
    required this.percentage,
    required this.currentStep,
    this.processedChunks = const [],
    this.remainingChunks = const [],
    this.errorMessage,
  });

  HumanizationProgress copyWith({
    double? percentage,
    String? currentStep,
    List<String>? processedChunks,
    List<String>? remainingChunks,
    String? errorMessage,
  }) {
    return HumanizationProgress(
      percentage: percentage ?? this.percentage,
      currentStep: currentStep ?? this.currentStep,
      processedChunks: processedChunks ?? this.processedChunks,
      remainingChunks: remainingChunks ?? this.remainingChunks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isComplete => percentage >= 1.0;
  bool get hasError => errorMessage != null;

  @override
  String toString() {
    return 'HumanizationProgress(percentage: $percentage, currentStep: $currentStep, processedChunks: ${processedChunks.length}, remainingChunks: ${remainingChunks.length})';
  }
}
