import 'package:flutter/material.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/ui/login_page/login_screen.dart';
import 'package:konek2move/ui/main_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:konek2move/widgets/custom_dialog.dart';
import 'package:konek2move/widgets/custom_input_fields.dart';
import 'package:konek2move/widgets/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final response = await api.emailVerification(
        _emailController.text.trim(),
      );

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
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        bool isLoggingOut = false;
        if (!didPop) {
          showCustomDialog(
            context: context,
            title: "Leave Delivery Mode?",
            message:
                "If you exit now, you may miss new delivery requests. Do you want to continue?",
            icon: Icons.logout_rounded,
            color: AppColors.secondaryRed,
            buttonText: "Exit App",
            cancelText: "Stay",
            onButtonPressed: () async {
              if (isLoggingOut) return;
              isLoggingOut = true;

              try {
                final response = await ApiServices.logout();

                if (!context.mounted) return;

                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop(); // close dialog

                if (response.retCode == "202") {
                  final prefs = await SharedPreferences.getInstance();

                  // ✅ Clear auth token only
                  await prefs.remove("jwt_token");

                  // ✅ Reset biometric session flag
                  await prefs.setBool("biometric_in_progress", false);

                  // ✅ Wait one frame before navigation
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pushAndRemoveUntil(
                      SlideFadeRoute(page: const LoginScreen()),
                      (route) => false,
                    );
                  });

                  showAppSnackBar(
                    context,
                    title: "Logged Out",
                    message: response.message ?? "Successfully logged out",
                    isSuccess: true,
                    icon: Icons.check_circle_rounded,
                  );
                } else {
                  showAppSnackBar(
                    context,
                    title: "Logout Failed",
                    message: response.message ?? "Something went wrong",
                    isSuccess: false,
                    icon: Icons.error_rounded,
                  );
                }
              } catch (e) {
                if (!context.mounted) return;

                Navigator.of(context, rootNavigator: true).pop();

                showAppSnackBar(
                  context,
                  title: "Something went wrong",
                  message: "We couldn’t complete your request.",
                  isSuccess: false,
                  icon: Icons.error_outline_rounded,
                );
              } finally {
                isLoggingOut = false;
              }
            },
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pushReplacement(
              context,
              SlideFadeRoute(page: const MainScreen(index: 2)),
            ),
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
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Update your account password",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Please enter your new password. Make sure it is secure and easy for you to remember.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                textAlign: TextAlign.justify,
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
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                ),
              ),
            ],
          ),
        ),

        bottomNavigationBar: _buildBottomAction(context),
      ),
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
            height: 52,
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
