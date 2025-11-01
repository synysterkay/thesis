import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'academic_level_screen.dart';

class SubjectSelectionScreen extends StatefulWidget {
  const SubjectSelectionScreen({Key? key}) : super(key: key);

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  String? selectedSubject;

  // Updated color scheme to match app design
  static const primaryColor = Color(0xFF2563EB);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const surfaceColor = Color(0xFFF8FAFC);
  static const borderColor = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);
  static const accentColor = Color(0xFF10B981);

  final List<SubjectOption> subjectOptions = [
    SubjectOption(
      title: "Computer Science",
      icon: Icons.computer,
      color: Color(0xFF2563EB),
      description:
          "Programming, algorithms, AI, and technology with charts & data",
    ),
    SubjectOption(
      title: "Business",
      icon: Icons.business,
      color: Color(0xFF10B981),
      description: "Management, marketing, finance with professional tables",
    ),
    SubjectOption(
      title: "Psychology",
      icon: Icons.psychology,
      color: Color(0xFFEC4899),
      description: "Human behavior, cognition with statistical analysis",
    ),
    SubjectOption(
      title: "Engineering",
      icon: Icons.engineering,
      color: Color(0xFF8B5CF6),
      description: "Technical research with detailed diagrams & data",
    ),
    SubjectOption(
      title: "Medicine",
      icon: Icons.medical_services,
      color: Color(0xFFF59E0B),
      description: "Healthcare research with clinical data & visualizations",
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
                "What's your thesis subject?",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                textAlign: TextAlign.left,
              ).animate().fadeIn(delay: const Duration(milliseconds: 200)),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                "To craft the perfect humanized AI thesis with professional charts and tables, we need to understand your field of study.",
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.left,
              ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

              const SizedBox(height: 40),

              // Subject selection options
              Expanded(
                child: ListView.builder(
                  itemCount: subjectOptions.length,
                  itemBuilder: (context, index) {
                    return _buildSubjectOption(subjectOptions[index], index);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // CTA Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: selectedSubject != null
                        ? [primaryColor, Color(0xFF1D4ED8)]
                        : [Color(0xFFE5E7EB), Color(0xFFD1D5DB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: selectedSubject != null
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
                  onPressed: selectedSubject != null
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AcademicLevelScreen(),
                            ),
                          );
                        }
                      : null, // Button disabled if no subject selected
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

  Widget _buildSubjectOption(SubjectOption subject, int index) {
    bool isSelected = selectedSubject == subject.title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSubject = subject.title;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: subject.color.withOpacity(0.3),
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
                isSelected ? subject.color.withOpacity(0.2) : Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? subject.color : Colors.grey[800]!,
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
                  color: subject.color.withOpacity(isSelected ? 1.0 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  subject.icon,
                  color: isSelected ? Colors.white : subject.color,
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
                      subject.title,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? subject.color : Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subject.description,
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
                  color: isSelected ? subject.color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? subject.color : Colors.grey[600]!,
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

class SubjectOption {
  final String title;
  final IconData icon;
  final Color color;
  final String description;

  SubjectOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });
}
