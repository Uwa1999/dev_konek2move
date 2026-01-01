// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:konek2move/services/api_services.dart';
// import 'package:konek2move/services/model_services.dart';
// import 'package:konek2move/ui/order_page/order_pod_screen.dart';
// import 'package:konek2move/utils/app_colors.dart';
// import 'package:konek2move/widgets/custom_dialog.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class OrderStatusController extends ChangeNotifier {
//   final OrderRecord order;
//   final Function(String) onStatusChanged;
//   static const double arrivalRadiusMeters = 100.0;
//
//   bool _isLoading = false;
//   String _currentStatus;
//
//   OrderStatusController({required this.order, required this.onStatusChanged})
//     : _currentStatus = order.status ?? "";
//
//   bool get isLoading => _isLoading;
//   String get status => _currentStatus;
//
//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
//
//   void _setStatus(String value) {
//     _currentStatus = value;
//     onStatusChanged(value); // update UI screen
//     notifyListeners(); // rebuild button
//   }
//
//   bool get hasValidCoordinates =>
//       order.pickupLat != null &&
//       order.pickupLng != null &&
//       order.deliveryLat != null &&
//       order.deliveryLng != null;
//
//   Future<Position> _getLocation() async {
//     bool enabled = await Geolocator.isLocationServiceEnabled();
//     if (!enabled) throw Exception("Location services disabled");
//
//     LocationPermission p = await Geolocator.checkPermission();
//     if (p == LocationPermission.denied) {
//       p = await Geolocator.requestPermission();
//       if (p == LocationPermission.denied) {
//         throw Exception("Location permission denied");
//       }
//     }
//     if (p == LocationPermission.deniedForever) {
//       throw Exception("Location permission permanently denied");
//     }
//
//     return await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//   }
//
//   Future<void> _updateStatus(BuildContext context, String newStatus) async {
//     _setLoading(true);
//
//     try {
//       final pos = await _getLocation();
//       final api = ApiServices();
//       final response = await api.updateStatus(
//         orderId: order.id!,
//         status: newStatus,
//         lat: pos.latitude.toString(),
//         lng: pos.longitude.toString(),
//       );
//
//       _setStatus(newStatus);
//
//       if (context.mounted && response.message != null) {
//         await showCustomDialog(
//           context: context,
//           title: "Status Updated",
//           message: response.message!,
//           icon: Icons.check_circle_rounded,
//           color: AppColors.primary,
//           buttonText: "OK",
//           onButtonPressed: null
//         );
//       }
//
//     } catch (e) {
//       if (context.mounted) {
//         await showCustomDialog(
//           context: context,
//           title: "Status Update Failed",
//           message: "Something went wrong.\n$e",
//           icon: Icons.warning_rounded,
//           color: AppColors.secondaryRed,
//           buttonText: "Retry",
//           onButtonPressed: () async {
//             Navigator.pop(context);
//             await _updateStatus(context, newStatus); // retry update
//           },
//         );
//       }
//
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//
//   Future<void> _navigate(String target) async {
//     _setLoading(true);
//     try {
//       double? lat = target == "pickup" ? order.pickupLat : order.deliveryLat;
//       double? lng = target == "pickup" ? order.pickupLng : order.deliveryLng;
//       final url = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
//
//       if (await canLaunchUrl(url)) {
//         await launchUrl(url, mode: LaunchMode.externalApplication);
//       }
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//
//
//   Future<void> _detectArrival(
//       BuildContext context,
//       String target,
//       String next,
//       ) async {
//     _setLoading(true);
//
//     try {
//       final pos = await _getLocation();
//
//       double tgtLat = target == "pickup"
//           ? order.pickupLat!
//           : order.deliveryLat!;
//       double tgtLng = target == "pickup"
//           ? order.pickupLng!
//           : order.deliveryLng!;
//
//       double dist = Geolocator.distanceBetween(
//         pos.latitude,
//         pos.longitude,
//         tgtLat,
//         tgtLng,
//       );
//
//       if (dist <= arrivalRadiusMeters) {
//         await _updateStatus(context, next);
//       } else {
//         // 🔥 <-- YOUR ADDED CUSTOM DIALOG HERE
//         if (context.mounted) {
//           await showCustomDialog(
//             context: context,
//             title: "Not Arrived Yet",
//             message:
//             "You are still more than $arrivalRadiusMeters meters away.\n\n"
//                 "Distance remaining: ${dist.toStringAsFixed(1)} meters",
//             icon: Icons.location_on_rounded,
//             color: AppColors.secondaryOrange,
//             buttonText: "Okay!",
//               onButtonPressed: null
//           );
//         }
//       }
//
//     } catch (e) {
//       if (context.mounted) {
//         await showCustomDialog(
//           context: context,
//           title: "Arrival Check Failed",
//           message: "$e",
//           icon: Icons.error_outline_rounded,
//           color: AppColors.secondaryRed,
//           buttonText: "Okay!",
//             onButtonPressed: null
//         );
//       }
//     } finally {
//       _setLoading(false);
//     }
//   }
//
//
//
//
//
//
//
//   /// ---------- BUTTON BUILDER ----------
//   Widget buildActionButton(BuildContext context) {
//     String label;
//     VoidCallback? callback;
//
//     switch (_currentStatus) {
//       case 'accepted':
//         label = "Navigate to Pickup Location";
//         callback = () async {
//           await _navigate("pickup");
//           await _detectArrival(context, "pickup", "at_pickup");
//         };
//         break;
//
//       case 'at_pickup':
//         label = "I Have Picked Up the Package";
//         callback = () => _updateStatus(context, "picked_up");
//         break;
//
//       case 'picked_up':
//         label = "Navigate to Drop-off Location";
//         callback = () async {
//           await _navigate("dropoff");
//           await _detectArrival(context, "dropoff", "en_route");
//         };
//         break;
//
//       case 'en_route':
//         label = "Mark Delivery Completed";
//         callback = () async {
//           final result = await showProofOfDeliveryBottomSheet(
//             context,
//             orderNo: order.orderNo!,
//             customerName: order.customer!.name!,
//           );
//
//           if (result == true) {
//             await _updateStatus(context, "delivered");
//           }
//         };
//         break;
//
//       case 'delivered':
//         return const SizedBox.shrink();
//         break;
//
//       default:
//         return const SizedBox.shrink();
//     }
//
//     return AnimatedBuilder(
//       animation: this,
//       builder: (_, _) => SizedBox(
//         width: double.infinity,
//         child: ElevatedButton(
//           onPressed: _isLoading ? null : callback,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.primary,
//             padding: const EdgeInsets.symmetric(vertical: 15),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(14),
//             ),
//             elevation: 0,
//           ),
//           child: _isLoading
//               ? const SizedBox(
//                   width: 22,
//                   height: 22,
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 2.8,
//                   ),
//                 )
//               : Text(
//                   label,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w700,
//                     color: Colors.white,
//                   ),
//                 ),
//         ),
//       ),
//     );
//   }
//
// }
//
//
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/services/model_services.dart';
import 'package:konek2move/ui/order_page/order_pod_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/widgets/custom_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderStatusController extends ChangeNotifier {
  final OrderRecord order;
  final Function(String) onStatusChanged;
  static const double arrivalRadiusMeters = 100.0;

  bool _isLoading = false;
  String _currentStatus;
  StreamSubscription<Position>? _positionStream;

  OrderStatusController({
    required this.order,
    required this.onStatusChanged,
  }) : _currentStatus = order.status ?? "";

  bool get isLoading => _isLoading;
  String get status => _currentStatus;

  // IMPORTANT: Prevent memory leaks
  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setStatus(String value) {
    _currentStatus = value;
    onStatusChanged(value);
    notifyListeners();
  }

  bool get hasValidCoordinates =>
      order.pickupLat != null &&
          order.pickupLng != null &&
          order.deliveryLat != null &&
          order.deliveryLng != null;

  Future<Position?> _getLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw "Location services are disabled.";

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied) throw "Location permission denied.";
    }
    if (p == LocationPermission.deniedForever) {
      throw "Location permissions are permanently denied.";
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> updateStatus(BuildContext context, String newStatus) async {
    _setLoading(true);

    try {
      final pos = await _getLocation();
      if (pos == null) return;

      final api = ApiServices();
      final response = await api.updateStatus(
        orderId: order.id!,
        status: newStatus,
        lat: pos.latitude.toString(),
        lng: pos.longitude.toString(),
      );

      _setStatus(newStatus);

      if (context.mounted && response.message != null) {
        await showCustomDialog(
          context: context,
          title: "Success",
          message: response.message!,
          icon: Icons.check_circle_rounded,
          color: AppColors.primary,
          buttonText: "OK",
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showCustomDialog(
          context: context,
          title: "Update Failed",
          message: e.toString(),
          icon: Icons.warning_rounded,
          color: AppColors.secondaryRed,
          buttonText: "Close",
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _navigate(String target) async {
    double? lat = target == "pickup" ? order.pickupLat : order.deliveryLat;
    double? lng = target == "pickup" ? order.pickupLng : order.deliveryLng;
    if (lat == null || lng == null) return;

    final Uri uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void startArrivalMonitoring(BuildContext context, String target, String nextStatus) {
    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position pos) async {
      final tgtLat = target == "pickup" ? order.pickupLat : order.deliveryLat;
      final tgtLng = target == "pickup" ? order.pickupLng : order.deliveryLng;

      if (tgtLat == null || tgtLng == null) return;

      final dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, tgtLat, tgtLng);

      if (dist <= arrivalRadiusMeters) {
        _positionStream?.cancel();
        _positionStream = null;
        if (context.mounted) {
          await updateStatus(context, nextStatus);
        }
      }
    });
  }

  void stopArrivalMonitoring() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Production Ready Button Widget
  Widget buildActionButton(BuildContext context) {
    return ListenableBuilder(
      listenable: this,
      builder: (context, _) {
        String label = "";
        VoidCallback? callback;

        switch (_currentStatus) {
          case 'accepted':
            label = "Navigate to Pickup";
            callback = () {
              _navigate("pickup");
              startArrivalMonitoring(context, "pickup", "at_pickup");
            };
            break;
          case 'at_pickup':
            label = "I Have Picked Up the Package";
            callback = () {
              stopArrivalMonitoring();
              updateStatus(context, "picked_up");
            };
            break;
          case 'picked_up':
            label = "Navigate to Drop-off";
            callback = () {
              _navigate("dropoff");
              startArrivalMonitoring(context, "dropoff", "en_route");
            };
            break;
          case 'en_route':
            label = "Mark Delivery Completed";
            callback = () async {
              stopArrivalMonitoring();
              final result = await showProofOfDeliveryBottomSheet(
                context,
                orderNo: order.orderNo!,
                customerName: order.customer!.name!,
              );
              if (result == true && context.mounted) {
                await updateStatus(context, "delivered");
              }
            };
            break;
          default:
            return const SizedBox.shrink();
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : callback,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        );
      },
    );
  }
}