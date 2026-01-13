//
// import 'package:flutter/material.dart';
//
// /* ===================================================================
//    STATIC GOOGLE MAP WITH CUSTOM BUBBLE MARKERS
// =================================================================== */
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
//   // ---- Map URL with your light-style theme ----
//   String get _mapUrl {
//     const apiKey = "AIzaSyA4eJv1jVmJWrTdOO6SOsEGirFKueKRg98";
//     const size = "700x350";
//     const zoom = 15;
//
//     // road + light theme style
//     const style =
//         "style=feature:all%7Celement:geometry%7Ccolor:0xf5f5f5"
//         "&style=feature:road%7Celement:geometry%7Ccolor:0xffffff"
//         "&style=feature:poi%7Cvisibility:off"
//         "&style=feature:transit%7Cvisibility:off";
//
//     return "https://maps.googleapis.com/maps/api/staticmap?"
//         "size=$size&scale=2&zoom=$zoom"
//     // IMPORTANT: markers removed — we draw our own UI markers
//         "&center=$pickupLat,$pickupLng"
//         "&$style&key=$apiKey";
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(16),
//       child: SizedBox(
//         height: 250, // << same as your original design
//         width: double.infinity,
//         child: Stack(
//           children: [
//             // Map background
//             Positioned.fill(
//               child: Image.network(
//                 _mapUrl,
//                 fit: BoxFit.cover,
//               ),
//             ),
//
//             // Pickup marker
//             _buildMarkerBubble(
//               icon: Icons.storefront,
//               alignment: Alignment(-0.3, -0.2),
//             ),
//
//             // Dropoff marker
//             _buildMarkerBubble(
//               icon: Icons.account_circle,
//               alignment: Alignment(0.5, 0.4),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ---- Custom Marker Bubble ----
//   Widget _buildMarkerBubble({
//     required IconData icon,
//     required Alignment alignment,
//   }) {
//     return Align(
//       alignment: alignment,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 4,
//                   offset: Offset(0, 2),
//                 )
//               ],
//             ),
//             child: Icon(icon, color: Colors.black, size: 22),
//           ),
//           CustomPaint(
//             size: const Size(12, 6),
//             painter: TrianglePainter(),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /* Triangle Tail for Marker Bubble */
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
import 'package:flutter/material.dart';

/* ===================================================================
   STATIC GOOGLE MAP (NO PATH)
=================================================================== */
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
    const zoom = 14;
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
