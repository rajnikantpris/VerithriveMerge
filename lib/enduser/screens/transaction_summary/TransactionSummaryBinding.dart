import 'package:get/get.dart';
import 'TransactionSummaryController.dart';
import '../../data/repository/project_repository.dart';
import '../../data/repository/project_repository_impl.dart';

class TransactionSummaryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProjectRepository>(() => ProjectRepositoryImpl(), tag: (ProjectRepository).toString());
    Get.lazyPut<TransactionSummaryController>(() => TransactionSummaryController());
  }
}
