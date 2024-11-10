import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/auth_response.dart';

class AuthService extends ChangeNotifier {
  FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  static const String _keyToken = 'token';
  static const String _keyUser = 'user';

  late Dio _dio;
  AuthResponse? _currentUser;
  bool _isLoading = false;

  AuthService() {
    _dio = Dio();
    _dio.options.baseUrl = 'https://kapameapi.azurewebsites.net/api';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final Dio dio = Dio();

      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      var res = await dio.post(
        'https://kapameapi.azurewebsites.net/api/auth/login',
        data: {"email": email.trim(), "password": password.trim()},
      );

      print(res);
      print(res.statusCode);

      if (res.statusCode == 200) {
        AuthResponse currentUser = AuthResponse(
          res.data['message'],
          res.data['isSuccess'],
          res.data['token'],
          res.data['errors'],
          AppUser.fromMap(res.data['user']),
          DateTime.parse(res.data['expireDate']),
        );

        await _saveSession(currentUser);
        print(currentUser.user?.fullName);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (e is DioException) {
        print("Login error: ${e.response?.data['message']}");
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _clearSession();
    notifyListeners();
  }

  Future<bool> checkSession(BuildContext context) async {
    final token = await secureStorage.read(key: _keyToken);
    final user = await secureStorage.read(key: _keyUser);

    if (token != null && user != null) {
      // Deserialize user data to a Map
      Map<String, dynamic> userDataMap = jsonDecode(user);

      // Create the _currentUser with deserialized user data
      _currentUser = AuthResponse(
        "Session restored",
        true,
        token,
        [],
        AppUser.fromMap(userDataMap), // Use the deserialized Map here
        DateTime.now().add(
          const Duration(days: 30),
        ),
      );

      notifyListeners();
      return true;
    }

    return false;
  }

  Future<void> _saveSession(AuthResponse user) async {
    await secureStorage.write(key: _keyToken, value: user.token);
    await secureStorage.write(key: _keyUser, value: json.encode(user.user));
    print(await secureStorage.read(key: _keyUser));
  }

  Future<void> _clearSession() async {
    await secureStorage.delete(key: _keyToken);
    await secureStorage.delete(key: _keyUser);
  }
}
