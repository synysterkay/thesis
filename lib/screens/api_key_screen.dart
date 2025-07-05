import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../providers/gemini_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ApiKeyScreen extends ConsumerStatefulWidget {
  const ApiKeyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends ConsumerState<ApiKeyScreen> {
  final _apiKeyController = TextEditingController();
  bool _apiKeySaved = false;
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  // Updated color scheme to match new white and blue design
  static const primaryColor = Color(0xFF2563EB);
  static const secondaryColor = Color(0xFF1D4ED8);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const textMuted = Color(0xFF64748B);

  final buttonGradient = const LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/api.mp4');
    await _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.setVolume(0.0); // Mute the video
    _videoController.play();
    setState(() {
      _isVideoInitialized = true;
    });
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('userApiKey');
    if (apiKey != null) {
      _apiKeyController.text = apiKey;
      setState(() => _apiKeySaved = true);
    }
  }

  Future<void> _saveApiKey() async {
    if (_apiKeyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter an API key',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userApiKey', _apiKeyController.text);
    ref.read(geminiServiceProvider).setUserApiKey(_apiKeyController.text);
    setState(() => _apiKeySaved = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'API Key Saved',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Set Up Your API Key",
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.vpn_key,
                        size: 32,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Get Your Own API Key",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: textSecondary,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: '1. Go to '),
                          TextSpan(
                            text: 'Google AI Studio',
                            style: GoogleFonts.inter(
                              color: primaryColor,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                final Uri url = Uri.parse('https://aistudio.google.com/apikey');
                                if (!await launchUrl(url)) {
                                  throw Exception('Could not launch $url');
                                }
                              },
                          ),
                          const TextSpan(
                            text: '\n2. Click "Create API Key"\n3. Copy the generated key and paste it below',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 24),
              
              // Video Tutorial
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isVideoInitialized
                      ? AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  )
                      : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading tutorial...',
                          style: GoogleFonts.inter(
                            color: textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
              
              const SizedBox(height: 24),
              
              // API Key Input
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _apiKeyController,
                  style: GoogleFonts.inter(color: textPrimary),
                  decoration: InputDecoration(
                    labelText: "Enter your API Key",
                    labelStyle: GoogleFonts.inter(color: textMuted),
                    hintText: "AIzaSyC...",
                    hintStyle: GoogleFonts.inter(color: textMuted.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.key, color: primaryColor),
                    filled: true,
                    fillColor: surfaceColor,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 24),
              
              // Save Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _apiKeySaved
                      ? LinearGradient(
                    colors: [Colors.green.shade600, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : buttonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: (_apiKeySaved ? Colors.green : primaryColor).withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _apiKeySaved ? () => setState(() => _apiKeySaved = false) : _saveApiKey,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _apiKeySaved ? Icons.check_circle : Icons.vpn_key,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _apiKeySaved ? 'API Key Saved - Change?' : 'Validate & Save',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
              
              const SizedBox(height: 24),
              
              // Info Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Using your own API key provides faster generation and better reliability.",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}
