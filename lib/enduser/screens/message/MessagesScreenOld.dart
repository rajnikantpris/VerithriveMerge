import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/message/ChatDetailBinding.dart';
import 'package:verithrive_dev/enduser/screens/message/ChatDetailScreen.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../../models/Conversation.dart';
import '../../core/widget/animated_loader.dart';
import '../../routes/app_routes.dart';
import 'MessagesController.dart';

class MessagesScreenOld extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MessagesController>(tag: 'messages');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4, // 🔴 Add shadow depth (try 2-8)
        shadowColor: Colors.black.withOpacity(
          0.1,
        ), // Optional: customize shadow color
        scrolledUnderElevation: 4,
        centerTitle: true,
        title: Text(
          'Messages',
          style: AppTextStyles.popinSemiboldTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar - always visible, not affected by loading state
          Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.greyText),
              ),
              child: TextField(
                onChanged: (value) =>
                    controller.updateSearchQuery(value),
                decoration: InputDecoration(
                  hintText: 'Search here',
                  hintStyle: AppTextStyles.popinRegularTextStyle(
                    fontSize: 12,
                    color: AppColors.greyText,
                  ),
                  prefixIcon: SvgPicture.asset(
                    AppAssets.search,
                    height: 50,
                    width: 50,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    maxHeight: 24,
                    minHeight: 24,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          // Conversations list with loading state
          Expanded(
            child: Obx(() {
              // Show initial loading indicator only for first load
              if (controller.isInitialLoading.value) {
                return Center(
                  child: AnimatedLoader(
                    assetPath: AppAssets.loader1,
                  ),
                );
              }
              
              // Show loading indicator for manual refresh when list is empty
              if (controller.isLoading.value && controller.conversations.isEmpty) {
                return Center(
                  child: AnimatedLoader(
                    assetPath: AppAssets.loader1,
                  ),
                );
              }
              
              final filteredConversations = controller.filteredConversations;
              if (filteredConversations.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => controller.silentRefreshInbox(), // Use silent refresh
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Text(
                          'No conversations found',
                          style: AppTextStyles.regularTextStyle(
                            fontSize: 16,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filteredConversations.length,
                itemBuilder: (context, index) {
                  final conversation = filteredConversations[index];
                  return _buildConversationItem(
                    context,
                    conversation,
                    controller,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    Conversation conversation,
    MessagesController controller,
  ) {
    return InkWell(
      onTap: () {
        Get.to(
          () => ChatDetailScreen(),
          binding: ChatDetailBinding(),
          arguments: conversation,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: conversation.isHighlighted
              ? AppColors.primaryLightColor
              : Colors.white,
        ),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Profile picture with online status
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipOval(
                  child: conversation.profileImageUrl != null &&
                          (conversation.profileImageUrl!.startsWith('http://') ||
                           conversation.profileImageUrl!.startsWith('https://'))
                      ? Image.network(
                          conversation.profileImageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, color: AppColors.grey),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          conversation.profileImageUrl ?? AppAssets.exercise,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, color: AppColors.grey),
                            );
                          },
                        ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: conversation.isOnline
                          ? Colors.green
                          : AppColors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12),
            // Name and message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    style: AppTextStyles.popinMediumTextStyle(
                      fontSize: 14,
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 14,
                      color: AppColors.greyText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Time and unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  controller.formatTime(conversation.lastMessageTime),
                  style: AppTextStyles.mediumTextStyle(
                    fontSize: 12,
                    color: AppColors.greyText,
                  ),
                ),
                if (conversation.unreadCount > 0) ...[
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      conversation.unreadCount.toString(),
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
