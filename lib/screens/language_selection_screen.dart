import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:translator/translator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/language_model.dart';
import '../widgets/native_ad_widget.dart';
import '../services/platform_language_service.dart';
import 'onboard_screen.dart';
import '../providers/locale_provider.dart';
import 'thesis_form_screen.dart';
import 'package:thesis_generator/screens/onboarding/onboarding_screen1.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  bool _isSubscribed = false;
  bool get _shouldShowAds => !kIsWeb && !Platform.isIOS && !_isSubscribed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscriptionStatus();
    });
  }

  Future<void> _checkSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isSubscribed = prefs.getBool('isSubscribed') ?? false;
    setState(() {
      _isSubscribed = isSubscribed;
    });
  }

  final translator = GoogleTranslator();
  int? selectedIndex;
  final Color secondaryColor = const Color(0xFFFF48B0);
  final List<LanguageModel> languages = [
    LanguageModel(name: 'English', code: 'en_US', countryCode: 'US'),
    LanguageModel(name: 'Español', code: 'es', countryCode: 'ES'),
    LanguageModel(name: 'Français', code: 'fr', countryCode: 'FR'),
    LanguageModel(name: '中文', code: 'zh', countryCode: 'CN'),
    LanguageModel(name: 'हिंदी', code: 'hi', countryCode: 'IN'),
  ];
  final buttonGradient = const LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFFFF48B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey[900]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildLanguageList()),
              if (_shouldShowAds) const NativeAdWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 30),
          Text(
            'Choose Language',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ).animate().fadeIn(),
          ShaderMask(
            shaderCallback: (bounds) => buttonGradient.createShader(bounds),
            child: IconButton(
              icon: Icon(
                Icons.check,
                color:
                    Colors.white.withOpacity(selectedIndex != null ? 1 : 0.6),
              ),
              onPressed: selectedIndex != null ? _onLanguageConfirmed : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: languages.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black,
          ),
          child: ListTile(
            onTap: () => setState(() => selectedIndex = index),
            leading: CountryFlag.fromCountryCode(
              languages[index].countryCode,
              height: 32,
              width: 32,
              borderRadius: 16,
            ),
            title: Text(
              languages[index].name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            trailing: Radio(
              value: index,
              groupValue: selectedIndex,
              onChanged: (value) =>
                  setState(() => selectedIndex = value as int),
              activeColor: secondaryColor,
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms);
      },
    );
  }

  void _onLanguageConfirmed() async {
    if (selectedIndex != null) {
      try {
        final selectedLanguage = languages[selectedIndex!];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language_code', selectedLanguage.code);
        ref
            .read(localeProvider.notifier)
            .setLocale(selectedLanguage.code.split('_')[0]);
        await PlatformLanguageService.setLanguage(selectedLanguage.code);
        final isSubscribed = prefs.getBool('isSubscribed') ?? false;

        if (mounted) {
          if (isSubscribed) {
            Navigator.pushReplacementNamed(context, '/thesis-form');
          } else if (kIsWeb || Platform.isIOS) {
            Navigator.pushReplacementNamed(context, '/onboarding1');
          } else {
            Navigator.pushReplacementNamed(context, '/onboard');
          }
        }
      } catch (e) {
        if (mounted) {
          if (kIsWeb || Platform.isIOS) {
            Navigator.pushReplacementNamed(context, '/onboarding1');
          } else {
            Navigator.pushReplacementNamed(context, '/onboard');
          }
        }
      }
    }
  }
}
