import 'dart:io';

abstract class ProjectRepository{

  Future<dynamic> sendPostApiRequest(Map<String, dynamic> Function() toJson,String apiName,bool isToken);

  Future<dynamic> sendPutApiRequest(Map<String, dynamic> Function() toJson,String apiName,bool isToken);

  Future<dynamic> sendGetApiWithParamRequest(Map<String, dynamic> Function() toJson,String apiName, bool isToken);

  Future<dynamic> sendGetApiNoParamRequest(String apiname);

  Future<dynamic> sendMultipartApiRequest(
    Map<String, dynamic> Function() toJson,
    String apiName,
    bool isToken, {
    File? imageFile,
    String? imageFieldName,
  });

  Future<dynamic> sendPutMultipartApiRequest(
    Map<String, dynamic> Function() toJson,
    String apiName,
    bool isToken, {
    File? imageFile,
    String? imageFieldName,
  });

  Future<dynamic> sendDeleteApiRequest(String apiName, bool isToken);

}