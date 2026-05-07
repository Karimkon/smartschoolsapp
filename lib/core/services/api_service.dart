import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Uint8List> getBytes(String path, {Map<String, dynamic>? params}) async {
    final res = await _dio.get<List<int>>(
      path,
      queryParameters: params,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout:    const Duration(seconds: 15),
      ),
    );
    return Uint8List.fromList(res.data!);
  }
}
