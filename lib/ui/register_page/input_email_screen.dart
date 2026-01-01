import 'package:flutter/material.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/ui/landing_page/landing_screen.dart';
import 'package:konek2move/ui/register_page/validate_email_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:konek2move/widgets/custom_dialog.dart';
import 'package:konek2move/widgets/custom_input_fields.dart'; // <-- make sure this import exists

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isEmailValid = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_validateInputs);
  }

  void _validateInputs() {
    final emailText = emailController.text.trim();

    final emailValid =
        emailText.isNotEmpty && emailText.toLowerCase().endsWith('@gmail.com');

    setState(() {
      isEmailValid = emailValid;
    });
  }

  Future<void> _onSendCode() async {
    if (!isEmailValid) return;

    setState(() {
      isLoading = true;
    });

    try {
      final ApiServices api = ApiServices();
      final response = await api.emailVerification(emailController.text.trim());

      if (!mounted) return;

      if (response.retCode == '200') {
        Navigator.pushReplacement(context, SlideFadeRoute(page: EmailVerificationScreen(email: emailController.text.trim())));
      } else {
        _showDialogMessage(message: response.message!, isError: true);
      }
    } catch (e) {
      if (!mounted) return;

      _showDialogMessage(
        message: 'Failed to send OTP: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// --- CUSTOM DIALOG HANDLING ---
  void _showDialogMessage({
    required String message,
    bool isError = false,
  }) {
    final color = isError ? Colors.redAccent : Colors.green;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    showCustomDialog(
      context: context,
      title: isError ? "Error" : "Success",
      message: message,
      icon: icon,
      color: color,
      buttonText: "Okay!",
      onButtonPressed: () async {
        Navigator.pop(context); // close dialog
      },
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pushReplacement(context, SlideFadeRoute(page: const LandingScreen())),
        ),
        centerTitle: true,
        title: const Text(
          "Input Email Address",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please enter an email address that is not yet registered to continue.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),

            const SizedBox(height: 24),

            CustomInputField(
              label: "Email Address",
              hint: "Enter your email",
              controller: emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomAction(context),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bool isThreeButtonNav = safeBottom == 0;

    return SafeArea(
      bottom: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            isThreeButtonNav ? 16 : safeBottom + 14,
          ),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              /// 🔥 if invalid email or loading → disable
              onPressed: isEmailValid && !isLoading ? _onSendCode : null,

              child: isLoading
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 14),
                  Text(
                    "Sending...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
                  : const Text(
                "Continue",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
