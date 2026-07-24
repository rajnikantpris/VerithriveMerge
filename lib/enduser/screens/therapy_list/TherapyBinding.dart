import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/data/remote/project_remote_data_source.dart';
import 'package:verithrive_dev/enduser/data/remote/project_remote_data_source_impl.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository_impl.dart';
import 'package:verithrive_dev/enduser/screens/therapy_list/TherapistController.dart';

class TherapyBinding extends Bindings {
  @override
  void dependencies() {
    final remoteTag = (ProjectRemoteDataSource).toString();
    final repoTag = (ProjectRepository).toString();

    if (!Get.isRegistered<ProjectRemoteDataSource>(tag: remoteTag)) {
      Get.lazyPut<ProjectRemoteDataSource>(
        () => ProjectRemoteDataSourceImpl(),
        tag: remoteTag,
        fenix: true,
      );
    }
    if (!Get.isRegistered<ProjectRepository>(tag: repoTag)) {
      Get.lazyPut<ProjectRepository>(
        () => ProjectRepositoryImpl(),
        tag: repoTag,
        fenix: true,
      );
    }

    if (Get.isRegistered<TherapistController>()) {
      Get.delete<TherapistController>(force: true);
    }
    Get.put(TherapistController());
  }
}
