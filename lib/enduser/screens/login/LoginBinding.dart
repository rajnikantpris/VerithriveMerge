import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/login/LoginController.dart';

import '../../data/remote/project_remote_data_source.dart';
import '../../data/remote/project_remote_data_source_impl.dart';
import '../../data/repository/project_repository.dart';
import '../../data/repository/project_repository_impl.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // Use lazyPut with fenix: true to reuse existing instances
    Get.lazyPut(() => LoginController(), fenix: true);
    Get.lazyPut<ProjectRepository>(() => ProjectRepositoryImpl(), tag: (ProjectRepository).toString(), fenix: true);
    Get.lazyPut<ProjectRemoteDataSource>(() => ProjectRemoteDataSourceImpl(), tag: (ProjectRemoteDataSource).toString(), fenix: true);
  }
}
