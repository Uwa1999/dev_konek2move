import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/services/model_services.dart';
import 'package:konek2move/ui/order_page/order_details_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';

import 'custom_dialog.dart';
import 'custom_line.dart';
import 'custom_snackbar.dart';

class OrderCard extends StatefulWidget {
  final OrderRecord order;
  final Future<void> Function()? onRefresh;
  const OrderCard({super.key, required this.order, this.onRefresh});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isAccepting = false;

  /// Warmed location cache
  Position? _cachedLocation;
  bool _warming = false;

  @override
  void initState() {
    super.initState();
    _warmLocation();
  }

  /// Warm GPS to reduce location delay
  Future<void> _warmLocation() async {
    if (_warming) return;
    _warming = true;
    try {
      _cachedLocation = await _getCurrentLocation();
    } catch (_) {}
    _warming = false;
  }

  /// Background API sync with retry
  Future<void> _sendAcceptStatus(Position pos, {int retry = 2}) async {
    for (var i = 0; i <= retry; i++) {
      try {
        await ApiServices().updateStatus(
          orderId: widget.order.id!,
          status: "accepted",
          lat: "${pos.latitude}",
          lng: "${pos.longitude}",
        );
        return;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
  }

  Future<void> _refreshParent() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
  }

  /// Location fetcher
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services disabled");

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw Exception("Location permission denied");
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Location permission denied forever — enable in settings",
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void _copyLocation(BuildContext context, String text) {
    if (text.trim().isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));

    showAppSnackBar(
      context,
      title: 'Copied',
      message: 'Location copied to clipboard',
      isSuccess: true,
      icon: Icons.copy_rounded,
    );
  }

