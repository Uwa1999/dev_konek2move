import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:konek2move/services/model_services.dart';
import 'package:konek2move/ui/main_screen.dart';
import 'package:konek2move/ui/order_page/order_status_controller.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:konek2move/widgets/custom_google_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'order_messages_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderRecord order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late OrderStatusController controller;
  String _userType = '';

  @override
  void initState() {
    super.initState();
    controller = OrderStatusController(
      order: widget.order,
      onStatusChanged: (_) => setState(() {}),
    );
    _loadUserType();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _safe(value) => (value == null || value.toString().trim().isEmpty)
      ? "-"
      : value.toString();

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return "-";
    final dt = DateTime.tryParse(raw);
    if (dt == null) return "-";
    return DateFormat("MMM d, yyyy - h:mm a").format(dt);
  }

  Future<void> _callNumber(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Dialer failed: $e');
    }
  }

  Future<void> _loadUserType() async {
    final prefs = await SharedPreferences.getInstance();
    _userType = prefs.getString("user_type") ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final mapHeight = MediaQuery.of(context).size.height * 0.42;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// ---------- MAP ----------
          if (controller.hasValidCoordinates)
            SizedBox(
              height: mapHeight,
              width: double.infinity,
              child: StaticOrderMap(
                pickupLat: widget.order.pickupLat!,
                pickupLng: widget.order.pickupLng!,
                dropLat: widget.order.deliveryLat!,
                dropLng: widget.order.deliveryLng!,
              ),
            ),

          /// ---------- BACK BUTTON ----------
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  SlideFadeRoute(page: MainScreen(index: 1)),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15), // shadow color
                      blurRadius: 8, // softness
                      offset: const Offset(0, 3), // position of shadow
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
            ),
          ),

          /// ---------- BOTTOM DETAILS SHEET ----------
          DraggableScrollableSheet(
            initialChildSize: 0.60,
            minChildSize: 0.60,
            maxChildSize: 0.95,
            snap: true,
            snapSizes: const [0.60, 0.95],
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 5,
                          margin: const EdgeInsets.only(top: 6, bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withOpacity(.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),

                      /// ---------- TITLE ----------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Order Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              // _safe(currentStatus),
                              _safe(controller.status),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// ---------- LOCATION UI ----------
                      const Text(
                        "Location",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 14),

                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: CustomPaint(
                                      painter: _DashedLinePainter(),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.flag,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Pick up:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _safe(widget.order.pickupAddress),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "Drop off:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _safe(widget.order.deliveryAddress),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// =========================================================
                      /// 🚚 **ACTION BUTTON CONTROLLED BY OrderStatusController**
                      /// =========================================================
                      controller.buildActionButton(context),

                      const SizedBox(height: 20),

                      /// --- MORE INFO BELOW ---
                      _buildInfoSection(),

                      const SizedBox(height: 24),
                      _buildItemsSection(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// --- Info Section (unchanged) ---
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _infoRow("Created", _formatDate(widget.order.createdAt)),
          const SizedBox(height: 8),
          _infoRow("Customer", _safe(widget.order.customer?.name)),
          const SizedBox(height: 8),
          _infoRow("Contact", _safe(widget.order.customer?.phone)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Call Button
              Expanded(
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      _callNumber(_safe(widget.order.customer?.phone));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.call_rounded, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Call Customer',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16), // spacing between buttons
              // Message Button
              Expanded(
                child: Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      final chatId = widget.order.chat?.id;
                      final orderNo = widget.order.orderNo.toString();

                      Navigator.pushReplacement(
                        context,
                        SlideFadeRoute(
                          page: OrderMessagesScreen(
                            chatId: chatId,
                            currentUserType: _userType,
                            orderNo: orderNo,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.message_rounded, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Message',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
        ],
      ),
    );
  }

  /// --- Items Section (unchanged) ---
  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Item Summary",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 14),
        _itemPrice("Item Count", _safe(widget.order.itemsCount)),
        const Divider(height: 32),
        _itemPrice(
          "Total Amount",
          "₱${_safe(widget.order.totalAmount)}",
          bold: true,
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _itemPrice(String label, String price, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/* ===================================================================
   DASHED LINE PAINTER
=================================================================== */
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 0;

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.2;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
