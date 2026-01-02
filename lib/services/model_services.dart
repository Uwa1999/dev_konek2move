class OrderResponse {
  final String? responseTime;
  final String? device;
  final String? retCode;
  final String? message;
  final String? error;
  final OrderData? data;

  OrderResponse({
    this.responseTime,
    this.device,
    this.retCode,
    this.message,
    this.error,
    this.data,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      responseTime: json['responseTime'] ?? '',
      device: json['device'] ?? '',
      retCode: json['retCode'] ?? '',
      message: json['message'] ?? '',
      error: json['error'] ?? '',
      data: json['data'] != null ? OrderData.fromJson(json['data']) : null,
    );
  }
}

class OrderData {
  final int? currentPage;
  final int? totalPages;
  final int? totalCount;
  final List<OrderRecord>? records;
  final Driver? driver; // for login response
  final String? jwtToken; // for login response

  OrderData({
    this.currentPage,
    this.totalPages,
    this.totalCount,
    this.records,
    this.driver,
    this.jwtToken,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      currentPage: json['currentPage'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      records: json['records'] != null
          ? (json['records'] as List)
                .map((e) => OrderRecord.fromJson(e))
                .toList()
          : [],
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      jwtToken: json['jwt_token'] ?? '',
    );
  }
}

class OrderRecord {
  final int? id;
  final String? orderNo;
  final String? supplierCode;
  final String? supplierName;
  final String? supplierAddress;
  final int? customerId;
  final String? barangayCode;
  final int? assignedDriverId;
  final String? status;
  final String? statusUpdatedAt;
  final int? itemsCount;
  final double? totalAmount;
  final String? pickupAddress;
  final String? deliveryAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? contactPhone;
  final bool? autoAssigned;
  final String? createdAt;
  final String? updatedAt;
  final String? barangayName;
  final Customer? customer;
  final Driver? driver;
  final Chat? chat;

  OrderRecord({
    this.id,
    this.orderNo,
    this.supplierCode,
    this.supplierName,
    this.supplierAddress,
    this.customerId,
    this.barangayCode,
    this.assignedDriverId,
    this.status,
    this.statusUpdatedAt,
    this.itemsCount,
    this.totalAmount,
    this.pickupAddress,
    this.deliveryAddress,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
    this.contactPhone,
    this.autoAssigned,
    this.createdAt,
    this.updatedAt,
    this.barangayName,
    this.customer,
    this.driver,
    this.chat,
  });

  /// Immutable copyWith for updating fields safely
  OrderRecord copyWith({
    int? id,
    String? orderNo,
    String? supplierCode,
    String? supplierName,
    String? supplierAddress,
    int? customerId,
    String? barangayCode,
    int? assignedDriverId,
    String? status,
    String? statusUpdatedAt,
    int? itemsCount,
    double? totalAmount,
    String? pickupAddress,
    String? deliveryAddress,
    double? pickupLat,
    double? pickupLng,
    double? deliveryLat,
    double? deliveryLng,
    String? contactPhone,
    bool? autoAssigned,
    String? createdAt,
    String? updatedAt,
    String? barangayName,
    Customer? customer,
    Driver? driver,
    Chat? chat,
  }) {
    return OrderRecord(
      id: id ?? this.id,
      orderNo: orderNo ?? this.orderNo,
      supplierCode: supplierCode ?? this.supplierCode,
      supplierName: supplierName ?? this.supplierName,
      supplierAddress: supplierAddress ?? this.supplierAddress,
      customerId: customerId ?? this.customerId,
      barangayCode: barangayCode ?? this.barangayCode,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      status: status ?? this.status,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      itemsCount: itemsCount ?? this.itemsCount,
      totalAmount: totalAmount ?? this.totalAmount,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      contactPhone: contactPhone ?? this.contactPhone,
      autoAssigned: autoAssigned ?? this.autoAssigned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      barangayName: barangayName ?? this.barangayName,
      customer: customer ?? this.customer,
      driver: driver ?? this.driver,
      chat: chat ?? this.chat,
    );
  }

  factory OrderRecord.fromJson(Map<String, dynamic> json) {
    return OrderRecord(
      id: json['id'],
      orderNo: json['order_no'] ?? '',
      supplierCode: json['supplier_code'] ?? '',
      supplierName: json['supplier_name'] ?? '',
      supplierAddress: json['supplier_address'] ?? '',
      customerId: json['customer_id'],
      barangayCode: json['barangay_code'] ?? '',
      assignedDriverId: json['assigned_driver_id'],
      status: json['status'] ?? '',
      statusUpdatedAt: json['status_updated_at'] ?? '',
      itemsCount: json['items_count'],
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      pickupAddress: json['pickup_address'] ?? '',
      deliveryAddress: json['delivery_address'] ?? '',
      pickupLat: (json['pickup_lat'] ?? 0).toDouble(),
      pickupLng: (json['pickup_lng'] ?? 0).toDouble(),
      deliveryLat: (json['delivery_lat'] ?? 0).toDouble(),
      deliveryLng: (json['delivery_lng'] ?? 0).toDouble(),
      contactPhone: json['contact_phone'] ?? '',
      autoAssigned: json['auto_assigned'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      barangayName: json['barangay_name'] ?? '',
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'])
          : null,
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
      chat: json['chat'] != null ? Chat.fromJson(json['chat']) : null,
    );
  }
}

class Customer {
  final int? id;
  final String? code;
  final String? name;
  final String? phone;

