import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../../core/widget/animated_loader.dart';
import '../../models/Conversation.dart';
import '../../models/ChatMessage.dart';
import 'ChatDetailController.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get controller from binding
    final controller = Get.find<ChatDetailController>();
    final conversation = controller.conversation;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        scrolledUnderElevation: 4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.blueColor),
          onPressed: () {
            Get.back();
          },
        ),
        title: Text(
          conversation.value!.name,
          style: AppTextStyles.mediumTextStyle(
            fontSize: 18,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: AnimatedLoader(
                    assetPath: AppAssets.loader1,
                  ),
                );
              }
              
              if (controller.messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet',
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 16,
                      color: AppColors.grey,
                    ),
                  ),
                );
              }
              
              // Use a key to force rebuild when messages change
              // Use reverse: true to start ListView from bottom
              // This automatically positions the view at the bottom showing newest messages
              return ListView.builder(
                key: ValueKey('messages_${controller.messages.length}'),
                controller: controller.scrollController,
                reverse: true, // Start from bottom, newest messages visible first
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  // Reverse the index to show messages in correct order
                  // When reverse:true, index 0 is the last item, so we need to reverse
                  final reversedIndex = controller.messages.length - 1 - index;
                  final message = controller.messages[reversedIndex];
                 // return _buildMessageBubble(message, conversation);
                },
              );
            }),
          ),
          // Message input
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: 10,
                        bottom: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreyF5F7F8,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: controller.inputController,
                        decoration: InputDecoration(
                          hintText: 'Write message',
                          hintStyle: AppTextStyles.regularTextStyle(
                            fontSize: 14,
                            color: AppColors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => controller.sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: SvgPicture.asset(
                        AppAssets.send,
                        height: 40,
                        width: 40,
                      ),
                      onPressed: () => controller.sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Conversation conversation) {
    final isMe = message.isSentByMe;

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Avatar for incoming messages
            ClipOval(
              child: conversation.profileImageUrl != null &&
                      (conversation.profileImageUrl!.startsWith('http://') ||
                       conversation.profileImageUrl!.startsWith('https://'))
                  ? Image.network(
                      conversation.profileImageUrl!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, size: 20, color: AppColors.grey),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 32,
                          height: 32,
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
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person, size: 20, color: AppColors.grey),
                        );
                      },
                    ),
            ),
            SizedBox(width: 8),
          ],
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primaryLightColor
                        : AppColors.lightGreyF5F7F8,
                    borderRadius: isMe
                        ? BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(0),
                          )
                        : BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(0),
                            bottomRight: Radius.circular(16),
                          ),
                  ),
                  child: Text(
                    message.message,
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 14,
                      color: isMe ? AppColors.black : AppColors.blueColor,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: AppTextStyles.regularTextStyle(
                    fontSize: 11,
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour.$minute';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
