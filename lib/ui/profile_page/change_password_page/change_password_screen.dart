import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/ui/main_screen.dart';
import 'package:konek2move/ui/profile_page/profile_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:konek2move/widgets/custom_input_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/main.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool isValid = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmail();

    _passwordController.addListener(_validateInputs);
    _confirmPasswordController.addListener(_validateInputs);
  }

  Future<void> _loadEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _emailController.text = prefs.getString("email") ?? "";
    _validateInputs();
  }

  void _validateInputs() {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      isValid =
          password.isNotEmpty &&
              confirmPassword.isNotEmpty &&
              password == confirmPassword;
    });
  }

  Future<void> _onSubmit() async {
    if (!isValid || isLoading) return;

    setState(() => isLoading = true);

    try {
      final api = ApiServices();
      final response =
      await api.emailVerification(_emailController.text.trim());

      if (!mounted) return;

      if (response.retCode == '200') {
        _showResultDialog(
          title: "Success",
          message: "OTP has been sent to your email.",
          isError: false,
        );
      } else {
        _showResultDialog(
          title: "Error",
          message: response.error ?? "Something went wrong",
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog(
          title: "Error",
          message: "Failed to send OTP.\n$e",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= CUSTOM DIALOG =================
  void _showResultDialog({
    required String title,
    required String message,
    required bool isError,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  size: 48,
                  color: isError ? Colors.redAccent : Colors.green,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Okay!"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          onPressed: () => Navigator.pushReplacement(context, SlideFadeRoute(page: const MainScreen(index: 3,))),
        ),
        centerTitle: true,
        title: const Text(
          "Change Password",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Please enter your new password. Make sure it is secure and easy for you to remember.",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),

            CustomInputField(
              label: "Email",
              hint: "Enter your email",
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),

            CustomInputField(
              required: true,
              label: "Password",
              hint: "Enter your password",
              controller: _passwordController,
              obscure: !_isPasswordVisible,
              prefixIcon: Icons.lock_outline,
              suffixIcon: _isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              onSuffixTap: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            const SizedBox(height: 16),

            CustomInputField(
              required: true,
              label: "Confirm Password",
              hint: "Re-enter your password",
              controller: _confirmPasswordController,
              obscure: !_isConfirmPasswordVisible,
              prefixIcon: Icons.lock_outline,
              suffixIcon: _isConfirmPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              onSuffixTap: () => setState(
                    () => _isConfirmPasswordVisible =
                !_isConfirmPasswordVisible,
              ),
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

              /// disable when invalid or loading
              onPressed: isValid && !isLoading ? _onSubmit : null,

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
                    "Submitting...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
                  : const Text(
                "Submit",
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
