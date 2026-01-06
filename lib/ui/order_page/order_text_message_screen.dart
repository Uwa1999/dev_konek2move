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
        "title": "Order Received ✅",
        "message":
            "Hi $name,\n\nNatanggap na namin ang iyong order #$orderNo.\nTotal Amount: $totalAmount\nSalamat sa pagtitiwala sa Ottokonek!",
      },
      {
        "title": "Order Picked Up 🚚",
        "message":
            "Hi $name,\n\nAng iyong order #$orderNo ay nakuha na ng aming rider at handa nang ihatid sa iyo.\nTotal Amount: $totalAmount\nMaaari mong i-track ang delivery sa Ottokonek app.",
      },
      {
        "title": "Out for Delivery 🏠",
        "message":
            "Hi $name,\n\nAng iyong order #$orderNo ay kasalukuyang nasa ruta papunta sa iyo.\nTotal Amount: $totalAmount\nIhanda ang pagtanggap ng package.",
      },
      {
        "title": "Delivered 🎉",
        "message":
            "Hi $name,\n\nAng iyong order #$orderNo ay matagumpay nang naihatid.\nTotal Amount: $totalAmount\nSalamat sa paggamit ng Ottokonek! Sana ay nasiyahan ka sa aming serbisyo.",
      },
      {
        "title": "Exclusive Promo 🌟",
        "message":
            "Hi $name,\n\nMay espesyal na promo para sa iyo! Bisitahin ang Ottokonek app at samantalahin ang eksklusibong diskwento.",
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
      backgroundColor: Colors.white,
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
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final template = templates[index];
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              title: Text(
                template['title']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  template['message']!,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: const Icon(Icons.send, color: AppColors.primary),
              onTap: phoneNumber.isNotEmpty
                  ? () => _sendSMS(phoneNumber, template['message']!, context)
                  : null,
            ),
          );
        },
      ),
    );
  }
}
