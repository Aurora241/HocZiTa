import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/nks_user_model.dart';

class NKSApiException implements Exception {
  final String message;
  final int? statusCode;
  NKSApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NKSApiService {
  static const _accountBase = 'https://account.nks.vn/api/nks';
  static const _onlineBase = 'https://online.nks.vn/api/nks';

  late final Dio _dio;

  NKSApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ));
  }

  // ── Auth ─────────────────────────────────────────────────────────────

  Future<NKSUserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '$_accountBase/user/login',
        data: {
          'username': username,
          'password': password,
          'system': 'NKS',
          'device': 'HocZiTa Flutter',
        },
      );
      final data = res.data['data'];
      return NKSUserModel.fromJson(
        data['user'] as Map<String, dynamic>,
        token: data['access_token'] as String,
      );
    } on DioException catch (e) {
      throw NKSApiException(_parseDioError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<NKSUserModel> getUserInfo({required String token}) async {
    try {
      final res = await _dio.post(
        '$_accountBase/user',
        data: {'access_token': token},
      );
      final data = res.data['data'];
      return NKSUserModel.fromJson(
        data['user'] as Map<String, dynamic>,
        token: token,
      );
    } on DioException catch (e) {
      throw NKSApiException(_parseDioError(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Update ────────────────────────────────────────────────────────────

  Future<NKSUserModel> updateInfo({
    required String token,
    String? firstname,
    String? lastname,
    String? intro,
    String? phone,
    int? gender,
    String? website,
    String? dob,
    String? pob,
    String? idNumber,
    String? idDate,
    String? idPlace,
    String? province,
  }) async {
    try {
      final res = await _dio.post(
        '$_accountBase/user/updateInfo',
        data: <String, dynamic>{
          'access_token': token,
          if (firstname != null) 'firstname': firstname,
          if (lastname != null) 'lastname': lastname,
          if (intro != null) 'intro': intro,
          if (phone != null) 'phone': phone,
          if (gender != null) 'gender': gender,
          if (website != null) 'website': website,
          if (dob != null) 'dob': dob,
          if (pob != null) 'pob': pob,
          if (idNumber != null) 'id_number': idNumber,
          if (idDate != null) 'id_date': idDate,
          if (idPlace != null) 'id_place': idPlace,
          if (province != null) 'province': province,
        },
      );
      final data = res.data['data'];
      return NKSUserModel.fromJson(
        data['user'] as Map<String, dynamic>,
        token: token,
      );
    } on DioException catch (e) {
      throw NKSApiException(_parseDioError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<NKSUserModel> updatePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final res = await _dio.post(
        '$_accountBase/user/updatePass',
        data: {
          'old_password': oldPassword,
          'password': newPassword,
          'access_token': token,
        },
      );
      final data = res.data['data'];
      return NKSUserModel.fromJson(
        data['user'] as Map<String, dynamic>,
        token: token,
      );
    } on DioException catch (e) {
      throw NKSApiException(_parseDioError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<NKSUserModel> updateAvatar({
    required String token,
    required String base64Image,
  }) async {
    try {
      final res = await _dio.post(
        '$_accountBase/user/updateAvatar',
        data: {
          'avatar': base64Image,
          'access_token': token,
        },
      );
      final data = res.data['data'];
      return NKSUserModel.fromJson(
        data['user'] as Map<String, dynamic>,
        token: token,
      );
    } on DioException catch (e) {
      throw NKSApiException(_parseDioError(e), statusCode: e.response?.statusCode);
    }
  }

  Future<NKSUserModel> updateCccd({
    required String token,
    required String frontBase64,
    required String backBase64,
    required String number,
    required String date,
    required String place,
  }) async {
    try {
      final res = await _dio.post(
        '$_accountBase/user/updateCccd',
        data: {
          'front': frontBase64,
          'back': backBase64,
          'number': number,
          'date': date,
          'place': place,
          'access_token': token,
        },
      );
      final data = res.data['data'];
      return NKSUserModel.fromJson(
        data['user'] as Map<String, dynamic>,
        token: token,
      );
    } on DioException catch (e) {
      throw NKSApiException(_parseDioError(e), statusCode: e.response?.statusCode);
    }
  }

  // ── Địa chỉ ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProvinces() async {
    try {
      final res = await _dio.post(
        '$_onlineBase/provinces',
        data: {'country_id': 192, 'slcBox': true},
      );
      debugPrint('[NKS] provinces status: ${res.statusCode}');

      // Dio có thể trả String nếu server không set Content-Type: application/json
      dynamic body = res.data;
      if (body is String) {
        debugPrint('[NKS] provinces body is String, parsing JSON manually');
        body = jsonDecode(body);
      }
      debugPrint('[NKS] provinces body type: ${body.runtimeType}');

      if (body is! Map) {
        debugPrint('[NKS] provinces unexpected body: $body');
        return [];
      }

      final list = body['data'];
      debugPrint('[NKS] provinces list type: ${list.runtimeType}, length: ${list?.length}');
      if (list != null && (list as List).isNotEmpty) {
        debugPrint('[NKS] provinces first item: ${list.first}');
      }
      if (list == null) return [];
      return List<Map<String, dynamic>>.from(list as List);
    } on DioException catch (e) {
      debugPrint('[NKS] provinces DioError: ${e.type} | ${e.response?.statusCode} | ${e.response?.data}');
      throw NKSApiException(_parseDioError(e));
    } catch (e) {
      debugPrint('[NKS] provinces unexpected error: $e');
      throw NKSApiException('Không thể tải danh sách tỉnh thành');
    }
  }

  Future<List<Map<String, dynamic>>> getAdministratives({
    required int provinceId,
  }) async {
    try {
      final res = await _dio.post(
        '$_onlineBase/administratives',
        data: {'province_id': provinceId, 'slcBox': true},
      );
      dynamic body = res.data;
      if (body is String) body = jsonDecode(body);
      if (body is! Map) return [];
      final list = body['data'];
      if (list == null) return [];
      return List<Map<String, dynamic>>.from(list as List);
    } on DioException catch (e) {
      throw NKSApiException(_parseDioError(e));
    } catch (e) {
      throw NKSApiException('Không thể tải danh sách quận/huyện');
    }
  }

  Future<List<Map<String, dynamic>>> getCommunes({
    required int districtId,
  }) async {
    try {
      final res = await _dio.post(
        '$_onlineBase/communes',
        data: {'administrative_id': districtId, 'slcBox': true},
      );
      debugPrint('[NKS] communes status: ${res.statusCode}');
      dynamic body = res.data;
      if (body is String) body = jsonDecode(body);
      if (body is! Map) {
        debugPrint('[NKS] communes unexpected body type: ${body.runtimeType}');
        return [];
      }
      final list = body['data'];
      debugPrint('[NKS] communes length: ${list?.length}, first: ${(list as List?)?.firstOrNull}');
      if (list == null) return [];
      return List<Map<String, dynamic>>.from(list);
    } on DioException catch (e) {
      debugPrint('[NKS] communes DioError: ${e.type} | ${e.response?.statusCode} | ${e.response?.data}');
      throw NKSApiException(_parseDioError(e));
    } catch (e) {
      debugPrint('[NKS] communes error: $e');
      throw NKSApiException('Không thể tải danh sách xã/phường');
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────

  String _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Kết nối quá chậm, vui lòng thử lại';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Không có kết nối mạng';
    }
    final msg = e.response?.data?['message'];
    if (msg != null) return msg.toString();
    return 'Có lỗi xảy ra (${e.response?.statusCode ?? 'unknown'})';
  }
}
