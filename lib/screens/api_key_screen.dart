import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  static const primaryColor = Color(0xFF9D4EDD);
  static const secondaryColor = Color(0xFFFF48B0);

  final buttonGradient = const LinearGradient(
    colors: [Color(0xFF9D4EDD), Color(0xFFFF48B0)],
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
        const SnackBar(content: Text('Please enter an API key')),
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
          style: GoogleFonts.lato(),
        ),
        backgroundColor: primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        "Set Up Your API Key",
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Get Your Own API Key",
                                style: GoogleFonts.lato(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                                  children: [
                                    const TextSpan(text: '1. Go to '),
                                    TextSpan(
                                      text: 'Google AI Studio',
                                      style: GoogleFonts.lato(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
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
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _isVideoInitialized
                                ? AspectRatio(
                              aspectRatio: _videoController.value.aspectRatio,
                              child: VideoPlayer(_videoController),
                            )
                                : const Center(
                              child: CircularProgressIndicator(
                                color: secondaryColor,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _apiKeyController,
                            style: GoogleFonts.lato(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: "Enter your API Key",
                              labelStyle: GoogleFonts.lato(color: secondaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: primaryColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: secondaryColor),
                              ),
                              prefixIcon: Icon(Icons.key, color: secondaryColor),
                            ),
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: _apiKeySaved
                                ? LinearGradient(
                              colors: [Colors.green.shade700, Colors.green.shade500],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : buttonGradient,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: -2,
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
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _apiKeySaved ? 'API Key Saved - Change?' : 'Validate & Save',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 24),
                        Text(
                          "Using your own API key provides faster generation and better reliability.",
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 500.ms),
                      ],
                    ),
                  ),
                ),
              ),
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
