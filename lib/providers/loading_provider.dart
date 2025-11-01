import 'package:flutter_riverpod/flutter_riverpod.dart';

final loadingStateProvider = StateProvider.autoDispose<bool>((ref) => false);

// Generation tracking state
class GenerationState {
  final bool isGeneratingAll;
  final String currentlyGenerating;
  final String currentStep;
  final double progress;
  final List<String> generationSteps;

  GenerationState({
    this.isGeneratingAll = false,
    this.currentlyGenerating = '',
    this.currentStep = '',
    this.progress = 0.0,
    this.generationSteps = const [],
  });

  GenerationState copyWith({
    bool? isGeneratingAll,
    String? currentlyGenerating,
    String? currentStep,
    double? progress,
    List<String>? generationSteps,
  }) {
    return GenerationState(
      isGeneratingAll: isGeneratingAll ?? this.isGeneratingAll,
      currentlyGenerating: currentlyGenerating ?? this.currentlyGenerating,
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
      generationSteps: generationSteps ?? this.generationSteps,
    );
  }
}

class GenerationNotifier extends StateNotifier<GenerationState> {
  GenerationNotifier() : super(GenerationState());

  void startGeneratingAll() {
    state = state.copyWith(
      isGeneratingAll: true,
      currentlyGenerating: 'Generating Content',
      progress: 0.0,
      generationSteps: [],
    );
  }

  void updateProgress({
    String? currentlyGenerating,
    String? currentStep,
    double? progress,
  }) {
    state = state.copyWith(
      currentlyGenerating: currentlyGenerating,
      currentStep: currentStep,
      progress: progress,
    );
  }

  void addGenerationStep(String step) {
    final newSteps = List<String>.from(state.generationSteps)..add(step);
    state = state.copyWith(generationSteps: newSteps);
  }

  void completeGeneration() {
    state = state.copyWith(
      isGeneratingAll: false,
      currentlyGenerating: '',
      currentStep: '',
      progress: 0.0,
    );
  }

  void clearSteps() {
    state = state.copyWith(generationSteps: []);
  }
}

final generationStateProvider =
    StateNotifierProvider<GenerationNotifier, GenerationState>((ref) {
  return GenerationNotifier();
});
