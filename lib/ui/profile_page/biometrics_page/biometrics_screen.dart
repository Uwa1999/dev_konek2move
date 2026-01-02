import 'package:flutter/material.dart';
import 'package:konek2move/widgets/custom_dialog.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:konek2move/ui/main_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';

class BiometricsScreen extends StatefulWidget {
  const BiometricsScreen({super.key});

  @override
  State<BiometricsScreen> createState() => _BiometricsScreenState();
}

class _BiometricsScreenState extends State<BiometricsScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

  bool _biometricsEnabled = false;
  bool _isSupported = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initBiometricStatus();
  }

  Future<void> _initBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometric_enabled') ?? false;

    final canCheck = await _auth.canCheckBiometrics;
    final available = await _auth.getAvailableBiometrics();

    setState(() {
      _biometricsEnabled = enabled;
      _isSupported = canCheck && available.isNotEmpty;
      _isLoading = false;
    });
  }

  // Returns true if toggle succeeded
  Future<bool> _toggleBiometrics(bool enable) async {
    final prefs = await SharedPreferences.getInstance();

    if (enable) {
      if (!_isSupported) {
        await showCustomDialog(
          context: context,
          title: "Biometrics Not Supported",
          message: "This device does not support biometric login.",
          icon: Icons.error_outline,
          color: Colors.redAccent,
          buttonText: "Okay!",
        );
        return false;
      }

      bool authenticated = false;
      try {
        authenticated = await _auth.authenticate(
          localizedReason: 'Confirm your identity to enable biometric login',
          biometricOnly: false,
        );
      } catch (e) {
        authenticated = false;
      }

      if (!authenticated) {
        await showCustomDialog(
          context: context,
          title: "Authentication Failed",
          message: "Biometric login remains disabled.",
          icon: Icons.error_outline,
          color: Colors.redAccent,
          buttonText: "Okay!",
        );
        return false;
      }

      await prefs.setBool('biometric_enabled', true);
      await showCustomDialog(
        context: context,
        title: "Biometrics Enabled",
        message:
            "You can now log in securely using your fingerprint or Face ID.",
        icon: Icons.fingerprint,
        color: AppColors.primary,
        buttonText: "Got it!",
      );

      return true;
    } else {
      // Disable without authentication
      await prefs.setBool('biometric_enabled', false);
      await showCustomDialog(
        context: context,
        title: "Biometrics Disabled",
        message: "Biometric login has been turned off for this device.",
        icon: Icons.lock_outline,
        color: AppColors.primary,
        buttonText: "Got it!",
      );
      return false; // return false because switch should turn off
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pushReplacement(
            context,
            SlideFadeRoute(page: const MainScreen(index: 3)),
          ),
        ),
        centerTitle: true,
        title: const Text(
          "Biometric Login",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Secure your account",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Use your fingerprint or Face ID for faster and more secure access to your account. Your biometric data is never stored on our servers.",
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  BiometricSwitch(
                    isEnabled: _biometricsEnabled,
                    isSupported: _isSupported,
                    onToggle: _toggleBiometrics,
                  ),
                  if (!_isSupported) ...[
                    const SizedBox(height: 16),
                    Text(
                      "Biometric authentication is not supported on this device.",
                      style: TextStyle(
                        color: Colors.red.shade400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class BiometricSwitch extends StatefulWidget {
  final bool isEnabled;
  final bool isSupported;
  final Future<bool> Function(bool) onToggle;

  const BiometricSwitch({
    super.key,
    required this.isEnabled,
    required this.isSupported,
    required this.onToggle,
  });

  @override
  State<BiometricSwitch> createState() => _BiometricSwitchState();
}

class _BiometricSwitchState extends State<BiometricSwitch> {
  late bool _switchValue;

  @override
  void initState() {
    super.initState();
    _switchValue = widget.isEnabled;
  }

  @override
  void didUpdateWidget(covariant BiometricSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnabled != widget.isEnabled) {
      _switchValue = widget.isEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint, size: 32, color: AppColors.primary),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Biometric Login",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  "Enable fingerprint or Face ID",
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: _switchValue,
            activeColor: AppColors.primary,
            onChanged: widget.isSupported
                ? (val) async {
                    bool success = await widget.onToggle(val);
                    setState(() => _switchValue = val && success);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
