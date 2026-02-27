import 'package:dio/dio.dart';
import 'package:get/get_connect/http/src/status/http_status.dart';
import 'package:verithrive_dev/enduser/flavors/build_config.dart';
import '../../network/dio_provider.dart';
import '../../network/error_handlers.dart';
import '../../network/exceptions/base_exception.dart';

abstract class BaseRemoteSource {
  Dio get dioClient => DioProvider.dioWithHeaderToken;

  final logger = BuildConfig.instance.config.logger;

  Future<Response<T>> callApiWithErrorParser<T>(Future<Response<T>> api) async {
    try {
      Response<T> response = await api;

      if (response.statusCode != HttpStatus.ok ||
          (response.data as Map<String, dynamic>)['statusCode'] !=
              HttpStatus.ok) {
        // TODO
      }

      return response;
    } on DioError catch (dioError) {
      Exception exception = handleDioError(dioError);
      //logger.e("Throwing error from repository: >>>>>>> $exception : ${(exception as BaseException).message}");
      throw exception;
    } catch (error) {
      //logger.e("Generic error: >>>>>>> $error");
      if (error is BaseException) {
        rethrow;
      }
      throw handleError("$error");
    }
  }
}
