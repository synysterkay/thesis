import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../constants/eula_text.dart';

class SubscriptionTerms extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription Terms & Conditions',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildTermItem(
              'Thesis Generator Premium offers unlimited thesis generation, advanced writing styles, and priority support'),
          _buildTermItem(
              'Monthly subscription provides 30 days of premium access'),
          _buildTermItem(
              'Yearly subscription provides 365 days of premium access'),
          _buildTermItem(
              'Payment will be charged to your Apple ID account at confirmation of purchase'),
          _buildTermItem(
              'Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period'),
          _buildTermItem(
              'Account will be charged for renewal within 24 hours prior to the end of the current period'),
          _buildTermItem(
              'You can manage and cancel your subscriptions by going to your account settings on the App Store'),
          _buildTermItem(
              'Any unused portion of a free trial period will be forfeited when purchasing a subscription'),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLinkButton('Privacy Policy',
                  'https://sites.google.com/view/thesis-generator'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('•', style: TextStyle(color: Colors.white60)),
              ),
              _buildLinkButton('Terms of Use',
                  'https://www.apple.com/legal/internet-services/itunes/dev/stdeula'),
            ],
          ),
          SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () async {
                try {
                  await InAppPurchase.instance.restorePurchases();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Purchases restored successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to restore purchases')),
                  );
                }
              },
              child: Text(
                'Restore Purchases',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton(String text, String url) {
    return TextButton(
      onPressed: () => launchUrl(Uri.parse(url)),
      child: Text(text, style: TextStyle(color: Colors.blue)),
    );
  }
}
