import 'package:flutter/material.dart';
import 'package:konek2move/services/api_services.dart';
import 'package:konek2move/services/model_services.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:konek2move/widgets/custom_snackbar.dart';
import 'package:shimmer/shimmer.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationRecord> notifications = [];
  bool isLoading = true;
  bool hasError = false;

  int currentPage = 1;
  int totalPages = 1;
  bool isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchNotifications();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isLoadingMore &&
          currentPage < totalPages) {
        fetchMoreNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
      hasError = false;
      currentPage = 1;
      notifications.clear();
    });

    try {
      final NotificationResponse response = await ApiServices()
          .getNotifications(page: currentPage);

      setState(() {
        notifications = response.data.records;
        totalPages = response.data.totalPages;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print("Error fetching notifications: $e");
    }
  }

  Future<void> fetchMoreNotifications() async {
    if (currentPage >= totalPages) return;

    setState(() => isLoadingMore = true);

    try {
      currentPage += 1;
      final NotificationResponse response = await ApiServices()
          .getNotifications(page: currentPage);

      setState(() {
        notifications.addAll(response.data.records);
        totalPages = response.data.totalPages;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() => isLoadingMore = false);
      print("Error fetching more notifications: $e");
    }
  }

  String formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) return "Just now";
      if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
      if (difference.inHours < 24) return "${difference.inHours}h ago";
      if (difference.inDays < 7) return "${difference.inDays}d ago";

      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return "";
    }
  }

  Widget _buildShimmerTile() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// --- ILLUSTRATION / IMAGE PLACEHOLDER ---
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 72,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 26),

              /// --- TITLE ---
              const Text(
                "No Notifications Yet",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              /// --- SUBTITLE ---
              const Text(
                "Your recent notifications will show up here.\nCheck back later",
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read, color: AppColors.primary),
            onPressed: isLoading
                ? null
                : () async {
                    setState(() {
                      isLoading = true;
                    });
                    try {
                      await ApiServices().markAllNotificationsAsRead();

                      setState(() {
                        for (var notif in notifications) {
                          notif.isRead = true;
                        }
                      });

                      showAppSnackBar(
                        icon: Icons.check_circle_rounded,
                        context,
                        title: "Success",
                        message: "All notifications marked as read",
                        isSuccess: true,
                      );
                    } catch (e) {
                      showAppSnackBar(
                        icon: Icons.error_outline,
                        context,
                        title: "Error",
                        message: "Failed to mark as read",
                        isSuccess: false,
                      );
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
            tooltip: 'Mark all as read',
          ),
        ],
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
      body: RefreshIndicator(
        onRefresh: fetchNotifications,
        child: isLoading
            ? ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => _buildShimmerTile(),
              )
            : hasError
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    child: Center(
                      child: Text(
                        "Failed to load notifications",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                ],
              )
            : notifications.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                itemCount: notifications.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < notifications.length) {
                    final notification = notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _NotificationTile(
                        notificationId: notification.id,
                        title: notification.title,
                        message: notification.body,
                        time: formatTime(notification.createdAt),
                        isUnread: !notification.isRead,
                        icon: Icons.notifications,
                        onTap: () async {
                          if (!notification.isRead) {
                            try {
                              await ApiServices().markNotificationAsRead(
                                notificationId: notification.id,
                              );
                              setState(() {
                                notification.isRead = true; // update UI
                              });
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Failed to mark as read"),
                                ),
                              );

                              showAppSnackBar(
                                icon: Icons.error_outline,
                                context,
                                title: "Error",
                                message: "Failed to mark as read",
                                isSuccess: false,
                              );
                            }
                          }
                        },
                      ),
                    );
                  } else {
                    // shimmer at bottom while loading more
                    return _buildShimmerTile();
                  }
                },
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final int notificationId; // NEW
  final String title;
  final String message;
  final String time;
  final bool isUnread;
  final IconData? icon;
  final VoidCallback? onTap; // NEW

  const _NotificationTile({
    required this.notificationId, // NEW
    required this.title,
    required this.message,
    required this.time,
    required this.isUnread,
    this.icon,
    this.onTap, // NEW
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // USE CALLBACK
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: isUnread
              ? Border(left: BorderSide(color: AppColors.primaryDark, width: 4))
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon ?? Icons.notifications,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                if (isUnread)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 14,
                            color: isUnread
                                ? Colors.black
                                : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnread ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
