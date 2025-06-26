import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AdConsentDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Personalized Ad Experience',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'We show limited ads to keep this app free. You can choose to see personalized ads that are more relevant to you.',
            style: GoogleFonts.urbanist(),
          ),
          SizedBox(height: 16),
          Text(
            'You can change this choice anytime in app settings.',
            style: GoogleFonts.urbanist(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Non-personalized Ads'),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: Text('Allow Personalization'),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
