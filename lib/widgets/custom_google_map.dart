import 'package:flutter/material.dart';

/* ===================================================================
   STATIC GOOGLE MAP (NO PATH)
=================================================================== */
// class StaticOrderMap extends StatelessWidget {
//   final double pickupLat;
//   final double pickupLng;
//   final double dropLat;
//   final double dropLng;
//
//   const StaticOrderMap({
//     super.key,
//     required this.pickupLat,
//     required this.pickupLng,
//     required this.dropLat,
//     required this.dropLng,
//   });
//
//   String get _mapUrl {
//     const apiKey = "AIzaSyA4eJv1jVmJWrTdOO6SOsEGirFKueKRg98";
//     const size = "700x350";
//     const zoom = 12;
//
//     // Sample marker icons (free to use for testing)
//     const pickupIconUrl = "https://www.flaticon.com/free-icons/map-marker";
//     const dropIconUrl = "https://maps.google.com/mapfiles/ms/icons/red-dot.png";
//
//     // Alternative options:
//     // const pickupIconUrl = "https://maps.google.com/mapfiles/ms/icons/blue.png";
//     // const dropIconUrl = "https://maps.google.com/mapfiles/ms/icons/orange.png";
//     // const pickupIconUrl = "https://maps.google.com/mapfiles/ms/icons/purple.png";
//     // const dropIconUrl = "https://maps.google.com/mapfiles/ms/icons/yellow.png";
//
//     const style =
//         "style=feature:all%7Celement:geometry%7Ccolor:0xf6f6f6"
//         "&style=feature:administrative%7Celement:labels.text.fill%7Ccolor:0x6e6e6e"
//         "&style=feature:administrative%7Celement:geometry.stroke%7Ccolor:0xe0e0e0"
//         "&style=feature:road%7Celement:geometry%7Ccolor:0xffffff"
//         "&style=feature:road%7Celement:labels.text.fill%7Ccolor:0x8a8a8a"
//         "&style=feature:road%7Celement:labels%7Cvisibility:on"
//         "&style=feature:road.highway%7Celement:geometry%7Ccolor:0xfdfaf5"
//         "&style=feature:road.highway%7Celement:geometry.stroke%7Ccolor:0xcccccc"
//         "&style=feature:water%7Celement:geometry%7Ccolor:0xd7e8f8"
//         "&style=feature:poi%7Cvisibility:off"
//         "&style=feature:transit%7Cvisibility:off"
//         "&style=feature:landscape.man_made%7Celement:geometry%7Ccolor:0xf2f2f2";
//
//     final encodedPickupIcon = Uri.encodeComponent(pickupIconUrl);
//     final encodedDropIcon = Uri.encodeComponent(dropIconUrl);
//
//     return "https://maps.googleapis.com/maps/api/staticmap?"
//         "size=$size&scale=2&zoom=$zoom"
//         "&markers=icon:$encodedPickupIcon%7C$pickupLat,$pickupLng"
//         "&markers=icon:$encodedDropIcon%7C$dropLat,$dropLng"
//         "&$style&key=$apiKey";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Image.network(_mapUrl, fit: BoxFit.cover);
//   }
// }
class StaticOrderMap extends StatelessWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;

  const StaticOrderMap({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
  });

  String get _mapUrl {
    const apiKey = "AIzaSyA4eJv1jVmJWrTdOO6SOsEGirFKueKRg98";
    const size = "700x350";
    const zoom = 12;
    const pickupLabel = "P";
    const dropLabel = "D";

    const style =
        "style=feature:all%7Celement:geometry%7Ccolor:0xf6f6f6"
        "&style=feature:administrative%7Celement:labels.text.fill%7Ccolor:0x6e6e6e"
        "&style=feature:administrative%7Celement:geometry.stroke%7Ccolor:0xe0e0e0"
        "&style=feature:road%7Celement:geometry%7Ccolor:0xffffff"
        "&style=feature:road%7Celement:labels.text.fill%7Ccolor:0x8a8a8a"
        "&style=feature:road%7Celement:labels%7Cvisibility:on"
        "&style=feature:road.highway%7Celement:geometry%7Ccolor:0xfdfaf5"
        "&style=feature:road.highway%7Celement:geometry.stroke%7Ccolor:0xcccccc"
        "&style=feature:water%7Celement:geometry%7Ccolor:0xd7e8f8"
        "&style=feature:poi%7Cvisibility:off"
        "&style=feature:transit%7Cvisibility:off"
        "&style=feature:landscape.man_made%7Celement:geometry%7Ccolor:0xf2f2f2";

    return "https://maps.googleapis.com/maps/api/staticmap?"
        "size=$size&scale=2&zoom=$zoom"
        "&markers=color:red%7Clabel:$pickupLabel%7C$pickupLat,$pickupLng"
        "&markers=color:blue%7Clabel:$dropLabel%7C$dropLat,$dropLng"
        "&$style&key=$apiKey";
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(_mapUrl, fit: BoxFit.cover);
  }
}

