import 'dart:async';

import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class ApiClient {
  final Dio dio;
  final CookieJar cookieJar;
  final Dio _refreshDio;
  final void Function()? onSessionExpired;

  ApiClient._internal(
    this.dio,
    this.cookieJar,
    this._refreshDio,
    this.onSessionExpired,
  );

  factory ApiClient({
    required String baseUrl,
    required String cookieStoragePath,
    void Function()? onSessionExpired,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl,
      followRedirects: false,
      validateStatus: (status) => status != null && status < 500,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    );

    final dio = Dio(options);
    final refreshDio = Dio(options);

    final cookieJar = PersistCookieJar(storage: FileStorage(cookieStoragePath));

    dio.interceptors.add(CookieManager(cookieJar));
    refreshDio.interceptors.add(CookieManager(cookieJar));

    dio.interceptors.add(
      _AuthRefreshInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        cookieJar: cookieJar,
        onSessionExpired: onSessionExpired,
      ),
    );

    return ApiClient._internal(dio, cookieJar, refreshDio, onSessionExpired);
  }
}

class _AuthRefreshInterceptor extends Interceptor {
  final Dio dio;
  final Dio refreshDio;
  final CookieJar cookieJar;
  final void Function()? onSessionExpired;

  Future<void>? _refreshFuture;

  _AuthRefreshInterceptor({
    required this.dio,
    required this.refreshDio,
    required this.cookieJar,
    required this.onSessionExpired,
  });

  bool _isAuthRoute(String path) {
    return path.endsWith('/login') ||
        path.endsWith('/refresh') ||
        path.endsWith('/logout') ||
        path.endsWith('/register');
  }

  bool _shouldHandle(Response response) {
    final ro = response.requestOptions;

    if (response.statusCode != 401) return false;
    if (_isAuthRoute(ro.path)) return false;
    if (ro.extra['__isRetry'] == true) return false;

    return true;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final ro = response.requestOptions;

    // Ha már retry volt és még mindig 401, akkor session vége.
    if (response.statusCode == 401 && ro.extra['__isRetry'] == true) {
      await _expireSession(ro);
      return handler.next(response);
    }

    if (!_shouldHandle(response)) {
      return handler.next(response);
    }

    try {
      await _refreshIfNeeded();
      final retryResponse = await _retry(ro);

      if (retryResponse.statusCode == 401) {
        await _expireSession(ro);
      }

      return handler.resolve(retryResponse);
    } catch (_) {
      await _expireSession(ro);
      return handler.next(response);
    }
  }
  
  Future<void> _expireSession(RequestOptions ro) async {
    try {
      await cookieJar.deleteAll();
    } catch (_) {}

    final suppress = ro.extra['__suppressSessionExpired'] == true;
    if (!suppress) {
      onSessionExpired?.call();
    }
  }

  Future<void> _refreshIfNeeded() {
    _refreshFuture ??= _doRefresh().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  Future<void> _doRefresh() async {
    final resp = await refreshDio.post('/refresh');
    if (resp.statusCode != 200) {
      throw Exception('Refresh sikertelen (HTTP ${resp.statusCode}).');
    }
    final data = resp.data;
    if (data is Map && data['success'] != true) {
      throw Exception(data['message'] ?? 'Refresh sikertelen.');
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions ro) {
    final newExtra = Map<String, dynamic>.from(ro.extra);
    newExtra['__isRetry'] = true;

    return dio.request<dynamic>(
      ro.path,
      data: ro.data,
      queryParameters: ro.queryParameters,
      cancelToken: ro.cancelToken,
      onReceiveProgress: ro.onReceiveProgress,
      onSendProgress: ro.onSendProgress,
      options: Options(
        method: ro.method,
        headers: ro.headers,
        responseType: ro.responseType,
        contentType: ro.contentType,
        followRedirects: ro.followRedirects,
        validateStatus: ro.validateStatus,
        receiveTimeout: ro.receiveTimeout,
        sendTimeout: ro.sendTimeout,
        extra: newExtra,
      ),
    );
  }
}
