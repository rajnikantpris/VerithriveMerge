import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/change_password/ChangePasswordController.dart';
import 'package:verithrive_dev/enduser/data/remote/project_remote_data_source_impl.dart';
import 'package:verithrive_dev/enduser/data/remote/project_remote_data_source.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository_impl.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository.dart';

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProjectRemoteDataSource>(() => ProjectRemoteDataSourceImpl(), tag: (ProjectRemoteDataSource).toString());
    Get.lazyPut<ProjectRepository>(() => ProjectRepositoryImpl(), tag: (ProjectRepository).toString());
    Get.lazyPut(() => ChangePasswordController());
  }
}
