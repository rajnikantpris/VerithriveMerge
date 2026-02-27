import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/notification/NotificationController.dart';

import '../../data/remote/project_remote_data_source.dart';
import '../../data/remote/project_remote_data_source_impl.dart';
import '../../data/repository/project_repository.dart';
import '../../data/repository/project_repository_impl.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProjectRemoteDataSource>(() => ProjectRemoteDataSourceImpl(), tag: (ProjectRemoteDataSource).toString());
    Get.lazyPut<ProjectRepository>(() => ProjectRepositoryImpl(), tag: (ProjectRepository).toString());
    Get.lazyPut(() => NotificationController());
  }
}