  // ---------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(widget.order.createdAt ?? "");
    final status = (widget.order.status ?? '').toLowerCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER -----------------------------------
          Row(
            children: [
              RichText(
                text: TextSpan(
                  text: 'Order No: ',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  children: [
                    TextSpan(
                      text: widget.order.orderNo ?? '',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.order.status.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          _infoRow('Supplier', widget.order.supplierName ?? ''),
          _infoRow(
            'Created',
            date == null
                ? '-'
                : DateFormat("MMM d, yyyy - h:mm a").format(date),
          ),
          _infoRow('Customer', widget.order.customer?.name ?? ''),
          _infoRow('Total Amount', '₱${widget.order.totalAmount ?? 0}'),
          const SizedBox(height: 18),
          // PICKUP & DROPOFF --------------------------
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    Expanded(
                      child: Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: CustomPaint(painter: DashedLinePainter()),
                      ),
                    ),
                    const Icon(Icons.flag, color: AppColors.primary, size: 20),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),

                      /// PICKUP
                      const Text(
                        'Pickup:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.order.supplierAddress ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _copyLocation(
                              context,
                              widget.order.supplierAddress ?? '',
                            ),
                            child: const Icon(
                              Icons.copy,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// DROP OFF
                      const Text(
                        'Drop off:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.order.deliveryAddress ?? '',
                              style: const TextStyle(
                                fontSize: 11,
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

          const SizedBox(height: 18),

          // ACTION BUTTONS ----------------------------
          if (status == 'assigned') ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            _buildRejectConfirmation(context, widget.order),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            _buildAcceptConfirmation(context, widget.order),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Accept Order',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]
          // WHEN ALREADY ACCEPTED OR DELIVERY PROGRESS
          else if (status == 'accepted' ||
              status == 'at_pickup' ||
              status == 'picked_up' ||
              status == 'en_route') ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    SlideFadeRoute(
                      page: OrderDetailsScreen(order: widget.order),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                ),
                child: const Text(
                  'Order Details',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ACCEPT MODAL -----------------------------------------------------
  Widget _buildAcceptConfirmation(BuildContext context, OrderRecord order) {
    final total = order.totalAmount ?? 0;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.38,
          minChildSize: 0.32,
          maxChildSize: 0.52,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    /// ── Drag Handle ──
                    Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),

                    /// ── Scrollable Content ──
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Confirm order acceptance",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),

                            const Text(
                              "By accepting, you're agreeing to pick up and deliver this order.",
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),

                            const SizedBox(height: 16),

                            /// ── Order Info Card ──
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _rowInfo("Order No", order.orderNo ?? "-"),
                                  const SizedBox(height: 6),
                                  _rowInfo(
                                    "Customer",
                                    order.customer?.name ?? "-",
                                  ),
                                  const SizedBox(height: 6),
                                  _rowInfo(
                                    "Total Amount",
                                    "₱$total",
                                    bold: true,
                                    highlight: true,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    /// ── Sticky Action Buttons ──
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: AppColors.textSecondary.withOpacity(.35),
                              ),
                              foregroundColor: AppColors.textSecondary,
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isAccepting
                                ? null
                                : () async {
                                    setModalState(() => _isAccepting = true);

                                    try {
                                      final pos =
                                          _cachedLocation ??
                                          await _getCurrentLocation();
                                      final updatedOrder = widget.order
                                          .copyWith(status: "accepted");

                                      if (!mounted) return;

                                      Navigator.pop(context);

                                      showAppSnackBar(
                                        context,
                                        title: "Order Accepted",
                                        message:
                                            "The order has been successfully accepted.",
                                        isSuccess: true,
                                        icon: Icons.check_circle_rounded,
                                      );

                                      Navigator.pushReplacement(
                                        context,
                                        SlideFadeRoute(
                                          page: OrderDetailsScreen(
                                            order: updatedOrder,
                                          ),
                                        ),
                                      );

                                      unawaited(_sendAcceptStatus(pos));
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text("$e")),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setModalState(
                                          () => _isAccepting = false,
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isAccepting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    "Accept Order",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // REJECT MODEL ------------------------------------------------------
  Widget _buildRejectConfirmation(BuildContext context, OrderRecord order) {
    String reason = "";
    bool isRejecting = false;

    return StatefulBuilder(
      builder: (context, setModalState) {
        // Detect if the keyboard is open
        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

        return DraggableScrollableSheet(
          // Expand sheet when keyboard shows
          initialChildSize: isKeyboardOpen ? 0.65 : 0.40,
          minChildSize: 0.32,
          maxChildSize: isKeyboardOpen ? 0.85 : 0.65,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    /// ── Drag Handle ──
                    Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withOpacity(.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),

                    /// ── Scrollable Content ──
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Reject this order?",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Please provide a short reason why you're rejecting this order.",
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 18),

                            /// ── Reason Input ──
                            TextField(
                              maxLines: 3,
                              onChanged: (value) => reason = value,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText: "Reason for rejection...",
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                contentPadding: const EdgeInsets.all(16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(14),
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    /// ── Sticky Buttons (DO NOT MOVE) ──
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: AppColors.textSecondary.withOpacity(.35),
                              ),
                              foregroundColor: AppColors.textSecondary,
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isRejecting
                                ? null
                                : () async {
                                    if (reason.trim().isEmpty) return;

                                    showCustomDialog(
                                      context: context,
                                      title: "Reject this order?",
                                      message:
                                          "Are you sure? This action cannot be undone.",
                                      icon: Icons.warning_rounded,
                                      color: Colors.red,
                                      buttonText: "Confirm Rejection",
                                      onButtonPressed: () async {
                                        setModalState(() => isRejecting = true);
                                        try {
                                          final response = await ApiServices()
                                              .refuseOrder(
                                                orderId: order.id!,
                                                reason: reason.trim(),
                                              );

                                          if (!mounted) return;
                                          Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pop();
                                          Navigator.pop(context);

                                          setModalState(
                                            () => isRejecting = false,
                                          );

                                          showAppSnackBar(
                                            context,
                                            title: response.retCode == "200"
                                                ? "Order Rejected"
                                                : "Action Failed",
                                            message:
                                                response.message ??
                                                "Something went wrong",
                                            isSuccess:
                                                response.retCode == "200",
                                            icon: response.retCode == "200"
                                                ? Icons.check_circle_rounded
                                                : Icons.error_rounded,
                                          );

                                          if (response.retCode == "200") {
                                            await _refreshParent();
                                          }
                                        } catch (_) {
                                          if (!mounted) return;
                                          Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          ).pop();
                                          setModalState(
                                            () => isRejecting = false,
                                          );

                                          showAppSnackBar(
                                            context,
                                            title: "Something went wrong",
                                            message:
                                                "We couldn’t complete your request.",
                                            isSuccess: false,
                                            icon: Icons.error_outline_rounded,
                                          );
                                        }
                                      },
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Reject Order",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //--------------- HELPERS --------------------

  /// Row used inside the card (top part)
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Row used in accept modal
  Widget _rowInfo(
    String label,
    String value, {
    bool bold = false,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
