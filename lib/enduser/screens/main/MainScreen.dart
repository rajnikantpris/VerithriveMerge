import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/core/widget/common_widgets.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginBinding.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginView.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/services/deep_link_service.dart';
import 'package:verithrive_dev/services/foreground_notification_service.dart';
import '../../utils/AppText.dart';
import '../../utils/app_text_styles.dart';
import '../../data/repository/project_repository.dart';
import '../../data/repository/project_repository_impl.dart';
import '../../data/remote/project_remote_data_source.dart';
import '../../data/remote/project_remote_data_source_impl.dart';
import '../../core/values/sharePrefrenceConst.dart';
import '../../routes/app_routes.dart';
import 'package:verithrive_dev/services/storage_service.dart';
import '../booking/BookingsController.dart';
import '../booking/BookingsScreen.dart';
import '../home_main/HomeMainController.dart';
import '../home_main/HomeMainScreen.dart';
import '../message/MessagesController.dart';
import '../message/MessagesScreen.dart';
import '../profile_main/ProfileMainController.dart';
import '../profile_main/ProfileMainScreen.dart';
import '../save/SavedController.dart';
import '../save/SavedScreen.dart';
import '../../../services/analytics_service.dart';
import 'MainTabController.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final MainTabController _tabController;
  final StorageService _storageService = Get.find<StorageService>();

  // List of pages
  final List<Widget> pages = [
    HomeMainScreen(),
    BookingsScreen(),
    MessagesScreen(),
    SavedScreen(),
    ProfileMainScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Ensure dependencies are registered before creating controllers
    _ensureDependenciesRegistered();

    // Tab controller for programmatic tab switching (e.g., from notifications)
    if (Get.isRegistered<MainTabController>()) {
      _tabController = Get.find<MainTabController>();
    } else {
      _tabController = Get.put(MainTabController());
    }

    // Initialize all controllers at startup
    Get.put(HomeMainController(), tag: 'home');
    Get.put(BookingsController(), tag: 'bookings');
    Get.put(MessagesController(), tag: 'messages');
    Get.put(SavedController(), tag: 'saved');
    Get.put(ProfileMainController(), tag: 'profile');

    // Load initial data for home screen
    Get.find<HomeMainController>(tag: 'home').refreshData();

    // If MainScreen was opened with an initial tab request (e.g., notification),
    // switch tabs AFTER first frame so UI is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Handle pending notification if app was opened from terminated state via notification
      // This ensures proper navigation stack: Splash -> Main -> Chat
      ForegroundNotificationService.handlePendingNotificationIfAny();
//// New Code
      // Handle pending booking navigation from foreground notifications received during splash
      ForegroundNotificationService.handlePendingBookingNavigationIfAny();

      // Handle pending review dialog from foreground notifications received during splash
      ForegroundNotificationService.handlePendingReviewDialogIfAny();

      // Open professional profile if app was launched via share deep link
      DeepLinkService.instance.handlePendingProfileIfAny();

      final args = Get.arguments;
      if (args is Map && args['openTab'] is int) {
        final int openTab = args['openTab'] as int;
        _tabController.setTab(openTab);
        if (openTab == 1 &&
            Get.isRegistered<BookingsController>(tag: 'bookings')) {
          Get.find<BookingsController>(tag: 'bookings').refreshData();
        }
      }
    });
  }

  void _ensureDependenciesRegistered() {
    // Ensure ProjectRepository is registered
    if (!Get.isRegistered<ProjectRepository>(
        tag: (ProjectRepository).toString())) {
      Get.lazyPut<ProjectRepository>(
        () => ProjectRepositoryImpl(),
        tag: (ProjectRepository).toString(),
        fenix: true,
      );
    }

    // Ensure ProjectRemoteDataSource is registered (required by ProjectRepository)
    if (!Get.isRegistered<ProjectRemoteDataSource>(
        tag: (ProjectRemoteDataSource).toString())) {
      Get.lazyPut<ProjectRemoteDataSource>(
        () => ProjectRemoteDataSourceImpl(),
        tag: (ProjectRemoteDataSource).toString(),
        fenix: true,
      );
    }
  }

  Future<void> onTabTapped(int index) async {
    // Analytics: Log global navigation tap event
    String elementText = '';
    switch (index) {
      case 0:
        elementText = 'Home';
        break;
      case 1:
        elementText = 'Bookings';
        break;
      case 2:
        elementText = 'Messages';
        break;
      case 3:
        elementText = 'Saved';
        break;
      case 4:
        elementText = 'Profile';
        break;
      default:
        elementText = 'Unknown';
        break;
    }

    AnalyticsService.instance.logEvent(
      name: 'global_nav_tap',
      parameters: {
        'screen_name': 'MainScreen',
        'screen_class': 'MainScreen',
        'element_text': elementText,
        'element_location': 'nav',
        'page_category': elementText,
      },
    );

    // Check if user is guest and trying to access restricted tabs
    // Only check on actual user tap, not during initial load
    if (_tabController.currentIndex.value != index) {
      bool isGuest =
          _storageService.readBool(SharePreferenceConst.isGuest) ?? false;

      if (isGuest) {
        // Restrict access to bookings, messages, saved, and profile tabs for guests
        if (index == 1 || index == 2 || index == 3 || index == 4) {
          String featureName = '';
          switch (index) {
            case 1:
              featureName = 'Bookings';
              break;
            case 2:
              featureName = 'Messages';
              break;
            case 3:
              featureName = 'Saved';
              break;
            case 4:
              featureName = 'Profile';
              break;
          }

          //  CommonUtils.getIntance().toastMessage("Please login to access "+featureName);

          Get.to(
            () => const LoginView(),
            binding: LoginBinding(),
          );

          // Check if login route is already active to prevent multiple navigations
          /*      if (!Get.currentRoute.startsWith('/login')) {
            // Redirect to login screen
            Get.toNamed(AppRoutes.login);
          }*/
          return;
        }
      }
    }

    if (_tabController.currentIndex.value != index) {
      _tabController.setTab(index);
    }

    // Refresh data when switching tabs
    switch (index) {
      case 0:
        // Home screen - call notification count API every time
        if (Get.isRegistered<HomeMainController>(tag: 'home')) {
          Get.find<HomeMainController>(tag: 'home').fetchNotificationCount();
        }
        break;
      case 1:
        Get.find<BookingsController>(tag: 'bookings').refreshData();
        break;
      case 2:
        Get.find<MessagesController>(tag: 'messages').refreshData();
        break;
      case 3:
        Get.find<SavedController>(tag: 'saved').refreshData();
        break;
      case 4:
        Get.find<ProfileMainController>(tag: 'profile').refreshData();
        break;
    }
  }

  @override
  void dispose() {
    // Clean up controllers when MainScreen is disposed
    Get.delete<HomeMainController>(tag: 'home');
    Get.delete<BookingsController>(tag: 'bookings');
    Get.delete<MessagesController>(tag: 'messages');
    Get.delete<SavedController>(tag: 'saved');
    Get.delete<ProfileMainController>(tag: 'profile');
    super.dispose();
  }

  Widget _buildNavItem(int index, String iconAsset, String label) {
    bool isSelected = _tabController.currentIndex.value == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTabTapped(index),
          splashColor: AppColors.primaryColor.withOpacity(0.2),
          highlightColor: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 60,
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  iconAsset,
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.unselectedTabColor,
                  width: 24,
                  height: 24,
                ),
                SizedBox(height: 4),
                Text(
                  label,
                  style: isSelected
                      ? AppTextStyles.rubikMedium(
                          fontSize: 12,
                          color: AppColors.primaryColor,
                        )
                      : AppTextStyles.rubikRegular(
                          fontSize: 12,
                          color: AppColors.unselectedTabColor,
                        ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          body: IndexedStack(
              index: _tabController.currentIndex.value, children: pages),
          bottomNavigationBar: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 0,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 0,
                  blurRadius: 5,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: Row(
                children: [
                  _buildNavItem(0, AppAssets.home, AppText.home),
                  _buildNavItem(1, AppAssets.booking, AppText.bookings),
                  _buildNavItem(2, AppAssets.messages, AppText.messages),
                  _buildNavItem(3, AppAssets.saved, AppText.saved),
                  _buildNavItem(4, AppAssets.profile_tab, AppText.profile),
                ],
              ),
            ),
          ),
        ));
  }
}
