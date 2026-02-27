import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/data/remote/project_remote_data_source.dart';
import 'package:verithrive_dev/enduser/data/remote/project_remote_data_source_impl.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository_impl.dart';
import 'package:verithrive_dev/enduser/screens/therapy_list/TherapistController.dart';

class TherapyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProjectRemoteDataSource>(() => ProjectRemoteDataSourceImpl(), tag: (ProjectRemoteDataSource).toString());
    Get.lazyPut<ProjectRepository>(() => ProjectRepositoryImpl(), tag: (ProjectRepository).toString());
    Get.put(TherapistController());
  }
}
