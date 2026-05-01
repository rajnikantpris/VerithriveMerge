import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/base_view.dart';
import '../../routes/app_routes.dart';
import '../../theme/colors.dart';
import '../../theme/fonts.dart';
import '../../theme/font_sizes.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/image_paths.dart';
import 'messages_controller.dart';

/// Messages tab UI.
class MessagesTab extends BaseView<MessagesController> {
  const MessagesTab({super.key, required this.controller});

  final MessagesController controller;

  // @override
  // Widget build(BuildContext context) {
  //   return Container(
  //     color: AppColor.white,
  //     child: Column(
  //       children: [
  //         Padding(
  //           padding: EdgeInsets.fromLTRB(
  //             HightWidthSizes.setValue_16,
  //             HightWidthSizes.setValue_16,
  //             HightWidthSizes.setValue_16,
  //             HightWidthSizes.setValue_10,
  //           ),
  //           child: _SearchField(
  //             onChanged: controller.updateSearch,
  //             onClear: () => controller.updateSearch(''),
  //           ),
  //         ),
  //         Expanded(
  //           child: Obx(() {
  //             final items = controller.filteredMessages;
  //             if (items.isEmpty) {
  //               return RefreshIndicator(
  //                 onRefresh: () => controller.checkAndReconnectSocket(),
  //                 child: SingleChildScrollView(
  //                   physics: const AlwaysScrollableScrollPhysics(),
  //                   child: SizedBox(
  //                     height: MediaQuery.of(context).size.height * 0.6,
  //                     child: Center(
  //                       child: Text(
  //                         'No Message found',
  //                         style: TextStyle(
  //                           fontFamily: AppFonts.rubikRegular,
  //                           fontSize: FontSizes.setFontValue_16,
  //                           fontWeight: FontWeight.w400,
  //                           color: AppColor.color_7F7F7F,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             }
  //             return RefreshIndicator(
  //               onRefresh: () => controller.checkAndReconnectSocket(),
  //               child: ListView.separated(
  //                 padding: EdgeInsets.only(
  //                   left: HightWidthSizes.setValue_16,
  //                   right: HightWidthSizes.setValue_16,
  //                   bottom: HightWidthSizes.setValue_16,
  //                 ),
  //                 itemBuilder: (context, index) {
  //                   final item = items[index];
  //                   return _MessageTile(item: item);
  //                 },
  //                 separatorBuilder: (_, __) => SizedBox(
  //                   height: HightWidthSizes.setValue_10,
  //                 ),
  //                 itemCount: items.length,
  //               ),
  //             );
  //           }),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget buildView(BuildContext context) {
    // Log screen view analytics
    /*
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(
        screenName: 'ProfessionalMessagesScreen',
        screenClass: 'MessagesTab',
        pageCategory: 'messaging',
        elementLocation: 'view',
      );
    });
    */

