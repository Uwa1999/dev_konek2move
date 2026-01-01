import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dns_services.dart';
import 'model_services.dart';

class ApiServices {

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
        body: jsonEncode({"email": email, "password": password,}),
      );
print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.body);
        return OrderResponse.fromJson(decodedData);
      }  if (response.statusCode == 500 || response.statusCode == 503) {
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
