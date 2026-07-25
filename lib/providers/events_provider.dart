import 'dart:async';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/storage_service.dart';

class EventsProvider extends ChangeNotifier {
  final StorageService storage;
  List<EventModel> _events = [];
  Timer? _ticker;

  EventsProvider(this.storage) {
    _events = storage.loadEvents();
    // تحديث كل دقيقة لتحريك العد التنازلي في الشاشة الرئيسية
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => notifyListeners());
  }

  List<EventModel> get events => List.unmodifiable(_events);

  List<EventModel> get upcoming {
    final list = _events.where((e) => !e.isPast).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  List<EventModel> search(String query) {
    if (query.trim().isEmpty) return upcoming;
    final q = query.trim();
    return _events.where((e) =>
        e.name.contains(q) || e.location.contains(q) || e.type.label.contains(q)).toList();
  }

  EventModel? byId(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addOrUpdate(EventModel event) async {
    final idx = _events.indexWhere((e) => e.id == event.id);
    if (idx >= 0) {
      _events[idx] = event;
    } else {
      _events.add(event);
    }
    await storage.saveEvents(_events);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _events.removeWhere((e) => e.id == id);
    await storage.saveEvents(_events);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
