import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/services/model_services.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/image_full_screen.dart';
import 'package:konek2move/widgets/custom_chat_bubble.dart';
import 'package:konek2move/widgets/custom_snackbar.dart';
import 'package:shimmer/shimmer.dart';

class OrderMessagesScreen extends StatefulWidget {
  final int? chatId;
  final String currentUserType;
  final String orderNo;

  const OrderMessagesScreen({
    super.key,
    required this.chatId,
    required this.currentUserType,
    required this.orderNo,
  });

  @override
  State<OrderMessagesScreen> createState() => _OrderMessagesScreenState();
}

class _OrderMessagesScreenState extends State<OrderMessagesScreen> {
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  int chatUnreadCount = 0;
  bool _isLoading = true;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();

    if (widget.chatId != null) {
      _startSSE();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    if (widget.chatId == null) {
      setState(() {
        _isLoading = false;
        _messages = [];
      });
      return;
    }

    try {
      final response = await ApiServices().getChatMessages(widget.chatId!);

      setState(() {
        _messages = response.data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint(e.toString());
    }
  }

  // ---------------- SEND MESSAGE ----------------
  void _sendMessage() async {
    // Use a default message if the input is empty
    final text = _controller.text.trim().isEmpty
        ? "Sent a message" // default text if null/empty
        : _controller.text.trim();

    final newMessage = ChatMessage(
      message: text,
      senderType: widget.currentUserType,
      messageType: 'text',
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(newMessage);
      _controller.clear();
    });

    try {
      final ChatMessageResponse response = await ApiServices().sendChatMessage(
        chatId: 0, // backend handles null
        orderNo: widget.orderNo,
        message: text,
      );

      if (response.data != null && response.data!.isNotEmpty) {
        final serverMessage = response.data!.first;

        setState(() {
          final index = _messages.indexOf(newMessage);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: serverMessage.id,
              message: serverMessage.message ?? text, // fallback to default
              senderType: serverMessage.senderType ?? widget.currentUserType,
              senderCode: serverMessage.senderCode,
              attachmentUrl: serverMessage.attachmentUrl,
              messageType: serverMessage.messageType ?? 'text',
              createdAt: serverMessage.createdAt ?? DateTime.now(),
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _messages.remove(newMessage);
      });

      showAppSnackBar(
        icon: Icons.error_rounded,
        context,
        title: "Error",
        message: "Failed to send message. Please try again.",
        isSuccess: false,
      );
    }
  }

  // ---------------- UPLOAD IMAGE ----------------
  void _uploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile == null) return;

      final File file = File(pickedFile.path);

      // Optimistic UI with a default message
      final newMessage = ChatMessage(
        message: "Sent an image", // default message
        senderType: widget.currentUserType,
        messageType: 'image',
        attachmentUrl: file.path,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.add(newMessage);
      });

      // Upload image to server
      final ChatMessageResponse response = await ApiServices().uploadChatImage(
        chatId: 0, // backend handles null
        orderNo: widget.orderNo,
        file: file,
      );

      if (response.data != null && response.data!.isNotEmpty) {
        final serverMessage = response.data!.first;

        setState(() {
          final index = _messages.indexOf(newMessage);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: serverMessage.id,
              message: serverMessage.message ?? "Sent an image", // fallback
              senderType: serverMessage.senderType ?? widget.currentUserType,
              senderCode: serverMessage.senderCode,
              attachmentUrl: serverMessage.attachmentUrl,
              messageType: serverMessage.messageType ?? 'image',
              createdAt: serverMessage.createdAt ?? DateTime.now(),
            );
          }
        });
      }
    } catch (e) {
      debugPrint("Image upload failed: $e");
      setState(() {
        _messages.removeWhere(
          (msg) =>
              msg.senderType == widget.currentUserType &&
              msg.attachmentUrl != null &&
              msg.messageType == 'image',
        );
      });

      showAppSnackBar(
        icon: Icons.error_rounded,
        context,
        title: "Error",
        message: "Failed to upload image. Please try again.",
        isSuccess: false,
      );
    }
  }

  // ---------------- SSE ----------------
  void _startSSE() {
    _notificationSubscription?.cancel();
    _notificationSubscription = ApiServices().listenNotifications().listen(
      (event) {
        final meta = event['data']?['meta'];
        if (meta == null) return;

        final chatIdFromSSE = meta['chat_id'];
        if (chatIdFromSSE != widget.chatId) return;

        final recipientType = event['data']?['recipient_type'] ?? 'other';
        final senderType = (recipientType == widget.currentUserType)
            ? (widget.currentUserType == 'driver' ? 'customer' : 'driver')
            : recipientType;

        final attachmentUrl = (meta['attachment_url'] ?? "").isEmpty
            ? null
            : meta['attachment_url'];

        final newMsg = ChatMessage(
          id: meta['message_id'] ?? 0,
          message: meta['message'],
          senderType: senderType,
          senderCode: event['data']?['recipient_code'],
          attachmentUrl: attachmentUrl,
          messageType: meta['message_type'] ?? 'text',
          createdAt:
              DateTime.tryParse(event['data']?['created_at'] ?? '') ??
              DateTime.now(),
        );

        setState(() {
          _messages.add(newMsg);
        });
      },
      onError: (error) async {
        await Future.delayed(const Duration(seconds: 3));
        _startSSE();
      },
      cancelOnError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Order Messages",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
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
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: _isLoading
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              alignment: index % 2 == 0
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 150,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : _messages.isEmpty
                    ? SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: SizedBox(
                          height: constraints.maxHeight * 0.65,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                              const Text(
                                "No Messages Yet",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Your chat messages will appear here.\nStart a conversation to get updates.",
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
                      )
                    : ListView.builder(
                        reverse:
                            true, // ← Reverse the list to show latest at bottom
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[_messages.length - 1 - index];
                          // ← Reverse indexing so newest message is at bottom
                          final isSender =
                              msg.senderType == widget.currentUserType;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: ChatBubble(
                              isSender: isSender,
                              message: msg.isText ? msg.message : null,
                              child: msg.isText
                                  ? null
                                  : GestureDetector(
                                      onTap: () {
                                        if (msg.attachmentUrl != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  FullscreenImageScreen(
                                                    imageUrl:
                                                        msg.attachmentUrl!,
                                                  ),
                                            ),
                                          );
                                        }
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child:
                                            msg.attachmentUrl!.startsWith(
                                              'http',
                                            )
                                            ? Image.network(
                                                msg.attachmentUrl!,
                                                width: 200,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(msg.attachmentUrl!),
                                                width: 200,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
              ),

              // ------- BOTTOM INPUT -------
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // Image button
                      InkWell(
                        onTap: _uploadImage, // always enabled
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _sendMessage, // always enabled
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
