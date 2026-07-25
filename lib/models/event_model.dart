import 'package:flutter/material.dart';

enum EventType {
  wedding, // حفل زفاف
  engagement, // خطوبة
  birthday, // عيد ميلاد
  graduation, // تخرج
  newborn, // مولود جديد
  housewarming, // بيت جديد
  anniversary, // ذكرى
  religious, // مناسبة دينية
  other, // أخرى
}

extension EventTypeX on EventType {
  String get label {
    switch (this) {
      case EventType.wedding:
        return 'حفل زفاف';
      case EventType.engagement:
        return 'خطوبة';
      case EventType.birthday:
        return 'عيد ميلاد';
      case EventType.graduation:
        return 'حفل تخرج';
      case EventType.newborn:
        return 'مولود جديد';
      case EventType.housewarming:
        return 'بيت جديد';
      case EventType.anniversary:
        return 'ذكرى سنوية';
      case EventType.religious:
        return 'مناسبة دينية';
      case EventType.other:
        return 'مناسبة أخرى';
    }
  }

  IconData get icon {
    switch (this) {
      case EventType.wedding:
        return Icons.favorite;
      case EventType.engagement:
        return Icons.diamond_outlined;
      case EventType.birthday:
        return Icons.cake;
      case EventType.graduation:
        return Icons.school;
      case EventType.newborn:
        return Icons.child_friendly;
      case EventType.housewarming:
        return Icons.home;
      case EventType.anniversary:
        return Icons.celebration;
      case EventType.religious:
        return Icons.mosque;
      case EventType.other:
        return Icons.event;
    }
  }
}

class EventModel {
  String id;
  String name;
  EventType type;
  DateTime date;
  TimeOfDay time;
  String location;
  String notes;
  String? imagePath;
  String invitationTemplateId; // القالب المختار لبطاقة الدعوة
  String invitationText; // نص الدعوة القابل للتعديل
  String invitationFontFamily;
  int invitationBackgroundColorValue;

  EventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.time,
    required this.location,
    this.notes = '',
    this.imagePath,
    this.invitationTemplateId = 'template_1',
    String? invitationText,
    this.invitationFontFamily = 'Cairo',
    this.invitationBackgroundColorValue = 0xFFFDF3F1,
  }) : invitationText = invitationText ?? '';

  DateTime get dateTime =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  Duration get remaining {
    final diff = dateTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isPast => remaining == Duration.zero && DateTime.now().isAfter(dateTime);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'date': date.toIso8601String(),
        'time': '${time.hour}:${time.minute}',
        'location': location,
        'notes': notes,
        'imagePath': imagePath,
        'invitationTemplateId': invitationTemplateId,
        'invitationText': invitationText,
        'invitationFontFamily': invitationFontFamily,
        'invitationBackgroundColorValue': invitationBackgroundColorValue,
      };

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['time'] as String? ?? '18:0').split(':');
    return EventModel(
      id: json['id'],
      name: json['name'] ?? '',
      type: EventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EventType.other,
      ),
      date: DateTime.parse(json['date']),
      time: TimeOfDay(
        hour: int.tryParse(timeParts[0]) ?? 18,
        minute: int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0,
      ),
      location: json['location'] ?? '',
      notes: json['notes'] ?? '',
      imagePath: json['imagePath'],
      invitationTemplateId: json['invitationTemplateId'] ?? 'template_1',
      invitationText: json['invitationText'] ?? '',
      invitationFontFamily: json['invitationFontFamily'] ?? 'Cairo',
      invitationBackgroundColorValue: json['invitationBackgroundColorValue'] ?? 0xFFFDF3F1,
    );
  }
}
