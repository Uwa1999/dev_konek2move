import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/ui/register_page/input_email_screen.dart';
import 'package:konek2move/ui/register_page/register_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:konek2move/widgets/custom_dialog.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool isOtpComplete = false;
  bool isLoading = false;
  int currentIndex = 0;
  int _secondsRemaining = 300;
  Timer? _timer;

  String maskEmailAddress(String email) {
    if (!email.contains('@')) return email;

    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) return '$username@$domain';

    final prefix = username.substring(0, 2);
    final middleMasked = '*' * (username.length - 2);

    return '$prefix$middleMasked@$domain';
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length < 6) {
      _showDialogMessage(message: 'Please enter complete OTP', isError: true);
      return;
    }

    setState(() => isOtpComplete = false);

    try {
      final api = ApiServices();
      final response = await api.emailOTPVerification(otp);

      if (!mounted) return;

      if (response.retCode == '200') {
        _showDialogMessage(
          message: "OTP Verification Successful!",
          isError: false,
        );

        Navigator.pushReplacement(
          context,
          SlideFadeRoute(page: RegisterScreen(email: widget.email)),
        );
      } else {
        _showDialogMessage(message: response.message!, isError: true);
      }
    } catch (e) {
      if (!mounted) return;

      _showDialogMessage(message: 'Failed to verify OTP: $e', isError: true);
    } finally {
      setState(() {
        isOtpComplete = _otpControllers.every((c) => c.text.isNotEmpty);
      });
    }
  }

  /// --- CUSTOM DIALOG HANDLING ---
  void _showDialogMessage({required String message, bool isError = false}) {
    final color = isError ? Colors.redAccent : Colors.green;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    showCustomDialog(
      context: context,
      title: isError ? "Error" : "Success",
      message: message,
      icon: icon,
      color: color,
      buttonText: "Okay!",
    );
  }

  @override
  void initState() {
    super.initState();
    _startTimer();

    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          setState(() => currentIndex = i);
        }
      });
    }
  }

  void _startTimer() {
    _secondsRemaining = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _resendOTP() async {
    try {
      final ApiServices api = ApiServices();
      final response = await api.emailVerification(widget.email);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${response.message}')));
      _startTimer();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 48,
      height: 55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: currentIndex == index
                ? AppColors.primary
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            autofocus: index == 0,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            textAlign: TextAlign.center,
            // textAlignVertical:
            //     TextAlignVertical.center, // ⭐ Force vertical centering
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              // height: 1.0, // ⭐ Prevents shifting on some AMOLED screens
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero, // ⭐ Prevents top/bottom shifting
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }

              setState(() {
                isOtpComplete = _otpControllers.every((c) => c.text.isNotEmpty);
              });
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pushReplacement(
            context,
            SlideFadeRoute(page: const EmailScreen()),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "Email Verification Code",
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Enter the code we just sent to email",
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 6),

            Text(
              maskEmailAddress(widget.email),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _otpBox(i),
                ),
              ),
            ),

            const SizedBox(height: 24),

            _secondsRemaining == 0
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code?",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      TextButton(
                        onPressed: () => _resendOTP(),
                        child: const Text(
                          "Resend",
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  )
                : Text(
                    "Resend available in $_secondsRemaining seconds",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

            const SizedBox(height: 20),
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
              onPressed: isOtpComplete && !isLoading ? _verifyOtp : null,

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
