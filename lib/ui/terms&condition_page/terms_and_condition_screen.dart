import 'package:flutter/material.dart';
import 'package:konek2move/ui/landing_page/landing_screen.dart';
import 'package:konek2move/ui/register_page/input_email_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';

class TermsAndConditionScreen extends StatefulWidget {
  const TermsAndConditionScreen({super.key});

  @override
  State<TermsAndConditionScreen> createState() =>
      _TermsAndConditionScreenState();
}

class _TermsAndConditionScreenState extends State<TermsAndConditionScreen> {
  bool isAccepted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ------- APP BAR -------
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pushReplacement(
            context,
            SlideFadeRoute(page: const LandingScreen()),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),

      // ------- CONTENT -------
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TermsSection(
              number: "1.",
              title: "Introduction",
              content:
                  "Welcome to Konek2Move Delivery App. By using our services, you agree to comply with our terms and conditions. Please read carefully before using the app.",
            ),
            _TermsSection(
              number: "2.",
              title: "Account Registration",
              content:
                  "You must provide accurate information when registering an account. You are responsible for maintaining the confidentiality of your account credentials.",
            ),
            _TermsSection(
              number: "3.",
              title: "Use of Service",
              content:
                  "The app provides delivery services. You agree not to misuse the app for illegal activities or violate any local laws.",
            ),
            _TermsSection(
              number: "4.",
              title: "Payments",
              content:
                  "All payments made through Konek2Move must be authorized and accurate. We are not responsible for unauthorized transactions.",
            ),
            _TermsSection(
              number: "5.",
              title: "Privacy",
              content:
                  "Your personal data is collected and used according to our Privacy Policy. By using the app, you consent to such data collection.",
            ),
            _TermsSection(
              number: "6.",
              title: "Termination",
              content:
                  "We may suspend or terminate your account if you violate these terms or engage in fraudulent activities.",
            ),
            _TermsSection(
              number: "7.",
              title: "Changes to Terms",
              content:
                  "Konek2Move may update these terms at any time. Continued use of the app constitutes acceptance of the updated terms.",
            ),
            _TermsSection(
              number: "8.",
              title: "Contact Us",
              content:
                  "For any questions or concerns regarding these terms, please contact our support team via the app or email.",
            ),
          ],
        ),
      ),

      bottomNavigationBar: _bottomAction(context),
    );
  }

  // ------- BOTTOM ACTION -------
  Widget _bottomAction(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.10),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, bottom + 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Transform.scale(
                  scale: 1.25,
                  child: Checkbox(
                    value: isAccepted,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    onChanged: (val) {
                      setState(() => isAccepted = val ?? false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: "I have read and agree to all the",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(
                          text: "Terms & Conditions",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAccepted
                    ? () {
                        Navigator.pushReplacement(
                          context,
                          SlideFadeRoute(page: const EmailScreen()),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAccepted
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isAccepted ? Colors.white : Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------- TERMS ITEM -------
class _TermsSection extends StatelessWidget {
  final String number;
  final String title;
  final String content;

  const _TermsSection({
    required this.number,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$number $title",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
