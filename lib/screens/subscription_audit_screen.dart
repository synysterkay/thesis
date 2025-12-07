/// Debug screen to audit and fix subscription discrepancies
/// This helps identify users marked as subscribed without actual payment
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/subscription_audit_service.dart';

class SubscriptionAuditScreen extends ConsumerStatefulWidget {
  const SubscriptionAuditScreen({super.key});

  @override
  ConsumerState<SubscriptionAuditScreen> createState() =>
      _SubscriptionAuditScreenState();
}

class _SubscriptionAuditScreenState
    extends ConsumerState<SubscriptionAuditScreen> {
  SubscriptionAuditResult? _auditResult;
  bool _isLoading = false;
  bool _isFixing = false;

  @override
  void initState() {
    super.initState();
    _runAudit();
  }

  Future<void> _runAudit() async {
    setState(() {
      _isLoading = true;
    });

    final result = await SubscriptionAuditService.auditCurrentUser();
    await SubscriptionAuditService.printAuditReport();

    setState(() {
      _auditResult = result;
      _isLoading = false;
    });
  }

  Future<void> _fixDiscrepancy() async {
    if (_auditResult?.isValid == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No issues found to fix')),
      );
      return;
    }

    setState(() {
      _isFixing = true;
    });

    final success = await SubscriptionAuditService.fixSubscriptionDiscrepancy();

    setState(() {
      _isFixing = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription discrepancy fixed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // Re-run audit to verify fix
      _runAudit();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fix subscription discrepancy'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Audit'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current User',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${user?.email ?? 'Not signed in'}'),
                    Text('UID: ${user?.uid ?? 'N/A'}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Audit Results
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Audit Results',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: _isLoading ? null : _runAudit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_auditResult == null)
                      const Text('Running audit...')
                    else ...[
                      _buildAuditStatusRow(
                        'Local Subscription',
                        _auditResult!.hasLocalSubscription,
                      ),
                      _buildAuditStatusRow(
                        'Stripe Subscription',
                        _auditResult!.hasStripeSubscription,
                      ),
                      const SizedBox(height: 16),

                      // Overall status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _auditResult!.isValid
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          border: Border.all(
                            color: _auditResult!.isValid
                                ? Colors.green
                                : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _auditResult!.isValid
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _auditResult!.isValid
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _auditResult!.isValid
                                        ? 'Subscription Valid'
                                        : 'Subscription Issue Found',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _auditResult!.isValid
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                    ),
                                  ),
                                  if (!_auditResult!.isValid) ...[
                                    Text(
                                      _getDiscrepancyDescription(
                                          _auditResult!.discrepancyType),
                                      style:
                                          TextStyle(color: Colors.red.shade700),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (!_auditResult!.isValid) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isFixing ? null : _fixDiscrepancy,
                            icon: _isFixing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.build),
                            label: Text(
                                _isFixing ? 'Fixing...' : 'Fix Discrepancy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],

                      if (_auditResult!.error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            border: Border.all(color: Colors.orange),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Error: ${_auditResult!.error}',
                                  style: const TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Warning message
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(
                        'Debug Tool',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This screen helps identify users marked as subscribed without actual payment. This was a security issue in the previous implementation.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Icon(
                status ? Icons.check_circle : Icons.cancel,
                color: status ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                status ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: status ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDiscrepancyDescription(DiscrepancyType type) {
    switch (type) {
      case DiscrepancyType.localOnlyNoStripe:
        return 'SECURITY ISSUE: User marked as subscribed without payment';
      case DiscrepancyType.stripeOnlyNoLocal:
        return 'User has paid but not marked locally';
      case DiscrepancyType.none:
        return 'No discrepancy';
    }
  }
}