  Customer({this.id, this.code, this.name, this.phone});

  Customer copyWith({int? id, String? code, String? name, String? phone}) {
    return Customer(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class Driver {
  final int? id;
  final String? userType;
  final String? driverCode;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? gender;
  final String? email;
  final String? phone;
  final bool? emailVerified;
  final String? address;
  final String? vehicleType;
  final String? licenseNumber;
  final String? licenseFrontUrl;
  final String? licenseBackUrl;
  final String? assignedStoreCode;
  final String? barangayCode;
  final String? status;
  final String? memberStatus;
  final bool? active;
  final String? createdAt;
  final String? updatedAt;

  Driver({
    this.id,
    this.userType,
    this.driverCode,
    this.firstName,
    this.lastName,
    this.fullName,
    this.gender,
    this.email,
    this.phone,
    this.emailVerified,
    this.address,
    this.vehicleType,
    this.licenseNumber,
    this.licenseFrontUrl,
    this.licenseBackUrl,
    this.assignedStoreCode,
    this.barangayCode,
    this.status,
    this.memberStatus,
    this.active,
    this.createdAt,
    this.updatedAt,
  });

  Driver copyWith({
    int? id,
    String? userType,
    String? driverCode,
    String? firstName,
    String? lastName,
    String? fullName,
    String? gender,
    String? email,
    String? phone,
    bool? emailVerified,
    String? address,
    String? vehicleType,
    String? licenseNumber,
    String? licenseFrontUrl,
    String? licenseBackUrl,
    String? assignedStoreCode,
    String? barangayCode,
    String? status,
    String? memberStatus,
    bool? active,
    String? createdAt,
    String? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      userType: userType ?? this.userType,
      driverCode: driverCode ?? this.driverCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emailVerified: emailVerified ?? this.emailVerified,
      address: address ?? this.address,
      vehicleType: vehicleType ?? this.vehicleType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseFrontUrl: licenseFrontUrl ?? this.licenseFrontUrl,
      licenseBackUrl: licenseBackUrl ?? this.licenseBackUrl,
      assignedStoreCode: assignedStoreCode ?? this.assignedStoreCode,
      barangayCode: barangayCode ?? this.barangayCode,
      status: status ?? this.status,
      memberStatus: memberStatus ?? this.memberStatus,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      userType: json['user_type'] ?? '',
      driverCode: json['driver_code'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      gender: json['gender'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      emailVerified: json['email_verified'] ?? false,
      address: json['address'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      licenseNumber: json['license_number'] ?? '',
      licenseFrontUrl: json['license_front_url'] ?? '',
      licenseBackUrl: json['license_back_url'] ?? '',
      assignedStoreCode: json['assigned_store_code'] ?? '',
      barangayCode: json['barangay_code'] ?? '',
      status: json['status'] ?? '',
      memberStatus: json['member_status'] ?? '',
      active: json['active'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class Chat {
  final int? id;
  final String? chatCode;
  final int? orderId;
  final bool? isActive;
  final String? lastMessageAt;
  final String? createdAt;
  final String? updatedAt;

  Chat({
    this.id,
    this.chatCode,
    this.orderId,
    this.isActive,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      chatCode: json['chat_code'] ?? '',
      orderId: json['order_id'],
      isActive: json['is_active'] ?? false,
      lastMessageAt: json['last_message_at'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class ChatMessageResponse {
  final String? responseTime;
  final String? device;
  final String? retCode;
  final String? message;
  final String? error;
  final List<ChatMessage>? data;

  ChatMessageResponse({
    this.responseTime,
    this.device,
    this.retCode,
    this.message,
    this.error,
    this.data,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) {
    return ChatMessageResponse(
      responseTime: json['responseTime'] ?? '',
      device: json['device'] ?? '',
      retCode: json['retCode'] ?? '',
      message: json['message'] ?? '',
      error: json['error'] ?? '',
      data: json['data'] != null
          ? (json['data'] as List).map((e) => ChatMessage.fromJson(e)).toList()
          : [],
    );
  }
}

class ChatMessage {
  final int? id;
  final String? senderType;
  final String? senderCode;
  final String? message;
  final String? attachmentUrl;
  final String? messageType;
  final DateTime? createdAt;

  ChatMessage({
    this.id,
    this.senderType,
    this.senderCode,
    this.message,
    this.attachmentUrl,
    this.messageType,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderType: json['sender_type'] ?? '',
      senderCode: json['sender_code'] ?? '',
      message: json['message'] ?? '',
      attachmentUrl: json['attachment_url'] ?? '',
      messageType: json['message_type'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  /// Helpers for UI
  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;
}
