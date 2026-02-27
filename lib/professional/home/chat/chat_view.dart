import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/base_view.dart';
import '../../../theme/colors.dart';
import '../../../theme/fonts.dart';
import '../../../theme/font_sizes.dart';
import '../../../theme/hight_width_sizes.dart';
import '../../../theme/image_paths.dart';
import 'chat_controller.dart';

class ChatView extends BaseView<ChatController> {
  const ChatView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000), // #0000001A
              blurRadius: HightWidthSizes.setValue_10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: AppColor.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: true,
          iconTheme: const IconThemeData(
            color: Color(0xFF000000), // #000000
          ),
          title: Obx(() {
            final peer = controller.peer.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  peer.name,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_20,
                    color: AppColor.color_414141,
                  ),
                ),
                if (peer.isOnline)
                  Text(
                    'Online',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_12,
                      color: AppColor.color_2FC4B2,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Obx(
                () {
                  if (controller.messages.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  // Build list with date separators
                  final items = <Widget>[];

                  for (int i = 0; i < controller.messages.length; i++) {
                    final message = controller.messages[i];
                    final previousMessage =
                        i > 0 ? controller.messages[i - 1] : null;

                    // Check if we need to add a date separator
                    final shouldShowDateSeparator = previousMessage == null ||
                        controller.isDifferentDay(
                          previousMessage.timestamp,
                          message.timestamp,
                        );

                    if (shouldShowDateSeparator && message.timestamp != null) {
                      items.add(
                        _DateSeparator(
                          dateLabel:
                              controller.formatDateHeader(message.timestamp!),
                        ),
                      );
                    }

                    items.add(
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i < controller.messages.length - 1
                              ? HightWidthSizes.setValue_10
                              : 0,
                        ),
                        child: _ChatBubble(
                          message: message,
                          avatarAsset: controller.peer.value.avatarAsset,
                        ),
                      ),
                    );
                  }

                  return ListView(
                    controller: controller.scrollController,
                    padding: EdgeInsets.fromLTRB(
                      HightWidthSizes.setValue_16,
                      HightWidthSizes.setValue_12,
                      HightWidthSizes.setValue_16,
                      HightWidthSizes.setValue_24,
                    ),
                    children: items,
                  );
                },
              ),
            ),
            _MessageComposer(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: HightWidthSizes.setValue_16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColor.color_ECECEC,
              thickness: 1,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: HightWidthSizes.setValue_12,
            ),
            child: Text(
              dateLabel,
              style: TextStyle(
                fontFamily: AppFonts.rubikRegular,
                fontWeight: FontWeight.w400,
                fontSize: FontSizes.setFontValue_12,
                color: AppColor.color_7F7F7F,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColor.color_ECECEC,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.avatarAsset});

  final ChatMessage message;
  final String avatarAsset;

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isMine ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor =
        message.isMine ? AppColor.color_E2F3F2 : AppColor.color_F5F7F8;

    final bubble = Column(
      crossAxisAlignment:
          message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_14,
            vertical: HightWidthSizes.setValue_12,
          ),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(HightWidthSizes.setValue_14),
              topRight: Radius.circular(HightWidthSizes.setValue_14),
              bottomLeft: Radius.circular(
                  message.isMine ? HightWidthSizes.setValue_14 : 0),
              bottomRight: Radius.circular(
                  message.isMine ? 0 : HightWidthSizes.setValue_14),
            ),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              fontFamily: AppFonts.rubikRegular,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_14,
              color: AppColor.color_4F5E7B,
            ),
          ),
        ),
        SizedBox(height: HightWidthSizes.setValue_4),
        Text(
          message.timeLabel,
          style: TextStyle(
            fontFamily: AppFonts.rubikRegular,
            fontWeight: FontWeight.w400,
            fontSize: FontSizes.setFontValue_11,
            color: AppColor.color_7F7F7F,
          ),
        ),
      ],
    );

    if (message.isMine) {
      return Align(alignment: alignment, child: bubble);
    }

    final avatarSize = HightWidthSizes.setValue_40;

    return Align(
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.color_BFBFBF.withOpacity(0.3),
            ),
            clipBehavior: Clip.hardEdge,
            child: _buildAvatarImage(),
          ),
          SizedBox(width: HightWidthSizes.setValue_10),
          bubble,
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    if (avatarAsset.isEmpty) {
      return Icon(Icons.person, color: AppColor.white);
    }

    // If avatarAsset looks like a URL, load it as a network image
    if (avatarAsset.startsWith('http://') || avatarAsset.startsWith('https://')) {
      return Image.network(
        avatarAsset,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to placeholder icon if network image fails
          return Icon(Icons.person, color: AppColor.white);
        },
      );
    }

    // Otherwise, treat it as a local asset path
    return Image.asset(
      avatarAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to placeholder if asset is missing
        return Icon(Icons.person, color: AppColor.white);
      },
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({required this.controller});

  final ChatController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          HightWidthSizes.setValue_16,
          HightWidthSizes.setValue_5,
          HightWidthSizes.setValue_16,
          HightWidthSizes.setValue_5,
        ),
        decoration: const BoxDecoration(
          color: AppColor.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 4,
              offset: Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: HightWidthSizes.setValue_16,
                ),
                decoration: BoxDecoration(
                  color: AppColor.color_F5F5F5,
                  borderRadius:
                      BorderRadius.circular(HightWidthSizes.setValue_24),
                  border: Border.all(color: AppColor.color_F5F5F5),
                ),
                child: TextField(
                  controller: controller.inputController,
                  decoration: InputDecoration(
                    hintText: 'Write message',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      fontSize: FontSizes.setFontValue_14,
                      color: AppColor.color_1B1A57,
                    ),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_14,
                    color: AppColor.color_1B1A57,
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
            ),
            SizedBox(width: HightWidthSizes.setValue_8),
            GestureDetector(
              onTap: controller.sendMessage,
              child: Container(
                width: HightWidthSizes.setValue_35,
                height: HightWidthSizes.setValue_35,
                decoration: const BoxDecoration(
                  color: AppColor.color_2FC4B2,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(HightWidthSizes.setValue_9),
                child: AppImages.chat_send_svg(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
