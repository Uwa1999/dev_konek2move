import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/ui/notification_page/notification_screen.dart';
import 'package:konek2move/ui/profile_page/profile_screen.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page/home_screen.dart';
import 'order_page/order_screen.dart';

class MainScreen extends StatefulWidget {
  final int index;
  const MainScreen({super.key, this.index = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _index;
  String firstName = '';
  String status = '';
  int unreadCount = 0;

  late StreamSubscription<Position> _locationStream;
  StreamSubscription<Map<String, dynamic>>? _sseSubscription;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final _pages = const [
    HomeScreen(),
    OrderScreen(),
    Placeholder(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.index;
    _loadFirstName();
    fetchUnreadCount();
    _listenToNotifications();
    // 🚀 preload everything after UI renders — prevents lag on launch
    Future.microtask(() async {
      await _requestRequiredPermissions();
      await _warmUpGPS();
      _startLocationStream();
    });
  }

  // =============================================================
  // 🔔 toast helper
  // =============================================================
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString("first_name") ?? "";
    final stat = prefs.getString("status") ?? "";
    setState(() {
      firstName = name;
      status = stat;
    });
  }

  Future<void> fetchUnreadCount() async {
    try {
      final count = await ApiServices().getNotifUnreadCount();
      if (mounted) {
        setState(() => unreadCount = count);
      }
    } catch (e) {
      print("Error fetching unread count: $e");
    }
  }

  /// -------------------------------
  /// 🔔 SSE: listen for incoming notifications
  /// -------------------------------
  void _listenToNotifications() {
    _sseSubscription = ApiServices().listenNotifications().listen((event) {
      final meta = event['data'];
      if (meta == null) return;

      final recipientType = meta['recipient_type'];
      if (recipientType != 'driver') return;

      // Increment unread count
      if (mounted) {
        setState(() {
          unreadCount += 1;
        });
      }

      // Play notification sound
      _playNotificationSound();

      print("🟢 New notification received, unreadCount: $unreadCount");
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print("❌ Error playing sound: $e");
    }
  }
  // =============================================================
  // 🛑 your required permissions method (copy integrated)
  // =============================================================
  Future<void> _requestRequiredPermissions() async {
    // --- LOCATION PERMISSION ---
    LocationPermission locStatus = await Geolocator.checkPermission();

    if (locStatus == LocationPermission.denied ||
        locStatus == LocationPermission.deniedForever) {
      locStatus = await Geolocator.requestPermission();

      if (locStatus == LocationPermission.denied) {
        _toast("Location permission is required for delivery tracking");
      }
      if (locStatus == LocationPermission.deniedForever) {
        _toast("Location permanently denied. Allow it from app settings.");
      }
    }

    // --- CAMERA PERMISSION ---
    PermissionStatus camStatus = await Permission.camera.status;

    if (!camStatus.isGranted) {
      camStatus = await Permission.camera.request();

      if (!camStatus.isGranted) {
        _toast("Camera permission is needed to take proof of delivery photos");
      }
    }
  }

  // =============================================================
  // 🚀 warm GPS to make accept/reject instantly fast
  // =============================================================
  Future<void> _warmUpGPS() async {
    try {} catch (_) {}
  }

  // =============================================================
  // 📡 keep GPS warm in background while app is open
  // =============================================================
  void _startLocationStream() {
    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 50,
      ),
    ).listen((pos) {});
  }

  @override
  void dispose() {
    _locationStream.cancel();
    _sseSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // =============================================================
  // UI — no changes
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _HomeAppBar(firstName: firstName, status: status, unreadCount: unreadCount,),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offsetAnimation, child: child),
          );
        },
        child: SizedBox(key: ValueKey(_index), child: _pages[_index]),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

/* ============================================================
   HOME APP BAR
============================================================ */
class _HomeAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String firstName;
  final String status;
  final int unreadCount;

  const _HomeAppBar({
    super.key,
    required this.firstName,
    required this.status,
    required this.unreadCount,
  });

  @override
  State<_HomeAppBar> createState() => _HomeAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HomeAppBarState extends State<_HomeAppBar> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight,
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
      titleSpacing: 16,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=12'),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.location_on, color: AppColors.primary, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, ${widget.firstName} !",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () async {
            // Open notification screen
            await Navigator.push(
              context,
              SlideFadeRoute(page: const NotificationScreen()),
            );

            // Optionally refresh unread count when returning
            if (mounted) setState(() {});
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none,
                size: 24,
                color: AppColors.primary,
              ),
              if (widget.unreadCount > 0)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          padding: const EdgeInsets.only(right: 16),
          constraints: const BoxConstraints(),
        )
      ],
    );
  }
}

/* ============================================================
   BOTTOM NAVIGATION
============================================================ */
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _BottomNav({required this.currentIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 72, // slightly taller helps touch accuracy
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 10,
                offset: Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              _item(Icons.home_outlined, 'Home', 0),
              _item(Icons.local_shipping_outlined, 'Orders', 1),
              _item(Icons.pin_drop_outlined, 'Location', 2),
              _item(Icons.person_outline, 'Profile', 3),
            ],
          ),
        ),
        Container(height: bottomInset, color: AppColors.surface),
      ],
    );
  }

  Widget _item(IconData icon, String label, int index) {
    final active = currentIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 26,
                color: active
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(.35),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active
                      ? AppColors.primary
                      : AppColors.textSecondary.withOpacity(.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
