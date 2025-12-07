import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentService {
  Future<void> requestConsentInfo() async {
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        var status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          loadForm();
        }
      },
      (error) => print('Consent info request error: ${error.message}'),
    );
  }

  void loadForm() {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        consentForm.show(
          (FormError? formError) {
            if (formError != null) {
              loadForm();
            }
          },
        );
      },
      (error) => print('Error loading consent form: ${error.message}'),
    );
  }
}
