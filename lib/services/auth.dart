import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:kapame/services/session_storage.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/auth_response.dart';

class AuthService extends ChangeNotifier {
  final SessionStorage _sessionStorage = SessionStorage();

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

  Future<bool> login(String email, String password,
      {bool rememberMe = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      var res = await _dio.post(
        'https://kapameapi.azurewebsites.net/api/auth/login',
        data: {"email": email.trim(), "password": password.trim()},
      );

      if (res.statusCode == 200) {
        AuthResponse currentUser = AuthResponse(
          res.data['message'],
          res.data['isSuccess'],
          res.data['token'],
          res.data['errors'],
          AppUser.fromMap(res.data['user']),
          DateTime.parse(res.data['expireDate']),
        );

        if (!currentUser.isSuccess || currentUser.token.isEmpty) return false;
        await _sessionStorage.save(currentUser, rememberMe: rememberMe);
        _currentUser = currentUser;
        return true;
      }
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _sessionStorage.clear();
    notifyListeners();
  }

  Future<bool> checkSession(BuildContext context) async {
    _currentUser = await _sessionStorage.restore();
    notifyListeners();
    return _currentUser != null;
  }
}
