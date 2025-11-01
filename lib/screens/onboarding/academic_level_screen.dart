import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'page_count_screen.dart';

class AcademicLevelScreen extends StatefulWidget {
  const AcademicLevelScreen({Key? key}) : super(key: key);

  @override
  State<AcademicLevelScreen> createState() => _AcademicLevelScreenState();
}

class _AcademicLevelScreenState extends State<AcademicLevelScreen> {
  String? selectedLevel;

  // Updated color scheme to match app design
  static const primaryColor = Color(0xFF2563EB);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const accentColor = Color(0xFF10B981);

  final List<AcademicOption> academicOptions = [
    AcademicOption(
      title: "Undergraduate",
      icon: Icons.school_outlined,
      color: Color(0xFF2563EB),
      description: "Bachelor's level with humanized AI content & visuals",
    ),
    AcademicOption(
      title: "Master's",
      icon: Icons.school,
      color: Color(0xFFEC4899),
      description: "Advanced research with charts, tables & data analysis",
    ),
    AcademicOption(
      title: "Doctoral",
      icon: Icons.psychology,
      color: Color(0xFF10B981),
      description: "PhD level with comprehensive visuals & undetectable AI",
    ),
    AcademicOption(
      title: "Research Paper",
      icon: Icons.article,
      color: Color(0xFFF59E0B),
      description: "Academic paper with professional formatting & graphs",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Headline
              Text(
                "What's your academic level?",
                style: GoogleFonts.lato(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.left,
              ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                "We'll tailor the thesis complexity to match your academic requirements.",
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.left,
              ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

              const SizedBox(height: 40),

              // Academic level options
              Expanded(
                child: ListView.builder(
                  itemCount: academicOptions.length,
                  itemBuilder: (context, index) {
                    return _buildAcademicOption(academicOptions[index], index);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // CTA Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: selectedLevel != null
                        ? [primaryColor, Color(0xFF1D4ED8)]
                        : [Colors.grey[700]!, Colors.grey[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: selectedLevel != null
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: selectedLevel != null
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PageCountScreen(),
                            ),
                          );
                        }
                      : null, // Button disabled if no option selected
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.grey[600],
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    "Continue",
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 500)),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcademicOption(AcademicOption option, int index) {
    bool isSelected = selectedLevel == option.title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLevel = option.title;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: option.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                    spreadRadius: 1,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
        ),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                isSelected ? option.color.withOpacity(0.2) : Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? option.color : Colors.grey[800]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: option.color.withOpacity(isSelected ? 1.0 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  option.icon,
                  color: isSelected ? Colors.white : option.color,
                  size: 30,
                ),
              ),

              SizedBox(width: 20),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? option.color : Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      option.description,
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? option.color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? option.color : Colors.grey[600]!,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: 400 + (index * 100)),
            duration: Duration(milliseconds: 400),
          )
          .slideY(
            begin: 0.2,
            end: 0,
            delay: Duration(milliseconds: 400 + (index * 100)),
            duration: Duration(milliseconds: 400),
            curve: Curves.easeOutQuad,
          ),
    );
  }
}

class AcademicOption {
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  AcademicOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });
}
