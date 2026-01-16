import 'package:flutter/material.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/ui/login_page/login_screen.dart';
import 'package:konek2move/ui/profile_page/account_info_page/account_info_screen.dart';
import 'package:konek2move/ui/profile_page/biometrics_page/biometrics_screen.dart';
import 'package:konek2move/ui/profile_page/change_password_page/change_password_screen.dart';
import 'package:konek2move/ui/profile_page/notification_page/notification_permission_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:konek2move/widgets/custom_dialog.dart';
import 'package:konek2move/widgets/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String email = '';

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString("first_name") ?? "Rider Name";
      email = prefs.getString("email") ?? "email@example.com";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPromoCard(),
          const SizedBox(height: 24),
          _buildSectionTitle("Account settings"),
          const SizedBox(height: 8),
          _buildSettingsCard(),
        ],
      ),
    );
  }

  // ================= PROMO CARD =================
  Widget _buildPromoCard() {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Boost your account",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Complete your profile to get more delivery requests.",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.trending_up, size: 36, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // ================= SECTION TITLE =================
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  // ================= SETTINGS CARD =================
  Widget _buildSettingsCard() {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.person_outlined,
            title: "Personal information",
            onTap: () {
              Navigator.pushReplacement(
                context,
                SlideFadeRoute(page: const RiderPersonalInfoScreen()),
              );
            },
          ),
          _divider(),
          _buildSettingsTile(
            icon: Icons.lock_outlined,
            title: "Change password",
            onTap: () {
              Navigator.pushReplacement(
                context,
                SlideFadeRoute(page: const ChangePasswordScreen()),
              );
            },
          ),
          _divider(),
          _buildSettingsTile(
            icon: Icons.notifications_none_outlined,
            title: "Notifications",
            onTap: () {
              Navigator.pushReplacement(
                context,
                SlideFadeRoute(page: const NotificationPermissionScreen()),
              );
            },
          ),
          _divider(),
          _buildSettingsTile(
            icon: Icons.fingerprint_outlined,
            title: "Biometrics",
            onTap: () {
              Navigator.pushReplacement(
                context,
                SlideFadeRoute(page: const BiometricsScreen()),
              );
            },
          ),
          _divider(),
          _buildSettingsTile(
            icon: Icons.help_outline_outlined,
            title: "Help & Support",
            onTap: () {
              showAppSnackBar(
                context,
                title: "Coming Soon",
                message:
                    "This feature is currently under development. Stay tuned!",
                isSuccess: false,
                icon: Icons.info_outline_rounded,
              );
            },
          ),
          _divider(),
          _buildSettingsTile(
            icon: Icons.logout_outlined,
            title: "Log out",
            isLogout: true,
            onTap: () async {
              bool isLoggingOut = false;

              showCustomDialog(
                context: context,
                title: "Logout?",
                message: "Are you sure you want to log out?",
                icon: Icons.logout_rounded,
                color: AppColors.secondaryRed,
                buttonText: "Confirm",
                cancelText: "Cancel",
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

                      // ✅ Mark user as logged out (CRITICAL)
                      await prefs.setBool("is_logged_in", false);

                      await prefs.setBool('logged_in_before', true);

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
            },
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.border);
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? AppColors.secondaryRed : AppColors.textPrimary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          color: isLogout ? AppColors.secondaryRed : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
