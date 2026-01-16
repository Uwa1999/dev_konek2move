import 'package:flutter/material.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/ui/login_page/login_screen.dart';
import 'package:konek2move/ui/main_screen.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:konek2move/widgets/custom_dialog.dart';
import 'package:konek2move/widgets/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:konek2move/utils/app_colors.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  bool _notificationsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? false;

    setState(() {
      _notificationsEnabled = enabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleNotifications(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enable);

    setState(() {
      _notificationsEnabled = enable;
    });

    showAppSnackBar(
      context,
      title: "Coming Soon",
      message: "This feature is currently under development. Stay tuned!",
      isSuccess: false,
      icon: Icons.info_outline_rounded,
    );
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
            "Notification Permission",
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "App Notifications",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Turn on notifications to stay updated on delivery requests, updates, and offers.",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 32),
                    NotificationSwitch(
                      isEnabled: _notificationsEnabled,
                      onToggle: _toggleNotifications,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class NotificationSwitch extends StatefulWidget {
  final bool isEnabled;
  final Future<void> Function(bool) onToggle;

  const NotificationSwitch({
    super.key,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  State<NotificationSwitch> createState() => _NotificationSwitchState();
}

class _NotificationSwitchState extends State<NotificationSwitch> {
  late bool _switchValue;

  @override
  void initState() {
    super.initState();
    _switchValue = widget.isEnabled;
  }

  @override
  void didUpdateWidget(covariant NotificationSwitch oldWidget) {
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
          const Icon(Icons.notifications, size: 32, color: AppColors.primary),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "App Notifications",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  "Receive alerts for updates and requests",
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          Switch(
            value: _switchValue,
            activeColor: AppColors.primary,
            onChanged: (val) async {
              await widget.onToggle(val);
              setState(() => _switchValue = val);
            },
          ),
        ],
      ),
    );
  }
}
