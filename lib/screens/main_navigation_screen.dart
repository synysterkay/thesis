import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../screens/home_dashboard_screen.dart';
import '../screens/thesis_form_screen.dart';
import '../screens/outline_viewer_screen.dart';
import '../screens/export_screen.dart';
import '../screens/thesis_history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  final bool isTrialMode;
  final int initialIndex;
  final String? workflowScreen; // 'outline', 'export', etc.
  final String? thesisId; // For loading specific thesis

  const MainNavigationScreen({
    super.key,
    this.isTrialMode = false,
    this.initialIndex = 1, // Default to "New" tab
    this.workflowScreen,
    this.thesisId,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _selectedIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateBackToServiceSelection() {
    // Navigate back to thesis service selection screen
    if (widget.isTrialMode) {
      Navigator.of(context)
          .pushReplacementNamed('/thesis-service-selection-trial');
    } else {
      Navigator.of(context).pushReplacementNamed('/thesis-service-selection');
    }
  }

  Widget _buildWorkflowScreen() {
    print(
        'DEBUG MainNavigationScreen: workflowScreen = "${widget.workflowScreen}", thesisId = "${widget.thesisId}"');
    switch (widget.workflowScreen) {
      case 'outline':
        print('DEBUG MainNavigationScreen: Building OutlineViewerScreen');
        return OutlineViewerScreen(thesisId: widget.thesisId);
      case 'export':
        print('DEBUG MainNavigationScreen: Building ExportScreen');
        return ExportScreen(thesisId: widget.thesisId);
      default:
        print(
            'DEBUG MainNavigationScreen: Building ThesisFormScreen (default)');
        return ThesisFormScreen(thesisId: widget.thesisId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _navigateBackToServiceSelection();
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            // Home/Dashboard
            HomeDashboardScreen(
              onNavigate: _onNavItemTapped,
            ),

            // New Thesis/Form (or workflow screen)
            _buildWorkflowScreen(),

            // My Theses/History
            const ThesisHistoryScreen(),

            // Profile
            const ProfileScreen(),

            // Settings
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: PhosphorIcons.house(PhosphorIconsStyle.fill),
                    label: 'Home',
                    index: 0,
                    isSelected: _selectedIndex == 0,
                  ),
                  _buildNavItem(
                    icon: PhosphorIcons.plusCircle(PhosphorIconsStyle.fill),
                    label: 'New',
                    index: 1,
                    isSelected: _selectedIndex == 1,
                  ),
                  _buildNavItem(
                    icon: PhosphorIcons.books(PhosphorIconsStyle.fill),
                    label: 'History',
                    index: 2,
                    isSelected: _selectedIndex == 2,
                  ),
                  _buildNavItem(
                    icon: PhosphorIcons.user(PhosphorIconsStyle.fill),
                    label: 'Profile',
                    index: 3,
                    isSelected: _selectedIndex == 3,
                  ),
                  _buildNavItem(
                    icon: PhosphorIcons.gear(PhosphorIconsStyle.fill),
                    label: 'Settings',
                    index: 4,
                    isSelected: _selectedIndex == 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ), // End of Scaffold
    ); // End of PopScope
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? Colors.deepPurple : Colors.grey[600],
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.deepPurple : Colors.grey[600],
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
