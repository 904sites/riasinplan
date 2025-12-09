import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  // Cek status login
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool('is_logged_in') ?? false;
    final currentEmail = prefs.getString('current_user_email');

    if (isLogged && currentEmail != null) {
      final allUsersString = prefs.getString('users_db');
      if (allUsersString != null) {
        final Map<String, dynamic> allUsers = json.decode(allUsersString);
        if (allUsers.containsKey(currentEmail)) {
          _currentUser = UserModel.fromMap(allUsers[currentEmail]);
          _isLoggedIn = true;
          notifyListeners();
        }
      }
    }
  }

  // UPDATE USER (Fitur Baru)
  Future<void> updateUser(UserModel updatedUser) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Ambil DB User
    String? allUsersString = prefs.getString('users_db');
    Map<String, dynamic> allUsers = {};
    if (allUsersString != null) {
      allUsers = json.decode(allUsersString);
    }

    // 2. Update data user ini di Map (berdasarkan email sebagai key)
    allUsers[updatedUser.email] = updatedUser.toMap();

    // 3. Simpan balik ke SharedPreferences
    await prefs.setString('users_db', json.encode(allUsers));

    // 4. Update state saat ini
    _currentUser = updatedUser;

    // 5. Update session data (jika perlu)
    await prefs.setString('user_data', updatedUser.toJson());

    notifyListeners();
  }

  Future<bool> register(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    String? allUsersString = prefs.getString('users_db');
    Map<String, dynamic> allUsers = {};
    if (allUsersString != null) allUsers = json.decode(allUsersString);

    if (allUsers.containsKey(user.email)) {
      throw Exception("Email sudah terdaftar!");
    }

    allUsers[user.email] = user.toMap();
    await prefs.setString('users_db', json.encode(allUsers));
    await _setLoginSession(user);
    return true;
  }

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    String? allUsersString = prefs.getString('users_db');
    if (allUsersString == null) return false;

    Map<String, dynamic> allUsers = json.decode(allUsersString);
    if (allUsers.containsKey(email)) {
      final userData = allUsers[email];
      if (userData['password'] == password) {
        final user = UserModel.fromMap(userData);
        await _setLoginSession(user);
        return true;
      }
    }
    return false;
  }

  Future<void> _setLoginSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    _currentUser = user;
    _isLoggedIn = true;
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('current_user_email', user.email);
    // Simpan data single user juga untuk backup
    await prefs.setString('user_data', user.toJson());
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('current_user_email');
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }
}
