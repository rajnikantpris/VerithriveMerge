import 'dart:io';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/data/repository/project_repository.dart';
import '../remote/project_remote_data_source.dart';

class ProjectRepositoryImpl extends ProjectRepository{

  final ProjectRemoteDataSource _remoteSource =
  Get.find(tag: (ProjectRemoteDataSource).toString());

  @override
  Future<dynamic> sendPostApiRequest(Map<String, dynamic> Function() toJson,String apiname,bool isToken) {
    return _remoteSource.sendPostApiRequest(toJson,apiname,isToken);
  }

  @override
  Future sendGetApiNoParamRequest(String apiname) {
    return _remoteSource.sendGetApiNoParamRequest(apiname);
  }

  @override
  Future sendGetApiWithParamRequest(Map<String, dynamic> Function() toJson, String apiname, bool isToken) {
    return _remoteSource.sendGetApiWithParamRequest(toJson,apiname,isToken);
  }

  @override
  Future<dynamic> sendPutApiRequest(Map<String, dynamic> Function() toJson,String apiname,bool isToken) {
    return _remoteSource.sendPutApiRequest(toJson,apiname,isToken);
  }

  @override
  Future sendMultipartApiRequest(
    Map<String, dynamic> Function() toJson,
    String apiName,
    bool isToken, {
    File? imageFile,
    String? imageFieldName,
  }) {
    return _remoteSource.sendMultipartApiRequest(
      toJson,
      apiName,
      isToken,
      imageFile: imageFile,
      imageFieldName: imageFieldName,
    );
  }

  @override
  Future sendPutMultipartApiRequest(
    Map<String, dynamic> Function() toJson,
    String apiName,
    bool isToken, {
    File? imageFile,
    String? imageFieldName,
  }) {
    return _remoteSource.sendPutMultipartApiRequest(
      toJson,
      apiName,
      isToken,
      imageFile: imageFile,
      imageFieldName: imageFieldName,
    );
  }

  @override
  Future<dynamic> sendDeleteApiRequest(String apiName, bool isToken) {
    return _remoteSource.sendDeleteApiRequest(apiName, isToken);
  }

}