    return Container(
      color: AppColor.white,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              HightWidthSizes.setValue_16,
              HightWidthSizes.setValue_16,
              HightWidthSizes.setValue_16,
              HightWidthSizes.setValue_10,
            ),
            child: _SearchField(
              onChanged: controller.updateSearch,
              onClear: () => controller.updateSearch(''),
            ),
          ),
          Expanded(
            child: Obx(() {
              final items = controller.filteredMessages;
              if (items.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => controller.checkAndReconnectSocket(),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppImages.chat_list_svg(
                                  width: 64,
                                  height: 64,
                                  color: AppColor.color_9D9D9D.withOpacity(0.5),
                                ),
                                SizedBox(height: HightWidthSizes.setValue_16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubikMedium,
                                    fontSize: FontSizes.setFontValue_18,
                                    color: AppColor.color_9D9D9D,
                                  ),
                                ),
                                SizedBox(height: HightWidthSizes.setValue_8),
                                Text(
                                  'Your conversations will appear here',
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubikRegular,
                                    fontSize: FontSizes.setFontValue_14,
                                    color: AppColor.color_9D9D9D,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => controller.checkAndReconnectSocket(),
                child: ListView.separated(
                  padding: EdgeInsets.only(
                    left: HightWidthSizes.setValue_16,
                    right: HightWidthSizes.setValue_16,
                    bottom: HightWidthSizes.setValue_16,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MessageTile(item: item);
                  },
                  separatorBuilder: (_, __) => SizedBox(
                    height: HightWidthSizes.setValue_10,
                  ),
                  itemCount: items.length,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.onChanged, required this.onClear});

  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: HightWidthSizes.setValue_45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
        border: Border.all(
          color: const Color(0x33000000), // #00000033
          width: HightWidthSizes.setValue_1,
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search here',
          hintStyle: TextStyle(
            fontFamily: AppFonts.rubikRegular,
            fontSize: FontSizes.setFontValue_16,
            fontWeight: FontWeight.w400,
            color: AppColor.color_7F7F7F,
          ),
          prefixIcon: const Icon(Icons.search, color: AppColor.color_BFBFBF),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: AppColor.color_BFBFBF),
            onPressed: () {
              _controller.clear();
              widget.onClear();
            },
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: HightWidthSizes.setValue_10,
          ),
        ),
        style: TextStyle(
          fontFamily: AppFonts.rubikRegular,
          fontSize: FontSizes.setFontValue_15,
          fontWeight: FontWeight.w400,
          color: AppColor.color_32435F,
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.item});

  final MessageItem item;

  @override
  Widget build(BuildContext context) {
    final hasUnread = item.unreadCount > 0;
    return Container(
      decoration: BoxDecoration(
        color: item.highlight ? AppColor.color_D7F1EB : AppColor.white,
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: HightWidthSizes.setValue_10,
          vertical: HightWidthSizes.setValue_6,
        ),
        onTap: () => Get.toNamed(Routes.chat, arguments: item),
        leading: _Avatar(item: item),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.rubikMedium,
                  fontWeight: FontWeight.w500,
                  fontSize: FontSizes.setFontValue_14,
                  color: AppColor.color_1B1A57,
                ),
              ),
            ),
            SizedBox(width: HightWidthSizes.setValue_8),
            Text(
              item.timeLabel,
              style: TextStyle(
                fontFamily: AppFonts.rubikLight,
                fontSize: FontSizes.setFontValue_12,
                color: AppColor.color_333333,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        subtitle: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (item.showDeliveredTick) ...[
              Icon(
                Icons.done_all,
                size: HightWidthSizes.setValue_16,
                color: AppColor.color_B5B6CA,
              ),
              SizedBox(width: HightWidthSizes.setValue_4),
            ],
            Expanded(
              child: Text(
                item.lastMessage,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontSize: FontSizes.setFontValue_12,
                  color: AppColor.color_4F5E7B,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (hasUnread) ...[
              SizedBox(width: HightWidthSizes.setValue_8),
              _UnreadBadge(count: item.unreadCount),
            ],
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.item});

  final MessageItem item;

  @override
  Widget build(BuildContext context) {
    final avatarSize = HightWidthSizes.setValue_50;
    final isNetworkImage = item.avatarAsset.startsWith('http://') ||
        item.avatarAsset.startsWith('https://');

    return SizedBox(
      height: avatarSize,
      width: avatarSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: AppColor.color_BFBFBF.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
          ClipOval(
            child: isNetworkImage
                ? Image.network(
                    item.avatarAsset,
                    width: avatarSize,
                    height: avatarSize,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        AppImages.user,
                        width: HightWidthSizes.setValue_20,
                        height: HightWidthSizes.setValue_20,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: avatarSize,
                        height: avatarSize,
                        color: AppColor.color_BFBFBF.withOpacity(0.4),
                        child: Center(
                          child: SizedBox(
                            width: HightWidthSizes.setValue_20,
                            height: HightWidthSizes.setValue_20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : Image.asset(
                    item.avatarAsset,
                    width: HightWidthSizes.setValue_20,
                    height: HightWidthSizes.setValue_20,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
          ),
          if (item.isOnline)
            Positioned(
              bottom: HightWidthSizes.setValue_2,
              right: HightWidthSizes.setValue_2,
              child: Container(
                width: HightWidthSizes.setValue_10,
                height: HightWidthSizes.setValue_10,
                decoration: const BoxDecoration(
                  color: AppColor.color_2FC4B2,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: HightWidthSizes.setValue_24,
      height: HightWidthSizes.setValue_24,
      decoration: const BoxDecoration(
        color: AppColor.color_2FC4B2,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: AppFonts.rubikMedium,
          fontWeight: FontWeight.w500,
          fontSize: FontSizes.setFontValue_12,
          color: AppColor.white,
        ),
      ),
    );
  }
}
