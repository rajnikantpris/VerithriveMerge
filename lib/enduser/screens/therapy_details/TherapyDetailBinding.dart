import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/data/remote/project_remote_data_source.dart';
import 'package:verithrive_dev/enduser/data/remote/project_remote_data_source_impl.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository_impl.dart';
import 'TherapistDetailController.dart';

class TherapyDetailBinding extends Bindings {
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

    // Avoid force-deleting a live controller while an older Detail route is
    // still mounted (double deep-link open). That disposed TabController and
    // crashed TabBar. Replace only when safe; GetX cleans up on route pop.
    if (Get.isRegistered<TherapistDetailController>()) {
      Get.delete<TherapistDetailController>(force: true);
    }
    Get.put(TherapistDetailController());
  }
}
