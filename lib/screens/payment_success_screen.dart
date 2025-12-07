import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  const PaymentSuccessScreen({super.key});

  @override
  ConsumerState<PaymentSuccessScreen> createState() =>
      _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  bool _isVerifying = true;
  String _statusMessage = 'Processing your payment...';

  @override
  void initState() {
    super.initState();
    _handlePaymentSuccess();
  }

  Future<void> _handlePaymentSuccess() async {
    try {
      // Show payment processing state
      setState(() {
        _statusMessage =
            'Thank you for subscribing to Thesis Generator. Your subscription is being activated...';
        _isVerifying = true;
      });

      // Simulate charging process for 5 seconds
      await Future.delayed(const Duration(seconds: 5));

      // Show completion state
      setState(() {
        _statusMessage = 'Payment complete! Redirecting to app...';
        _isVerifying = false;
      });

      // Brief pause before redirect
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        print('🔄 Payment completed - redirecting to thesisgenerator.tech');
        _redirectToMainApp();
      }
    } catch (e) {
      print('Error handling payment success: $e');
      if (mounted) {
        _redirectToMainApp();
      }
    }
  }

  /// Redirect to thesisgenerator.tech for a fresh start
  void _redirectToMainApp() async {
    try {
      if (kIsWeb) {
        // Force redirect to main domain using url_launcher
        final uri = Uri.parse('https://thesisgenerator.tech/index.html');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, webOnlyWindowName: '_self');
        }
      } else {
        // On mobile, navigate to signin screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/signin',
          (route) => false,
        );
      }
    } catch (e) {
      print('Error redirecting: $e');
      // Fallback: navigate to signin screen
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/signin',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isVerifying
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isVerifying
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF10B981))
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                _isVerifying ? Icons.hourglass_empty : Icons.check,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            if (_isVerifying) ...[
              const CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            ] else ...[
              const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 32,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
