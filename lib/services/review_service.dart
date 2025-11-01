import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

class ReviewService {
  final InAppReview inAppReview = InAppReview.instance;

  Future<void> requestReview() async {
    final prefs = await SharedPreferences.getInstance();
    int launchCount = prefs.getInt('launch_count') ?? 0;
    bool hasReviewed = prefs.getBool('has_reviewed') ?? false;

    // We can still limit how often we show the review prompt
    if (launchCount >= 3 && !hasReviewed) {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        await prefs.setBool('has_reviewed', true);
      }
    }

    await prefs.setInt('launch_count', launchCount + 1);
  }

  Future<void> openStoreListing() async {
    if (await inAppReview.isAvailable()) {
      if (Platform.isIOS) {
        await inAppReview.openStoreListing(
          appStoreId: '6739264844',
        );
      } else {
        await inAppReview
            .openStoreListing(); // Android uses package name automatically
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_reviewed', true);
    }
  }
}
