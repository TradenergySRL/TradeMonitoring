import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService with ChangeNotifier {
  static const String baseUrl = 'https://together-amazingly-mouse.ngrok-free.app';
  String _token = '';
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  String get token => _token;

  AuthService() {
    _initializeAuthStatus();
  }

  Future<void> _initializeAuthStatus() async {
    await checkAuthStatus();
  }

  Future<void> authenticateWithCredentials(String username, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final auth = 'Basic ${base64Encode(utf8.encode('$username:$password'))}';

    final response = await http.post(
      url,
      headers: {'Authorization': auth},
    );

    if (response.statusCode == 200) {
      _token = json.decode(response.body)['token'];
      _isAuthenticated = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token);
      notifyListeners();
    } else {
      throw Exception('Failed to authenticate');
    }
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('token')) {
      _token = prefs.getString('token')!;
      _isAuthenticated = true;
    } else {
      _isAuthenticated = false;
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _isAuthenticated = false;
    notifyListeners();
  }
}
