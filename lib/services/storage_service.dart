import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/event_model.dart';
import '../models/guest_model.dart';

/// طبقة حفظ البيانات محلياً على الجهاز (بدون إنترنت)
class StorageService {
  static const _kOnboardingDone = 'onboarding_done';
  static const _kUserProfile = 'user_profile';
  static const _kEvents = 'events';
  static const _kGuests = 'guests';
  static const _kDarkMode = 'dark_mode';

  final SharedPreferences prefs;
  StorageService(this.prefs);

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ---------- الإعداد الأولي ----------
  bool get onboardingDone => prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool value) => prefs.setBool(_kOnboardingDone, value);

  bool get darkMode => prefs.getBool(_kDarkMode) ?? false;
  Future<void> setDarkMode(bool value) => prefs.setBool(_kDarkMode, value);

  // ---------- الملف الشخصي ----------
  UserProfile? loadUserProfile() {
    final raw = prefs.getString(_kUserProfile);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw));
  }

  Future<void> saveUserProfile(UserProfile profile) =>
      prefs.setString(_kUserProfile, jsonEncode(profile.toJson()));

  // ---------- المناسبات ----------
  List<EventModel> loadEvents() {
    final raw = prefs.getString(_kEvents);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => EventModel.fromJson(e)).toList();
  }

  Future<void> saveEvents(List<EventModel> events) =>
      prefs.setString(_kEvents, jsonEncode(events.map((e) => e.toJson()).toList()));

  // ---------- المدعوون ----------
  List<GuestModel> loadGuests() {
    final raw = prefs.getString(_kGuests);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => GuestModel.fromJson(e)).toList();
  }

  Future<void> saveGuests(List<GuestModel> guests) =>
      prefs.setString(_kGuests, jsonEncode(guests.map((e) => e.toJson()).toList()));
}
