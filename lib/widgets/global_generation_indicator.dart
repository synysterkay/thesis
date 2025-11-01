import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/loading_provider.dart';

class GlobalGenerationIndicator extends ConsumerWidget {
  final bool showFullStatus;
  final bool isCompact;

  const GlobalGenerationIndicator({
    super.key,
    this.showFullStatus = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generationState = ref.watch(generationStateProvider);

    if (!generationState.isGeneratingAll) {
      return const SizedBox.shrink();
    }

    const primaryColor = Color(0xFF2563EB);
    const backgroundColor = Color(0xFFFFFFFF);
    const borderColor = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF1A1A1A);

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: generationState.progress <= 0
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(primaryColor),
                    )
                  : CircularProgressIndicator(
                      value: generationState.progress / 100,
                      strokeWidth: 2,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
            ),
            const SizedBox(width: 8),
            Text(
              generationState.progress <= 0
                  ? 'Starting...'
                  : '${generationState.progress.toStringAsFixed(0)}%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Show loading indicator when progress is 0
              generationState.progress <= 0
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : CircularProgressIndicator(
                      value: generationState.progress / 100,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(primaryColor),
                      strokeWidth: 2,
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      generationState.currentlyGenerating,
                      style: GoogleFonts.inter(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (generationState.currentStep.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        generationState.currentStep,
                        style: GoogleFonts.inter(
                          color: textPrimary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      generationState.progress <= 0
                          ? 'Starting...'
                          : '${generationState.progress.toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showFullStatus && generationState.currentStep.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    generationState.currentStep,
                    style: GoogleFonts.inter(
                      color: textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (showFullStatus && generationState.generationSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: generationState.generationSteps
                      .map((step) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    step,
                                    style: GoogleFonts.inter(
                                      color: textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideY();
  }
}
