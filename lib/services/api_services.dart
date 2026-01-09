import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dns_services.dart';
import 'model_services.dart';

class ApiServices {
  Future<void> markAllNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";

    final url = Uri.parse(
      '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/notification/mark-all-read',
    );
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
    } else {
      print(
        'Failed to mark notifications as read: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> markNotificationAsRead({required int notificationId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";
    final url = Uri.parse(
      '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/notification/view',
    );

    final body = json.encode({'notification_id': notificationId});

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
    } else {
      throw Exception(
        'Failed to mark notification as read: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<int> getNotifUnreadCount() async {
    try {
      final url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/notification/unread-count',
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token") ?? "";

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);

        // Check if data exists and has unread_count
        if (jsonBody['data'] != null &&
            jsonBody['data']['unread_count'] != null) {
          return jsonBody['data']['unread_count'] as int;
        } else {
          return 0;
        }
      } else {
        print(
          "getNotifUnreadCount: Unexpected status code ${response.statusCode}",
        );
        return 0;
      }
    } catch (e) {
      print("getNotifUnreadCount: Exception $e");
      return 0;
    }
  }

  Future<NotificationResponse> getNotifications({int page = 1}) async {
    try {
      final url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/notification/index?page=$page',
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token") ?? "";

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return NotificationResponse.fromJson(jsonDecode(response.body));
      }

      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Request error: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to fetch notifications. $e");
    }
  }

  static Future<OrderResponse> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";

    final Uri url = Uri.parse(
      '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/auth/signout',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        return OrderResponse.fromJson(jsonDecode(response.body));
      }
      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Request error: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to log out. $e");
    }
  }

  Stream<Map<String, dynamic>> listenNotifications() async* {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? "";
    final userCode = prefs.getString("driver_code") ?? "";
    final userType = prefs.getString("user_type") ?? "";

    final url = Uri.parse(
      '${GetDNS.getNotifications()}/api/public/v1/moveapp/notification/listen?user_code=$userCode&user_type=$userType',
    );

    final client = http.Client();

    try {
      final request = http.Request('GET', url);
      request.headers['X-API-KEY'] = GetKEY.getApiKey();
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('SSE failed: HTTP ${response.statusCode}');
      }

      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        final clean = line.trim();
        if (clean.isEmpty) continue;
        if (!clean.startsWith('data:')) continue;

        final dataPart = clean.substring(5).trim();
        if (dataPart.isEmpty) continue;

        try {
          final decoded = json.decode(dataPart);
          if (decoded is Map<String, dynamic>) {
            // 🔹 Print every SSE response
            print("📨 SSE data: $decoded");
            yield decoded;
          }
        } catch (e) {
          print("❌ SSE decode error: $e");
        }
      }
    } catch (e) {
      print("❌ SSE error: $e");
    } finally {
      client.close();
    }
  }

  Future<ChatMessageResponse> getChatMessages(int chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token") ?? "";

      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/chat/$chatId/messages',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return ChatMessageResponse.fromJson(jsonDecode(response.body));
      }
      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Request error: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to fetch message. $e");
    }
  }

  Future<ChatMessageResponse> sendChatMessage({
    required int chatId,
    required String orderNo,
    required String message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token") ?? "";

      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/chat/$chatId/message',
      );

      var request = http.MultipartRequest("POST", url);

      request.fields['message'] = message;
      request.fields['order_no'] = orderNo;
      request.fields['message_type'] = "text";

      // Auth header
      request.headers['Authorization'] = 'Bearer $token';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        return ChatMessageResponse.fromJson(decodedData);
      }
      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Request error: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to fetch orders. $e");
    }
  }

  Future<ChatMessageResponse> uploadChatImage({
    required int chatId,
    required String orderNo,
    required File file,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString("jwt_token") ?? "";

      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/chat/$chatId/upload',
      );

      var request = http.MultipartRequest('POST', url);

      request.fields['order_no'] = orderNo;
      request.fields['message_type'] = "file";

      final mimeType = file.path.split('.').last.toLowerCase();
      final imageType = mimeType == "png" ? "png" : "jpeg";

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: http.MediaType("image", imageType),
        ),
      );

      // Add Authorization header
      request.headers['Authorization'] = 'Bearer $token';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        return ChatMessageResponse.fromJson(decoded);
      }
      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Request error: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to upload. $e");
    }
  }

  Future<OrderResponse> signIn(String email, String password) async {
    try {
      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/public/v1/moveapp/auth/signin',
      );
      final http.Response response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({"email": email, "password": password}),
      );
      print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        return OrderResponse.fromJson(decodedData);
      }
      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Request error: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to fetch orders. $e");
    }
  }

  Future<OrderResponse> refuseOrder({
    required int orderId,
    required String reason,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token") ?? "";
      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/driver/task/$orderId/refuse',
      );

      var request = http.MultipartRequest('PUT', url);

      request.fields['reason'] = reason;

      request.headers['Authorization'] = 'Bearer $token';

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        return OrderResponse.fromJson(decodedData);
      }
      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Request error: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to fetch orders. $e");
    }
  }

  Future<OrderResponse> getOrder({String orderNo = "", String? status}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString("id") ?? "0";
      final token = prefs.getString("jwt_token") ?? "";
      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/orders/index'
        '?driver_id=$id&order_no=$orderNo&status=$status',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return OrderResponse.fromJson(jsonDecode(response.body));
      }

      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Request error: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to fetch orders. $e");
    }
  }

  Future<OrderResponse> updateStatus({
    required int orderId,
    required String status,
    required String lng,
    required String lat,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token") ?? "";

      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/driver/task/$orderId/status',
      );

      var request = http.MultipartRequest('PUT', url);

      request.fields['status'] = status;
      request.fields['lng'] = lng;
      request.fields['lat'] = lat;

      // Add Authorization header with JWT token
      request.headers['Authorization'] = 'Bearer $token';

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return OrderResponse.fromJson(jsonDecode(response.body));
      }

      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Request error: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to fetch orders. $e");
    }
  }

  Future<OrderResponse> uploadProofOfDelivery({
    required String orderNo,
    required String recipientName,
    required File photoItem,
    required File signature,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token") ?? "";

      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/driver/pod',
      );

      var request = http.MultipartRequest('POST', url);

      // Authorization Header
      request.headers['Authorization'] = 'Bearer $token';

      // Form fields
      request.fields['order_no'] = orderNo;
      request.fields['recipient_name'] = recipientName;

      // Attach photo
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photoItem.path,
          contentType: http.MediaType('image', 'jpeg'),
        ),
      );

      // Attach signature
      request.files.add(
        await http.MultipartFile.fromPath(
          'signature',
          signature.path,
          contentType: http.MediaType('image', 'png'),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return OrderResponse.fromJson(jsonDecode(response.body));
      }

      // ---- FRIENDLY ERROR MESSAGES ----
      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Proof upload failed: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to upload proof. $e");
    }
  }

  Future<OrderResponse> emailVerification(String email) async {
    try {
      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/public/v1/moveapp/auth/request-signup-otp',
      );
      final http.Response response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({"email": email}),
      );
      if (response.statusCode == 200) {
        return OrderResponse.fromJson(jsonDecode(response.body));
      }

      // ---- FRIENDLY ERROR MESSAGES ----
      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Verification failed: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to verify. $e");
    }
  }

  Future<OrderResponse> signup({
    required String firstName,
    String? middleName,
    required String lastName,
    String? suffix,
    required String gender,
    required String email,
    required String phone,
    required String address,
    required String password,
    required String vehicleType,
    required String licenseNumber,
    required File licenseFront,
    required File licenseBack,
  }) async {
    try {
      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/public/v1/moveapp/auth/signup',
      );

      var request = http.MultipartRequest('POST', url);

      // Add text fields
      request.fields['first_name'] = firstName;
      if (middleName != null) request.fields['middle_name'] = middleName;
      request.fields['last_name'] = lastName;
      if (suffix != null) request.fields['suffix'] = suffix;
      request.fields['gender'] = gender;
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      request.fields['address'] = address;
      request.fields['password'] = password;
      request.fields['vehicle_type'] = vehicleType;
      request.fields['license_number'] = licenseNumber;
      request.files.add(
        await http.MultipartFile.fromPath(
          'license_front',
          licenseFront.path,
          contentType: http.MediaType('image', 'jpeg'),
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'license_back',
          licenseBack.path,
          contentType: http.MediaType('image', 'jpeg'),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return OrderResponse.fromJson(jsonDecode(response.body));
      }

      // ---- FRIENDLY ERROR MESSAGES ----
      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Registration failed: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to register. $e");
    }
  }

  Future<OrderResponse> emailOTPVerification(String otp) async {
    try {
      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/public/v1/moveapp/auth/verify-signup-otp',
      );
      final http.Response response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({"otp": otp}),
      );
      if (response.statusCode == 200) {
        return OrderResponse.fromJson(jsonDecode(response.body));
      }
      if (response.statusCode == 500 || response.statusCode == 503) {
        throw Exception("Server is down right now. Please try again later.");
      }

      throw Exception("Registration failed: ${response.statusCode}");
    } catch (e) {
      throw Exception("Unable to register. $e");
    }
  }

  Future<Map<String, List<String>>> fetchDropdownOptions() async {
    try {
      final Uri url = Uri.parse(
        '${GetDNS.getOttokonekHestia()}/api/public/v1/moveapp/dropdown',
      );
      final http.Response response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        final Map<String, dynamic> data = decodedData['data'];

        // Convert each list in data to List<String>
        Map<String, List<String>> dropdowns = {};
        data.forEach((key, value) {
          dropdowns[key] = List<String>.from(value);
        });

        return dropdowns;
      } else {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dns_services.dart';
// import 'model_services.dart';
// import 'network_inspector_services.dart';
//
// class ApiServices {
//   void _logResponse({
//     required String url,
//     required String method,
//     required int statusCode,
//     Map<String, String>? requestHeaders,
//     Map<String, String>? responseHeaders,
//     dynamic requestBody,
//     dynamic responseBody,
//   }) {
//     InspectorController.addLog(
//       NetworkLog(
//         url: url,
//         method: method,
//         statusCode: statusCode,
//         requestHeaders: requestHeaders ?? {},
//         responseHeaders: responseHeaders ?? {},
//         requestBody: requestBody,
//         responseBody: responseBody,
//         timestamp: DateTime.now(),
//       ),
//     );
//   }
//
//   Future<void> markAllNotificationsAsRead() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("jwt_token") ?? "";
//
//     final url = Uri.parse(
//       '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/notification/mark-all-read',
//     );
//
//     final headers = {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     };
//
//     try {
//       final response = await http.post(url, headers: headers);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'POST',
//         statusCode: response.statusCode,
//         requestHeaders: headers,
//         responseHeaders: response.headers,
//         requestBody: null,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         // Success
//       } else {
//         print(
//           'Failed to mark notifications as read: ${response.statusCode} ${response.body}',
//         );
//       }
//     } catch (e) {
//       _logResponse(
//         url: url.toString(),
//         method: 'POST',
//         statusCode: 0,
//         requestHeaders: headers,
//         responseHeaders: {},
//         requestBody: null,
//         responseBody: 'Error: $e',
//       );
//       rethrow;
//     }
//   }
//
//   Future<void> markNotificationAsRead({required int notificationId}) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("jwt_token") ?? "";
//     final url = Uri.parse(
//       '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/notification/view',
//     );
//
//     final body = json.encode({'notification_id': notificationId});
//     final headers = {
//       'Content-Type': 'application/json; charset=UTF-8',
//       'Authorization': 'Bearer $token',
//     };
//
//     try {
//       final response = await http.post(url, headers: headers, body: body);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'POST',
//         statusCode: response.statusCode,
//         requestHeaders: headers,
//         responseHeaders: response.headers,
//         requestBody: body,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         // Success
//       } else {
//         throw Exception(
//           'Failed to mark notification as read: ${response.statusCode} ${response.body}',
//         );
//       }
//     } catch (e) {
//       if (e is! Exception) {
//         _logResponse(
//           url: url.toString(),
//           method: 'POST',
//           statusCode: 0,
//           requestHeaders: headers,
//           responseHeaders: {},
//           requestBody: body,
//           responseBody: 'Error: $e',
//         );
//       }
//       rethrow;
//     }
//   }
//
//   Future<int> getNotifUnreadCount() async {
//     try {
//       final url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/notification/unread-count',
//       );
//
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("jwt_token") ?? "";
//
//       final headers = {
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $token',
//       };
//
//       final response = await http.get(url, headers: headers);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'GET',
//         statusCode: response.statusCode,
//         requestHeaders: headers,
//         responseHeaders: response.headers,
//         requestBody: null,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> jsonBody = json.decode(response.body);
//
//         if (jsonBody['data'] != null &&
//             jsonBody['data']['unread_count'] != null) {
//           return jsonBody['data']['unread_count'] as int;
//         } else {
//           return 0;
//         }
//       } else {
//         print(
//           "getNotifUnreadCount: Unexpected status code ${response.statusCode}",
//         );
//         return 0;
//       }
//     } catch (e) {
//       print("getNotifUnreadCount: Exception $e");
//       return 0;
//     }
//   }
//
//   Future<NotificationResponse> getNotifications({int page = 1}) async {
//     try {
//       final url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/notification/index?page=$page',
//       );
//
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("jwt_token") ?? "";
//
//       final headers = {
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $token',
//       };
//
//       final response = await http.get(url, headers: headers);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'GET',
//         statusCode: response.statusCode,
//         requestHeaders: headers,
//         responseHeaders: response.headers,
//         requestBody: null,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         return NotificationResponse.fromJson(jsonDecode(response.body));
//       }
//
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Request error: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to fetch notifications. $e");
//     }
//   }
//
//   static Future<OrderResponse> logout() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("jwt_token") ?? "";
//
//     final Uri url = Uri.parse(
//       '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/auth/signout',
//     );
//
//     final headers = {
//       'Authorization': 'Bearer $token',
//       'Accept': 'application/json',
//     };
//
//     try {
//       final response = await http.get(url, headers: headers);
//
//       InspectorController.addLog(
//         NetworkLog(
//           url: url.toString(),
//           method: 'GET',
//           statusCode: response.statusCode,
//           requestHeaders: headers,
//           responseHeaders: response.headers,
//           requestBody: null,
//           responseBody: response.body,
//           timestamp: DateTime.now(),
//         ),
//       );
//
//       print(response.body);
//       if (response.statusCode == 200) {
//         return OrderResponse.fromJson(jsonDecode(response.body));
//       }
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Request error: ${response.statusCode}");
//     } catch (e) {
//       if (e is! Exception) {
//         InspectorController.addLog(
//           NetworkLog(
//             url: url.toString(),
//             method: 'GET',
//             statusCode: 0,
//             requestHeaders: headers,
//             responseHeaders: {},
//             requestBody: null,
//             responseBody: 'Error: $e',
//             timestamp: DateTime.now(),
//           ),
//         );
//       }
//       throw Exception("Unable to log out. $e");
//     }
//   }
//
//   Stream<Map<String, dynamic>> listenNotifications() async* {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("jwt_token") ?? "";
//     final userCode = prefs.getString("driver_code") ?? "";
//     final userType = prefs.getString("user_type") ?? "";
//
//     final url = Uri.parse(
//       '${GetDNS.getNotifications()}/api/public/v1/moveapp/notification/listen?user_code=$userCode&user_type=$userType',
//     );
//
//     final client = http.Client();
//
//     try {
//       final request = http.Request('GET', url);
//       request.headers['X-API-KEY'] = GetKEY.getApiKey();
//       request.headers['Authorization'] = 'Bearer $token';
//       request.headers['Accept'] = 'text/event-stream';
//       request.headers['Cache-Control'] = 'no-cache';
//
//       // Log SSE connection attempt
//       InspectorController.addLog(
//         NetworkLog(
//           url: url.toString(),
//           method: 'GET (SSE)',
//           requestHeaders: request.headers,
//           responseHeaders: {},
//           requestBody: null,
//           responseBody: 'SSE Stream Started',
//           timestamp: DateTime.now(),
//         ),
//       );
//
//       final response = await client.send(request);
//
//       if (response.statusCode != 200) {
//         InspectorController.addLog(
//           NetworkLog(
//             url: url.toString(),
//             method: 'GET (SSE)',
//             statusCode: response.statusCode,
//             requestHeaders: request.headers,
//             responseHeaders: response.headers,
//             requestBody: null,
//             responseBody: 'SSE failed: HTTP ${response.statusCode}',
//             timestamp: DateTime.now(),
//           ),
//         );
//         throw Exception('SSE failed: HTTP ${response.statusCode}');
//       }
//
//       final lines = response.stream
//           .transform(utf8.decoder)
//           .transform(const LineSplitter());
//
//       await for (final line in lines) {
//         final clean = line.trim();
//         if (clean.isEmpty) continue;
//         if (!clean.startsWith('data:')) continue;
//
//         final dataPart = clean.substring(5).trim();
//         if (dataPart.isEmpty) continue;
//
//         try {
//           final decoded = json.decode(dataPart);
//           if (decoded is Map<String, dynamic>) {
//             // Log SSE data received
//             InspectorController.addLog(
//               NetworkLog(
//                 url: url.toString(),
//                 method: 'GET (SSE)',
//                 statusCode: 200,
//                 requestHeaders: request.headers,
//                 responseHeaders: {},
//                 requestBody: null,
//                 responseBody: dataPart,
//                 timestamp: DateTime.now(),
//               ),
//             );
//             print("📨 SSE data: $decoded");
//             yield decoded;
//           }
//         } catch (e) {
//           print("❌ SSE decode error: $e");
//         }
//       }
//     } catch (e) {
//       print("❌ SSE error: $e");
//     } finally {
//       client.close();
//     }
//   }
//
//   Future<ChatMessageResponse> getChatMessages(int chatId) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("jwt_token") ?? "";
//
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/chat/$chatId/messages',
//       );
//
//       final headers = {
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $token',
//       };
//
//       final response = await http.get(url, headers: headers);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'GET',
//         statusCode: response.statusCode,
//         requestHeaders: headers,
//         responseHeaders: response.headers,
//         requestBody: null,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         return ChatMessageResponse.fromJson(jsonDecode(response.body));
//       }
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Request error: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to fetch message. $e");
//     }
//   }
//
//   Future<ChatMessageResponse> sendChatMessage({
//     required int chatId,
//     required String orderNo,
//     required String message,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("jwt_token") ?? "";
//
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/chat/$chatId/message',
//       );
//
//       var request = http.MultipartRequest("POST", url);
//
//       request.fields['message'] = message;
//       request.fields['order_no'] = orderNo;
//       request.fields['message_type'] = "text";
//
//       request.headers['Authorization'] = 'Bearer $token';
//
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'POST (Multipart)',
//         statusCode: response.statusCode,
//         requestHeaders: request.headers,
//         responseHeaders: response.headers,
//         requestBody: request.fields,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final Map<String, dynamic> decodedData = jsonDecode(response.body);
//         return ChatMessageResponse.fromJson(decodedData);
//       }
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Request error: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to fetch orders. $e");
//     }
//   }
//
//   Future<ChatMessageResponse> uploadChatImage({
//     required int chatId,
//     required String orderNo,
//     required File file,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final String token = prefs.getString("jwt_token") ?? "";
//
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/chat/$chatId/upload',
//       );
//
//       var request = http.MultipartRequest('POST', url);
//
//       request.fields['order_no'] = orderNo;
//       request.fields['message_type'] = "file";
//
//       final mimeType = file.path.split('.').last.toLowerCase();
//       final imageType = mimeType == "png" ? "png" : "jpeg";
//
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'file',
//           file.path,
//           contentType: http.MediaType("image", imageType),
//         ),
//       );
//
//       request.headers['Authorization'] = 'Bearer $token';
//
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'POST (Multipart)',
//         statusCode: response.statusCode,
//         requestHeaders: request.headers,
//         responseHeaders: response.headers,
//         requestBody: {...request.fields, 'file': file.path},
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final Map<String, dynamic> decoded = jsonDecode(response.body);
//         return ChatMessageResponse.fromJson(decoded);
//       }
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Request error: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to upload. $e");
//     }
//   }
//
//   Future<OrderResponse> signIn(String email, String password) async {
//     try {
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/public/v1/moveapp/auth/signin',
//       );
//
//       final headers = <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//       };
//
//       final body = jsonEncode({"email": email, "password": password});
//
//       final http.Response response = await http.post(
//         url,
//         headers: headers,
//         body: body,
//       );
//
//       // Mask password in logs
//       final maskedBody = jsonEncode({
//         "email": email,
//         "password": "***MASKED***",
//       });
//
//       _logResponse(
//         url: url.toString(),
//         method: 'POST',
//         statusCode: response.statusCode,
//         requestHeaders: headers,
//         responseHeaders: response.headers,
//         requestBody: maskedBody,
//         responseBody: response.body,
//       );
//
//       print(response.body);
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> decodedData = jsonDecode(response.body);
//         return OrderResponse.fromJson(decodedData);
//       }
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Request error: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to fetch orders. $e");
//     }
//   }
//
//   Future<OrderResponse> refuseOrder({
//     required int orderId,
//     required String reason,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("jwt_token") ?? "";
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/driver/task/$orderId/refuse',
//       );
//
//       var request = http.MultipartRequest('PUT', url);
//
//       request.fields['reason'] = reason;
//       request.headers['Authorization'] = 'Bearer $token';
//
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'PUT (Multipart)',
//         statusCode: response.statusCode,
//         requestHeaders: request.headers,
//         responseHeaders: response.headers,
//         requestBody: request.fields,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> decodedData = jsonDecode(response.body);
//         return OrderResponse.fromJson(decodedData);
//       }
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Request error: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to fetch orders. $e");
//     }
//   }
//
//   Future<OrderResponse> getOrder({String orderNo = "", String? status}) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final id = prefs.getString("id") ?? "0";
//       final token = prefs.getString("jwt_token") ?? "";
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/orders/index'
//         '?driver_id=$id&order_no=$orderNo&status=$status',
//       );
//
//       final headers = {
//         'Content-Type': 'application/json; charset=UTF-8',
//         'Authorization': 'Bearer $token',
//       };
//
//       final response = await http.get(url, headers: headers);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'GET',
//         statusCode: response.statusCode,
//         requestHeaders: headers,
//         responseHeaders: response.headers,
//         requestBody: null,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         return OrderResponse.fromJson(jsonDecode(response.body));
//       }
//
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Request error: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to fetch orders. $e");
//     }
//   }
//
//   Future<OrderResponse> updateStatus({
//     required int orderId,
//     required String status,
//     required String lng,
//     required String lat,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("jwt_token") ?? "";
//
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/driver/task/$orderId/status',
//       );
//
//       var request = http.MultipartRequest('PUT', url);
//
//       request.fields['status'] = status;
//       request.fields['lng'] = lng;
//       request.fields['lat'] = lat;
//
//       request.headers['Authorization'] = 'Bearer $token';
//
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'PUT (Multipart)',
//         statusCode: response.statusCode,
//         requestHeaders: request.headers,
//         responseHeaders: response.headers,
//         requestBody: request.fields,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         return OrderResponse.fromJson(jsonDecode(response.body));
//       }
//
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Request error: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to fetch orders. $e");
//     }
//   }
//
//   Future<OrderResponse> uploadProofOfDelivery({
//     required String orderNo,
//     required String recipientName,
//     required File photoItem,
//     required File signature,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("jwt_token") ?? "";
//
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/private/v1/moveapp/driver/pod',
//       );
//
//       var request = http.MultipartRequest('POST', url);
//
//       request.headers['Authorization'] = 'Bearer $token';
//
//       request.fields['order_no'] = orderNo;
//       request.fields['recipient_name'] = recipientName;
//
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'photo',
//           photoItem.path,
//           contentType: http.MediaType('image', 'jpeg'),
//         ),
//       );
//
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'signature',
//           signature.path,
//           contentType: http.MediaType('image', 'png'),
//         ),
//       );
//
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'POST (Multipart)',
//         statusCode: response.statusCode,
//         requestHeaders: request.headers,
//         responseHeaders: response.headers,
//         requestBody: {
//           ...request.fields,
//           'photo': photoItem.path,
//           'signature': signature.path,
//         },
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         return OrderResponse.fromJson(jsonDecode(response.body));
//       }
//
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Proof upload failed: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to upload proof. $e");
//     }
//   }
//
//   Future<OrderResponse> emailVerification(String email) async {
//     try {
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/public/v1/moveapp/auth/request-signup-otp',
//       );
//
//       final headers = <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//       };
//
//       final body = jsonEncode({"email": email});
//
//       final http.Response response = await http.post(
//         url,
//         headers: headers,
//         body: body,
//       );
//
//       _logResponse(
//         url: url.toString(),
//         method: 'POST',
//         statusCode: response.statusCode,
//         requestHeaders: headers,
//         responseHeaders: response.headers,
//         requestBody: body,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         return OrderResponse.fromJson(jsonDecode(response.body));
//       }
//
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Verification failed: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to verify. $e");
//     }
//   }
//
//   Future<OrderResponse> signup({
//     required String firstName,
//     String? middleName,
//     required String lastName,
//     String? suffix,
//     required String gender,
//     required String email,
//     required String phone,
//     required String address,
//     required String password,
//     required String vehicleType,
//     required String licenseNumber,
//     required File licenseFront,
//     required File licenseBack,
//   }) async {
//     try {
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/public/v1/moveapp/auth/signup',
//       );
//
//       var request = http.MultipartRequest('POST', url);
//
//       request.fields['first_name'] = firstName;
//       if (middleName != null) request.fields['middle_name'] = middleName;
//       request.fields['last_name'] = lastName;
//       if (suffix != null) request.fields['suffix'] = suffix;
//       request.fields['gender'] = gender;
//       request.fields['email'] = email;
//       request.fields['phone'] = phone;
//       request.fields['address'] = address;
//       request.fields['password'] = password;
//       request.fields['vehicle_type'] = vehicleType;
//       request.fields['license_number'] = licenseNumber;
//
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'license_front',
//           licenseFront.path,
//           contentType: http.MediaType('image', 'jpeg'),
//         ),
//       );
//       request.files.add(
//         await http.MultipartFile.fromPath(
//           'license_back',
//           licenseBack.path,
//           contentType: http.MediaType('image', 'jpeg'),
//         ),
//       );
//
//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);
//
//       // Mask password in logs
//       final maskedFields = Map<String, String>.from(request.fields);
//       maskedFields['password'] = '***MASKED***';
//
//       _logResponse(
//         url: url.toString(),
//         method: 'POST (Multipart)',
//         statusCode: response.statusCode,
//         requestHeaders: request.headers,
//         responseHeaders: response.headers,
//         requestBody: {
//           ...maskedFields,
//           'license_front': licenseFront.path,
//           'license_back': licenseBack.path,
//         },
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         return OrderResponse.fromJson(jsonDecode(response.body));
//       }
//
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Registration failed: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to register. $e");
//     }
//   }
//
//   Future<OrderResponse> emailOTPVerification(String otp) async {
//     try {
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/public/v1/moveapp/auth/verify-signup-otp',
//       );
//
//       final headers = <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//       };
//
//       final body = jsonEncode({"otp": otp});
//
//       final http.Response response = await http.post(
//         url,
//         headers: headers,
//         body: body,
//       );
//
//       _logResponse(
//         url: url.toString(),
//         method: 'POST',
//         statusCode: response.statusCode,
//         requestHeaders: headers,
//         responseHeaders: response.headers,
//         requestBody: body,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         return OrderResponse.fromJson(jsonDecode(response.body));
//       }
//       if (response.statusCode == 500 || response.statusCode == 503) {
//         throw Exception("Server is down right now. Please try again later.");
//       }
//
//       throw Exception("Registration failed: ${response.statusCode}");
//     } catch (e) {
//       throw Exception("Unable to register. $e");
//     }
//   }
//
//   Future<Map<String, List<String>>> fetchDropdownOptions() async {
//     try {
//       final Uri url = Uri.parse(
//         '${GetDNS.getOttokonekHestia()}/api/public/v1/moveapp/dropdown',
//       );
//
//       final http.Response response = await http.get(url);
//
//       _logResponse(
//         url: url.toString(),
//         method: 'GET',
//         statusCode: response.statusCode,
//         requestHeaders: {},
//         responseHeaders: response.headers,
//         requestBody: null,
//         responseBody: response.body,
//       );
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> decodedData = jsonDecode(response.body);
//         final Map<String, dynamic> data = decodedData['data'];
//
//         Map<String, List<String>> dropdowns = {};
//         data.forEach((key, value) {
//           dropdowns[key] = List<String>.from(value);
//         });
//
//         return dropdowns;
//       } else {
//         throw Exception(
//           'Server returned ${response.statusCode}: ${response.body}',
//         );
//       }
//     } catch (e) {
//       throw Exception('An error occurred: $e');
//     }
//   }
// }
