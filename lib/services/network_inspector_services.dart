// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:konek2move/utils/internet_connection.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// // --- 1. DATA MODEL ---
// class NetworkLog {
//   final String url, method;
//   final int? statusCode;
//   final dynamic requestBody, responseBody;
//   final Map<String, String> requestHeaders;
//   final Map<String, String> responseHeaders;
//   final DateTime timestamp;
//
//   NetworkLog({
//     required this.url,
//     required this.method,
//     this.statusCode,
//     this.requestBody,
//     this.responseBody,
//     required this.requestHeaders,
//     required this.responseHeaders,
//     required this.timestamp,
//   });
// }
//
// // --- 2. NOTIFICATION SERVICE ---
//
// class NetworkNotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//
//   // Initialize notifications
//   static Future<void> init() async {
//     // --- 1. Android initialization ---
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     // --- 2. iOS/macOS initialization ---
//     const darwinInit = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     // --- 3. Initialize the plugin ---
//     await _notificationsPlugin.initialize(
//       const InitializationSettings(android: androidInit, iOS: darwinInit),
//       onDidReceiveNotificationResponse: (details) {
//         navigatorKey.currentState?.push(
//           MaterialPageRoute(builder: (_) => const LogHistoryScreen()),
//         );
//       },
//     );
//
//     // --- 4. Request notification permission on Android 13+ ---
//     if (await Permission.notification.isDenied) {
//       await Permission.notification.request();
//     }
//   }
//
//   static Future<void> showNotification({
//     required int id,
//     required String title,
//     required String body,
//   }) async {
//     const androidDetails = AndroidNotificationDetails(
//       'network_inspector',
//       'Network Inspector',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//     const iosDetails = DarwinNotificationDetails();
//     await _notificationsPlugin.show(
//       id,
//       title,
//       body,
//       const NotificationDetails(android: androidDetails, iOS: iosDetails),
//     );
//   }
// }
//
// // --- 3. THE LOG STORAGE ---
// class InspectorController {
//   static final List<NetworkLog> logs = [];
//
//   static void addLog(NetworkLog log) {
//     logs.insert(0, log);
//     NetworkNotificationService.showNotification(
//       id: DateTime.now().millisecond,
//       title: "HTTP ${log.statusCode}: ${log.method}",
//       body: log.url,
//     );
//   }
// }
//
// // --- 4. LOG HISTORY & DETAIL SCREENS ---
// class LogHistoryScreen extends StatefulWidget {
//   const LogHistoryScreen({super.key});
//   @override
//   State<LogHistoryScreen> createState() => _LogHistoryScreenState();
// }
//
// class _LogHistoryScreenState extends State<LogHistoryScreen> {
//   @override
//   Widget build(BuildContext context) {
//     final logs = InspectorController.logs;
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Network History"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.delete_sweep),
//             onPressed: () => setState(() => logs.clear()),
//           ),
//         ],
//       ),
//       body: logs.isEmpty
//           ? const Center(child: Text("No logs captured."))
//           : ListView.separated(
//               itemCount: logs.length,
//               separatorBuilder: (_, __) => const Divider(height: 1),
//               itemBuilder: (context, index) {
//                 final log = logs[index];
//                 final isError = (log.statusCode ?? 0) >= 400;
//                 return ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: isError
//                         ? Colors.red[100]
//                         : Colors.green[100],
//                     child: Text(
//                       "${log.statusCode ?? '??'}",
//                       style: TextStyle(
//                         color: isError ? Colors.red : Colors.green,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   title: Text(
//                     "${log.method} ${log.url}",
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   subtitle: Text(log.timestamp.toString().split('.').first),
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => LogDetailScreen(log: log),
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
//
// class LogDetailScreen extends StatelessWidget {
//   final NetworkLog log;
//   const LogDetailScreen({super.key, required this.log});
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 3,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text("${log.method} [${log.statusCode}]"),
//           bottom: const TabBar(
//             tabs: [
//               Tab(text: "INFO"),
//               Tab(text: "HEADERS"),
//               Tab(text: "BODY"),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             _buildList([
//               _tile("URL", log.url),
//               _tile("Method", log.method),
//               _tile("Status", log.statusCode.toString()),
//               _tile("Time", log.timestamp.toString()),
//             ]),
//             _buildList([
//               const Text(
//                 "REQUEST HEADERS",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               ...log.requestHeaders.entries.map((e) => _tile(e.key, e.value)),
//               const Divider(),
//               const Text(
//                 "RESPONSE HEADERS",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               ...log.responseHeaders.entries.map((e) => _tile(e.key, e.value)),
//             ]),
//             _buildList([
//               const Text(
//                 "REQUEST BODY",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               _codeBox(log.requestBody.toString()),
//               const SizedBox(height: 20),
//               const Text(
//                 "RESPONSE BODY",
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               _codeBox(log.responseBody.toString()),
//             ]),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildList(List<Widget> children) =>
//       ListView(padding: const EdgeInsets.all(16), children: children);
//   Widget _tile(String k, String v) => Padding(
//     padding: const EdgeInsets.symmetric(vertical: 4),
//     child: Text("$k: $v", style: const TextStyle(fontSize: 13)),
//   );
//   Widget _codeBox(String text) => Container(
//     padding: const EdgeInsets.all(8),
//     color: Colors.grey[200],
//     child: SelectableText(
//       text,
//       style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
//     ),
//   );
// }
