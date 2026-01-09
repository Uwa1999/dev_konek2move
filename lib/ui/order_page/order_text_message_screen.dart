import 'package:flutter/material.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/widgets/custom_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderTextMessagesScreen extends StatelessWidget {
  final String? name;
  final String? contact;
  final String? orderNo;
  final String? amount;

  const OrderTextMessagesScreen({
    super.key,
    this.name,
    this.contact,
    this.orderNo,
    this.amount,
  });

  List<Map<String, String>> getTemplates(
    String name,
    String orderNo,
    String? amount,
  ) {
    final totalAmount = amount != null && amount.isNotEmpty
        ? "₱$amount"
        : "N/A";

    return [
      {
        "title": "Natanggap ang Order ✅",
        "message":
            "Magandang araw, $name 👋\n\n"
            "Natanggap na namin ang iyong order.\n\n"
            "🧾 Order No: $orderNo\n"
            "💰 Kabuuang Halaga: $totalAmount\n\n"
            "Inihahanda na namin ang iyong mga item para sa delivery.\n\n"
            "Maraming salamat sa iyong tiwala.\n\n"
            "— OttoKonek Indogrosir",
      },
      {
        "title": "Nakuha na ang Order 🚚",
        "message":
            "Magandang araw, $name 👋\n\n"
            "Nakuha na ng aming rider ang iyong order.\n\n"
            "📦 Order No: $orderNo\n"
            "💰 Kabuuang Halaga: $totalAmount\n\n"
            "Ito ay ihahatid na sa iyong address sa lalong madaling panahon.\n\n"
            "Mangyaring panatilihing bukas ang iyong linya para sa update.\n\n"
            "— OttoKonek Indogrosir",
      },
      {
        "title": "Out for Delivery 🏠",
        "message":
            "Magandang araw, $name 👋\n\n"
            "Ang iyong order ay kasalukuyang nasa biyahe na papunta sa iyo.\n\n"
            "📦 Order No: $orderNo\n"
            "💰 Kabuuang Halaga: $totalAmount\n\n"
            "Siguraduhing may tatanggap ng package.\n\n"
            "Salamat sa iyong pasensya.\n\n"
            "— OttoKonek Indogrosir",
      },
      {
        "title": "Na-deliver na 🎉",
        "message":
            "Magandang araw, $name 👋\n\n"
            "Matagumpay nang naihatid ang iyong order.\n\n"
            "📦 Order No: $orderNo\n"
            "💰 Kabuuang Halaga: $totalAmount\n\n"
            "Umaasa kaming ikaw ay nasiyahan sa iyong order.\n"
            "Maraming salamat sa pagpili sa amin.\n\n"
            "— OttoKonek Indogrosir",
      },
    ];
  }

  Future<void> _sendSMS(
    String phone,
    String message,
    BuildContext context,
  ) async {
    try {
      final Uri smsUri = Uri(
        scheme: 'smsto',
        path: phone,
        queryParameters: {'body': message},
      );

      if (!await launchUrl(smsUri, mode: LaunchMode.externalApplication)) {
        _showErrorDialog(context);
      }
    } catch (e) {
      debugPrint("SMS Launch Error: $e");
      _showErrorDialog(context);
    }
  }

  void _showErrorDialog(BuildContext context) {
    showCustomDialog(
      context: context,
      title: "App Not Found",
      message: "We couldn't find a messaging app on this device to send SMS.",
      icon: Icons.error_outline,
      color: AppColors.secondaryRed,
      buttonText: "Okay!",
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerName = name ?? "Customer";
    final phoneNumber = contact ?? "";
    final orderNumber = orderNo ?? "N/A";

    final templates = getTemplates(customerName, orderNumber, amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Quick SMS",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          /// MESSAGE LIST
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              itemCount: templates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final template = templates[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE + ICON
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.message,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              template['title']!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // MESSAGE PREVIEW
                      Text(
                        template['message']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // SEND BUTTON
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: phoneNumber.isNotEmpty
                              ? () => _sendSMS(
                                  phoneNumber,
                                  template['message']!,
                                  context,
                                )
                              : null,
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text("Send SMS"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
