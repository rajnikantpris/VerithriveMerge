import 'package:get/get.dart';
import 'FitnessGoalController.dart';
import '../../data/remote/project_remote_data_source.dart';
import '../../data/remote/project_remote_data_source_impl.dart';
import '../../data/repository/project_repository.dart';
import '../../data/repository/project_repository_impl.dart';

class FitnessGoalBinding extends Bindings {
  @override
  void dependencies() {
    // Register dependencies first (in order of dependency chain)
    // ProjectRemoteDataSource must be registered before ProjectRepository
    if (!Get.isRegistered<ProjectRemoteDataSource>(tag: (ProjectRemoteDataSource).toString())) {
      Get.lazyPut<ProjectRemoteDataSource>(
        () => ProjectRemoteDataSourceImpl(),
        tag: (ProjectRemoteDataSource).toString(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<ProjectRepository>(tag: (ProjectRepository).toString())) {
      Get.lazyPut<ProjectRepository>(
        () => ProjectRepositoryImpl(),
        tag: (ProjectRepository).toString(),
        fenix: true,
      );
    }
    // Register controller last, after its dependencies
    Get.lazyPut<FitnessGoalController>(() => FitnessGoalController());
  }
}

