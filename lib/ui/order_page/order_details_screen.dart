import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/services/model_services.dart';
import 'package:konek2move/ui/main_screen.dart';
import 'package:konek2move/ui/order_page/order_status_controller.dart';
import 'package:konek2move/ui/order_page/order_text_message_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:konek2move/widgets/custom_google_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'order_messages_screen.dart';
import 'dart:async';

class OrderDetailsScreen extends StatefulWidget {
  final OrderRecord order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late OrderStatusController controller;
  String _userType = '';
  int chatUnreadCount = 0;
  bool _isChatOpen = false;

  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    controller = OrderStatusController(
      order: widget.order,
      onStatusChanged: (_) => setState(() {}),
    );
    _loadUserType();
    _startSSE(); // start listening SSE immediately
  }

  @override
  void dispose() {
    controller.dispose();
    _notificationSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ---------------- SSE Chat Listener ----------------
  void _startSSE() {
    _notificationSubscription?.cancel();

    _notificationSubscription = ApiServices().listenNotifications().listen(
      (event) {
        final meta = event['data']?['meta'];
        if (meta == null) return;

        final topic = event['data']?['topic'] ?? '';
        if (!topic.startsWith('chat.new_message')) return;

        final chatIdFromSSE = meta['chat_id'];
        final chatId = widget.order.chat?.id;
        if (chatIdFromSSE != chatId) return;

        final recipientType = event['data']?['recipient_type'] ?? 'other';
        final senderType = (recipientType == _userType)
            ? (_userType == 'driver' ? 'customer' : 'driver')
            : recipientType;

        final attachmentUrl = (meta['attachment_url'] ?? "").isEmpty
            ? null
            : meta['attachment_url'];

        final newMsg = ChatMessage(
          id: meta['message_id'] ?? 0,
          message: meta['message'],
          senderType: senderType,
          senderCode: event['data']?['recipient_code'],
          attachmentUrl: attachmentUrl,
          messageType: meta['message_type'] ?? 'text',
          createdAt:
              DateTime.tryParse(event['data']?['created_at'] ?? '') ??
              DateTime.now(),
        );

        setState(() {
          if (!_isChatOpen) {
            chatUnreadCount += 1;

            // Play notification sound
            _audioPlayer.play(
              AssetSource('sounds/notification.mp3'),
              volume: 1.0,
            );
          }
        });
      },
      onError: (error) async {
        await Future.delayed(const Duration(seconds: 3));
        _startSSE();
      },
      cancelOnError: false,
    );
  }

  void _copyLocation(BuildContext context, String text) {
    if (text.trim().isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
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
                // pickupLabel: widget.order.pickupAddress!,
                // dropLabel: widget.order.deliveryAddress!,
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
                  SlideFadeRoute(page: MainScreen(index: 0)),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
            ),
          ),

          /// ---------- CHAT BUTTON WITH UNREAD COUNT ----------
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                final chatId = widget.order.chat?.id;
                final orderNo = widget.order.orderNo.toString();

                setState(() {
                  _isChatOpen = true;
                  chatUnreadCount = 0;
                });

                Navigator.push(
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                    ),
                  ),
                  if (chatUnreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            chatUnreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
                      const SizedBox(height: 8),

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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _safe(widget.order.pickupAddress),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _copyLocation(
                                          context,
                                          widget.order.pickupAddress ?? '',
                                        ),
                                        child: const Icon(
                                          Icons.copy,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _safe(widget.order.deliveryAddress),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _copyLocation(
                                          context,
                                          widget.order.deliveryAddress ?? '',
                                        ),
                                        child: const Icon(
                                          Icons.copy,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      controller.buildActionButton(context),

                      const SizedBox(height: 12),

                      _buildInfoSection(),

                      const SizedBox(height: 12),
                      _buildItemsSection(),
                    ],
                  ),
                ),
              );
            },
          ),

          /// ---------- FLOATING CALL & MESSAGE BAR ----------
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  /// CALL BUTTON
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _callNumber(_safe(widget.order.customer?.phone)),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: const Text(
                        "Call Customer",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// MESSAGE BUTTON
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          SlideFadeRoute(
                            page: OrderTextMessagesScreen(
                              name: widget.order.customer!.name,
                              contact: widget.order.driver!.phone.toString(),
                              orderNo: widget.order.orderNo.toString(),
                              amount: widget.order.totalAmount.toString(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.message_rounded, size: 18),
                      label: const Text(
                        "Text Message",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// --- Info Section ---
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _infoRow("ID", _safe(widget.order.customer?.id)),
          const SizedBox(height: 8),
          _infoRow("Supplier name", _safe(widget.order.supplierName)),
          const SizedBox(height: 8),
          _infoRow("Created", _formatDate(widget.order.createdAt)),
          const SizedBox(height: 8),
          _infoRow("Customer", _safe(widget.order.customer?.name)),
          const SizedBox(height: 8),
          _infoRow("Contact", _safe(widget.order.customer?.phone)),
        ],
      ),
    );
  }

  /// --- Items Section ---
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
        const SizedBox(height: 12),
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
