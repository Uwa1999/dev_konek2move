import 'dart:io';

import 'package:flutter/material.dart';
import 'package:konek2move/services/provider_services.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:provider/provider.dart';

/// 🌍 GLOBAL NAVIGATOR KEY (REQUIRED FOR GLOBAL DIALOGS)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 🔔 DIALOG STATE TYPE (PREVENT DUPLICATES)
enum _InternetDialogType { none, noInternet, limited }

/// 🌐 INTERNET DIALOG LISTENER (PRODUCTION SAFE)
class InternetDialogListener extends StatefulWidget {
  final Widget child;

  const InternetDialogListener({super.key, required this.child});

  @override
  State<InternetDialogListener> createState() => _InternetDialogListenerState();
}

class _InternetDialogListenerState extends State<InternetDialogListener> {
  _InternetDialogType _activeDialog = _InternetDialogType.none;

  /// ❌ CLOSE ONLY DIALOG ROUTES
  void _closeInternetDialogs(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.popUntil((route) => route is! PopupRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (_, connectivity, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = navigatorKey.currentContext;
          if (ctx == null) return;

          /// ⛔ WAIT FOR UI + FIRST CHECK
          if (connectivity.isChecking || !connectivity.uiReady) return;

          // ==========================================================
          // ✅ INTERNET RESTORED
          // ==========================================================
          if (connectivity.hasRealInternet &&
              _activeDialog != _InternetDialogType.none) {
            _closeInternetDialogs(ctx);
            _activeDialog = _InternetDialogType.none;

            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text("Internet connected"),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.primary,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          // ==========================================================
          // 🔴 NO SIGNAL AT ALL
          // ==========================================================
          if (!connectivity.hasRealInternet &&
              connectivity.hasNoSignal &&
              _activeDialog != _InternetDialogType.noInternet) {
            _closeInternetDialogs(ctx);
            _activeDialog = _InternetDialogType.noInternet;

            showInternetDialog(
              context: ctx,
              title: "No Internet Connection",
              message: "Please turn on your mobile data or Wi-Fi to continue.",
              icon: Icons.wifi_off_rounded,
              color: AppColors.secondaryRed,
              buttonText: "Close App",
              onRetry: () async {
                exit(0);
              },
            );
            return;
          }

          // ==========================================================
          // 🟠 LIMITED INTERNET (ONLY AFTER EVER CONNECTED)
          // ==========================================================
          if (!connectivity.hasRealInternet &&
              connectivity.hasSignal &&
              connectivity.hasEverConnected && // 🔑 FINAL FIX
              _activeDialog != _InternetDialogType.limited) {
            _closeInternetDialogs(ctx);
            _activeDialog = _InternetDialogType.limited;

            showInternetDialog(
              context: ctx,
              title: "Limited Internet Access",
              message:
              "You're connected to a network, but the internet is currently unavailable.",
              icon: Icons.signal_wifi_connected_no_internet_4_rounded,
              color: AppColors.secondaryOrange,
              buttonText: "Retry",
              onRetry: () async {
                await ctx.read<ConnectivityProvider>().retryConnection();
              },
            );
          }
        });

        return widget.child;
      },
    );
  }

  Future<void> showInternetDialog({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required String buttonText,
    required Future<void> Function()? onRetry,
  }) async {
    bool dialogClosed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      useRootNavigator: true,
      builder: (dialogContext) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (_, setDialogState) {
            void safeSetState(VoidCallback fn) {
              if (!dialogClosed) {
                setDialogState(fn);
              }
            }

            return Dialog(
              elevation: 12,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ICON
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 42, color: color),
                    ),

                    const SizedBox(height: 18),

                    // TITLE
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // MESSAGE
                    Text(
                      isLoading
                          ? "Checking your internet connection..."
                          : message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.6,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                          if (onRetry == null) return;

                          safeSetState(() => isLoading = true);
                          await onRetry();
                          safeSetState(() => isLoading = false);
                        },
                        child: isLoading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => dialogClosed = true);
  }

}
