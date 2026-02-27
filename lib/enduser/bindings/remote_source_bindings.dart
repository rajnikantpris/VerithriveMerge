import 'package:get/get.dart';

import '../data/remote/project_remote_data_source.dart';
import '../data/remote/project_remote_data_source_impl.dart';


class RemoteSourceBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProjectRemoteDataSource>(
      () => ProjectRemoteDataSourceImpl(),
      tag: (ProjectRemoteDataSource).toString(),
    );
  }
}
