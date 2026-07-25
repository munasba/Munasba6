enum GuestRelation { family, friend, colleague, other }

extension GuestRelationX on GuestRelation {
  String get label {
    switch (this) {
      case GuestRelation.family:
        return 'عائلة';
      case GuestRelation.friend:
        return 'صديق';
      case GuestRelation.colleague:
        return 'زميل';
      case GuestRelation.other:
        return 'أخرى';
    }
  }
}

class GuestModel {
  String id;
  String eventId; // فارغ = مدعو عام غير مرتبط بمناسبة محددة (دفتر جهات الاتصال)
  String name;
  String phone;
  GuestRelation relation;
  bool invited; // تم إرسال الدعوة له
  bool called; // تم التواصل معه هاتفياً

  GuestModel({
    required this.id,
    required this.eventId,
    required this.name,
    required this.phone,
    this.relation = GuestRelation.friend,
    this.invited = false,
    this.called = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'name': name,
        'phone': phone,
        'relation': relation.name,
        'invited': invited,
        'called': called,
      };

  factory GuestModel.fromJson(Map<String, dynamic> json) => GuestModel(
        id: json['id'],
        eventId: json['eventId'] ?? '',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        relation: GuestRelation.values.firstWhere(
          (e) => e.name == json['relation'],
          orElse: () => GuestRelation.other,
        ),
        invited: json['invited'] ?? false,
        called: json['called'] ?? false,
      );
}
