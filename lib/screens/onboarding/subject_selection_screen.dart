import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A5568);

  final List<SubjectOption> subjectOptions = [
    SubjectOption(
      title: "Computer Science",
      icon: PhosphorIcons.code(PhosphorIconsStyle.regular),
      color: Color(0xFF2563EB),
      description:
          "Programming, algorithms, AI, and technology with charts & data",
    ),
    SubjectOption(
      title: "Business",
      icon: PhosphorIcons.briefcase(PhosphorIconsStyle.regular),
      color: Color(0xFF10B981),
      description: "Management, marketing, finance with professional tables",
    ),
    SubjectOption(
      title: "Psychology",
      icon: PhosphorIcons.brain(PhosphorIconsStyle.regular),
      color: Color(0xFFEC4899),
      description: "Human behavior, cognition with statistical analysis",
    ),
    SubjectOption(
      title: "Engineering",
      icon: PhosphorIcons.gear(PhosphorIconsStyle.regular),
      color: Color(0xFF8B5CF6),
      description: "Technical research with detailed diagrams & data",
    ),
    SubjectOption(
      title: "Medicine",
      icon: PhosphorIcons.heartbeat(PhosphorIconsStyle.regular),
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

              // Header badge with Phosphor icon
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.bookOpen(PhosphorIconsStyle.regular),
                        size: 16,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Choose Your Subject',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
              const SizedBox(height: 32),

              // Title
              Text(
                "What's your thesis subject?",
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                "Select your field of study to generate a customized thesis with relevant charts and data.",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

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

              // Continue button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedSubject != null
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AcademicLevelScreen(),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: const Color(0xFFF3F4F6),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: selectedSubject != null
                          ? const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: selectedSubject == null
                          ? const Color(0xFFF3F4F6)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Continue",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: selectedSubject != null
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            PhosphorIcons.arrowRight(
                                PhosphorIconsStyle.regular),
                            size: 20,
                            color: selectedSubject != null
                                ? Colors.white
                                : const Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
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
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? subject.color.withOpacity(0.08)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? subject.color : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? subject.color.withOpacity(0.15)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 12 : 4,
                offset: Offset(0, isSelected ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? subject.color
                      : subject.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  subject.icon,
                  color: isSelected ? Colors.white : subject.color,
                  size: 28,
                ),
              ),

              SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subject.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: textSecondary,
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
                    color: isSelected ? subject.color : const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        PhosphorIcons.check(PhosphorIconsStyle.bold),
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(
            delay: Duration(milliseconds: 500 + (index * 100)),
            duration: Duration(milliseconds: 400),
          )
          .slideY(
            begin: 0.2,
            end: 0,
            delay: Duration(milliseconds: 500 + (index * 100)),
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
