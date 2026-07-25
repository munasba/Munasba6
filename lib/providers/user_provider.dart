import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  final StorageService storage;
  UserProfile? profile;
  bool darkMode;

  UserProvider(this.storage)
      : profile = storage.loadUserProfile(),
        darkMode = storage.darkMode;

  Future<void> saveProfile(UserProfile p) async {
    profile = p;
    await storage.saveUserProfile(p);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    darkMode = value;
    await storage.setDarkMode(value);
    notifyListeners();
  }
}
