import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;

import 'dio_provider.dart';
import '../../services/storage_service.dart';

class DioRequestRetrier {
  final dioClient = DioProvider.tokenClient;
  final RequestOptions requestOptions;

  DioRequestRetrier({required this.requestOptions});

  Future<Response<T>> retry<T>() async {
    var header = await getCustomHeaders();

    return await dioClient.request(
      requestOptions.path,
      cancelToken: requestOptions.cancelToken,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
      options: Options(headers: header, method: requestOptions.method),
    );
  }

  Future<Map<String, String>> getCustomHeaders() async {
    final storage = getx.Get.isRegistered<StorageService>()
        ? getx.Get.find<StorageService>()
        : null;
    final String accessToken = storage?.readString(StorageService.keyToken) ??
        storage?.readString('access_token') ??
        '';
    var customHeaders = {'content-type': 'application/json'};
    if (accessToken.trim().isNotEmpty) {
      customHeaders.addAll({
        'Authorization': "Bearer $accessToken",
      });
    }

    return customHeaders;
  }
}
