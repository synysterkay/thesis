import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'thesis_details_screen.dart';

class ThesisPreviewScreen extends StatelessWidget {
  const ThesisPreviewScreen({Key? key}) : super(key: key);

  // App colors
  static const primaryColor = Color(0xFF9D4EDD);
  static const secondaryColor = Color(0xFFFF48B0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Color(0xFF1A1A1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Headline
                Text(
                  "Your Thesis Will Be Ready",
                  style: GoogleFonts.lato(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

                const SizedBox(height: 16),

                // Subheadline
                Text(
                  "Academic Excellence Awaits",
                  style: GoogleFonts.lato(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

                const SizedBox(height: 24),

                // Copy text
                Text(
                  "We will create a comprehensive, well-structured thesis that meets academic standards and showcases your research topic effectively.",
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 600)),

                const SizedBox(height: 40),

                // Thesis preview cards
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildThesisSection(
                          "Structured Framework",
                          "Clear introduction, methodology, results, and conclusion sections",
                          Icons.view_agenda,
                          Colors.blue,
                          0,
                        ),

                        _buildThesisSection(
                          "Research Integration",
                          "Seamlessly incorporates relevant academic sources and citations",
                          Icons.search,
                          primaryColor,
                          1,
                        ),

                        _buildThesisSection(
                          "Academic Language",
                          "Professional scholarly tone appropriate for your academic level",
                          Icons.spellcheck,
                          Colors.green,
                          2,
                        ),

                        _buildThesisSection(
                          "Original Content",
                          "100% unique content that passes plagiarism checks",
                          Icons.verified_user,
                          Colors.amber,
                          3,
                        ),
                      ],
                    ),
                  ),
                ),

                // CTA Button
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ThesisDetailsScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      "Let's get Started",
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 1200)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThesisSection(String title, String description, IconData icon, Color color, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative side accent
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                color: color,
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            color: Colors.grey[400],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 800 + (index * 100)),
      duration: const Duration(milliseconds: 400),
    ).slideY(
      begin: 0.2,
      end: 0,
      delay: Duration(milliseconds: 800 + (index * 100)),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuad,
    );
  }
}
