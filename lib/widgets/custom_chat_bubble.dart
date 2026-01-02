import 'package:flutter/material.dart';
import 'package:konek2move/utils/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final String? message;
  final Widget? child; // new optional child
  final bool isSender;

  const ChatBubble({super.key, this.message, this.child, this.isSender = false})
    : assert(
        message != null || child != null,
        "Either message or child must be provided",
      );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: child != null
            ? const EdgeInsets.all(0) // no padding for child (like image)
            : const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isSender ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isSender ? 20 : 0),
            bottomRight: Radius.circular(isSender ? 0 : 20),
          ),
        ),
        child:
            child ??
            Text(
              message!,
              style: TextStyle(
                color: isSender ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
      ),
    );
  }
}
