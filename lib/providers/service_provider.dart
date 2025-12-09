import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';

class ServiceProvider with ChangeNotifier {
  List<ServiceModel> _services = [];
  String _currentUserId = ""; // ID User saat ini
  String _searchQuery = ""; // Query Pencarian

  // --- GETTERS ---
  List<ServiceModel> get services => _services;

  // Getter untuk data yang sudah difilter berdasarkan search
  List<ServiceModel> get filteredServices {
    if (_searchQuery.isEmpty) {
      return _services;
    }
    return _services
        .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // --- SEARCH LOGIC ---
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // --- LOGIC USER ID ---
  Future<void> setUserId(String userId) async {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _services = [];
      _searchQuery = "";
      notifyListeners();
      await loadServices();
    }
  }

  // --- CRUD ---
  Future<void> addService(ServiceModel service) async {
    _services.add(service);
    notifyListeners();
    _saveServices();
  }

  Future<void> updateService(ServiceModel updatedService) async {
    final index = _services.indexWhere((s) => s.id == updatedService.id);
    if (index != -1) {
      _services[index] = updatedService;
      notifyListeners();
      _saveServices();
    }
  }

  Future<void> deleteService(String id) async {
    _services.removeWhere((s) => s.id == id);
    notifyListeners();
    _saveServices();
  }

  // --- LOAD & SAVE PER USER ---
  Future<void> loadServices() async {
    if (_currentUserId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    // Gunakan Key Unik per User
    final String key = 'services_$_currentUserId';

    final String? data = prefs.getString(key);
    if (data != null) {
      final List<dynamic> jsonList = json.decode(data);
      _services = jsonList.map((e) => ServiceModel.fromMap(e)).toList();
    } else {
      _services = [];
    }
    notifyListeners();
  }

  Future<void> _saveServices() async {
    if (_currentUserId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final String key = 'services_$_currentUserId';

    final String data = json.encode(_services.map((e) => e.toMap()).toList());
    await prefs.setString(key, data);
  }
}
