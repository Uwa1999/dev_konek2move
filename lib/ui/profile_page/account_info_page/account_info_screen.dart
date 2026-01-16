import 'package:flutter/material.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/ui/login_page/login_screen.dart';
import 'package:konek2move/widgets/custom_dialog.dart';
import 'package:konek2move/widgets/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:konek2move/ui/main_screen.dart';

class RiderPersonalInfoScreen extends StatefulWidget {
  const RiderPersonalInfoScreen({super.key});

  @override
  State<RiderPersonalInfoScreen> createState() =>
      _RiderPersonalInfoScreenState();
}

class _RiderPersonalInfoScreenState extends State<RiderPersonalInfoScreen> {
  String firstName = '';
  String fullName = '';
  String driverCode = '';
  String status = '';
  String assignedStoreCode = '';
  String barangayCode = '';
  String userType = '';
  bool active = false;

  @override
  void initState() {
    super.initState();
    _loadRiderInfo();
  }

  Future<void> _loadRiderInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('first_name') ?? '';
      fullName = prefs.getString('full_name') ?? '';
      driverCode = prefs.getString('driver_code') ?? '';
      status = prefs.getString('status') ?? '';
      assignedStoreCode = prefs.getString('assigned_store_code') ?? '';
      barangayCode = prefs.getString('barangay_code') ?? '';
      userType = prefs.getString('user_type') ?? '';
      active = prefs.getBool('active') ?? false;
    });
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.surface,
          centerTitle: true,
          title: const Text(
            "Personal Info",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
            ),
            onPressed: () => Navigator.pushReplacement(
              context,
              SlideFadeRoute(page: const MainScreen(index: 2)),
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
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ================= PROFILE HEADER =================
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    child: Image.asset("assets/images/konek2move-circle.png"),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    "( $userType )",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // ================= INFO CARD =================
            _buildInfoCard(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "This section shows your driver account information. "
                "Ensure your details are accurate so you can receive delivery requests without issues. "
                "Your personal data is secure and used only for account verification and delivery operations.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildInfoCard() {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.person_outline,
            label: "Full Name",
            value: fullName,
          ),
          _divider(),
          _buildInfoTile(
            icon: Icons.badge_outlined,
            label: "Driver Code",
            value: driverCode,
          ),
          _divider(),
          _buildInfoTile(
            icon: Icons.info_outline,
            label: "Status",
            value: status,
          ),
          _divider(),
          _buildInfoTile(
            icon: Icons.check_circle_outline,
            label: "Active",
            value: active ? "Yes" : "No",
          ),
          _divider(),
          _buildInfoTile(
            icon: Icons.storefront_outlined,
            label: "Assigned Store Code",
            value: assignedStoreCode,
          ),
          _divider(),
          _buildInfoTile(
            icon: Icons.location_city_outlined,
            label: "Barangay Code",
            value: barangayCode,
          ),
          _divider(),
          _buildInfoTile(
            icon: Icons.admin_panel_settings_outlined,
            label: "User Type",
            value: userType,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, thickness: 1, color: AppColors.border);
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14.5,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontSize: 14.5,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: null,
    );
  }
}
