import 'package:flutter/material.dart';
import '../models/guest_model.dart';
import '../services/storage_service.dart';

class GuestsProvider extends ChangeNotifier {
  final StorageService storage;
  List<GuestModel> _guests = [];

  GuestsProvider(this.storage) {
    _guests = storage.loadGuests();
  }

  List<GuestModel> get all => List.unmodifiable(_guests);

  int get totalGuests => _guests.length;

  List<GuestModel> forEvent(String eventId) =>
      _guests.where((g) => g.eventId == eventId).toList();

  List<GuestModel> searchInEvent(String eventId, String query) {
    final list = forEvent(eventId);
    if (query.trim().isEmpty) return list;
    return list.where((g) => g.name.contains(query) || g.phone.contains(query)).toList();
  }

  /// إحصائيات مناسبة: تمت دعوتهم / تم الاتصال بهم / لم تتم دعوتهم بعد
  Map<String, int> statsForEvent(String eventId) {
    final list = forEvent(eventId);
    final invited = list.where((g) => g.invited).length;
    final called = list.where((g) => g.called).length;
    final notInvited = list.length - invited;
    return {
      'total': list.length,
      'invited': invited,
      'called': called,
      'notInvited': notInvited,
    };
  }

  Future<void> add(GuestModel guest) async {
    _guests.add(guest);
    await storage.saveGuests(_guests);
    notifyListeners();
  }

  Future<void> addMany(List<GuestModel> guests) async {
    _guests.addAll(guests);
    await storage.saveGuests(_guests);
    notifyListeners();
  }

  Future<void> update(GuestModel guest) async {
    final idx = _guests.indexWhere((g) => g.id == guest.id);
    if (idx >= 0) {
      _guests[idx] = guest;
      await storage.saveGuests(_guests);
      notifyListeners();
    }
  }

  Future<void> toggleInvited(String id) async {
    final g = _guests.firstWhere((g) => g.id == id);
    g.invited = !g.invited;
    await storage.saveGuests(_guests);
    notifyListeners();
  }

  Future<void> toggleCalled(String id) async {
    final g = _guests.firstWhere((g) => g.id == id);
    g.called = !g.called;
    await storage.saveGuests(_guests);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _guests.removeWhere((g) => g.id == id);
    await storage.saveGuests(_guests);
    notifyListeners();
  }

  Future<void> deleteForEvent(String eventId) async {
    _guests.removeWhere((g) => g.eventId == eventId);
    await storage.saveGuests(_guests);
    notifyListeners();
  }
}
