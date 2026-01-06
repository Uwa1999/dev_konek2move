import 'dart:async';
import 'package:flutter/material.dart';

import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/services/model_services.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/widgets/custom_card.dart';
import 'package:shimmer/shimmer.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  // =====================================================
  // SEARCH & FILTER CORE
  // =====================================================
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _searchDebounce;

  List<OrderRecord> _orders = [];
  bool _loading = true;
  String? _selectedStatus;

  // avoid duplicate API calls
  String _lastQuery = "";
  String? _lastStatus;

  final List<String> _allStatuses = [
    "assigned",
    "accepted",
    "at_pickup",
    "picked_up",
    "en_route",
    "failed",
    "delivered",
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();

    // 🔎 Live search
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // =====================================================
  // SEARCH HANDLER (debounce)
  // =====================================================
  void _onSearchChanged() {
    setState(() {}); // refresh clear icon

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchOrders();
    });
  }

  // =====================================================
  // FETCH ORDERS — production style
  // =====================================================
  Future<void> _fetchOrders({bool force = false}) async {
    final query = _searchCtrl.text.trim();
    final status = _selectedStatus ?? "";

    // no duplicate calls
    if (!force && query == _lastQuery && status == _lastStatus) return;

    _lastQuery = query;
    _lastStatus = status;

    if (mounted) setState(() => _loading = true);

    try {
      final res = await ApiServices().getOrder(orderNo: query, status: status);

      if (!mounted) return;
      setState(() => _orders = res.data?.records ?? []);
    } catch (e) {
      debugPrint("ORDER ERROR: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onStatusSelect(String? status) {
    setState(() => _selectedStatus = status);
    _fetchOrders(force: true);
  }

  Future<void> _reload() async => _fetchOrders(force: true);

  // 🔹 format status display
  String _capitalize(String status) {
    return status
        .replaceAll("_", " ")
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(" ");
  }

  // =====================================================
  // FILTER BOTTOM SHEET
  // =====================================================
  void _showStatusFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Filter by Status",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _statusTile("All", null),
                ..._allStatuses.map((s) => _statusTile(_capitalize(s), s)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusTile(String label, String? value) {
    final bool selected = _selectedStatus == value;

    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () {
        Navigator.pop(context);
        _onStatusSelect(value);
      },
    );
  }

  // =====================================================
  // SEARCH BAR UI
  // =====================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: AnimatedBuilder(
        animation: _searchFocus,
        builder: (_, _) {
          final isFocused = _searchFocus.hasFocus;

          return Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFocused ? AppColors.primary : Colors.grey.shade300,
                width: isFocused ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: isFocused ? AppColors.primary : Colors.grey,
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    decoration: const InputDecoration(
                      hintText: "Search order no...",
                      border: InputBorder.none,
                    ),
                  ),
                ),

                if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() {});
                      _fetchOrders(force: true);
                    },
                    child: const Icon(Icons.close, color: Colors.red),
                  ),

                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _showStatusFilterSheet,
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: _selectedStatus == null
                        ? Colors.grey.shade600
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // SHIMMER PLACEHOLDER
  // =====================================================
  List<Widget> _buildShimmer() {
    return List.generate(
      4,
      (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Row(
                children: [
                  _shimmerItem(width: 160, height: 16), // Order No
                  const Spacer(),
                  _shimmerItem(
                    width: 60,
                    height: 26,
                    radius: 20,
                  ), // Details btn
                ],
              ),

              const SizedBox(height: 14),

              // ===== INFO ROWS =====
              _shimmerRow(widthLeft: 70, widthRight: 120),
              const SizedBox(height: 6),
              _shimmerRow(widthLeft: 100, widthRight: 140),
              const SizedBox(height: 6),
              _shimmerRow(widthLeft: 60, widthRight: 160),

              const SizedBox(height: 18),

              // ===== PICKUP & DROPOFF =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        _circleShimmer(20),
                        const SizedBox(height: 5),
                        _shimmerItem(width: 2, height: 28, radius: 2),
                        const SizedBox(height: 5),
                        _circleShimmer(20),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerItem(width: double.infinity, height: 16),
                        const SizedBox(height: 6),
                        _shimmerItem(width: double.infinity, height: 12),
                        const SizedBox(height: 16),
                        _shimmerItem(width: 75, height: 14),
                        const SizedBox(height: 6),
                        _shimmerItem(width: double.infinity, height: 12),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ===== ACTION BUTTONS =====
              Row(
                children: [
                  Expanded(child: _shimmerItem(height: 42, radius: 14)),
                  const SizedBox(width: 14),
                  Expanded(child: _shimmerItem(height: 42, radius: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerItem({
    double width = double.infinity,
    double height = 20,
    double radius = 12,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  /// shimmer circle (for icons)
  Widget _circleShimmer(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _shimmerRow({required double widthLeft, required double widthRight}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _shimmerItem(width: widthLeft, height: 12),
        _shimmerItem(width: widthRight, height: 12),
      ],
    );
  }

  // =====================================================
  // UI — prevent bottom overflow
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            _buildSearchBar(),

            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _reload,
                child: _loading
                    ? ListView(
                        padding: const EdgeInsets.only(top: 10, bottom: 80),
                        children: _buildShimmer(),
                      )
                    : _orders.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height:
                                MediaQuery.of(context).size.height *
                                0.65, // adaptive height
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                /// --- ILLUSTRATION / IMAGE PLACEHOLDER ---
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.inbox_rounded,
                                    size: 72,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 26),

                                /// --- TITLE ---
                                const Text(
                                  "No Orders Yet",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                /// --- SUBTITLE ---
                                const Text(
                                  "Your recent orders will show up here.\nCheck back later",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12 + 80),
                        // ^ padding bottom prevents overflow under NavBar
                        itemCount: _orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (_, index) => OrderCard(
                          order: _orders[index],
                          onRefresh: _reload,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
