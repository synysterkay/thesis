import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/store_products.dart';

class IOSSubscriptionDialog extends StatefulWidget {
  final Function(String) onSubscribe;
  final List<ProductDetails> products;

  const IOSSubscriptionDialog({
    Key? key,
    required this.onSubscribe,
    required this.products,
  }) : super(key: key);

  @override
  _IOSSubscriptionDialogState createState() => _IOSSubscriptionDialogState();
}

class _IOSSubscriptionDialogState extends State<IOSSubscriptionDialog> {
  int _currentImageIndex = 0;
  String _selectedSubscriptionType = 'monthly';

  final List<String> _benefitImages = [
    'assets/onboard1.jpg',
    'assets/onboard2.jpg',
    'assets/onboard3.jpg',
  ];

  final List<String> _benefitTexts = [
    'Unlimited Thesis Generation',
    'Advanced Writing Styles',
    'Priority Support',
  ];

  final List<String> _benefitDescriptions = [
    'Generate as many thesis statements as you need',
    'Access to multiple writing styles and formats',
    '24/7 premium customer support',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  SizedBox(height: 40),
                  // Title of publication or service
                  Text(
                    'Thesis Generator Premium',
                    style: GoogleFonts.urbanist(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Unlock unlimited thesis generation and advanced features',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),

                  // Carousel of benefits
                  _buildCarousel(),
                  SizedBox(height: 32),

                  // Subscription options - most important section
                  Text(
                    'Choose Your Plan',
                    style: GoogleFonts.urbanist(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  _buildSubscriptionOptions(),
                  SizedBox(height: 24),

                  // Subscribe button
                  _buildSubscribeButton(),
                  SizedBox(height: 32),

                  // Features section
                  _buildPremiumFeatures(),
                  SizedBox(height: 32),

                  // Legal information in an expandable section
                  _buildLegalInformation(),
                  SizedBox(height: 16),

                  // Restore purchases button
                  _buildRestorePurchases(),
                  SizedBox(height: 24),
                ],
              ),
            ),
            _buildCloseButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.25,
      child: FlutterCarousel(
        options: CarouselOptions(
          height: double.infinity,
          autoPlay: true,
          enlargeCenterPage: true,
          onPageChanged: (index, reason) {
            setState(() => _currentImageIndex = index);
          },
          showIndicator: false, // Add this line to hide the indicators
        ),
        items: List.generate(3, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                _benefitImages[index],
                height: 120,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 16),
              Text(
                _benefitTexts[index],
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _benefitDescriptions[index],
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }


  Widget _buildPremiumFeatures() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFFF48B0).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ Premium Features',
            style: GoogleFonts.urbanist(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          ..._benefitTexts.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFFFF48B0), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value,
                          style: GoogleFonts.urbanist(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _benefitDescriptions[entry.key],
                          style: GoogleFonts.urbanist(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLegalInformation() {
    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text(
        'Subscription Terms & Legal Information',
        style: GoogleFonts.urbanist(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
      iconColor: Color(0xFFFF48B0),
      collapsedIconColor: Colors.white70,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTermItem('Thesis Generator Premium offers unlimited thesis generation, advanced writing styles, and priority support'),
              _buildTermItem('Monthly subscription provides 30 days of premium access for ${_getMonthlyPrice()}'),
              _buildTermItem('Yearly subscription provides 365 days of premium access for ${_getYearlyPrice()}'),
              _buildTermItem('Payment will be charged to your Apple ID account at confirmation of purchase'),
              _buildTermItem('Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period'),
              _buildTermItem('Account will be charged for renewal within 24 hours prior to the end of the current period'),
              _buildTermItem('You can manage and cancel your subscriptions by going to your account settings on the App Store'),
              _buildTermItem('Any unused portion of a free trial period will be forfeited when purchasing a subscription'),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLinkButton('Privacy Policy', 'https://sites.google.com/view/thesis-generator'),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('•', style: TextStyle(color: Colors.white60)),
                  ),
                  _buildLinkButton('Terms of Use', 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Color(0xFFFF48B0), fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.urbanist(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
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
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size(0, 0),
      ),
      child: Text(
        text,
        style: GoogleFonts.urbanist(
          color: Color(0xFFFF48B0),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildRestorePurchases() {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          try {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF48B0),
                ),
              ),
            );
            await InAppPurchase.instance.restorePurchases();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Purchases restored successfully')),
            );
          } catch (e) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to restore purchases')),
            );
          }
        },
        icon: Icon(Icons.restore, color: Color(0xFFFF48B0), size: 18),
        label: Text(
          'Restore Purchases',
          style: GoogleFonts.urbanist(
            color: Color(0xFFFF48B0),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 16,
      left: 16,
      child: IconButton(
        icon: Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSubscriptionOptions() {
    if (widget.products.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Text(
          'Loading subscription options...',
          style: GoogleFonts.urbanist(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      );
    }

    final monthlyProduct = widget.products.firstWhere(
          (product) => product.id == StoreProducts.monthlySubIOS,
    );

    final yearlyProduct = widget.products.firstWhere(
          (product) => product.id == StoreProducts.yearlySubIOS,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildSubscriptionOption(
              monthlyProduct,
              'Monthly',
              isSelected: _selectedSubscriptionType == 'monthly',
            ),
          ),
          Expanded(
            child: _buildSubscriptionOption(
              yearlyProduct,
              'Yearly',
              isSelected: _selectedSubscriptionType == 'yearly',
              isBestValue: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption(
      ProductDetails product,
      String period, {
        required bool isSelected,
        bool isBestValue = false,
      }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFFFF48B0) : Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFFF48B0),
          width: 2,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: Color(0xFFFF48B0).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: Stack(
          children: [
          if (isBestValue)
      Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
          ),
        ),
        child: Text(
          'BEST VALUE',
          style: GoogleFonts.urbanist(
            color: Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
    InkWell(
      onTap: () => setState(() {
        _selectedSubscriptionType = period.toLowerCase();
      }),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              period,
              style: GoogleFonts.urbanist(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${product.price}',
              style: GoogleFonts.urbanist(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              period == 'Monthly' ? '30 days access' : '365 days access',
              style: GoogleFonts.urbanist(
                color: isSelected ? Colors.white70 : Colors.white54,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _getSavingsText(product),
              style: GoogleFonts.urbanist(
                color: isSelected ? Colors.white : Color(0xFFFF48B0),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
          ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return ElevatedButton(
      onPressed: () async {
        try {
          final selectedProduct = widget.products.firstWhere(
                (product) => _getPeriod(product.id) == _selectedSubscriptionType,
          );
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: CircularProgressIndicator(color: Color(0xFFFF48B0)),
            ),
          );
          await widget.onSubscribe(selectedProduct.id);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Processing your subscription...')),
          );
        } catch (e) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to process subscription. Please try again.')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF48B0),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        minimumSize: Size(double.infinity, 56),
        elevation: 4,
      ),
      child: Text(
        'Start Premium Access',
        style: GoogleFonts.urbanist(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getPeriod(String productId) {
    if (productId.contains('yearly')) return 'yearly';
    if (productId.contains('monthly')) return 'monthly';
    return 'weekly';
  }

  String _getSavingsText(ProductDetails product) {
    if (_getPeriod(product.id) == 'monthly') {
      return 'Save 40%';
    }
    if (_getPeriod(product.id) == 'yearly') {
      return 'Best Value! Save 67%';
    }
    return '';
  }

  String _getMonthlyPrice() {
    try {
      final monthlyProduct = widget.products.firstWhere(
            (product) => product.id == StoreProducts.monthlySubIOS,
      );
      return monthlyProduct.price;
    } catch (e) {
      return 'Price unavailable';
    }
  }

  String _getYearlyPrice() {
    try {
      final yearlyProduct = widget.products.firstWhere(
            (product) => product.id == StoreProducts.yearlySubIOS,
      );
      return yearlyProduct.price;
    } catch (e) {
      return 'Price unavailable';
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
