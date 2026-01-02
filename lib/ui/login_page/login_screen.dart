import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/services/model_services.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:konek2move/widgets/custom_snackbar.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/ui/forgot_password_page/forgot_password_screen.dart';
import 'package:konek2move/ui/terms&condition_page/terms_and_condition_screen.dart';
import 'package:konek2move/ui/main_screen.dart';
import 'package:konek2move/widgets/custom_input_fields.dart';
import 'package:konek2move/widgets/custom_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _showBiometric = false;

  late AnimationController _controller;
  late Animation<Offset> _containerSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _containerSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
      _initPreferences();
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Load SharedPreferences + check biometrics
  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool("biometric_enabled") ?? false;
    if (!mounted) return;
    setState(() => _showBiometric = enabled);

    if (enabled)
      Future.delayed(const Duration(milliseconds: 200), _biometricLogin);
  }

  /// BIOMETRIC LOGIN
  Future<void> _biometricLogin() async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Login using your biometrics or device PIN',
        biometricOnly: false,
      );
      if (!didAuthenticate) return;

      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString("email");
      final password = prefs.getString("password");
      if (email == null || password == null) {
        _showCustomDialog("No saved credentials for biometric login", false);
        return;
      }

      setState(() => _loading = true);

      final response = await ApiServices().signIn(email, password);

      if (!mounted) return;
      setState(() => _loading = false);

      if (response.retCode == '201') {
        await _saveUserData(response);
        Navigator.pushReplacement(
          context,
          SlideFadeRoute(page: const MainScreen()),
        );
      } else {
        _showCustomDialog(
          response.error ?? response.message ?? "Login failed",
          false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showCustomDialog(
        "It looks like you haven't set up biometric login yet. You can enable it in settings for quicker access next time!",
        false,
      );
    }
  }

  /// LOGIN BUTTON
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final emailText = _email.text.trim();
    final passwordText = _password.text.trim();

    // Check for empty fields first
    if (emailText.isEmpty && passwordText.isEmpty) {
      _showCustomDialog("Please enter your email and password", false);
      return;
    } else if (emailText.isEmpty) {
      _showCustomDialog("Please enter your email address", false);
      return;
    } else if (passwordText.isEmpty) {
      _showCustomDialog("Please enter your password", false);
      return;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(emailText)) {
      _showCustomDialog("Please enter a valid email address", false);
      return;
    }

    if (_loading) return;

    setState(() => _loading = true);

    try {
      final response = await ApiServices().signIn(
        _email.text.trim(),
        _password.text.trim(),
      );
      if (!mounted) return;
      setState(() => _loading = false);

      if (response.retCode == '201') {
        await _saveUserData(response);
        showAppSnackBar(
          icon: Icons.check_circle_rounded,
          context,
          title: "Success",
          message: response.message!,
          isSuccess: true,
        );
        Navigator.pushReplacement(
          context,
          SlideFadeRoute(page: const MainScreen()),
        );
      } else {
        _showCustomDialog(
          response.error ?? response.message ?? "Login failed",
          false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showCustomDialog("Error: $e", false);
    }
  }

  // josharban455@gmail.com
  //   Admin123*
  Future<void> _saveUserData(OrderResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("email", _email.text.trim());
    await prefs.setString("password", _password.text.trim());
    await prefs.setString("jwt_token", response.data!.jwtToken!);
    await prefs.setString("first_name", response.data!.driver!.firstName!);
    await prefs.setString("driver_code", response.data!.driver!.driverCode!);
    await prefs.setBool("active", response.data!.driver!.active!);
    await prefs.setString("status", response.data!.driver!.status!);
    await prefs.setString("id", response.data!.driver!.id.toString());
    await prefs.setString(
      "assigned_store_code",
      response.data!.driver!.assignedStoreCode!,
    );
    await prefs.setString(
      "barangay_code",
      response.data!.driver!.barangayCode!,
    );
    await prefs.setString("user_type", response.data!.driver!.userType!);
  }

  /// SHOW CUSTOM DIALOG
  void _showCustomDialog(String message, bool success) {
    showCustomDialog(
      context: context,
      title: success ? "Success" : "Unauthorized",
      message: message,
      icon: success ? Icons.check_circle_rounded : Icons.error_outline,
      color: success ? AppColors.primary : Colors.red,
      buttonText: "Okay!",
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  "Konek2Move",
                  style: const TextStyle(
                    fontSize: 36,
                    letterSpacing: 1,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          SlideTransition(
            position: _containerSlide,
            child: Container(
              height: size.height * 0.75,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 40,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome Back 👋",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Login now and get your deliveries on the go!",
                        style: TextStyle(color: Colors.black54, fontSize: 15),
                      ),
                      const SizedBox(height: 28),
                      CustomInputField(
                        required: true,
                        label: "Email Address",
                        hint: "Enter your email address",
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 20),
                      CustomInputField(
                        required: true,
                        label: "Password",
                        hint: "Enter your password",
                        controller: _password,
                        obscure: _obscure,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: _obscure
                            ? Icons.visibility_off
                            : Icons.visibility,
                        onSuffixTap: () => setState(() => _obscure = !_obscure),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              SlideFadeRoute(
                                page: const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _loading ? null : _login,
                          child: _loading
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
                                      "Signing in...",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: const TextStyle(color: Colors.black54),
                            children: [
                              TextSpan(
                                text: "Register now",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacement(
                                      context,
                                      SlideFadeRoute(
                                        page: const TermsAndConditionScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showBiometric) const SizedBox(height: 28),
                      if (_showBiometric)
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text("or"),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),
                      if (_showBiometric) const SizedBox(height: 12),
                      if (_showBiometric)
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _biometricLogin,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center, // center content
                              mainAxisSize:
                                  MainAxisSize.min, // shrink row to content
                              children: [
                                const Icon(Icons.fingerprint_rounded, size: 24),
                                const SizedBox(width: 5),
                                const Text(
                                  "Log in with Biometrics",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
