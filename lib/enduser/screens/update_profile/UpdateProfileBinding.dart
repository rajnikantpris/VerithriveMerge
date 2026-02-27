import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/update_profile/UpdateProfileController.dart';
import '../../data/repository/project_repository.dart';
import '../../data/repository/project_repository_impl.dart';
import '../../data/remote/project_remote_data_source.dart';
import '../../data/remote/project_remote_data_source_impl.dart';

class UpdateProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Register dependencies first (in order of dependency chain)
    // ProjectRemoteDataSource must be registered before ProjectRepository
    Get.lazyPut<ProjectRemoteDataSource>(() => ProjectRemoteDataSourceImpl(), tag: (ProjectRemoteDataSource).toString());
    Get.lazyPut<ProjectRepository>(() => ProjectRepositoryImpl(), tag: (ProjectRepository).toString());
    // Register controller last, after its dependencies
    Get.lazyPut(() => UpdateProfileController());
  }
}

