import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/screens/forgot_password/ForgotPasswordController.dart';
import '../../data/repository/project_repository.dart';
import '../../data/repository/project_repository_impl.dart';
import '../../data/remote/project_remote_data_source.dart';
import '../../data/remote/project_remote_data_source_impl.dart';

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ForgotPasswordController(), permanent: false);
    Get.lazyPut<ProjectRepository>(() => ProjectRepositoryImpl(), tag: (ProjectRepository).toString());
    Get.lazyPut<ProjectRemoteDataSource>(() => ProjectRemoteDataSourceImpl(), tag: (ProjectRemoteDataSource).toString());
  }
}
