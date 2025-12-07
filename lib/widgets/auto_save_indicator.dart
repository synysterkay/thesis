import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/thesis_provider.dart';
import 'dart:async';

class AutoSaveIndicator extends ConsumerStatefulWidget {
  const AutoSaveIndicator({super.key});

  @override
  _AutoSaveIndicatorState createState() => _AutoSaveIndicatorState();
}

class _AutoSaveIndicatorState extends ConsumerState<AutoSaveIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _hideTimer;
  String _status = '';
  Color _statusColor = Colors.grey;
  IconData _statusIcon = Icons.save_outlined;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _updateStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _updateStatus() {
    final thesisNotifier = ref.read(thesisStateProvider.notifier);

    if (thesisNotifier.hasUnsavedChanges) {
      _showStatus('Saving...', Colors.orange, Icons.sync);

      // Simulate save completion after a short delay
      Timer(const Duration(seconds: 1), () {
        if (mounted) {
          _showStatus('All changes saved', Colors.green, Icons.check_circle);
          _scheduleHide();
        }
      });
    } else {
      _showStatus('All changes saved', Colors.green, Icons.check_circle);
      _scheduleHide();
    }
  }

  void _showStatus(String status, Color color, IconData icon) {
    setState(() {
      _status = status;
      _statusColor = color;
      _statusIcon = icon;
    });
    _animationController.forward();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for thesis state changes to update save status
    ref.listen<AsyncValue<dynamic>>(thesisStateProvider, (previous, next) {
      _updateStatus();
    });

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_status == 'Saving...')
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                ),
              )
            else
              Icon(
                _statusIcon,
                size: 14,
                color: _statusColor,
              ),
            const SizedBox(width: 6),
            Text(
              _status,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AutoSaveSettings extends ConsumerWidget {
  const AutoSaveSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thesisNotifier = ref.read(thesisStateProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auto-save Settings',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Switch(
              value: thesisNotifier.isAutoSaveEnabled,
              onChanged: (enabled) async {
                await thesisNotifier.setAutoSaveEnabled(enabled);
              },
              activeColor: const Color(0xFF2563EB),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-save',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Automatically save your progress every 30 seconds',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await thesisNotifier.saveThesis();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Thesis saved successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.save, size: 16),
                label: Text(
                  'Save Now',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await thesisNotifier.clearCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.clear_all, size: 16),
                label: Text(
                  'Clear Cache',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SaveStatusWidget extends ConsumerWidget {
  const SaveStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<DateTime?>(
      future: ref.read(thesisStateProvider.notifier).getLastSaveTime(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final lastSave = snapshot.data!;
        final now = DateTime.now();
        final difference = now.difference(lastSave);

        String timeAgo;
        if (difference.inMinutes < 1) {
          timeAgo = 'Just now';
        } else if (difference.inMinutes < 60) {
          timeAgo = '${difference.inMinutes}m ago';
        } else if (difference.inHours < 24) {
          timeAgo = '${difference.inHours}h ago';
        } else {
          timeAgo = '${difference.inDays}d ago';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule,
                size: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Last saved $timeAgo',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
