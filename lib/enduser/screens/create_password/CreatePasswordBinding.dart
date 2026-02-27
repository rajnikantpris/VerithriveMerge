import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/create_password/CreatePasswordController.dart';
import '../../data/repository/project_repository.dart';
import '../../data/repository/project_repository_impl.dart';
import '../../data/remote/project_remote_data_source.dart';
import '../../data/remote/project_remote_data_source_impl.dart';

class CreatePasswordBinding extends Bindings {
  @override
  void dependencies() {
    // Register dependencies first (in order of dependency chain)
    // ProjectRemoteDataSource must be registered before ProjectRepository
    Get.lazyPut<ProjectRemoteDataSource>(() => ProjectRemoteDataSourceImpl(), tag: (ProjectRemoteDataSource).toString());
    Get.lazyPut<ProjectRepository>(() => ProjectRepositoryImpl(), tag: (ProjectRepository).toString());
    // Register controller last, after its dependencies
    // Using permanent: false ensures controller is removed when route is popped
    Get.lazyPut(() => CreatePasswordController(), fenix: false);
  }
}
