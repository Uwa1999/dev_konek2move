
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:konek2move/ui/profile_page/profile_screen.dart';
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

  late StreamSubscription<Position> _locationStream;

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
    try {
    } catch (_) {}
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
    ).listen((pos) {
    });
  }

  @override
  void dispose() {
    _locationStream.cancel();
    super.dispose();
  }

  // =============================================================
  // UI — no changes
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _HomeAppBar(firstName: firstName, status: status,),
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
            child: SlideTransition(
              position: offsetAnimation,
              child: child,
            ),
          );
        },
        child: SizedBox(
          key: ValueKey(_index),
          child: _pages[_index],
        ),
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
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String firstName;
  final String status;

   const _HomeAppBar({required this.firstName, required this.status});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);


  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: kToolbarHeight, // 🔥 lock height

      flexibleSpace: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
      ),

      titleSpacing: 16,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 🔥 keeps inside height
        children: [
          const CircleAvatar(
            radius: 20, // 🔥 22 → 20 fits the height exactly like OrderAppBar
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=12'),
          ),
          const SizedBox(width: 10),

          const Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 6),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, $firstName !",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                 Text(
                status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Stack(
            children: [
              const Icon(
                Icons.notifications_none,
                size: 24, // 🔥 26 → 24 matches default AppBar icon size
                color: AppColors.primary,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
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

  const _BottomNav({
    required this.currentIndex,
    required this.onChanged,
  });

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
                offset: Offset(0, -3),
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