///
// import 'package:flutter/material.dart';
// import 'dart:math' as math;
//
// class StaticOrderMap extends StatefulWidget {
//   final double pickupLat;
//   final double pickupLng;
//   final double dropLat;
//   final double dropLng;
//
//   const StaticOrderMap({
//     super.key,
//     required this.pickupLat,
//     required this.pickupLng,
//     required this.dropLat,
//     required this.dropLng,
//   });
//
//   @override
//   State<StaticOrderMap> createState() => _StaticOrderMapState();
// }
//
// class _StaticOrderMapState extends State<StaticOrderMap> {
//   String? _activeMarker; // "pickup" | "drop"
//
//   final double mapWidth = 700;
//   final double mapHeight = 350;
//   final String apiKey = "AIzaSyA4eJv1jVmJWrTdOO6SOsEGirFKueKRg98";
//
//   /// Calculates distance in km between two points using Haversine formula
//   double _distanceInKm(double lat1, double lng1, double lat2, double lng2) {
//     const earthRadius = 6371;
//     final dLat = _deg2rad(lat2 - lat1);
//     final dLng = _deg2rad(lng2 - lng1);
//     final a =
//         math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(_deg2rad(lat1)) *
//             math.cos(_deg2rad(lat2)) *
//             math.sin(dLng / 2) *
//             math.sin(dLng / 2);
//     final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
//     return earthRadius * c;
//   }
//
//   double _deg2rad(double deg) => deg * (math.pi / 180);
//
//   /// Auto zoom based on distance
//   int get _calculatedZoom {
//     final dist = _distanceInKm(
//       widget.pickupLat,
//       widget.pickupLng,
//       widget.dropLat,
//       widget.dropLng,
//     );
//
//     if (dist < 1) return 16;
//     if (dist < 5) return 14;
//     if (dist < 10) return 12;
//     if (dist < 20) return 10;
//     return 8;
//   }
//
//   /// Map center between pickup and dropoff
//   double get _centerLat => (widget.pickupLat + widget.dropLat) / 2;
//   double get _centerLng => (widget.pickupLng + widget.dropLng) / 2;
//
//   String get _mapUrl {
//     const style =
//         "style=feature:all%7Celement:geometry%7Ccolor:0xf6f6f6"
//         "&style=feature:administrative%7Celement:labels.text.fill%7Ccolor:0x6e6e6e"
//         "&style=feature:administrative%7Celement:geometry.stroke%7Ccolor:0xe0e0e0"
//         "&style=feature:road%7Celement:geometry%7Ccolor:0xffffff"
//         "&style=feature:road%7Celement:labels.text.fill%7Ccolor:0x8a8a8a"
//         "&style=feature:road%7Celement:labels%7Cvisibility:on"
//         "&style=feature:road.highway%7Celement:geometry%7Ccolor:0xfdfaf5"
//         "&style=feature:road.highway%7Celement:geometry.stroke%7Ccolor:0xcccccc"
//         "&style=feature:water%7Celement:geometry%7Ccolor:0xd7e8f8"
//         "&style=feature:poi%7Cvisibility:off"
//         "&style=feature:transit%7Cvisibility:off"
//         "&style=feature:landscape.man_made%7Celement:geometry%7Ccolor:0xf2f2f2";
//
//     return "https://maps.googleapis.com/maps/api/staticmap?"
//         "size=${mapWidth.toInt()}x${mapHeight.toInt()}&scale=2&zoom=$_calculatedZoom"
//         "&center=$_centerLat,$_centerLng"
//         "&$style&key=$apiKey";
//   }
//
//   /// Converts LatLng to Alignment based on map center and zoom
//   Alignment _latLngToAlignment(double lat, double lng) {
//     final latRad = lat * math.pi / 180;
//     final centerLatRad = _centerLat * math.pi / 180;
//
//     double x = (lng - _centerLng) * 256 * math.pow(2, _calculatedZoom) / 360;
//     double y =
//         (math.log(math.tan(math.pi / 4 + latRad / 2)) -
//             math.log(math.tan(math.pi / 4 + centerLatRad / 2))) *
//         256 *
//         math.pow(2, _calculatedZoom) /
//         (2 * math.pi);
//
//     double alignX = (x / mapWidth) * 2;
//     double alignY = (y / mapHeight) * 2;
//
//     return Alignment(alignX, alignY);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: SizedBox(
//         height: 250,
//         width: double.infinity,
//         child: Stack(
//           children: [
//             Positioned.fill(child: Image.network(_mapUrl, fit: BoxFit.cover)),
//
//             // Pickup marker
//             _buildMarker(
//               id: "pickup",
//               alignment: _latLngToAlignment(widget.pickupLat, widget.pickupLng),
//               icon: Icons.storefront,
//               title: "Pickup Location",
//               subtitle: "Merchant Store",
//             ),
//
//             // Dropoff marker
//             _buildMarker(
//               id: "drop",
//               alignment: _latLngToAlignment(widget.dropLat, widget.dropLng),
//               icon: Icons.person,
//               title: "Drop-off Location",
//               subtitle: "Customer Address",
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMarker({
//     required String id,
//     required Alignment alignment,
//     required IconData icon,
//     required String title,
//     required String subtitle,
//   }) {
//     final isActive = _activeMarker == id;
//
//     return Align(
//       alignment: alignment,
//       child: GestureDetector(
//         onTap: () {
//           setState(() {
//             _activeMarker = isActive ? null : id;
//           });
//         },
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (isActive) _buildInfoBubble(title: title, subtitle: subtitle),
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 4,
//                     offset: Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Icon(icon, size: 22, color: Colors.black),
//             ),
//             CustomPaint(size: const Size(12, 6), painter: TrianglePainter()),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoBubble({required String title, required String subtitle}) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: const [
//           BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             title,
//             style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             subtitle,
//             style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class TrianglePainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = Colors.white;
//     final path = Path()
//       ..moveTo(0, 0)
//       ..lineTo(size.width, 0)
//       ..lineTo(size.width / 2, size.height)
//       ..close();
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }
